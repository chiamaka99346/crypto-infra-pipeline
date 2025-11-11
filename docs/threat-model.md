# Threat Model

## Overview

This document outlines the security architecture, trust boundaries, potential threats, and implemented mitigations for the crypto infrastructure pipeline.

## Architecture Trust Boundaries

```
┌─────────────────────────────────────────────────────────────┐
│                        INTERNET                             │
│                     (Untrusted Zone)                        │
└──────────────────────────┬──────────────────────────────────┘
                           │
                    ┌──────▼──────┐
                    │   Trust     │
                    │  Boundary 1 │
                    └──────┬──────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                   PUBLIC SUBNET                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Application Load Balancer (ALB)                     │  │
│  │  - Security Group: 0.0.0.0/0:80                      │  │
│  │  - HTTP Only (Port 80)                               │  │
│  └──────────────────────────────────────────────────────┘  │
└──────────────────────────┬──────────────────────────────────┘
                           │
                    ┌──────▼──────┐
                    │   Trust     │
                    │  Boundary 2 │
                    └──────┬──────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                   PRIVATE SUBNET                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  ECS Fargate Tasks                                   │  │
│  │  - Security Group: ALB SG only:80                    │  │
│  │  - Application Container                             │  │
│  │  - No Direct Internet Access                         │  │
│  └──────────────────────────────────────────────────────┘  │
│                           │                                 │
│                    ┌──────▼──────┐                          │
│                    │   Trust     │                          │
│                    │  Boundary 3 │                          │
│                    └──────┬──────┘                          │
│                           │                                 │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  RDS PostgreSQL                                      │  │
│  │  - Security Group: ECS SG only:5432                  │  │
│  │  - Not Publicly Accessible                           │  │
│  │  - Encrypted at Rest                                 │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Trust Boundary Analysis

### Boundary 1: Internet → ALB

**Description**: Public internet traffic entering the AWS infrastructure via the Application Load Balancer.

**Trust Level**: 
- Source: Untrusted (Public Internet)
- Destination: Semi-trusted (AWS-managed ALB)

**Threats**:
1. **DDoS Attacks**: Volumetric attacks overwhelming the ALB
2. **HTTP Exploits**: Malformed requests, injection attempts
3. **Credential Stuffing**: Brute force authentication attempts
4. **Bot Traffic**: Automated scraping and abuse
5. **Layer 7 Attacks**: Application-level exploits

**Mitigations**:
- ✅ **AWS Shield Standard**: Automatic DDoS protection
- ✅ **Security Group**: Restricts ingress to port 80 only
- ✅ **ALB Access Logs**: Can be enabled for audit trail
- ⚠️ **Recommended**: Add AWS WAF for L7 protection
- ⚠️ **Recommended**: Enable HTTPS/TLS with ACM certificate
- ⚠️ **Recommended**: Implement rate limiting

### Boundary 2: ALB → ECS Tasks

**Description**: Traffic flowing from the load balancer to application containers.

**Trust Level**:
- Source: Semi-trusted (ALB with filtered traffic)
- Destination: Trusted (Private application layer)

**Threats**:
1. **Container Escape**: Breaking out of container isolation
2. **Code Injection**: SQL injection, XSS, command injection
3. **Vulnerable Dependencies**: Outdated libraries with CVEs
4. **Secrets Exposure**: Credentials leaked in logs/errors
5. **Lateral Movement**: Compromised container accessing other resources

**Mitigations**:
- ✅ **Security Group**: ECS tasks only accept traffic from ALB SG on port 80
- ✅ **Private Subnets**: ECS tasks not directly accessible from internet
- ✅ **IAM Task Role**: Least privilege access to AWS services
- ✅ **Secrets Manager Integration**: No hardcoded credentials
- ✅ **Container Insights**: Monitoring and logging enabled
- ✅ **CloudWatch Logs**: Centralized log aggregation
- ⚠️ **Recommended**: Container image scanning (Trivy, Grype)
- ⚠️ **Recommended**: Runtime security monitoring (Falco)
- ⚠️ **Recommended**: Read-only root filesystem

### Boundary 3: ECS Tasks → RDS

**Description**: Database connections from application containers to PostgreSQL.

**Trust Level**:
- Source: Trusted (Application layer)
- Destination: Highly trusted (Data layer)

**Threats**:
1. **SQL Injection**: Malicious queries compromising data
2. **Credential Theft**: Database passwords stolen or leaked
3. **Data Exfiltration**: Unauthorized data extraction
4. **Privilege Escalation**: Gaining elevated database permissions
5. **Man-in-the-Middle**: Intercepting database traffic

**Mitigations**:
- ✅ **Security Group**: RDS only accepts connections from ECS SG on port 5432
- ✅ **Private Subnets**: Database not publicly accessible
- ✅ **Encryption at Rest**: Storage encrypted with KMS
- ✅ **KMS Key Rotation**: Automatic annual key rotation
- ✅ **Secrets Manager**: Database password stored securely
- ✅ **IAM Integration**: ECS task role can read secrets
- ✅ **No Public Access**: `publicly_accessible = false`
- ✅ **Automated Backups**: 7-day retention for recovery
- ✅ **CloudWatch Logs**: PostgreSQL logs exported
- ⚠️ **Recommended**: Enable encryption in transit (SSL/TLS)
- ⚠️ **Recommended**: Database activity auditing
- ⚠️ **Recommended**: Parameterized queries in application code

## Data Flow Security

### Secrets Management

**Password Generation**:
```
Random Provider (24 chars) 
  → Secrets Manager (encrypted) 
  → KMS Encryption 
  → ECS Task (environment variable)
  → RDS Connection
