terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# 1. Fetch latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  owners = ["099720109477"] # Canonical
}

# 2. Create a Security Group for SSH and Kubernetes API access
resource "aws_security_group" "k3s_sg" {
  name        = "k3s-argocd-sg"
  description = "Allow SSH and Kube API access"

  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # ⚠️ Restrict this to your actual IP for security!
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. Free Tier EC2 Instance with User Data for K3s & ArgoCD
resource "aws_instance" "free_tier_vm" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro" 
  
  # Attach the security group
  vpc_security_group_ids = [aws_security_group.k3s_sg.id]

  # Optional: Add your SSH key name here if you want to SSH into the box later
  # key_name = "your-aws-ssh-key-name"

  tags = {
    Name      = "Vault-Secured-K3s-ArgoCD"
    ManagedBy = "Terraform-GHA"
  }

  # 4. Bootstrap Script (User Data)
  user_data = <<-EOF
    #!/bin/bash
    # Update OS packages
    apt-get update && apt-get upgrade -y

    # Install K3s (lightweight Kubernetes)
    # We disable traefik to save precious RAM on the t2.micro
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --disable traefik" sh -

    # Wait for K3s to be fully ready
    sleep 30
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

    # Create ArgoCD namespace
    kubectl create namespace argocd

    # Install ArgoCD via official manifests
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

    # Patch the ArgoCD Server to use a NodePort so it's easier to access
    kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
  EOF
}

# Output the Public IP so you can easily find it in GitHub Actions logs
output "instance_public_ip" {
  value       = aws_instance.free_tier_vm.public_ip
  description = "The public IP address of the EC2 instance"
}
