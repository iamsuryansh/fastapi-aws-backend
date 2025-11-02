#!/bin/bash

# Update system
yum update -y

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Install SSM Agent
yum install -y amazon-ssm-agent
systemctl start amazon-ssm-agent
systemctl enable amazon-ssm-agent

# Configure Docker to use ECR
aws configure set default.region us-east-1

# Login to ECR and pull image
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${split("/", var.image_uri)[0]}

# Pull and run the Docker container
docker pull ${image_uri}
docker run -d --name fastapi-container --restart unless-stopped -p 8000:8000 ${image_uri}

# Install CloudWatch agent (optional)
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm