#!/bin/bash

# Configuration Script - Run this first to set up all your personal details

echo "=========================================="
echo "Blue-Green Deployment Lab - Configuration"
echo "=========================================="
echo ""
echo "This script will help you configure all necessary details."
echo ""

# GitHub Configuration
echo "--- GitHub Configuration ---"
read -p "Enter your GitHub username: " GITHUB_USER
read -p "Enter your repository name (e.g., blue-green-deployment-lab): " REPO_NAME
GITHUB_REPO="https://github.com/${GITHUB_USER}/${REPO_NAME}.git"
echo "GitHub URL will be: $GITHUB_REPO"
echo ""

# Docker Hub Configuration
echo "--- Docker Hub Configuration ---"
read -p "Enter your Docker Hub username: " DOCKERHUB_USER
echo ""

# AWS Configuration
echo "--- AWS Configuration ---"
read -p "Enter your preferred AWS region (default: us-east-1): " AWS_REGION
AWS_REGION=${AWS_REGION:-us-east-1}
echo ""

# Summary
echo "=========================================="
echo "Configuration Summary:"
echo "=========================================="
echo "GitHub User:     $GITHUB_USER"
echo "Repository:      $REPO_NAME"
echo "Full Repo URL:   $GITHUB_REPO"
echo "Docker Hub:      $DOCKERHUB_USER"
echo "AWS Region:      $AWS_REGION"
echo "=========================================="
echo ""

read -p "Is this correct? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Configuration cancelled. Please run the script again."
    exit 1
fi

echo ""
echo "Updating configuration files..."

# Update Jenkinsfile
echo "✅ Updating Jenkinsfile..."
sed -i.bak "s/YOUR_DOCKERHUB_USERNAME/${DOCKERHUB_USER}/g" Jenkinsfile
sed -i.bak "s|YOUR_ORG/YOUR_REPO|${GITHUB_USER}/${REPO_NAME}|g" Jenkinsfile

# Update Kubernetes manifests
echo "✅ Updating k8s/deployment-blue.yaml..."
sed -i.bak "s/YOUR_DOCKERHUB_USERNAME/${DOCKERHUB_USER}/g" k8s/deployment-blue.yaml

echo "✅ Updating k8s/deployment-green.yaml..."
sed -i.bak "s/YOUR_DOCKERHUB_USERNAME/${DOCKERHUB_USER}/g" k8s/deployment-green.yaml

# Update Terraform variables
echo "✅ Creating terraform/terraform.tfvars..."
cat > terraform/terraform.tfvars <<EOF
aws_region = "${AWS_REGION}"
project_name = "blue-green-deployment"
EOF

# Create a configuration reference file
cat > .lab-config <<EOF
# Lab Configuration (Generated: $(date))
GITHUB_USER=$GITHUB_USER
REPO_NAME=$REPO_NAME
GITHUB_REPO=$GITHUB_REPO
DOCKERHUB_USER=$DOCKERHUB_USER
AWS_REGION=$AWS_REGION
EOF

echo ""
echo "=========================================="
echo "Configuration Complete! ✅"
echo "=========================================="
echo ""
echo "Next Steps:"
echo ""
echo "1. Initialize Git repository:"
echo "   git init"
echo "   git add ."
echo "   git commit -m 'Initial commit: Blue-Green deployment setup'"
echo "   git remote add origin $GITHUB_REPO"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
echo "2. Check AWS credentials:"
echo "   aws sts get-caller-identity"
echo ""
echo "3. Verify SSH key exists:"
echo "   ls -la ~/.ssh/id_rsa*"
echo ""
echo "4. Start infrastructure deployment:"
echo "   cd terraform"
echo "   terraform init"
echo "   terraform plan"
echo "   terraform apply"
echo ""
echo "5. After Terraform completes, update Ansible inventory:"
echo "   JENKINS_IP=\$(cd terraform && terraform output -raw jenkins_public_ip)"
echo "   sed -i \"s/JENKINS_PUBLIC_IP/\$JENKINS_IP/g\" ansible/inventory.ini"
echo ""
echo "See README.md for complete setup instructions."
echo ""
echo "Configuration saved to .lab-config"
echo ""
