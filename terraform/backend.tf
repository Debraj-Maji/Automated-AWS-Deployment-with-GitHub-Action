terraform {
  required_version = ">= 1.3.0"

  backend "s3" {
    bucket = "devops-task-tf-state-12345"
    key    = "infrastructure/terraform.tfstate"
    region = "ap-south-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
  default_tags {
    tags = {
      Environment = "Production"
      Project     = "DevOps-Task"
      ManagedBy   = "Terraform"
    }
  }
}