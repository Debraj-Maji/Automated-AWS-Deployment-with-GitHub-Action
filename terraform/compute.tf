module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.7.0"

  name                       = "devops-alb"
  vpc_id                     = module.vpc.vpc_id
  enable_deletion_protection = false
  subnets                    = module.vpc.public_subnets
  security_groups            = [module.alb_sg.security_group_id]

  access_logs = {
    bucket  = aws_s3_bucket.alb_logs.id
    enabled = true
  }

  listeners = {
    http_redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = { port = "443", protocol = "HTTPS", status_code = "HTTP_301" }
    }
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = aws_acm_certificate_validation.wait_for_issued.certificate_arn
      forward = {
        target_group_key = "app_tg"
      }
    }
  }

  target_groups = {
    app_tg = {
      backend_protocol  = "HTTP"
      backend_port      = 80
      target_type       = "instance"
      create_attachment = false
      health_check = {
        enabled             = true
        path                = "/"
        healthy_threshold   = 3
        unhealthy_threshold = 3
      }
    }
  }
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "7.0.0"

  name                      = "devops-asg"
  min_size                  = 2
  max_size                  = 4
  desired_capacity          = 2
  vpc_zone_identifier       = module.vpc.private_subnets
  target_group_arns         = [module.alb.target_groups["app_tg"].arn]
  image_id                  = data.aws_ami.amazon_linux_2.id
  instance_type             = "t3.micro"
  security_groups           = [module.ec2_sg.security_group_id]
  iam_instance_profile_name = aws_iam_instance_profile.ec2_profile.name

  user_data = base64encode(templatefile("${path.module}/../scripts/user_data.sh", {
    SECRET_ID = module.db.db_instance_master_user_secret_arn
    REGION    = var.aws_region
    DB_HOST   = module.db.db_instance_address
  }))

  depends_on = [
    module.db
  ]
}