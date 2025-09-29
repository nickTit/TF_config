# Firewall configuration for the our instances
resource "aws_security_group_rule" "matts-week-21-http-inbound" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow-tls.id
}

# Creating our launch configuration with user data to launch an Apache web server
resource "aws_launch_configuration" "matts-week21-lc" {
  name_prefix          = "${var.project_name}-lc"
  image_id             = "ami-06e46074ae430fba6"
  instance_type        = "t2.micro"
  security_groups      = [aws_security_group.allow-tls.id]
  user_data            = file("apache_httpd.sh")

  lifecycle {
    create_before_destroy = true
  }
}


# Creating our Auto Scaling group
resource "aws_autoscaling_group" "matts-week21-asg" {
  name                 = "${var.project_name}-asg"

  desired_capacity     = 2
  max_size             = 5
  min_size             = 2
  health_check_type    = "EC2"
  vpc_zone_identifier  = [aws_subnet.subnet-1.id, aws_subnet.subnet-2.id]

  launch_configuration = aws_launch_configuration.matts-week21-lc.name
}

# Creating our Application Load Balancer target group
resource "aws_lb_target_group" "matts-week21-lbtg" {
  name     = "${var.project_name}-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.matts-week-21.id
}
