locals {
  tier_set = toset(var.tiers)
}

resource "aws_security_group" "tier" {
  for_each = local.tier_set

  name        = "${var.name_prefix}-sg-${each.key}"
  description = "Tier security group for ${each.key}"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-sg-${each.key}"
    Tier = each.key
  })
}

# Create ingress rules on the destination tier SG.
resource "aws_security_group_rule" "tier_ingress" {
  for_each = {
    for r in var.rules : "${r.name}-${r.from_tier}-${r.to_tier}-${r.from_port}" => r
  }

  type                     = "ingress"
  security_group_id        = aws_security_group.tier[each.value.to_tier].id
  source_security_group_id = aws_security_group.tier[each.value.from_tier].id

  protocol  = each.value.protocol
  from_port = each.value.from_port
  to_port   = each.value.to_port

  description = each.value.desc
}

resource "aws_security_group_rule" "tier_egress" {
  for_each = {
    for r in var.rules : "${r.name}-${r.from_tier}-${r.to_tier}-${r.from_port}" => r
  }

  type                     = "egress"
  security_group_id        = aws_security_group.tier[each.value.from_tier].id
  source_security_group_id = aws_security_group.tier[each.value.to_tier].id

  protocol  = each.value.protocol
  from_port = each.value.from_port
  to_port   = each.value.to_port

  description = each.value.desc
}

resource "aws_security_group_rule" "app_https_egress" {
  count = var.allow_app_https_egress ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.tier["app"].id

  protocol    = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_blocks = ["0.0.0.0/0"]

  description = "App tier outbound HTTPS for patching"
}


resource "aws_security_group_rule" "dmz_http_ingress" {
  type              = "ingress"
  security_group_id = aws_security_group.tier["dmz"].id

  protocol    = "tcp"
  from_port   = 80
  to_port     = 80
  cidr_blocks = ["0.0.0.0/0"]

  description = "Internet to DMZ ALB (demo HTTP)"
}
