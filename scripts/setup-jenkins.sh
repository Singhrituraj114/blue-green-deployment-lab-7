#!/bin/bash

# Remote Jenkins Setup Script
# This script will be executed on the EC2 instance

echo "=========================================="
echo "Starting Jenkins Setup"
echo "=========================================="

# Update system
echo "Updating system packages..."
sudo yum update -y

# Install Java
echo "Installing Java 11..."
sudo yum install -y java-11-openjdk java-11-openjdk-devel

# Add Jenkins repository
echo "Adding Jenkins repository..."
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# Install Jenkins
echo "Installing Jenkins..."
sudo yum install -y jenkins

# Install Docker
echo "Installing Docker..."
sudo yum install -y docker

# Start services
echo "Starting services..."
sudo systemctl start jenkins
sudo systemctl enable jenkins
sudo systemctl start docker
sudo systemctl enable docker

# Add jenkins and ec2-user to docker group
sudo usermod -aG docker jenkins
sudo usermod -aG docker ec2-user

# Install kubectl
echo "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Install AWS CLI
echo "Installing AWS CLI..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install --update
rm -rf aws awscliv2.zip

# Install eksctl
echo "Installing eksctl..."
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Install Maven
echo "Installing Maven..."
sudo yum install -y maven

# Wait for Jenkins to start
echo "Waiting for Jenkins to initialize..."
sleep 30

# Get Jenkins initial password
echo "=========================================="
echo "Jenkins Setup Complete!"
echo "=========================================="
echo ""
if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
    echo "Jenkins Initial Admin Password:"
    sudo cat /var/lib/jenkins/secrets/initialAdminPassword
else
    echo "Jenkins is still initializing. Password will be available soon."
fi
echo ""
echo "Access Jenkins at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo ""
