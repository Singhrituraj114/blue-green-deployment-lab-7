# Simple PowerShell Script to Configure Jenkins via SSH
# This runs all commands in ONE SSH session to avoid repeated passphrase prompts

$JenkinsIP = "35.154.123.73"
$KeyPath = "C:\Users\singh\.ssh\jenkins_key"

Write-Host "============================================"
Write-Host "Configuring Jenkins Server"
Write-Host "============================================"
Write-Host ""
Write-Host "Connecting to $JenkinsIP..."
Write-Host "This will take 5-10 minutes..."
Write-Host ""

# Create a single multi-line command
$Commands = @"
sudo yum update -y && \
sudo yum install -y java-11-openjdk java-11-openjdk-devel docker git maven && \
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo && \
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key && \
sudo yum install -y jenkins && \
sudo systemctl start jenkins docker && \
sudo systemctl enable jenkins docker && \
sudo usermod -aG docker jenkins && \
sudo usermod -aG docker ec2-user && \
curl -LO https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl && \
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
rm -f kubectl && \
curl --silent --location https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz | tar xz -C /tmp && \
sudo mv /tmp/eksctl /usr/local/bin && \
echo 'Waiting for Jenkins to start...' && \
sleep 60 && \
echo '==========================================' && \
echo 'JENKINS INITIAL ADMIN PASSWORD:' && \
echo '==========================================' && \
sudo cat /var/lib/jenkins/secrets/initialAdminPassword && \
echo '==========================================' && \
echo 'Jenkins URL: http://35.154.123.73:8080'
"@

# Run in a single SSH session (only asks for passphrase ONCE if at all)
ssh -i $KeyPath -o StrictHostKeyChecking=no ec2-user@$JenkinsIP $Commands
