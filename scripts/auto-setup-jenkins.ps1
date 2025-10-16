# Simple PowerShell script to configure Jenkins remotely

Write-Host "=========================================="
Write-Host "Configuring Jenkins Server"
Write-Host "Jenkins IP: 35.154.123.73"
Write-Host "=========================================="
Write-Host ""

# Define setup commands as array
$commands = @(
    "sudo yum update -y"
    "sudo yum install -y java-11-openjdk java-11-openjdk-devel"
    "sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo"
    "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key"
    "sudo yum install -y jenkins"
    "sudo yum install -y docker git"
    "sudo systemctl start jenkins"
    "sudo systemctl enable jenkins"
    "sudo systemctl start docker"
    "sudo systemctl enable docker"
    "sudo usermod -aG docker jenkins"
    "curl -LO https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl"
    "sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl"
    "curl --silent --location https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz | tar xz -C /tmp"
    "sudo mv /tmp/eksctl /usr/local/bin"
)

Write-Host "Running setup commands (this will take 5-10 minutes)..."
Write-Host ""

foreach ($cmd in $commands) {
    Write-Host "► Running: $cmd"
    ssh -i C:\Users\singh\.ssh\jenkins_key -o StrictHostKeyChecking=no ec2-user@35.154.123.73 "$cmd" 2>&1 | Out-Null
}

Write-Host ""
Write-Host "Waiting for Jenkins to start (60 seconds)..."
Start-Sleep -Seconds 60

Write-Host ""
Write-Host "=========================================="
Write-Host "Getting Jenkins Initial Admin Password"
Write-Host "=========================================="
Write-Host ""

$password = ssh -i C:\Users\singh\.ssh\jenkins_key -o StrictHostKeyChecking=no ec2-user@35.154.123.73 "sudo cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null"

if ($password) {
    Write-Host "JENKINS INITIAL ADMIN PASSWORD:"
    Write-Host $password
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "Setup Complete! ✅"
    Write-Host "=========================================="
    Write-Host ""
    Write-Host "Jenkins URL: http://35.154.123.73:8080"
    Write-Host ""
    Write-Host "Copy the password above and use it to login!"
} else {
    Write-Host "Jenkins is still starting. Wait 2 more minutes, then run:"
    Write-Host 'ssh -i C:\Users\singh\.ssh\jenkins_key ec2-user@35.154.123.73 "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"'
}
