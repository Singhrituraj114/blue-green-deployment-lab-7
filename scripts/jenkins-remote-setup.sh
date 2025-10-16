#!/bin/bash
# Jenkins Remote Setup Script

echo "=========================================="
echo "Starting Jenkins Configuration"
echo "=========================================="

# Update system
echo "Updating system..."
sudo yum update -y

# Install Java 11
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

# Install Git
echo "Installing Git..."
sudo yum install -y git

# Install Maven
echo "Installing Maven..."
sudo yum install -y maven

# Start services
echo "Starting services..."
sudo systemctl start jenkins
sudo systemctl enable jenkins
sudo systemctl start docker
sudo systemctl enable docker

# Add users to docker group
echo "Configuring permissions..."
sudo usermod -aG docker jenkins
sudo usermod -aG docker ec2-user

# Install kubectl
echo "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm -f kubectl

# Install AWS CLI
echo "Installing AWS CLI..."
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install --update
rm -rf aws awscliv2.zip

# Install eksctl
echo "Installing eksctl..."
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

echo ""
echo "=========================================="
echo "Waiting for Jenkins to start..."
echo "=========================================="
sleep 45

# Display Jenkins password
if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
    echo ""
    echo "=========================================="
    echo "JENKINS INITIAL ADMIN PASSWORD:"
    echo "=========================================="
    sudo cat /var/lib/jenkins/secrets/initialAdminPassword
    echo ""
    echo "=========================================="
else
    echo "Jenkins password file not found yet. Wait 2 minutes and check manually."
fi

echo ""
echo "Configuration complete!"
echo "Access Jenkins at: http://15.207.86.196:8080"
