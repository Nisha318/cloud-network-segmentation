data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-igw"
  })
}

# DMZ subnets
resource "aws_subnet" "dmz" {
  for_each = { for i, cidr in var.dmz_subnet_cidrs : i => cidr }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = local.azs[tonumber(each.key)]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-dmz-${each.key}"
    Tier = "dmz"
  })
}

# App subnets
resource "aws_subnet" "app" {
  for_each = { for i, cidr in var.app_subnet_cidrs : i => cidr }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = local.azs[tonumber(each.key)]

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-app-${each.key}"
    Tier = "app"
  })
}

# Data subnets
resource "aws_subnet" "data" {
  for_each = { for i, cidr in var.data_subnet_cidrs : i => cidr }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = local.azs[tonumber(each.key)]

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-data-${each.key}"
    Tier = "data"
  })
}

# Endpoints subnets
resource "aws_subnet" "endpoints" {
  for_each = { for i, cidr in var.endpoints_subnet_cidrs : i => cidr }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = local.azs[tonumber(each.key)]

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-endpoints-${each.key}"
    Tier = "endpoints"
  })
}

# -------------------------
# Route tables
# -------------------------

# Public route table for DMZ
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rt-public"
    Tier = "dmz"
  })
}

resource "aws_route" "public_igw" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "dmz" {
  for_each       = aws_subnet.dmz
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Private route table for App tier (NAT)
resource "aws_route_table" "app_private" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rt-app-private"
    Tier = "app"
  })
}

resource "aws_route_table_association" "app" {
  for_each       = aws_subnet.app
  subnet_id      = each.value.id
  route_table_id = aws_route_table.app_private.id
}

# Private route table for Data tier (no default route by design)
resource "aws_route_table" "data_private" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rt-data-private"
    Tier = "data"
  })
}

resource "aws_route_table_association" "data" {
  for_each       = aws_subnet.data
  subnet_id      = each.value.id
  route_table_id = aws_route_table.data_private.id
}

# Private route table for Endpoints tier (no default route by design)
resource "aws_route_table" "endpoints_private" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rt-endpoints-private"
    Tier = "endpoints"
  })
}

resource "aws_route_table_association" "endpoints" {
  for_each       = aws_subnet.endpoints
  subnet_id      = each.value.id
  route_table_id = aws_route_table.endpoints_private.id
}

# -------------------------
# NAT Gateway (optional)
# -------------------------
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-eip"
  })
}

# Put NAT in DMZ subnet 0
resource "aws_nat_gateway" "this" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.dmz["0"].id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route" "app_nat" {
  count                  = var.enable_nat_gateway ? 1 : 0
  route_table_id         = aws_route_table.app_private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}
