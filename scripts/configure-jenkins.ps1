# PowerShell script to configure Jenkins remotely using AWS SSM

$InstanceId = "i-0acd9c2ff7d139bd8"
$Region = "ap-south-1"

Write-Host "=========================================="
Write-Host "Configuring Jenkins Server Remotely"
Write-Host "=========================================="
Write-Host ""

# Jenkins setup commands
$SetupCommands = @'
#!/bin/bash
echo "Starting Jenkins configuration..."

# Update system
sudo yum update -y

# Install Java 11
sudo yum install -y java-11-openjdk java-11-openjdk-devel

# Add Jenkins repository
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# Install Jenkins
sudo yum install -y jenkins

# Install Docker
sudo yum install -y docker

# Install Git
sudo yum install -y git

# Start services
sudo systemctl start jenkins
sudo systemctl enable jenkins
sudo systemctl start docker
sudo systemctl enable docker

# Add users to docker group
sudo usermod -aG docker jenkins
sudo usermod -aG docker ec2-user

# Install kubectl
curl -LO "https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install --update
rm -rf aws awscliv2.zip

# Install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Install Maven
sudo yum install -y maven

echo "Configuration complete!"
sleep 30

# Display Jenkins password
if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
    echo "=========================================="
    echo "Jenkins Initial Admin Password:"
    sudo cat /var/lib/jenkins/secrets/initialAdminPassword
    echo "=========================================="
fi
'@

Write-Host "Sending configuration commands to EC2 instance..."
Write-Host "This will take about 5-10 minutes..."
Write-Host ""

try {
    $CommandId = (aws ssm send-command `
        --instance-ids $InstanceId `
        --document-name "AWS-RunShellScript" `
        --parameters "commands=$SetupCommands" `
        --region $Region `
        --output json | ConvertFrom-Json).Command.CommandId
    
    Write-Host "Command sent successfully! Command ID: $CommandId"
    Write-Host "Waiting for command to complete..."
    Write-Host ""
    
    # Wait for command to complete
    Start-Sleep -Seconds 10
    
    # Check command status
    $Status = "InProgress"
    $Counter = 0
    while ($Status -eq "InProgress" -and $Counter -lt 60) {
        Start-Sleep -Seconds 10
        $Counter++
        $CommandStatus = aws ssm get-command-invocation `
            --command-id $CommandId `
            --instance-id $InstanceId `
            --region $Region `
            --output json | ConvertFrom-Json
        
        $Status = $CommandStatus.Status
        Write-Host "Status: $Status (Waiting $($Counter * 10) seconds...)"
    }
    
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "Configuration Output:"
    Write-Host "=========================================="
    Write-Host $CommandStatus.StandardOutputContent
    
    if ($CommandStatus.StandardErrorContent) {
        Write-Host ""
        Write-Host "Errors (if any):"
        Write-Host $CommandStatus.StandardErrorContent
    }
    
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "Setup Complete!"
    Write-Host "=========================================="
    Write-Host ""
    Write-Host "Jenkins URL: http://15.207.86.196:8080"
    Write-Host ""
    Write-Host "Wait 2-3 more minutes for Jenkins to fully start,"
    Write-Host "then open the URL in your browser!"
    
} catch {
    Write-Host "Error: $_"
    Write-Host ""
    Write-Host "AWS Systems Manager might not be enabled on the instance."
    Write-Host "Alternative: Wait 5 minutes, then access Jenkins at:"
    Write-Host "http://15.207.86.196:8080"
}
