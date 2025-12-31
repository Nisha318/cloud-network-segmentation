output "vpc_id" {
  value = aws_vpc.this.id
}

output "dmz_subnet_ids" {
  value = [for s in aws_subnet.dmz : s.id]
}

output "app_subnet_ids" {
  value = [for s in aws_subnet.app : s.id]
}

output "data_subnet_ids" {
  value = [for s in aws_subnet.data : s.id]
}

output "endpoints_subnet_ids" {
  value = [for s in aws_subnet.endpoints : s.id]
}


output "public_route_table_id" {
  value = aws_route_table.public.id
}

output "app_route_table_id" {
  value = aws_route_table.app_private.id
}

output "data_route_table_id" {
  value = aws_route_table.data_private.id
}

output "endpoints_route_table_id" {
  value = aws_route_table.endpoints_private.id
}
