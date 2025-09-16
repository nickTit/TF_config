provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
} 


resource "aws_vpc" "vpc" {
  cidr_block       = "172.16.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}



resource "aws_subnet" "public_subnet" {
  count = length(var.public_addresses) # 3
  //for_each = toset(var.public_addresses) 
  vpc_id     = aws_vpc.vpc.id
  //cidr_block = each.value
  cidr_block = element(tolist(var.public_addresses), count.index) #choose by index 0..2
  availability_zone = var.availability_zone[0] #may also be set via list of variables
  
  tags = {
    //Name = "Main subnet # ${each.key}"
    Name = "Main public subnet # ${count.index}"
  }
}


resource "aws_subnet" "private_subnet" {
  count = length(var.private_addresses) # 3
  //for_each = toset(var.public_addresses) 
  vpc_id     = aws_vpc.vpc.id
  //cidr_block = each.value
  cidr_block = element(tolist(var.private_addresses), count.index) #choose by index 0..2
  availability_zone = var.availability_zone[1] #may also be set via list of variables
  
  tags = {
    //Name = "Main subnet # ${each.key}"
    Name = "Main private subnet # ${count.index}"
  }
}




resource "aws_internet_gateway" "gw" {
 vpc_id = aws_vpc.vpc.id
 tags = {
   Name = "Project VPC IG"
 }

}

resource "aws_route_table" "second_rt" {
  vpc_id = aws_vpc.vpc.id 

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "2nd Route Table"
  }
} # только так можно сделать? можно ли просто сделать 2 
  # правила в route? или обязательно новую создавать таблицу?
resource "aws_route_table" "third_rt" {
  vpc_id = aws_vpc.vpc.id 
  tags = {
    Name = "2nd Route Table"
  }
}




resource "aws_route_table_association" "public_subnet_asso" {
 count = length(var.public_addresses)
 subnet_id      = element(aws_subnet.public_subnet[*].id, count.index)
 
 //for_each = aws_subnet.public_subnet   # write out with for_each    literally set  
 //subnet_id      = each.value.id
 
 route_table_id = aws_route_table.second_rt.id
} 
resource "aws_route_table_association" "private_subnet_asso" {
 count = length(var.private_addresses)
 subnet_id      = element(aws_subnet.private_subnet[*].id, count.index)
 
 //for_each = aws_subnet.public_subnet   # write out with for_each    literally set  
 //subnet_id      = each.value.id
 
 route_table_id = aws_route_table.third_rt.id
}