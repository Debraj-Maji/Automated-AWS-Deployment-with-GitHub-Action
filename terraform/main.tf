data "aws_availability_zones" "available" {}
data "aws_elb_service_account" "main" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.1"

  name = "devops-task-vpc"
  cidr = var.vpc_cidr

  azs              = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets  = ["10.0.10.0/24", "10.0.11.0/24"]
  database_subnets = ["10.0.20.0/24", "10.0.21.0/24"]

  enable_nat_gateway           = true
  single_nat_gateway           = true
  create_database_subnet_group = true
}

module "app_storage" {
  source        = "terraform-aws-modules/s3-bucket/aws"
  version       = "4.1.0"
  bucket        = "devops-app-storage-${random_string.suffix.result}"
  force_destroy = true
  server_side_encryption_configuration = {
    rule = { apply_server_side_encryption_by_default = { sse_algorithm = "AES256" } }
  }
}

resource "aws_s3_bucket" "alb_logs" {
  bucket        = "devops-alb-logs-${random_string.suffix.result}"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = data.aws_elb_service_account.main.arn }
      Action    = "s3:PutObject"
      Resource  = "${aws_s3_bucket.alb_logs.arn}/*"
    }]
  })
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "4.3.2"

  domain_name            = var.domain_name
  create_route53_records = false
  wait_for_validation    = false
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}