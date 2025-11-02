# FastAPI Backend with AWS Deployment

A complete FastAPI backend application with CI/CD pipeline using GitHub Actions for deployment on AWS infrastructure (EC2 + Route53 + ALB).

## 🚀 Features

- **FastAPI Application**: Modern Python web framework with automatic API documentation
- **Docker Support**: Containerized application for consistent deployments
- **AWS Infrastructure**: EC2 instances with Auto Scaling, Application Load Balancer, and optional Route53
- **CI/CD Pipeline**: Automated testing, building, and deployment with GitHub Actions
- **Infrastructure as Code**: Terraform for managing AWS resources
- **Health Checks**: Built-in health monitoring and application status endpoints
- **Comprehensive Testing**: Unit tests with pytest and FastAPI TestClient

## 📋 Prerequisites

Before deploying this application, ensure you have:

- AWS Account with appropriate permissions
- AWS CLI configured with credentials
- Terraform installed (>= 1.0)
- Docker installed
- Python 3.9+ installed
- Git repository set up

## 🛠️ Local Development

### 1. Clone and Setup

```bash
git clone <your-repository>
cd fastapi_with_gh_actions_and_aws

# Create virtual environment
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Run Locally

```bash
# Start the application
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Or using Python directly
python main.py
```

### 3. Run with Docker

```bash
# Build and run with docker-compose
docker-compose up --build

# Or build and run manually
docker build -t fastapi-backend .
docker run -p 8000:8000 fastapi-backend
```

### 4. Testing

```bash
# Run tests
pytest test_main.py -v

# Test specific endpoints
curl http://localhost:8000/health
curl http://localhost:8000/
```

## 📚 API Documentation

Once the application is running, visit:
- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`

### Available Endpoints

- `GET /` - Welcome message
- `GET /health` - Health check endpoint
- `GET /items` - List all items
- `GET /items/{item_id}` - Get specific item
- `POST /items` - Create new item
- `PUT /items/{item_id}` - Update item
- `DELETE /items/{item_id}` - Delete item

## ☁️ AWS Deployment

### 1. Setup AWS Credentials

Configure your AWS credentials and create the following GitHub Secrets:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

### 2. Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your AWS settings
AWS_REGION=us-east-1
APP_NAME=fastapi-backend
DOMAIN_NAME=your-domain.com  # Optional
```

### 3. Manual Deployment

```bash
# Make scripts executable
chmod +x scripts/deploy.sh
chmod +x scripts/cleanup.sh

# Run deployment script
./scripts/deploy.sh
```

### 4. Automated Deployment

The CI/CD pipeline automatically:
1. Runs tests on pull requests and pushes
2. Builds Docker image and pushes to ECR
3. Deploys infrastructure using Terraform
4. Updates application on EC2 instances
5. Performs health checks

Simply push to the `main` branch to trigger deployment.

## 🏗️ Infrastructure

### AWS Resources Created

- **VPC**: Custom VPC with public subnets
- **EC2**: Auto Scaling Group with configurable instance types
- **ALB**: Application Load Balancer with health checks
- **ECR**: Container registry for Docker images
- **Route53**: DNS configuration (optional)
- **IAM**: Roles and policies for EC2 and deployment
- **Security Groups**: Properly configured network access

### Architecture Diagram

```
Internet → Route53 → ALB → Target Group → EC2 Instances (Auto Scaling)
                                      ↓
                                   ECR Repository
```

## 🔧 Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Application port | 8000 |
| `AWS_REGION` | AWS region | us-east-1 |
| `APP_NAME` | Application name | fastapi-backend |
| `ENVIRONMENT` | Environment name | production |
| `DOMAIN_NAME` | Custom domain | None |
| `INSTANCE_TYPE` | EC2 instance type | t3.micro |

### Terraform Variables

Customize deployment in `infrastructure/main.tf`:
- Instance types and sizes
- Auto Scaling configuration
- Security group rules
- Domain configuration

## 🔍 Monitoring and Logging

### Health Checks
- Application: `GET /health`
- Load Balancer: Configured health checks on port 8000
- Auto Scaling: ELB health checks with 5-minute grace period

### Logs
- Application logs: Available via Docker logs
- Infrastructure: CloudWatch integration available
- Deployment: GitHub Actions logs

## 🚦 CI/CD Pipeline

### Workflow Steps

1. **Test**: Run pytest and code quality checks
2. **Build**: Create Docker image and push to ECR
3. **Deploy**: Update infrastructure and application
4. **Verify**: Health check validation

### GitHub Actions Configuration

The pipeline uses:
- Python 3.9 for testing
- AWS credentials from secrets
- Terraform for infrastructure
- Docker for containerization

## 🔒 Security Best Practices

- **IAM Roles**: Principle of least privilege
- **Security Groups**: Restricted network access
- **Container Security**: Non-root user in Docker
- **Secrets Management**: Use AWS Secrets Manager for production
- **HTTPS**: Configure ALB with SSL certificate

## 📊 Scaling

### Auto Scaling Configuration
- **Min Size**: 1 instance
- **Max Size**: 3 instances
- **Desired**: 2 instances
- **Scaling Metrics**: CPU and request-based

### Performance Optimization
- Use Application Load Balancer for distribution
- Configure health checks for reliability
- Implement caching strategies as needed
- Monitor with CloudWatch

## 🛠️ Development Workflow

### Adding Features
1. Create feature branch
2. Develop and test locally
3. Run tests: `pytest test_main.py -v`
4. Create pull request
5. Merge to main for automatic deployment

### Database Integration
To add database support:
1. Add database credentials to environment
2. Update `requirements.txt` with database drivers
3. Modify `main.py` to include database models
4. Update infrastructure for RDS if needed

## 📝 Troubleshooting

### Common Issues

**Deployment Fails**
- Check AWS credentials and permissions
- Verify Terraform state and resources
- Review GitHub Actions logs

**Health Check Fails**
- Ensure application starts on port 8000
- Check security group rules
- Verify Docker image functionality

**Performance Issues**
- Monitor CloudWatch metrics
- Check Auto Scaling configuration
- Review application logs

### Useful Commands

```bash
# Check application status
curl http://<load-balancer-dns>/health

# View deployment logs
aws logs describe-log-groups --log-group-name-prefix /aws/ec2

# Check running instances
aws ec2 describe-instances --filters "Name=tag:Environment,Values=production"

# Manual deployment
./scripts/deploy.sh

# Clean up resources
./scripts/cleanup.sh
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Related Resources

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)