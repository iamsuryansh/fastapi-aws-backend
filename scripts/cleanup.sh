#!/bin/bash

# Cleanup script for AWS resources

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

APP_NAME=${APP_NAME:-fastapi-backend}
AWS_REGION=${AWS_REGION:-us-east-1}

echo -e "${YELLOW}Starting cleanup of AWS resources for $APP_NAME...${NC}"

# Confirm cleanup
read -p "Are you sure you want to destroy all AWS resources? This action cannot be undone. (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Cleanup cancelled.${NC}"
    exit 0
fi

# Destroy infrastructure
echo -e "${YELLOW}Destroying infrastructure with Terraform...${NC}"
cd infrastructure
terraform destroy -auto-approve
cd ..

# Clean up ECR images (optional)
read -p "Do you want to delete all ECR images? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Deleting ECR images...${NC}"
    aws ecr list-images --repository-name $APP_NAME --region $AWS_REGION --query 'imageIds[*]' --output json | \
    aws ecr batch-delete-image --repository-name $APP_NAME --region $AWS_REGION --image-ids file:///dev/stdin || true
fi

echo -e "${GREEN}Cleanup completed!${NC}"