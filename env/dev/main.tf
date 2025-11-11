locals { name = "crypto-${var.env}" }

module "vpc" {
  source = "../../modules/vpc"
  name   = local.name
  cidr   = "10.50.0.0/16"
}

module "secrets" {
  source   = "../../modules/secrets"
  app_name = "crypto-api"
}

module "rds" {
  source              = "../../modules/rds-postgres"
  name                = local.name
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnets
  allow_from_sg_id    = null
  master_username     = "crypto"
  master_password_arn = module.secrets.db_password_arn

  depends_on = [module.secrets]
}

module "alb" {
  source            = "../../modules/alb"
  name              = local.name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnets
}

module "ecs" {
  source               = "../../modules/ecs-fargate"
  name                 = local.name
  vpc_id               = module.vpc.vpc_id
  public_subnet_ids    = module.vpc.public_subnets
  container_image      = var.container_image
  desired_count        = 2
  target_group_arn     = module.alb.tg_arn
  environment = {
    DB_HOST = module.rds.endpoint
    DB_NAME = module.rds.db_name
  }
  secrets = {
    DB_PASSWORD = module.secrets.db_password_arn
  }
  alb_security_group_id = module.alb.alb_sg_id
}

# Allow ECS tasks to talk to Postgres
resource "aws_security_group_rule" "rds_ingress_from_ecs" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = module.rds.rds_sg_id
  source_security_group_id = module.ecs.service_sg_id
}