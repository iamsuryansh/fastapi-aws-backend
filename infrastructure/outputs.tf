# Load Balancer DNS Name
output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

# Load Balancer Zone ID
output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = aws_lb.main.zone_id
}

# ECR Repository URL
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.main.repository_url
}

# VPC ID
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

# Public Subnet IDs
output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

# Security Group IDs
output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "ec2_security_group_id" {
  description = "ID of the EC2 security group"
  value       = aws_security_group.ec2.id
}

# Route53 Zone ID (if domain is configured)
output "route53_zone_id" {
  description = "Route53 zone ID"
  value       = var.domain_name != "" ? aws_route53_zone.main[0].zone_id : null
}

# Instance IPs (for deployment script)
output "instance_ips" {
  description = "Private IP addresses of EC2 instances"
  value       = "Check Auto Scaling Group for current instances"
}