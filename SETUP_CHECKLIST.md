# Configuration Checklist for VLE-7

## Pre-Lab Requirements

### 1. Create GitHub Repository
- [ ] Go to: https://github.com/new
- [ ] Repository name: `blue-green-deployment-lab` (or your choice)
- [ ] Visibility: Public
- [ ] **DO NOT** initialize with README, .gitignore, or license
- [ ] Click "Create repository"
- [ ] Copy the repository URL (shown after creation)

**Example URL format:**
```
https://github.com/YOUR_USERNAME/blue-green-deployment-lab.git
```

---

### 2. Create Docker Hub Account
- [ ] Go to: https://hub.docker.com/signup
- [ ] Sign up with email
- [ ] Verify email
- [ ] Note your Docker Hub username

**Create Access Token (Recommended):**
- [ ] Login to Docker Hub
- [ ] Go to: Account Settings → Security → New Access Token
- [ ] Token name: `jenkins-pipeline`
- [ ] Access permissions: Read, Write, Delete
- [ ] Copy and save the token (you won't see it again!)

---

### 3. AWS Account Setup
- [ ] Have AWS account ready
- [ ] Create IAM user (if not using root):
  - [ ] Go to IAM → Users → Add User
  - [ ] Username: `devops-lab-user`
  - [ ] Access type: Programmatic access
  - [ ] Attach policies:
    - [ ] AmazonEC2FullAccess
    - [ ] AmazonEKSClusterPolicy
    - [ ] AmazonEKSWorkerNodePolicy
    - [ ] IAMFullAccess
    - [ ] AmazonVPCFullAccess
  - [ ] Copy Access Key ID and Secret Access Key

**Configure AWS CLI:**
```bash
aws configure
# AWS Access Key ID: [YOUR_ACCESS_KEY]
# AWS Secret Access Key: [YOUR_SECRET_KEY]
# Default region name: us-east-1
# Default output format: json
```

**Verify:**
```bash
aws sts get-caller-identity
```

---

### 4. Generate SSH Key (if not exists)
```bash
# Check if key exists
ls ~/.ssh/id_rsa

# If not, generate new key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -C "your_email@example.com"
# Press Enter for all prompts (no passphrase for lab simplicity)

# Verify
ls -la ~/.ssh/id_rsa*
```

---

### 5. Install Required Tools

**Terraform:**
```bash
# Windows (PowerShell)
choco install terraform

# Verify
terraform --version
```

**Ansible:**
```bash
# Windows (WSL or use Windows Subsystem for Linux)
# Or use Ansible from Git Bash

# Verify
ansible --version
```

**Git:**
```bash
# Should already be installed
git --version
```

**AWS CLI:**
```bash
# Windows
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi

# Verify
aws --version
```

---

## Configuration Template

Fill this out before starting:

```yaml
Personal Configuration:
  GitHub:
    Username: ________________
    Repository: ________________
    Full URL: https://github.com/________/__________.git
  
  Docker Hub:
    Username: ________________
    Password/Token: ________________ (keep secure!)
  
  AWS:
    Region: ________________ (e.g., us-east-1)
    Access Key ID: ________________
    Secret Access Key: ________________
  
  SSH:
    Private Key Path: ~/.ssh/id_rsa
    Public Key Path: ~/.ssh/id_rsa.pub
```

---

## Quick Configuration Steps

### Option 1: Automated (Recommended)
```bash
# Run the configuration script
bash configure.sh

# Follow the prompts
# Script will update all files automatically
```

### Option 2: Manual Configuration

**1. Update Jenkinsfile:**
```bash
# Open Jenkinsfile and replace:
# Line 7: YOUR_DOCKERHUB_USERNAME → your_dockerhub_username
# Line 23: YOUR_ORG/YOUR_REPO → yourgithub/yourrepo
```

**2. Update Kubernetes manifests:**
```bash
# k8s/deployment-blue.yaml (line 20)
# k8s/deployment-green.yaml (line 20)
# Replace: YOUR_DOCKERHUB_USERNAME → your_dockerhub_username
```

**3. Initialize Git:**
```bash
git init
git add .
git commit -m "Initial commit: Blue-Green deployment setup"
git remote add origin YOUR_GITHUB_URL
git branch -M main
git push -u origin main
```

---

## Post-Terraform Configuration

After running `terraform apply`, you'll get the Jenkins IP:

```bash
# Get Jenkins IP
cd terraform
terraform output jenkins_public_ip

# Update Ansible inventory
cd ../ansible
# Edit inventory.ini and replace JENKINS_PUBLIC_IP with actual IP
```

---

## Jenkins Configuration (After Ansible Setup)

### Access Jenkins:
1. Open browser: `http://JENKINS_IP:8080`
2. Get initial password:
   ```bash
   ssh -i ~/.ssh/id_rsa ec2-user@JENKINS_IP
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```
3. Install suggested plugins
4. Create admin user

### Add Docker Hub Credentials:
1. Manage Jenkins → Credentials
2. System → Global credentials
3. Add Credentials:
   - Kind: Username with password
   - Username: `your_dockerhub_username`
   - Password: `your_dockerhub_token`
   - ID: `dockerhub-credentials`
   - Description: Docker Hub Credentials

### Create Pipeline Job:
1. New Item → Pipeline
2. Name: `blue-green-deployment`
3. GitHub project: `YOUR_GITHUB_URL`
4. Build Triggers: ✓ GitHub hook trigger
5. Pipeline → SCM → Git
6. Repository URL: `YOUR_GITHUB_URL`
7. Branch: `*/main`
8. Script Path: `Jenkinsfile`
9. Save

### Configure GitHub Webhook:
1. Go to your GitHub repo
2. Settings → Webhooks → Add webhook
3. Payload URL: `http://JENKINS_IP:8080/github-webhook/`
4. Content type: `application/json`
5. Events: Just the push event
6. Save

---

## Verification Checklist

Before starting deployment:

- [ ] GitHub repo created and code pushed
- [ ] Docker Hub account ready with credentials
- [ ] AWS credentials configured and tested
- [ ] SSH key pair generated
- [ ] All tools installed (terraform, ansible, git, aws-cli)
- [ ] Jenkinsfile updated with your details
- [ ] k8s manifests updated with your Docker Hub username
- [ ] Git repository initialized and pushed
- [ ] Ready to run `terraform apply`

---

## Quick Reference Commands

```bash
# 1. Configure everything
bash configure.sh

# 2. Deploy infrastructure
cd terraform
terraform init
terraform apply -auto-approve

# 3. Get Jenkins IP
JENKINS_IP=$(terraform output -raw jenkins_public_ip)
echo $JENKINS_IP

# 4. Update Ansible inventory
cd ../ansible
sed -i "s/JENKINS_PUBLIC_IP/$JENKINS_IP/g" inventory.ini

# 5. Configure Jenkins
ansible-playbook -i inventory.ini jenkins_setup.yml

# 6. Setup EKS
ansible-playbook -i inventory.ini eks_setup.yml

# 7. Access Jenkins
echo "http://$JENKINS_IP:8080"
```

---

## Cost Estimate (Approximate)

- **EC2 Instance (t3.medium)**: ~$0.04/hour
- **EKS Cluster**: ~$0.10/hour
- **EKS Worker Nodes (2x t3.medium)**: ~$0.08/hour
- **Load Balancer**: ~$0.025/hour

**Total**: ~$0.25/hour or ~$6/day

**💡 Tip**: Remember to run `cleanup.sh` or `terraform destroy` when done!

---

## Need Help?

- Terraform issues? Check: `terraform.tfstate`
- Ansible connection issues? Test: `ansible -i ansible/inventory.ini jenkins -m ping`
- AWS CLI issues? Run: `aws sts get-caller-identity`
- Jenkins not accessible? Check security group: Port 8080 open

See README.md for detailed troubleshooting guide.
