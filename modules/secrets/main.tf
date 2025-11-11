resource "aws_kms_key" "main" {
  description             = "KMS key for ${var.app_name} secrets encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = merge(
    var.tags,
    {
      Name = "${var.app_name}-kms-key"
    }
  )
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.app_name}"
  target_key_id = aws_kms_key.main.key_id
}

resource "random_password" "db_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db_password" {
  name       = "${var.app_name}/db_password"
  kms_key_id = aws_kms_key.main.arn

  tags = merge(
    var.tags,
    {
      Name = "${var.app_name}/db_password"
    }
  )
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    password = random_password.db_password.result
  })
}