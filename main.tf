module "vpc" {

  version = "5.21.0"
  source = "terraform-aws-modules/vpc/aws"

  name = "rearc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  map_public_ip_on_launch = true
  enable_nat_gateway = true
  single_nat_gateway = true
  enable_dns_hostnames = true
  enable_dns_support = true
  create_igw = true

  private_subnet_tags = {
    "Name"                            = "rearc-private-subnet"
  }

  public_subnet_tags = {
    "Name"                            = "rearc-public-subnet"
  }

  tags = {
    Terraform = "true"
  }
}

module "public-rearc-sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "public-rearc-sg"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = {
    Name = "public-rearc-sg"
  }
}

module "ec2_instance_bastion" {

  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "5.8.0"
  name                   = "public-bastion"
  instance_type          = "t3.micro"
  ami                    = "ami-09e6f87a47903347c"
  subnet_id              = module.vpc.public_subnets[0] 
  vpc_security_group_ids = [module.public-rearc-sg.security_group_id]
  key_name               = "quest"
  tags = {
    Name = "public-quest"
  }

}


module "private-rearc-sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "private-rearc-sg"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 3000
      to_port                  = 3000
      protocol                 = "tcp"
      source_security_group_id = module.alb_sg.security_group_id
    },
    {
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      source_security_group_id = module.public-rearc-sg.security_group_id
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = {
    Name = "private-rearc-sg"
  }
}


module "ec2_instance" {

  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "5.8.0"
  name                   = "private-rearc-server"
  instance_type          = "t3.medium"
  ami                    = "ami-09e6f87a47903347c"
  subnet_id              = module.vpc.private_subnets[0] 
  vpc_security_group_ids = [module.private-rearc-sg.security_group_id]
  key_name               = "quest"
  tags = {
    Name = "private-quest"
  }

}



module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "alb-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = {
    Name = "alb-sg"
  }
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.16.0"
  create_security_group= false

  name               = "rearc-app-alb"
  load_balancer_type = "application"
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets
  security_groups    = [module.alb_sg.security_group_id]

  enable_deletion_protection = false

  target_groups = {
    quest-instance = {
      name_prefix      = "h1"
      protocol         = "HTTP"
      port             = 3000
      target_type      = "instance"
      target_id        = module.ec2_instance.id
      health_check = {
        enabled             = true
        path                = "/health"
        protocol            = "HTTP"
        matcher             = "200"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
      }
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "quest-instance"
      }
    }
  }

  tags = {
    Terraform = "true"
  }
}
