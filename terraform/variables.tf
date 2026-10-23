variable "aws_region" {
  default = "ap-south-1"
}

variable "domain_name" {
  description = "Domain name in Route53"
  type        = string
  default     = "devops-task.theworkpc.com"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}