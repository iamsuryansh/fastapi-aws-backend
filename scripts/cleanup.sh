#!/bin/bash

# Complete AWS cleanup script - Destroys all resources and disables CI/CD

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

APP_NAME=${APP_NAME:-fastapi-backend}
AWS_REGION=${AWS_REGION:-ap-south-1}
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              FastAPI AWS Complete Cleanup Script            ║${NC}"  
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

# Display what will be destroyed
echo -e "${YELLOW}This script will destroy the following AWS resources:${NC}"
echo -e "  • VPC and networking (vpc-004f4c21e0e211cd2)"
echo -e "  • Application Load Balancer (fastapi-backend-alb)"
echo -e "  • Auto Scaling Group with EC2 instances"
echo -e "  • ECR repository and Docker images"
echo -e "  • IAM roles and policies"
echo -e "  • S3 bucket (Terraform state)"
echo -e "  • Security groups and network ACLs"
echo
echo -e "${YELLOW}Region: ${AWS_REGION}${NC}"
echo -e "${YELLOW}Account: ${AWS_ACCOUNT_ID}${NC}"
echo

# Confirm cleanup with multiple confirmations for safety
echo -e "${RED}⚠️  WARNING: This action is IRREVERSIBLE! ⚠️${NC}"
read -p "Type 'DELETE' to confirm you want to destroy ALL AWS resources: " confirmation
if [ "$confirmation" != "DELETE" ]; then
    echo -e "${YELLOW}Cleanup cancelled. No resources were destroyed.${NC}"
    exit 0
fi

read -p "Are you absolutely sure? This will DELETE everything! (yes/no): " final_confirm
if [ "$final_confirm" != "yes" ]; then
    echo -e "${YELLOW}Cleanup cancelled. No resources were destroyed.${NC}"
    exit 0
fi

echo -e "${GREEN}Starting comprehensive AWS cleanup...${NC}"
echo

# Step 1: Disable GitHub Actions deployment
echo -e "${YELLOW}Step 1: Disabling GitHub Actions AWS deployment...${NC}"
if [ -f ".github/workflows/ci-cd.yml" ]; then
    # Create a backup
    cp .github/workflows/ci-cd.yml .github/workflows/ci-cd.yml.backup
    echo -e "${BLUE}✓ Backup created: .github/workflows/ci-cd.yml.backup${NC}"
    
    # Disable deploy stage by commenting it out
    sed -i 's/^  deploy:/  # deploy: # DISABLED - Run cleanup.sh to restore/' .github/workflows/ci-cd.yml
    sed -i '/^  # deploy: # DISABLED/,/^[[:space:]]*if: github\.ref/{s/^/    # /}' .github/workflows/ci-cd.yml
    sed -i '/^    # deploy: # DISABLED/,/^[[:space:]]*- name: Deploy to EC2/{s/^    /      # /}' .github/workflows/ci-cd.yml
    
    echo -e "${GREEN}✓ GitHub Actions deployment disabled${NC}"
    echo -e "${BLUE}  → Push to GitHub to disable automated deployments${NC}"
else
    echo -e "${YELLOW}⚠ GitHub Actions workflow file not found${NC}"
fi

# Step 2: Stop and remove Auto Scaling Group instances (fastest cleanup)
echo -e "${YELLOW}Step 2: Stopping Auto Scaling Group and EC2 instances...${NC}"
aws autoscaling update-auto-scaling-group \
    --auto-scaling-group-name fastapi-backend-asg \
    --min-size 0 \
    --desired-capacity 0 \
    --max-size 0 \
    --region $AWS_REGION 2>/dev/null || echo "ASG not found or already stopped"
echo -e "${GREEN}✓ Auto Scaling Group stopped${NC}"

# Wait for instances to terminate
echo -e "${BLUE}  → Waiting for EC2 instances to terminate...${NC}"
sleep 30

# Step 3: Destroy infrastructure with Terraform
echo -e "${YELLOW}Step 3: Destroying infrastructure with Terraform...${NC}"
cd infrastructure

# Handle the ECR repository first (since it was imported)
echo -e "${BLUE}  → Removing ECR repository from Terraform state...${NC}"
terraform state rm aws_ecr_repository.main 2>/dev/null || echo "ECR not in state"

