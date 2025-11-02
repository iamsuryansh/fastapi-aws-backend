#!/bin/bash

# Script to disable GitHub Actions CI/CD deployment without destroying AWS resources

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Disable GitHub Actions AWS Deployment             ║${NC}"  
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

echo -e "${YELLOW}This script will:${NC}"
echo -e "  • Disable AWS deployment in GitHub Actions"
echo -e "  • Keep your AWS resources running (no deletion)"
echo -e "  • Create backup of original workflow"
echo -e "  • Allow easy re-enabling later"
echo

# Check if workflow file exists
if [ ! -f ".github/workflows/ci-cd.yml" ]; then
    echo -e "${RED}❌ Error: .github/workflows/ci-cd.yml not found${NC}"
    echo -e "${BLUE}Make sure you're in the project root directory${NC}"
    exit 1
fi

# Confirm action
read -p "Do you want to disable AWS deployment in GitHub Actions? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Operation cancelled.${NC}"
    exit 0
fi

# Create backup if it doesn't exist
if [ ! -f ".github/workflows/ci-cd.yml.backup" ]; then
    cp .github/workflows/ci-cd.yml .github/workflows/ci-cd.yml.backup
    echo -e "${GREEN}✓ Backup created: .github/workflows/ci-cd.yml.backup${NC}"
else
    echo -e "${BLUE}✓ Backup already exists${NC}"
fi

# Check if already disabled
if grep -q "# deploy: # DISABLED" .github/workflows/ci-cd.yml; then
    echo -e "${YELLOW}⚠ AWS deployment is already disabled${NC}"
    echo -e "${BLUE}To re-enable, run: ./scripts/enable-cicd.sh${NC}"
    exit 0
fi

# Disable the deploy job by commenting it out
echo -e "${YELLOW}Disabling AWS deployment in GitHub Actions...${NC}"

# Create a temporary file with disabled deployment
cat > .github/workflows/ci-cd.yml.temp << 'EOF'
name: FastAPI CI/CD Pipeline

on:
  push:
    branches: [ master, main ]
  pull_request:
    branches: [ master, main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.9'
    
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
    
    - name: Run tests
      run: |
        python -m pytest test_main.py -v

  build:
    needs: test
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ap-south-1
    
    - name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v2
    
    - name: Build and push Docker image
      env:
        ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        ECR_REPOSITORY: fastapi-backend
        IMAGE_TAG: ${{ github.sha }}
      run: |
        docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
        docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:latest .
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest

  # deploy: # DISABLED - AWS deployment disabled by disable-cicd.sh script
  # needs: build
  # runs-on: ubuntu-latest
  # if: github.ref == 'refs/heads/master' || github.ref == 'refs/heads/main'
  # 
  # steps:
  # - uses: actions/checkout@v4
  # 
  # - name: Configure AWS credentials
  #   uses: aws-actions/configure-aws-credentials@v4
  #   with:
  #     aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
  #     aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
  #     aws-region: ap-south-1
  # 
  # - name: Setup Terraform
  #   uses: hashicorp/setup-terraform@v3
  #   with:
  #     terraform_version: 1.12.2
  # 
  # - name: Deploy to EC2
  #   env:
  #     AWS_ACCOUNT_ID: 501235162920
  #   run: |
  #     cd infrastructure
  #     terraform init
  #     terraform apply -auto-approve \
  #       -var="image_uri=$AWS_ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com/fastapi-backend:${{ github.sha }}"
EOF

# Replace the original file
mv .github/workflows/ci-cd.yml.temp .github/workflows/ci-cd.yml

echo -e "${GREEN}✅ AWS deployment disabled in GitHub Actions${NC}"
echo

# Show current status
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                        Status                                ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo -e "${GREEN}✅ Testing: Still enabled${NC}"
echo -e "${GREEN}✅ Docker Build: Still enabled${NC}"
echo -e "${RED}❌ AWS Deployment: DISABLED${NC}"
echo -e "${BLUE}💡 Your AWS resources continue running${NC}"
echo

# Next steps
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo -e "1. ${BLUE}Commit and push changes:${NC}"
echo -e "   git add .github/workflows/ci-cd.yml"
echo -e "   git commit -m 'Disable AWS deployment in CI/CD pipeline'"
echo -e "   git push origin master"
echo
echo -e "2. ${BLUE}To re-enable deployment later:${NC}"
echo -e "   ./scripts/enable-cicd.sh"
echo
echo -e "3. ${BLUE}To completely destroy AWS resources:${NC}"
echo -e "   ./scripts/cleanup.sh"
echo

echo -e "${GREEN}🎉 GitHub Actions CI/CD deployment disabled successfully!${NC}"