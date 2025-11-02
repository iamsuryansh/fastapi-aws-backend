#!/bin/bash

# Deployment script for FastAPI backend on AWS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION=${AWS_REGION:-us-east-1}
APP_NAME=${APP_NAME:-fastapi-backend}
ENVIRONMENT=${ENVIRONMENT:-production}

echo -e "${GREEN}Starting deployment of $APP_NAME to AWS...${NC}"

# Check if required tools are installed
check_dependencies() {
    echo -e "${YELLOW}Checking dependencies...${NC}"
    
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}AWS CLI is not installed${NC}"
        exit 1
    fi
    
    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}Terraform is not installed${NC}"
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker is not installed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}All dependencies are installed${NC}"
}

# Build and push Docker image
build_and_push_image() {
    echo -e "${YELLOW}Building and pushing Docker image...${NC}"
    
    # Get ECR login token
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.$AWS_REGION.amazonaws.com
    
    # Build image
    IMAGE_URI=$(aws sts get-caller-identity --query Account --output text).dkr.ecr.$AWS_REGION.amazonaws.com/$APP_NAME:$(git rev-parse HEAD)
    
    docker build -t $IMAGE_URI .
    docker tag $IMAGE_URI $(aws sts get-caller-identity --query Account --output text).dkr.ecr.$AWS_REGION.amazonaws.com/$APP_NAME:latest
    
    # Push image
    docker push $IMAGE_URI
    docker push $(aws sts get-caller-identity --query Account --output text).dkr.ecr.$AWS_REGION.amazonaws.com/$APP_NAME:latest
    
    echo "IMAGE_URI=$IMAGE_URI" > .env
    echo -e "${GREEN}Image built and pushed successfully${NC}"
}

# Deploy infrastructure
deploy_infrastructure() {
    echo -e "${YELLOW}Deploying infrastructure...${NC}"
    
    cd infrastructure
    
    # Initialize Terraform
    terraform init
    
    # Plan deployment
    terraform plan -var="image_uri=$IMAGE_URI"
    
    # Apply deployment
    terraform apply -auto-approve -var="image_uri=$IMAGE_URI"
    
    cd ..
    
    echo -e "${GREEN}Infrastructure deployed successfully${NC}"
}

# Update application
update_application() {
    echo -e "${YELLOW}Updating application on EC2 instances...${NC}"
    
    # Send command to all instances with the Environment tag
    aws ssm send-command \
        --document-name "AWS-RunShellScript" \
        --parameters "commands=[
            'sudo docker stop fastapi-container || true',
            'sudo docker rm fastapi-container || true',
            'aws ecr get-login-password --region $AWS_REGION | sudo docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.$AWS_REGION.amazonaws.com',
            'sudo docker pull $IMAGE_URI',
            'sudo docker run -d --name fastapi-container --restart unless-stopped -p 8000:8000 $IMAGE_URI'
        ]" \
        --targets "Key=tag:Environment,Values=$ENVIRONMENT" \
        --region $AWS_REGION
    
    echo -e "${GREEN}Application updated on EC2 instances${NC}"
}

# Health check
health_check() {
    echo -e "${YELLOW}Performing health check...${NC}"
    
    # Get load balancer DNS from Terraform output
    cd infrastructure
    LB_DNS=$(terraform output -raw load_balancer_dns)
    cd ..
    
    # Wait for deployment to complete
    echo "Waiting for deployment to complete..."
    sleep 60
    
    # Check health endpoint
    for i in {1..10}; do
        if curl -f "http://$LB_DNS/health" > /dev/null 2>&1; then
            echo -e "${GREEN}Health check passed!${NC}"
            echo -e "${GREEN}Application is available at: http://$LB_DNS${NC}"
            return 0
        fi
        echo "Health check attempt $i failed, retrying in 30 seconds..."
        sleep 30
    done
    
    echo -e "${RED}Health check failed after 10 attempts${NC}"
    return 1
}

# Main deployment function
main() {
    echo -e "${GREEN}FastAPI AWS Deployment Script${NC}"
    echo "=================================="
    
    check_dependencies
    
    # Source environment variables if .env exists
    if [ -f .env ]; then
        source .env
    fi
    
    build_and_push_image
    deploy_infrastructure
    update_application
    health_check
    
    echo -e "${GREEN}Deployment completed successfully!${NC}"
}

# Run main function
main "$@"