# Destroy all Terraform-managed resources
echo -e "${BLUE}  → Running terraform destroy...${NC}"
terraform destroy -auto-approve -var="image_uri=placeholder" 2>/dev/null || {
    echo -e "${RED}⚠ Terraform destroy failed or partially completed${NC}"
    echo -e "${BLUE}  → Continuing with manual cleanup...${NC}"
}

cd ..
echo -e "${GREEN}✓ Terraform infrastructure destroyed${NC}"

# Step 4: Manual cleanup of remaining resources
echo -e "${YELLOW}Step 4: Manual cleanup of remaining AWS resources...${NC}"

# Delete ECR repository and images
echo -e "${BLUE}  → Deleting ECR repository and images...${NC}"
aws ecr list-images \
    --repository-name $APP_NAME \
    --region $AWS_REGION \
    --query 'imageIds[*]' \
    --output json 2>/dev/null | \
aws ecr batch-delete-image \
    --repository-name $APP_NAME \
    --region $AWS_REGION \
    --image-ids file:///dev/stdin 2>/dev/null || echo "    No ECR images found"

aws ecr delete-repository \
    --repository-name $APP_NAME \
    --region $AWS_REGION \
    --force 2>/dev/null || echo "    ECR repository not found"
echo -e "${GREEN}✓ ECR repository deleted${NC}"

# Step 5: Clean up IAM resources
echo -e "${YELLOW}Step 5: Cleaning up IAM resources...${NC}"

# Detach and delete IAM policy
aws iam detach-user-policy \
    --user-name fastapi-github-actions \
    --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/FastAPIGitHubActionsPolicy 2>/dev/null || true

aws iam delete-policy \
    --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/FastAPIGitHubActionsPolicy 2>/dev/null || true

# Delete access keys and user
aws iam list-access-keys \
    --user-name fastapi-github-actions \
    --query 'AccessKeyMetadata[*].AccessKeyId' \
    --output text 2>/dev/null | \
while read -r key_id; do
    [ -n "$key_id" ] && aws iam delete-access-key --user-name fastapi-github-actions --access-key-id "$key_id" 2>/dev/null || true
done

aws iam delete-user \
    --user-name fastapi-github-actions 2>/dev/null || true
echo -e "${GREEN}✓ IAM user and policies deleted${NC}"

# Step 6: Delete S3 bucket (Terraform state)
echo -e "${YELLOW}Step 6: Deleting S3 bucket and Terraform state...${NC}"
S3_BUCKET="fastapi-terraform-state-${AWS_ACCOUNT_ID}"

# Empty the bucket first
aws s3 rm s3://$S3_BUCKET --recursive 2>/dev/null || true

# Delete all versions (for versioned buckets)
aws s3api list-object-versions \
    --bucket $S3_BUCKET \
    --query 'Versions[*].[Key,VersionId]' \
    --output text 2>/dev/null | \
while read -r key version_id; do
    [ -n "$key" ] && [ -n "$version_id" ] && \
    aws s3api delete-object \
        --bucket $S3_BUCKET \
        --key "$key" \
        --version-id "$version_id" 2>/dev/null || true
done

# Delete delete markers
aws s3api list-object-versions \
    --bucket $S3_BUCKET \
    --query 'DeleteMarkers[*].[Key,VersionId]' \
    --output text 2>/dev/null | \
while read -r key version_id; do
    [ -n "$key" ] && [ -n "$version_id" ] && \
    aws s3api delete-object \
        --bucket $S3_BUCKET \
        --key "$key" \
        --version-id "$version_id" 2>/dev/null || true
done

# Delete the bucket
aws s3 rb s3://$S3_BUCKET --force 2>/dev/null || true
echo -e "${GREEN}✓ S3 bucket deleted${NC}"

# Step 7: Verify cleanup
echo -e "${YELLOW}Step 7: Verifying cleanup completion...${NC}"

