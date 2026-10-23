module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.4.0"

  identifier           = "devops-app-db"
  engine               = "mysql"
  engine_version       = "8.0"
  family               = "mysql8.0"
  major_engine_version = "8.0"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  storage_encrypted    = true

  db_name                     = "appdb"
  username                    = "admin"
  manage_master_user_password = true # Let AWS natively handle the password and secret
  port                        = 3306

  multi_az               = false
  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [module.rds_sg.security_group_id]

  skip_final_snapshot = true
}