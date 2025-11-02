# FastAPI AWS Scripts Overview

This directory contains automation scripts for managing the FastAPI AWS deployment lifecycle.

## 🚀 Deployment Scripts

### `deploy.sh`
**Purpose**: Complete AWS infrastructure deployment and application setup
```bash
./scripts/deploy.sh
```

**What it does**:
- ✅ Sets up AWS S3 bucket for Terraform state
- ✅ Initializes Terraform backend configuration  
- ✅ Creates ECR repository for Docker images
- ✅ Provisions complete AWS infrastructure (VPC, EC2, ALB, ASG)
- ✅ Builds and pushes Docker image to ECR
- ✅ Deploys application to EC2 instances
- ✅ Provides access URLs and verification steps

**Use when**: Initial deployment or full infrastructure recreation

---

## 🧹 Cleanup Scripts

### `cleanup.sh` ⚠️ DESTRUCTIVE
**Purpose**: Complete AWS infrastructure destruction and cost elimination
```bash
./scripts/cleanup.sh
```

**What it does**:
- 🔥 **DESTROYS ALL AWS RESOURCES** (VPC, EC2, ALB, ASG, ECR, IAM, S3)
- 🚫 Disables AWS deployment in GitHub Actions
- 💰 Eliminates ~$45/month in AWS costs
- 🧹 Cleans up local Terraform files
- 📋 Provides next steps for GitHub cleanup

**Use when**: Project completion, cost reduction, complete cleanup
**⚠️ WARNING**: This action is IRREVERSIBLE!

### `disable-cicd.sh` 🛡️ SAFE
**Purpose**: Disable automated deployments while keeping AWS resources
```bash
./scripts/disable-cicd.sh
```

**What it does**:
- 🚫 Comments out deploy stage in GitHub Actions workflow
- ✅ Keeps all AWS resources running (no deletion)
- 💾 Creates backup of original workflow (`.github/workflows/ci-cd.yml.backup`)
- 🔄 Allows easy re-enabling with `enable-cicd.sh`

**Use when**: Temporary deployment pause, development mode, cost reduction

### `enable-cicd.sh` 🔄 RESTORE
**Purpose**: Re-enable automated deployments
```bash
./scripts/enable-cicd.sh
```

**What it does**:
- ✅ Restores original GitHub Actions workflow from backup
- 🚀 Re-enables automated AWS deployment on push
- 🔄 Restores full CI/CD pipeline functionality

**Use when**: Resuming automated deployments after using `disable-cicd.sh`

---

## 📋 Usage Scenarios

### Scenario 1: Initial Setup
```bash
./scripts/deploy.sh    # Deploy everything
```

### Scenario 2: Temporary Deployment Pause (Keep AWS Resources)
```bash
./scripts/disable-cicd.sh    # Stop deployments, keep AWS resources
# ... development work ...
./scripts/enable-cicd.sh     # Resume deployments
```

### Scenario 3: Complete Project Cleanup (Destroy Everything)
```bash
./scripts/cleanup.sh    # Destroy all AWS resources and disable CI/CD
```

### Scenario 4: Cost Management
```bash
# Option A: Keep infrastructure, stop deployments
./scripts/disable-cicd.sh

# Option B: Destroy everything for maximum savings
./scripts/cleanup.sh
```

---

## 💰 Cost Impact

| Script | AWS Resources | Monthly Cost | Impact |
|--------|---------------|--------------|---------|
| `deploy.sh` | Creates all resources | ~$45 | 💰 Starts billing |
| `disable-cicd.sh` | **Keeps all resources** | ~$45 | 🔄 No cost change |
| `cleanup.sh` | **Destroys all resources** | $0 | 💸 Saves $45/month |

---

## 🔐 Safety Features

### Multiple Confirmations
- `cleanup.sh` requires typing "DELETE" + "yes" confirmation
- `disable-cicd.sh` and `enable-cicd.sh` require y/N confirmation
- All scripts show preview of actions before execution

### Automatic Backups
- `disable-cicd.sh` creates `.github/workflows/ci-cd.yml.backup`
- `enable-cicd.sh` restores from backup automatically
- Terraform state stored in S3 with versioning

### Verification Steps
- All scripts verify current state before making changes
- `cleanup.sh` shows remaining resources after completion
- Scripts provide next steps and verification commands

---

## 🛠️ Technical Details

### Dependencies
- **AWS CLI v2**: For AWS resource management
- **Terraform v1.12.2+**: For infrastructure as code
- **Docker**: For container building and deployment
- **Git**: For workflow file management
- **Bash**: All scripts are bash-compatible

### Permissions Required
- AWS credentials with full deployment permissions (same as GitHub Actions)
- Write access to `.github/workflows/` directory
- Execute permissions on script files (`chmod +x scripts/*.sh`)

### Error Handling
- All scripts use `set -e` for immediate exit on errors
- Graceful handling of missing resources (cleanup operations)
- User-friendly error messages with troubleshooting hints
- Safe defaults and confirmation prompts

---

## 📞 Support

### Common Issues
1. **"AWS credentials not found"**: Configure AWS CLI with `aws configure`
2. **"Terraform not found"**: Install Terraform v1.12.2+
3. **"Permission denied"**: Run `chmod +x scripts/*.sh`
4. **"Backup not found"**: Original workflow was not properly backed up

### Verification Commands
```bash
# Check AWS resources status
aws ec2 describe-instances --region ap-south-1 --filters "Name=tag:Environment,Values=production"

# Check GitHub Actions status
cat .github/workflows/ci-cd.yml | grep -A 5 "deploy:"

# Check script permissions
ls -la scripts/
```

### Restoration
If something goes wrong:
```bash
# Restore GitHub workflow from backup
cp .github/workflows/ci-cd.yml.backup .github/workflows/ci-cd.yml

# Rebuild infrastructure
./scripts/deploy.sh
```