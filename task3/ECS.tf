resource "aws_autoscaling_group" "asg" {
  vpc_zone_identifier = aws_subnet.subnets[*].id
  max_size = 3
  min_size = 0
  desired_capacity = 1
  name = "main autoscaling group"
  //availability_zones = var.availability_zone[*] // may be in different az (like left-right az scaling )
  protect_from_scale_in = "true"
  launch_template {
    id = aws_launch_template.foobar.id
    version = "$Latest"    
  }

  tag {
   key                 = "AmazonECSManaged"
   value               = true
   propagate_at_launch = true
  }
}

resource "aws_launch_template" "foobar" {
  name_prefix   = "foobar"
  image_id      = "ami-043339ea831b48099"
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.autoscaleSG.id]
// а зачем много sec group указывать? для каждой таски?
}

resource "aws_security_group" "autoscaleSG" {
  vpc_id = aws_vpc.vpc.id
  description = "Allow http for test nginx"
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  } 
}

resource "aws_lb" "main_lb" {
  name               = "ecs-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.autoscaleSG.id]
  subnets            = aws_subnet.subnets[*].id 
  //почему он в нескольких подсетях? он же должен в 1 подсети находиться? или это те подсети, куда он будет транслировать трафик  
  //enable_deletion_protection = true
  
  tags = {
    Environment = "test"
  }
}
resource "aws_lb_listener" "main_lb_listener" {
  port = 80
  protocol = "HTTP"
  load_balancer_arn = aws_lb.main_lb.arn
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.main_lb_targetGroup.arn
  }
}
resource "aws_lb_target_group" "main_lb_targetGroup" {
  port = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id = aws_vpc.vpc.id
  
  health_check {
    path = "/"
  }
}





resource "aws_ecs_cluster" "ecs_cluster" {
 name = "my-ecs-cluster"
}



resource "aws_ecs_capacity_provider" "ecs_cap_provider" {
  name = "example"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.asg.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 10
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "ecs_clust_cap_provider" {
  cluster_name = aws_ecs_cluster.ecs_cluster.name

  capacity_providers = [aws_ecs_capacity_provider.ecs_cap_provider.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.ecs_cap_provider.name
  }
}

resource "aws_iam_policy" "ecs_policy" {
  policy = jsonencode(
    {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
  )
}
# resource "aws_iam_policy_attachment" "ecs_policy_att" {
#   name = "ecs policy"
#   policy_arn = aws_iam_policy.ecs_policy.arn
# }
resource "aws_iam_role_policy" "policy_attached_to_role" {
  policy = aws_iam_policy.ecs_policy.policy
  role = aws_iam_role.ecs_role.id
}
resource "aws_iam_role" "ecs_role" {
  
  assume_role_policy = jsonencode(
    {
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "ecs.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
  )
}


resource "aws_ecs_task_definition" "service" {
  family = "service"
  network_mode       = "awsvpc"
  execution_role_arn = aws_iam_role.ecs_role.arn
  cpu                = 256
  runtime_platform { //not necessary
   operating_system_family = "LINUX"
   cpu_architecture        = "X86_64"
  }
  
  container_definitions = jsonencode([
    {
      name      = "first"
      image     = "nginxdemos/hello"
      //https://hub.docker.com/r/nginxdemos/hello/
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          //protocol = "tcp"
        }
      ]
    }
  ])

  # volume {
  #   name      = "service-storage"
  #   host_path = "/ecs/service-storage"
  # }
}

resource "aws_ecs_service" "ecs_service" {
 name            = "my-ecs-service"
 cluster         = aws_ecs_cluster.ecs_cluster.id
 task_definition = aws_ecs_task_definition.service.arn
 desired_count   = 1

 network_configuration {
   subnets            = aws_subnet.subnets[*].id 
   security_groups = [aws_security_group.autoscaleSG.id]
 }

 force_new_deployment = true
 placement_constraints {
   type = "distinctInstance"
 }

 triggers = {
   redeployment = timestamp()
 }

 capacity_provider_strategy {
   capacity_provider = aws_ecs_capacity_provider.ecs_cap_provider.name
   weight            = 100
 }

 load_balancer {
   target_group_arn = aws_lb_target_group.main_lb_targetGroup.arn
   container_name   = "first"
   container_port   = 80
 }

 depends_on = [aws_autoscaling_group.asg]
}