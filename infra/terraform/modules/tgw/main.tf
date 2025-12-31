resource "aws_ec2_transit_gateway" "this" {
  description = "${var.name_prefix} transit gateway"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-tgw"
  })
}
