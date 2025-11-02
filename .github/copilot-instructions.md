# FastAPI Backend with AWS Deployment

This is a FastAPI backend project with CI/CD pipeline using GitHub Actions for deployment on AWS infrastructure (EC2 + Route53 + ALB).

## Project Structure
- FastAPI application with Python 3.9+
- Docker containerization
- GitHub Actions for CI/CD
- AWS infrastructure using Terraform
- Automated deployment to EC2 with Load Balancer

## Development Guidelines
- Follow FastAPI best practices for API development
- Use type hints and Pydantic models
- Implement proper error handling and logging
- Write unit tests with pytest
- Use environment variables for configuration

## Deployment
- Automated deployment via GitHub Actions
- Infrastructure provisioned with Terraform
- Blue-green deployment strategy
- Health checks and monitoring