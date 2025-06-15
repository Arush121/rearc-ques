terraform {
    required_version = ">= 1.7.0"
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = ">= 5.90"
        }
    }
    backend "s3" {
        bucket         = "brush-devops-terraform"
        key            = "rearc.tfstate"
        region         = "us-east-1"
        dynamodb_table = "rearc-lock"
        encrypt        = true
  }
}