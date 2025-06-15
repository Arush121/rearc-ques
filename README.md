# rearc-ques
Overview of the solution proposed

1) Tools & Technologies

1.a) Terraform v1.7+ with AWS provider (>= 5.90)

1.b) Remote state management via S3 backend & DynamoDB for state locking

1.c) Terraform AWS Modules:

vpc, ec2-instance, security-group, alb





2) Infrastructure Components

2.1) VPC Module

2.1.1) CIDR Block: 10.0.0.0/16

2.1.2) Subnets:

3 Public (10.0.101.0/24, etc.)

3 Private (10.0.1.0/24, etc.)

2.1.3) High Availability across 3 AZs: us-east-1a, 1b, 1c

2.1.4) Networking Features:

NAT Gateway (1 shared)

Internet Gateway

DNS Support & Hostnames enabled

Tagging for resource tracking (Terraform, subnet names)




2.2) Security Groups

2.2.1) Public Bastion SG (public-rearc-sg):

Ingress: SSH (22) open to the world (0.0.0.0/0)

Egress: All traffic

2.2.2) ALB SG (alb-sg):

Ingress: HTTP (80) open to the world

Egress: All traffic

2.2.3) Private App SG (private-rearc-sg):

Ingress:

Port 22 from Bastion SG

Port 3000 from ALB SG

Egress: All traffic



2.3) EC2 Instances

2.3.1) Bastion Host (public-bastion)

Public subnet

SSH accessible

t3.micro instance

2.3.2) App Server (private-rearc-server)

Private subnet

t3.medium instance

Listens on port 3000



2.4) Application Load Balancer (ALB)

Type: Application (HTTP)

Attached to: Public subnets

Listener: Port 80 → Forward to target group

Target Group:

Targets: Private EC2 instance

Port: 3000 (App server)

Health Check: /health on HTTP



2.5) Connectivity & Access

Bastion host in public subnet used for SSH access to private EC2

ALB routes internet traffic to app running on port 3000 in private instance

Strict, security-group-based traffic control — no public IP for private server



2.6) Remote State Management

State stored in S3 bucket: brush-devops-terraform

Locking via DynamoDB table: rearc-lock