# GitHub OIDC Setup for AWS

This document explains how to set up GitHub Actions OIDC authentication with AWS so the CI/CD pipeline can deploy infrastructure.

## Prerequisites

- AWS CLI configured with admin permissions
- GitHub repository: `chiamaka99346/crypto-infra-pipeline`

## Step 1: Create OIDC Provider in AWS

Run this command to create the GitHub OIDC provider:

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  --region eu-central-1
```

**Output:** You'll get an ARN like: `arn:aws:iam::062266257890:oidc-provider/token.actions.githubusercontent.com`

## Step 2: Create IAM Role Trust Policy

Create a file `github-trust-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::062266257890:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:chiamaka99346/crypto-infra-pipeline:*"
        }
      }
    }
  ]
}
```

## Step 3: Create IAM Role

```bash
aws iam create-role \
  --role-name github-actions-deploy \
  --assume-role-policy-document file://github-trust-policy.json \
  --region eu-central-1
```

## Step 4: Attach Permissions Policy

Create `github-permissions-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "ecs:*",
        "elasticloadbalancing:*",
        "rds:*",
        "secretsmanager:*",
        "kms:*",
        "iam:GetRole",
        "iam:PassRole",
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:GetRolePolicy",
        "logs:*",
        "s3:*",
        "dynamodb:*"
      ],
      "Resource": "*"
    }
  ]
}
```

```bash
aws iam put-role-policy \
  --role-name github-actions-deploy \
  --policy-name GithubActionsDeployPolicy \
  --policy-document file://github-permissions-policy.json \
  --region eu-central-1
```

## Step 5: Verify Setup

Check that the role exists:

```bash
aws iam get-role --role-name github-actions-deploy --region eu-central-1
```

## Step 6: Test GitHub Actions

Now push a commit to trigger the workflow:

```bash
git commit --allow-empty -m "test: trigger CI/CD pipeline"
git push origin main
```

## Troubleshooting

### Error: "Not authorized to perform sts:AssumeRoleWithWebIdentity"

**Causes:**
1. OIDC provider not created
2. Trust policy incorrect
3. Repository name mismatch in condition

**Fix:**
- Verify OIDC provider exists: `aws iam list-open-id-connect-providers`
- Check trust policy: `aws iam get-role --role-name github-actions-deploy --query 'Role.AssumeRolePolicyDocument'`
- Ensure repository name matches exactly: `chiamaka99346/crypto-infra-pipeline`

### Error: "Access Denied" during terraform apply

**Cause:** IAM role doesn't have sufficient permissions

**Fix:**
- Review and expand the permissions policy
- Add specific service permissions as needed

## Quick Setup Script

Save this as `setup-github-oidc.sh`:

```bash
#!/bin/bash

ACCOUNT_ID="062266257890"
REPO="chiamaka99346/crypto-infra-pipeline"
REGION="eu-central-1"

# Create OIDC Provider
echo "Creating OIDC Provider..."
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  --region $REGION

# Create Trust Policy
cat > /tmp/trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${REPO}:*"
        }
      }
    }
  ]
}
EOF

# Create IAM Role
echo "Creating IAM Role..."
aws iam create-role \
  --role-name github-actions-deploy \
  --assume-role-policy-document file:///tmp/trust-policy.json \
  --region $REGION

# Attach AdministratorAccess (or create custom policy)
echo "Attaching permissions..."
aws iam attach-role-policy \
  --role-name github-actions-deploy \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess \
  --region $REGION

echo "Setup complete!"
echo "Role ARN: arn:aws:iam::${ACCOUNT_ID}:role/github-actions-deploy"
```

Run with: `bash setup-github-oidc.sh`

## Security Notes

- The script above uses `AdministratorAccess` for simplicity
- For production, use the least-privilege permissions policy shown earlier
- Regularly audit IAM role permissions
- Consider adding IP restrictions or time-based conditions
- Enable CloudTrail to monitor role usage

## References

- [GitHub OIDC Documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [AWS IAM OIDC](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
