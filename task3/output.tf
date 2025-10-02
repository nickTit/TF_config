output "public_ipv4_adresses" {
  value = [aws_instance.ec2.public_ip, aws_instance.ec2.public_dns]
  description = "available public ipv4 adresses"
}


output "endpoint_policy" {
  value = aws_vpc_endpoint.s3.policy
}

output "subnets_adresses" {
  value = aws_subnet.subnets[*].cidr_block
}