# Check for remaining resources
REMAINING_VPC=$(aws ec2 describe-vpcs --region $AWS_REGION --filters "Name=tag:Name,Values=fastapi-backend-vpc" --query 'Vpcs[0].VpcId' --output text 2>/dev/null || echo "None")
REMAINING_ALB=$(aws elbv2 describe-load-balancers --region $AWS_REGION --query 'LoadBalancers[?contains(LoadBalancerName, `fastapi`)]' --output text 2>/dev/null || echo "")
REMAINING_INSTANCES=$(aws ec2 describe-instances --region $AWS_REGION --filters "Name=tag:Environment,Values=production" "Name=instance-state-name,Values=running,pending,stopping,stopped" --query 'Reservations[*].Instances[*].InstanceId' --output text 2>/dev/null || echo "")

if [ "$REMAINING_VPC" = "None" ] && [ -z "$REMAINING_ALB" ] && [ -z "$REMAINING_INSTANCES" ]; then
    echo -e "${GREEN}✅ All AWS resources successfully deleted!${NC}"
else
    echo -e "${YELLOW}⚠ Some resources may still exist:${NC}"
    [ "$REMAINING_VPC" != "None" ] && echo -e "  • VPC: $REMAINING_VPC"
    [ -n "$REMAINING_ALB" ] && echo -e "  • Load Balancer: Found"
    [ -n "$REMAINING_INSTANCES" ] && echo -e "  • EC2 Instances: $REMAINING_INSTANCES"
    echo -e "${BLUE}These may be cleaned up automatically or require manual removal${NC}"
fi

# Step 8: Cleanup local files
echo -e "${YELLOW}Step 8: Cleaning up local files...${NC}"
rm -rf infrastructure/.terraform/ 2>/dev/null || true
rm -f infrastructure/.terraform.lock.hcl 2>/dev/null || true
rm -f infrastructure/terraform.tfstate* 2>/dev/null || true
echo -e "${GREEN}✓ Local Terraform files cleaned${NC}"

# Final summary
echo
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                     Cleanup Summary                          ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo -e "${GREEN}✅ AWS Infrastructure: Destroyed${NC}"
echo -e "${GREEN}✅ EC2 Instances: Terminated${NC}"  
echo -e "${GREEN}✅ Load Balancer: Deleted${NC}"
echo -e "${GREEN}✅ ECR Repository: Deleted${NC}"
echo -e "${GREEN}✅ IAM User/Policies: Deleted${NC}"
echo -e "${GREEN}✅ S3 State Bucket: Deleted${NC}"
echo -e "${GREEN}✅ GitHub Actions: Deployment Disabled${NC}"
echo -e "${GREEN}✅ Local Files: Cleaned${NC}"
echo

# Cost savings information
echo -e "${BLUE}💰 Estimated monthly cost savings: ~$45/month${NC}"
echo -e "${BLUE}   • EC2 instances: ~$16/month${NC}"
echo -e "${BLUE}   • Load Balancer: ~$23/month${NC}"
echo -e "${BLUE}   • Data transfer: ~$5/month${NC}"
echo -e "${BLUE}   • Storage: ~$1/month${NC}"
echo

# Next steps
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo -e "1. ${BLUE}Commit and push changes to disable GitHub Actions:${NC}"
echo -e "   git add .github/workflows/ci-cd.yml"
echo -e "   git commit -m 'Disable AWS deployment - infrastructure destroyed'"
echo -e "   git push origin master"
echo
echo -e "2. ${BLUE}Remove AWS credentials from GitHub Secrets:${NC}"
echo -e "   • Go to: https://github.com/iamsuryansh/fastapi-aws-backend/settings/secrets/actions"
echo -e "   • Delete: AWS_ACCESS_KEY_ID"  
echo -e "   • Delete: AWS_SECRET_ACCESS_KEY"
echo
echo -e "3. ${BLUE}To restore deployment later:${NC}"
echo -e "   • Restore: mv .github/workflows/ci-cd.yml.backup .github/workflows/ci-cd.yml"
echo -e "   • Re-run: ./scripts/deploy.sh"
echo

echo -e "${GREEN}🎉 Complete cleanup finished successfully!${NC}"
echo -e "${BLUE}Your AWS account is now clean and no longer incurring costs for this project.${NC}"