```

**Security Controls**:
- ✅ **Random Password**: 24 characters with special characters
- ✅ **KMS Encryption**: Customer-managed key with rotation
- ✅ **Access Control**: IAM policies restrict secret access
- ✅ **No Hardcoding**: Secrets never in source code or logs
- ✅ **Rotation Enabled**: KMS key rotates annually

### Network Segmentation

**Public Subnet**:
- Internet Gateway attached
- ALB only
- NAT Gateway for private subnet egress
- No compute workloads

**Private Subnet**:
- No direct internet access
- Outbound via NAT Gateway
- ECS tasks and RDS instances
- All sensitive workloads isolated

## Security Controls Summary

### Identity & Access Management
| Control | Status | Description |
|---------|--------|-------------|
| IAM Task Execution Role | ✅ Implemented | Pulls images, writes logs |
| IAM Task Role | ✅ Implemented | Application permissions (Secrets Manager) |
| Least Privilege Policies | ✅ Implemented | Minimal permissions granted |
| No Long-term Credentials | ✅ Implemented | OIDC for GitHub Actions |

### Network Security
| Control | Status | Description |
|---------|--------|-------------|
| Security Groups | ✅ Implemented | Least privilege, port-specific |
| Private Subnets | ✅ Implemented | Compute and data isolated |
| No Public Database | ✅ Implemented | RDS not internet-accessible |
| VPC Flow Logs | ⚠️ Recommended | Network traffic analysis |

### Encryption
| Control | Status | Description |
|---------|--------|-------------|
| RDS Encryption at Rest | ✅ Implemented | Storage encrypted |
| KMS Key Rotation | ✅ Implemented | Annual automatic rotation |
| Secrets Manager | ✅ Implemented | Password encrypted |
| TLS/HTTPS | ⚠️ Recommended | Add ACM certificate |
| RDS SSL/TLS | ⚠️ Recommended | Encrypt data in transit |

### Monitoring & Logging
| Control | Status | Description |
|---------|--------|-------------|
| CloudWatch Logs | ✅ Implemented | ECS and RDS logs |
| Container Insights | ✅ Implemented | ECS metrics and logs |
| RDS Logs Export | ✅ Implemented | PostgreSQL and upgrade logs |
| CloudTrail | ⚠️ Recommended | API activity logging |
| GuardDuty | ⚠️ Recommended | Threat detection |

### Compliance & Scanning
| Control | Status | Description |
|---------|--------|-------------|
| tfsec | ✅ Implemented | Static Terraform analysis |
| Checkov | ✅ Implemented | Policy-as-code scanning |
| terraform-compliance | ✅ Implemented | BDD compliance testing |
| Container Scanning | ⚠️ Recommended | Image vulnerability scanning |

## Incident Response

### Detection
1. **CloudWatch Alarms**: Monitor for anomalies
2. **Container Insights**: Track task failures and resource usage
3. **RDS Metrics**: Database connection spikes, slow queries
4. **GitHub Actions**: Failed security scans

### Response Procedures
1. **Isolate**: Update security group to block traffic
2. **Investigate**: Review CloudWatch logs and metrics
3. **Contain**: Stop compromised tasks, rotate credentials
4. **Recover**: Deploy from known-good state
5. **Document**: Update change log and threat model

### Rollback Strategy
- Git revert → automatic redeployment
- Terraform state rollback
- RDS point-in-time recovery (7-day window)

## Risk Assessment

| Risk | Likelihood | Impact | Severity | Mitigation Status |
|------|-----------|--------|----------|-------------------|
| DDoS Attack | High | Medium | High | Partial (Shield Standard) |
| SQL Injection | Medium | High | High | Partial (App-dependent) |
| Credential Theft | Low | High | Medium | Good (Secrets Manager) |
| Container Compromise | Low | High | Medium | Good (Isolation + SG) |
| Data Exfiltration | Low | High | Medium | Good (Private + Encrypted) |
| Insider Threat | Low | High | Medium | Partial (IAM policies) |
| Supply Chain Attack | Medium | High | High | Partial (Need image scan) |

## Recommendations for Hardening

### High Priority
1. **Enable HTTPS**: Add ACM certificate and TLS listener
2. **WAF Integration**: Deploy AWS WAF with OWASP rules
3. **Container Scanning**: Integrate Trivy in CI/CD
4. **VPC Flow Logs**: Enable for network forensics
5. **RDS SSL**: Enforce encrypted connections

### Medium Priority
6. **CloudTrail**: Enable API activity logging
7. **GuardDuty**: Activate threat detection
8. **Secrets Rotation**: Implement automatic password rotation
9. **Database Auditing**: Enable pgAudit extension
10. **Read-only Filesystem**: Harden container runtime

### Low Priority
11. **AWS Config**: Track configuration changes
12. **Security Hub**: Centralized security findings
13. **Systems Manager**: Patch management
14. **Backup Vault**: Centralized backup management
15. **Multi-region DR**: Disaster recovery setup

## Compliance Mappings

### CIS AWS Foundations Benchmark
- ✅ 2.1.1: S3 bucket encryption (N/A - no S3 buckets yet)
- ✅ 2.1.5: RDS encryption at rest
- ✅ 2.8: KMS key rotation enabled
- ✅ 5.1: No overly permissive security groups

### OWASP Top 10
- ✅ A02: Cryptographic Failures - KMS encryption
- ✅ A05: Security Misconfiguration - Compliance scanning
- ✅ A07: Identification and Authentication - IAM roles
- ⚠️ A01: Broken Access Control - App-level validation needed

## Review Schedule

- **Monthly**: Review security group rules and IAM policies
- **Quarterly**: Update threat model, review logs and metrics
- **Annually**: Complete risk assessment, penetration testing
- **Ad-hoc**: After incidents or significant changes