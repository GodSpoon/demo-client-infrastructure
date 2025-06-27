variable "client_name" {
  description = "Client name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ssh_public_key" {
  description = "SSH public key for EC2 access"
  type        = string
  sensitive   = true
}

variable "msp_ip_range" {
  description = "IP range for MSP SSH access"
  type        = string
  default     = "0.0.0.0/0"  # Replace with your MSP's IP range
}
