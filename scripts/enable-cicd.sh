#!/bin/bash

# Script to re-enable GitHub Actions CI/CD deployment

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║            Re-enable GitHub Actions AWS Deployment          ║${NC}"  
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

# Check if backup exists
if [ ! -f ".github/workflows/ci-cd.yml.backup" ]; then
    echo -e "${RED}❌ Error: Backup file .github/workflows/ci-cd.yml.backup not found${NC}"
    echo -e "${BLUE}Cannot restore original workflow${NC}"
    exit 1
fi

# Check if currently disabled
if ! grep -q "# deploy: # DISABLED" .github/workflows/ci-cd.yml; then
    echo -e "${YELLOW}⚠ AWS deployment is already enabled${NC}"
    exit 0
fi

echo -e "${YELLOW}This script will:${NC}"
echo -e "  • Restore original GitHub Actions workflow"
echo -e "  • Re-enable automated AWS deployment"
echo -e "  • Allow CI/CD pipeline to deploy on push to master/main"
echo

# Confirm action
read -p "Do you want to re-enable AWS deployment in GitHub Actions? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Operation cancelled.${NC}"
    exit 0
fi

# Restore from backup
cp .github/workflows/ci-cd.yml.backup .github/workflows/ci-cd.yml

echo -e "${GREEN}✅ AWS deployment re-enabled in GitHub Actions${NC}"
echo

# Show current status
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                        Status                                ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo -e "${GREEN}✅ Testing: Enabled${NC}"
echo -e "${GREEN}✅ Docker Build: Enabled${NC}"
echo -e "${GREEN}✅ AWS Deployment: ENABLED${NC}"
echo

# Next steps
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo -e "1. ${BLUE}Commit and push changes:${NC}"
echo -e "   git add .github/workflows/ci-cd.yml"
echo -e "   git commit -m 'Re-enable AWS deployment in CI/CD pipeline'"
echo -e "   git push origin master"
echo
echo -e "2. ${BLUE}Verify GitHub Actions pipeline runs successfully${NC}"
echo
echo -e "3. ${BLUE}Check AWS resources are accessible:${NC}"
echo -e "   curl http://fastapi-backend-alb-950649830.ap-south-1.elb.amazonaws.com/health"
echo

echo -e "${GREEN}🎉 GitHub Actions CI/CD deployment re-enabled successfully!${NC}"