output "private_ip" {
  description = "private ip addresses"
  value = aws_subnet.private_subnet[*].cidr_block
}

output "assocoation_id" {
  value =  aws_route_table_association.public_subnet_asso[*].id
}