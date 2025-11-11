# Infrastructure Change Log

All notable changes to the crypto infrastructure pipeline will be documented in this file.

## Format

Each entry should include:
- **Date**: YYYY-MM-DD
- **Version**: Semantic version or identifier
- **Description**: Summary of changes
- **Author**: Who made the change
- **Impact**: Expected downtime or breaking changes

---

## 2025-11-11 — v1.0.0 — Initial Deploy

**Components**:
- ✅ VPC with public/private subnets across 2 AZs
- ✅ Application Load Balancer (HTTP port 80)
- ✅ ECS Fargate cluster with 2 tasks (CPU: 256, Memory: 512)
- ✅ RDS PostgreSQL 16.3 (db.t4g.micro, 20GB encrypted storage)
- ✅ AWS Secrets Manager for database credentials
- ✅ KMS key with automatic rotation
- ✅ Security groups with least-privilege access
- ✅ CloudWatch logging for ECS and RDS

**Security**:
- Encryption at rest enabled for all storage
- Private subnets for compute and database
- No publicly accessible database
- Secrets never hardcoded

**CI/CD**:
- GitHub Actions workflow with plan/apply jobs
- Security scanning: tfsec, Checkov
- Compliance validation: terraform-compliance
- Automated deployment on merge to main

**Infrastructure as Code**:
- Terraform 1.6.0+
- Modular design (vpc, alb, ecs-fargate, rds-postgres, secrets)
- S3 backend with DynamoDB locking

**Impact**: Initial deployment, no previous infrastructure