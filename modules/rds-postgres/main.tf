data "aws_secretsmanager_secret" "master_password" {
  arn = var.master_password_arn
}

data "aws_secretsmanager_secret_version" "master_password" {
  secret_id = data.aws_secretsmanager_secret.master_password.id
}

locals {
  db_password = jsondecode(data.aws_secretsmanager_secret_version.master_password.secret_string)["password"]
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-db-subnet-group"
    }
  )
}

resource "aws_security_group" "rds" {
  name        = "${var.name}-rds-sg"
  description = "Security group for RDS PostgreSQL instance"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-rds-sg"
    }
  )
}

resource "aws_db_instance" "main" {
  identifier     = "${var.name}-postgres"
  engine         = "postgres"
  engine_version = "16"
  instance_class = "db.t4g.micro"

  allocated_storage     = 20
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "postgres"
  username = var.master_username
  password = local.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "mon:04:00-mon:05:00"

  skip_final_snapshot       = true
  final_snapshot_identifier = null

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-postgres"
    }
  )
}