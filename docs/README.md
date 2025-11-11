# Crypto Infrastructure Pipeline

A production-ready, secure AWS infrastructure for deploying containerized applications with Terraform, featuring automated security scanning and compliance validation.

## 🏗️ Stack Components

### Network Layer
- **VPC**: 10.50.0.0/16 CIDR with DNS support
- **Public Subnets**: 2 subnets across 2 AZs for ALB and NAT Gateway
- **Private Subnets**: 2 subnets across 2 AZs for ECS tasks and RDS
- **Internet Gateway**: Outbound internet access for public subnets
- **NAT Gateway**: Outbound internet access for private subnets (⚠️ hourly cost)

### Compute Layer
- **ECS Fargate**: Serverless container orchestration
  - CPU: 256 (0.25 vCPU)
  - Memory: 512 MB
  - Desired count: 2 tasks
  - Container Insights enabled

### Load Balancing
- **Application Load Balancer**: Internet-facing, HTTP on port 80
- **Target Group**: Health checks on `/` path

### Database Layer
- **RDS PostgreSQL 16.3**: db.t4g.micro instance
  - Storage: 20GB encrypted GP3
  - Automated backups (7-day retention)
  - CloudWatch logs enabled
  - Not publicly accessible

### Security & Secrets
- **KMS Key**: Customer-managed key with automatic rotation
- **Secrets Manager**: Encrypted database password storage
- **Security Groups**: Least-privilege network access
  - ALB → ECS: Port 80
  - ECS → RDS: Port 5432

## 📥 Inputs

Configure these variables in `env/dev/tfvars.example` (copy to `terraform.tfvars`):

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `region` | string | AWS region | `eu-central-1` |
| `env` | string | Environment name | `dev` |
| `container_image` | string | Docker image URI | `public.ecr.aws/nginx/nginx:stable` |

## 📤 Outputs

After deployment, Terraform outputs:

- **ALB DNS**: Public endpoint for your application
- **RDS Endpoint**: Database connection string
- **VPC ID**: Network identifier
- **Subnet IDs**: Public and private subnet lists

## 🚀 How to Deploy

### Prerequisites

1. **AWS Account**: With appropriate permissions
2. **S3 Backend**: Create S3 bucket and DynamoDB table for state
   ```bash
   aws s3 mb s3://chiamaka-tf-state-1762851626.57447 --region eu-central-1
   aws dynamodb create-table \
     --table-name tf-locks \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST \
     --region eu-central-1
   ```
3. **GitHub OIDC**: Configure OIDC provider and IAM role `github-actions-deploy`
4. **Configuration**: All placeholders have been updated with actual values

### Manual Deployment

```bash
# Navigate to environment directory
cd env/dev

# Copy example tfvars
cp tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
# nano terraform.tfvars

# Initialize Terraform
terraform init

# Review plan
terraform plan -var-file=terraform.tfvars

# Apply changes
terraform apply -var-file=terraform.tfvars
```

### CI/CD Deployment

1. **Pull Request**: Opens PR → triggers security scan and plan
2. **Review**: Check plan output and security findings
3. **Merge to Main**: Auto-applies infrastructure changes

## 🔄 Rollback Strategy

### Option 1: Revert via Git
```bash
# Revert the problematic commit
git revert <commit-hash>
git push origin main
# CI/CD will apply the previous state
```

### Option 2: Manual Rollback
```bash
cd env/dev
terraform init

# Target specific resource to recreate
terraform taint module.ecs.aws_ecs_service.main
terraform apply -var-file=terraform.tfvars

# Or restore from previous plan
terraform apply -var-file=terraform.tfvars -target=<resource>
```

### Option 3: State Rollback (Advanced)
```bash
# List state versions
aws s3api list-object-versions \
  --bucket chiamaka-tf-state-1762851626.57447 \
  --prefix crypto-infra/dev/

# Restore previous version
aws s3api get-object \
  --bucket chiamaka-tf-state-1762851626.57447 \
  --key crypto-infra/dev/terraform.tfstate \
  --version-id <previous-version-id> \
  terraform.tfstate.backup
```

## 💰 Cost Warning

### ⚠️ IMPORTANT: NAT Gateway Hourly Costs

**The NAT Gateway incurs charges even when idle:**
- **Hourly rate**: ~$0.045/hour (~$32/month)
- **Data processing**: $0.045/GB processed
- **Total estimated cost**: $40-60/month for light usage

### 💡 Cost Optimization

**For development environments, destroy when not in use:**

```bash
cd env/dev
terraform destroy -var-file=terraform.tfvars
```

**To resume work later:**
```bash
terraform apply -var-file=terraform.tfvars
```

### Other Costs (Approximate)
- **RDS db.t4g.micro**: ~$13/month
- **ALB**: ~$16/month + data processing
- **ECS Fargate**: ~$12/month (2 tasks)
- **CloudWatch Logs**: ~$1-2/month
- **Secrets Manager**: ~$0.40/month
- **KMS**: ~$1/month

**Total estimated monthly cost**: ~$60-90/month

## 🔒 Security Features

- ✅ Encryption at rest (RDS, Secrets Manager)
- ✅ KMS key rotation enabled
- ✅ Security groups with least privilege
- ✅ Private subnets for compute and database
- ✅ Automated security scanning (tfsec, Checkov)
- ✅ Compliance validation (terraform-compliance)
- ✅ CloudWatch logging enabled
- ✅ No hardcoded secrets

## 📋 Compliance

Automated compliance checks enforce:
- **Encryption**: All storage encrypted (RDS, S3, EBS)
- **Tags**: All resources properly tagged
- **KMS**: Key rotation enabled

See `compliance/terraform-compliance/features/` for full policy set.

## 🧪 Local Testing

```bash
# Run security scans
tfsec .
checkov -d . --framework terraform

# Run compliance checks
cd env/dev
terraform init
terraform plan -var-file=tfvars.example -out=tf.plan
terraform show -json tf.plan > tf.plan.json
terraform-compliance -f ../../compliance/terraform-compliance/features -p tf.plan.json
```

## 📚 Additional Documentation

- [Threat Model](./threat-model.md) - Security analysis and mitigations
- [Change Log](./change-log.md) - Infrastructure change history

## 🤝 Contributing

1. Create feature branch from `main`
2. Make changes and commit
3. Open PR (triggers automated plan)
4. Review security scan results
5. Merge to `main` (triggers apply)

## 📞 Support

For issues or questions:
1. Check existing documentation
2. Review GitHub Actions logs
3. Examine Terraform plan output
4. Check AWS CloudWatch logs