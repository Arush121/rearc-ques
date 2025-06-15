# Rearc Infrastructure Deployment

## ✅ Proof of Completion

All required features have been successfully implemented. Relevant screenshots are included in the `screenshots/` directory, covering the following areas:

- ✅ Public Cloud (AWS)  
- ✅ Docker  
- ✅ Secrets Management  
- ✅ Load Balancer  


> **Note 1:** Although the infrastructure is fully deployed on AWS, the verification page incorrectly flags that AWS is not being used.  
> **Note 2:** TLS was configured at the EC2 instance (localhost) level. Due to the absence of a registered domain, TLS was not applied at the ALB/domain level.

---

## 💡 Improvements with More Time

- **Parameterization**  
  I would externalize hardcoded values into `variables.tf` and `terraform.tfvars` files to enhance modularity, reusability, and support for multiple environments.

- **HTTPS Support**  
  With access to a registered domain and an ACM certificate, I would configure HTTPS on the ALB by attaching the TLS certificate to a listener on port 443.

- **Infrastructure Granularity**  
  I would replace the use of pre-built community modules for EC2, ALB, and security groups with custom `resource` blocks to gain greater control, flexibility, and visibility over the infrastructure.

---

## 🛠️ Solution Overview

### 1. Tools & Technologies

- **Terraform v1.7+** with AWS provider (≥ 5.90)
- **Remote state management** via S3 backend & DynamoDB state locking
- **Terraform AWS Modules Used:**
  - VPC
  - EC2 Instance
  - Security Group
  - ALB

---

### 2. Infrastructure Components

#### 2.1. VPC Configuration

- **CIDR Block:** `10.0.0.0/16`
- **Subnets:**
  - 3 Public subnets (e.g., `10.0.101.0/24`)
  - 3 Private subnets (e.g., `10.0.1.0/24`)
- **High Availability:** Spread across `us-east-1a`, `us-east-1b`, `us-east-1c`
- **Networking Features:**
  - Internet Gateway (IGW)
  - NAT Gateway (single, shared)
  - DNS Support & Hostnames enabled
  - Resource tagging for traceability

#### 2.2. Security Groups

- **Public Bastion SG (`public-rearc-sg`):**
  - Ingress: SSH (port 22) from `0.0.0.0/0`
  - Egress: All traffic

- **ALB SG (`alb-sg`):**
  - Ingress: HTTP (port 80) from `0.0.0.0/0`
  - Egress: All traffic

- **Private App SG (`private-rearc-sg`):**
  - Ingress:
    - Port 22 from Bastion SG
    - Port 3000 from ALB SG
  - Egress: All traffic

#### 2.3. EC2 Instances

- **Bastion Host (`public-bastion`):**
  - Deployed in public subnet
  - Accessible via SSH
  - Instance type: `t3.micro`

- **App Server (`private-rearc-server`):**
  - Deployed in private subnet
  - No public IP
  - Listens on port `3000`
  - Instance type: `t3.medium`

#### 2.4. Application Load Balancer (ALB)

- **Type:** Application (HTTP)
- **Attached Subnets:** Public
- **Listener:** Port 80 → forwards to target group
- **Target Group:**
  - Instance target on port 3000
  - Health check path: `/health` (HTTP)

#### 2.5. Connectivity & Access

- SSH access to private EC2 is enabled via the Bastion host
- Public ALB forwards traffic to private app server
- Private EC2 has no public IP — security group restrictions ensure controlled access

#### 2.6. Remote State Management

- **S3 Bucket:** `brush-devops-terraform`
- **DynamoDB Table:** `rearc-lock` (for state locking)
