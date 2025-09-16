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

resource "aws_internet_gateway" "gw" {
 vpc_id = aws_vpc.vpc.id
 tags = {
   Name = "Project VPC IG"
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
    Name = "3rd Route Table"
  }
}




resource "aws_route_table_association" "public_subnet_asso" {
 count = length(var.public_addresses)
 subnet_id = element(aws_subnet.public_subnet[*].id, count.index)
 //for_each = aws_subnet.public_subnet   # write out with for_each    literally set  
 //subnet_id      = each.value.id 
 route_table_id = aws_route_table.second_rt.id
} 

resource "aws_route_table_association" "private_subnet_asso" {
 count = length(var.private_addresses)
 subnet_id = element(aws_subnet.private_subnet[*].id, count.index)
 
 //for_each = aws_subnet.public_subnet   # write out with for_each    literally set  
 //subnet_id      = each.value.id
 
 route_table_id = aws_route_table.third_rt.id
}



resource "aws_network_acl" "main_public_NACL" {
  vpc_id = aws_vpc.vpc.id  
  # egress {
  #   protocol   = "tcp"
  #   rule_no    = 200
  #   action     = "allow"
  #   cidr_block = "10.3.0.0/"
  #   from_port  = 443
  #   to_port    = 443
  # }

  # ingress {
  #   protocol   = "tcp"
  #   rule_no    = 100
  #   action     = "allow"
  #   cidr_block = "10.3.0.0/18"
  #   from_port  = 80
  #   to_port    = 80
  # }
  tags = {
    Name = "main public NACL"
  }
}


resource "aws_network_acl" "main_private_NACL" {
  vpc_id = aws_vpc.vpc.id  
   tags = {
    Name = "main public NACL"
  }
}

resource "aws_network_acl_rule" "public_rules_ingress" {
  protocol   = "tcp"
  rule_number    = 20
  rule_action = "allow"
  network_acl_id = aws_network_acl.main_public_NACL.id
  cidr_block = "0.0.0.0/0" # all inet https + http
  from_port      = 80
  to_port        = 443
  egress         = false
}

resource "aws_network_acl_rule" "public_rules_inress" {
  protocol   = "tcp"
  rule_number    = 10
  rule_action = "allow"
  network_acl_id = aws_network_acl.main_public_NACL.id
  cidr_block = "11.203.40.183/32" #for ssh
  from_port      = 22
  to_port        = 22
  egress         = false
}
resource "aws_network_acl_rule" "public_rules_egress" {
  network_acl_id = aws_network_acl.main_public_NACL.id
  rule_number    = 100
  egress         = true # true = ИСХОДЯЩИЙ
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}


resource "aws_network_acl_rule" "private_rules_egress" {
  protocol   = "-1"
  rule_number    = 20
  rule_action = "allow"
  network_acl_id = aws_network_acl.main_private_NACL.id
  cidr_block = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
  egress         = true
}

resource "aws_network_acl_rule" "private_rules_ingress" {
  protocol   = "-1"
  rule_number    = 200
  rule_action = "allow"
  network_acl_id = aws_network_acl.main_private_NACL.id
  cidr_block = aws_vpc.vpc.cidr_block
  from_port      = 0
  to_port        = 0
  egress         = false
}



resource "aws_network_acl_association" "public_NACL_asso_ingress" {
  count = length(var.public_addresses)
  subnet_id = aws_subnet.public_subnet[count.index].id
  network_acl_id = aws_network_acl.main_public_NACL.id
}
resource "aws_network_acl_association" "private_NACL_asso_ingress" {
  count = length(var.private_addresses)
  subnet_id = aws_subnet.private_subnet[count.index].id
  network_acl_id = aws_network_acl.main_private_NACL.id
}