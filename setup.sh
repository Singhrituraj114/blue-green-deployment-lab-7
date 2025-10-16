#!/bin/bash

# Quick Setup Script for Blue-Green Deployment Lab

echo "======================================"
echo "Blue-Green Deployment - Quick Setup"
echo "======================================"
echo ""

# Check prerequisites
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo "❌ $1 is not installed. Please install it first."
        exit 1
    else
        echo "✅ $1 found"
    fi
}

echo "Checking prerequisites..."
check_command terraform
check_command ansible
check_command git
check_command ssh

echo ""
echo "Prerequisites check complete!"
echo ""

# Generate SSH key if not exists
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "Generating SSH key pair..."
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    echo "✅ SSH key generated"
else
    echo "✅ SSH key already exists"
fi

echo ""
read -p "Enter your AWS region (default: us-east-1): " AWS_REGION
AWS_REGION=${AWS_REGION:-us-east-1}

read -p "Enter your Docker Hub username: " DOCKERHUB_USER
read -p "Enter your GitHub repository URL: " GITHUB_REPO

echo ""
echo "Configuration:"
echo "  AWS Region: $AWS_REGION"
echo "  Docker Hub: $DOCKERHUB_USER"
echo "  GitHub: $GITHUB_REPO"
echo ""

read -p "Proceed with setup? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Setup cancelled."
    exit 0
fi

# Update Terraform variables
cd terraform
cat > terraform.tfvars <<EOF
aws_region = "$AWS_REGION"
project_name = "blue-green-deployment"
EOF

echo ""
echo "Step 1: Initializing Terraform..."
terraform init

echo ""
echo "Step 2: Planning infrastructure..."
terraform plan -out=tfplan

echo ""
read -p "Apply Terraform plan? (yes/no): " APPLY
if [ "$APPLY" = "yes" ]; then
    terraform apply tfplan
    
    # Get Jenkins IP
    JENKINS_IP=$(terraform output -raw jenkins_public_ip)
    echo ""
    echo "✅ Infrastructure created!"
    echo "   Jenkins IP: $JENKINS_IP"
    
    # Update Ansible inventory
    cd ../ansible
    sed -i.bak "s/JENKINS_PUBLIC_IP/$JENKINS_IP/g" inventory.ini
    
    echo ""
    echo "Step 3: Waiting for EC2 instance to be ready..."
    sleep 30
    
    echo ""
    echo "Step 4: Running Ansible playbook..."
    ansible-playbook -i inventory.ini jenkins_setup.yml
    
    echo ""
    echo "======================================"
    echo "Setup Complete!"
    echo "======================================"
    echo ""
    echo "Next steps:"
    echo "1. Access Jenkins: http://$JENKINS_IP:8080"
    echo "2. Configure EKS: ansible-playbook -i ansible/inventory.ini ansible/eks_setup.yml"
    echo "3. Update Jenkinsfile with your Docker Hub username: $DOCKERHUB_USER"
    echo "4. Update k8s/*.yaml files with your Docker Hub username"
    echo "5. Push code to GitHub: $GITHUB_REPO"
    echo "6. Configure GitHub webhook: http://$JENKINS_IP:8080/github-webhook/"
    echo ""
    echo "See README.md for detailed instructions."
else
    echo "Terraform apply skipped."
fi
