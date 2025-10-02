provider "aws" {
  secret_key = var.secret_key
  access_key = var.access_key
  region = var.region
}
resource "aws_instance" "ec2" {
  ami = "ami-043339ea831b48099"
  instance_type = "t3.micro"
  security_groups = [aws_security_group.web_sg.id]
user_data     = <<-EOF
                    #!/bin/bash
                    sudo yum install -y nginx
                    sudo systemctl start nginx
                  EOF
  
  associate_public_ip_address = true //it will be changed every time infrastructure destroyed->applied | change to elastic?
  private_ip = "172.16.0.4"
  subnet_id = aws_subnet.subnets[0].id
  tags = {
    Name="opachki"
  }
}

resource "aws_security_group" "web_sg" {
  name        = "main sg for ec2"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = aws_vpc.vpc.id 

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    //cidr_blocks = ["11.203.40.183/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



resource "aws_vpc" "vpc" {
    cidr_block       = "172.16.0.0/16"
    region = var.region
}

resource "aws_subnet" "subnets" {
  count = length(var.public_address)
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.public_address[count.index]
  availability_zone = var.availability_zone[count.index]

  tags = {
  Name = "Public subnet No  ${count.index}"
}

}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "main"
  }
}

resource "aws_route_table" "sec_rt" { //route table
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

}

resource "aws_route_table_association" "sec_rt_assoc" {//route table attachemt
  count = length(var.public_address)
  subnet_id = aws_subnet.subnets[count.index].id 
  route_table_id = aws_route_table.sec_rt.id   
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.vpc.id
  service_name = "com.amazonaws.${var.region}.s3"
  //service_name = "com.amazonaws.us-west-2.s3"
  vpc_endpoint_type          = "Gateway"
  route_table_ids = [aws_route_table.sec_rt.id]
  tags = {
    Environment = "test"
  }
}






resource "aws_flow_log" "example" {
  iam_role_arn    = aws_iam_role.log_role.arn
  log_destination = aws_cloudwatch_log_group.example.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.vpc.id
  tags = {
    name = "obana"
  }
  
}

resource "aws_cloudwatch_log_group" "example" {
  name = "example123"
  //kms_key_id = 
}

resource "aws_iam_role" "log_role" {
  name               = "main_log_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json //which service allowed to use this policy
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
    
    actions = ["sts:AssumeRole"]
  }
}




//aws_iam_policy_document.log_policy -> aws_iam_role_policy.policy_attachment_to_role -> aws_iam_role.log_role--\
//aws_iam_policy_document.assume_role -> aws_iam_role.log_role -------(iam of service!!! not user`s)-----------> aws_flow_log.example

data "aws_iam_policy_document" "log_policy" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "policy_attachment_to_role" {
  name   = "test"
  role   = aws_iam_role.log_role.id
  policy = data.aws_iam_policy_document.log_policy.json
}



