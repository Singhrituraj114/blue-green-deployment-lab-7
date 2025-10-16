# Virtual Lab Experiment – 7

# Automated Blue-Green Deployment Strategy

## 🎯 Objective
Implement an automated Blue-Green Deployment of a Dockerized application on Kubernetes using a CI/CD pipeline with Jenkins, configured via Terraform and Ansible, with version control using GitHub.

## 📋 Tech Stack
- **Jenkins**: CI/CD Pipeline
- **Docker**: Containerization
- **Kubernetes**: Orchestration (EKS)
- **Terraform**: Infrastructure provisioning
- **Ansible**: Configuration management
- **GitHub**: Source code and Jenkins webhook integration
- **Node.js**: Sample application

## 📁 Project Structure
```
VLE-7/
├── terraform/              # Infrastructure as Code
│   ├── main.tf            # Main Terraform configuration
│   ├── variables.tf       # Variable definitions
│   └── outputs.tf         # Output values
├── ansible/               # Configuration Management
│   ├── jenkins_setup.yml  # Jenkins installation playbook
│   ├── eks_setup.yml      # EKS cluster setup playbook
│   └── inventory.ini      # Ansible inventory
├── app/                   # Application code
│   ├── server.js          # Node.js application
│   ├── package.json       # Node.js dependencies
│   ├── Dockerfile         # Docker image definition
│   └── .dockerignore      # Docker ignore rules
├── k8s/                   # Kubernetes manifests
│   ├── namespace.yaml     # Namespace definition
│   ├── deployment-blue.yaml   # Blue deployment
│   ├── deployment-green.yaml  # Green deployment
│   └── service.yaml       # LoadBalancer service
├── scripts/               # Utility scripts
│   ├── switch-traffic.sh  # Switch traffic between colors
│   ├── rollback.sh        # Rollback deployment
│   └── check-status.sh    # Check deployment status
├── Jenkinsfile            # CI/CD pipeline definition
└── README.md              # This file
```

## 🚀 Step-by-Step Setup Guide

### Prerequisites
1. **AWS Account** with appropriate permissions
2. **SSH Key Pair** (`~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub`)
3. **GitHub Account** and repository
4. **Docker Hub Account**
5. **Local Tools**:
   - Terraform >= 1.0
   - Ansible >= 2.9
   - Git
   - AWS CLI (optional)

---

### Step 1: Set Up Infrastructure with Terraform

1. **Navigate to Terraform directory**:
   ```bash
   cd terraform
   ```

2. **Generate SSH key pair** (if not exists):
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
   ```

3. **Update variables** (optional):
   Edit `variables.tf` to customize:
   - AWS region
   - Instance types
   - CIDR blocks

4. **Initialize Terraform**:
   ```bash
   terraform init
   ```

5. **Plan infrastructure**:
   ```bash
   terraform plan
   ```

6. **Apply infrastructure**:
   ```bash
   terraform apply -auto-approve
   ```

7. **Save outputs**:
   ```bash
   terraform output -json > ../terraform-outputs.json
   ```

8. **Note the Jenkins IP**:
   ```bash
   terraform output jenkins_public_ip
   ```

**Expected Output**:
- VPC with public subnet
- EC2 instance for Jenkins
- Security groups with required ports
- IAM roles for EKS access

---

### Step 2: Configure Jenkins Server with Ansible

1. **Navigate to Ansible directory**:
   ```bash
   cd ../ansible
   ```

2. **Update inventory file**:
   Edit `inventory.ini` and replace `JENKINS_PUBLIC_IP` with the actual IP from Terraform output:
   ```ini
   [jenkins]
   jenkins_server ansible_host=<JENKINS_PUBLIC_IP> ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/id_rsa
   ```

3. **Test connectivity**:
   ```bash
   ansible -i inventory.ini jenkins -m ping
   ```

4. **Run Jenkins setup playbook**:
   ```bash
   ansible-playbook -i inventory.ini jenkins_setup.yml
   ```

5. **Note the Jenkins initial password** from the playbook output.

6. **Access Jenkins**:
   - Open browser: `http://<JENKINS_IP>:8080`
   - Enter initial admin password
   - Install suggested plugins
   - Create admin user

**Jenkins will be configured with**:
- Java 11
- Jenkins latest version
- Docker and Docker Compose
- Maven
- kubectl
- AWS CLI
- eksctl

---

### Step 3: Set Up EKS Cluster

1. **Option A: Using Ansible** (Recommended):
   ```bash
   ansible-playbook -i inventory.ini eks_setup.yml
   ```

2. **Option B: Using Terraform**:
   Edit `terraform/variables.tf`:
   ```hcl
   variable "create_eks_cluster" {
     default = true
   }
   ```
   Then run `terraform apply` again.

3. **Verify cluster**:
   SSH into Jenkins server and run:
   ```bash
   kubectl get nodes
   kubectl get namespaces
   ```

**Expected Output**:
- EKS cluster with 2 worker nodes
- Namespace `blue-green-app` created
- kubeconfig configured for both ec2-user and jenkins user

---

### Step 4: Configure Docker Hub Credentials in Jenkins

1. **Login to Jenkins** (`http://<JENKINS_IP>:8080`)

2. **Navigate to**: Manage Jenkins → Credentials → System → Global credentials

3. **Add credentials**:
   - Kind: Username with password
   - Username: Your Docker Hub username
   - Password: Your Docker Hub password
   - ID: `dockerhub-credentials`
   - Description: Docker Hub Credentials

---

### Step 5: Prepare GitHub Repository

1. **Create a new repository** on GitHub (or use existing)

2. **Clone this project**:
   ```bash
   cd ..
   git init
   git add .
   git commit -m "Initial commit: Blue-Green deployment setup"
   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
   git push -u origin main
   ```

3. **Update configuration files**:
   - In `Jenkinsfile`: Update `DOCKERHUB_USERNAME` and repository URL
   - In `k8s/deployment-*.yaml`: Update Docker image with your username

---

### Step 6: Configure GitHub Webhook

1. **Go to your GitHub repository** → Settings → Webhooks → Add webhook

2. **Configure webhook**:
   - Payload URL: `http://<JENKINS_IP>:8080/github-webhook/`
   - Content type: `application/json`
   - Events: Just the push event
   - Active: ✓

3. **Install GitHub Integration plugin** in Jenkins:
   - Manage Jenkins → Plugins → Available
   - Search for "GitHub Integration Plugin"
   - Install and restart

---

### Step 7: Create Jenkins Pipeline Job

1. **In Jenkins**: New Item → Pipeline → Name: `blue-green-deployment`

2. **Configure pipeline**:
   - General: ✓ GitHub project → Project URL: Your GitHub repo
   - Build Triggers: ✓ GitHub hook trigger for GITScm polling
   - Pipeline:
     - Definition: Pipeline script from SCM
     - SCM: Git
     - Repository URL: Your GitHub repo
     - Credentials: Add GitHub credentials if private
     - Branch: `*/main`
     - Script Path: `Jenkinsfile`

3. **Save configuration**

---

### Step 8: Deploy Initial Application

1. **Manual deployment** (first time):
   ```bash
   # SSH into Jenkins server
   ssh -i ~/.ssh/id_rsa ec2-user@<JENKINS_IP>
   
   # Deploy blue environment
   kubectl apply -f k8s/namespace.yaml
   kubectl apply -f k8s/deployment-blue.yaml
   kubectl apply -f k8s/service.yaml
   
   # Check status
   kubectl get all -n blue-green-app
   ```

2. **Get service URL**:
   ```bash
   kubectl get service myapp-service -n blue-green-app
   ```

3. **Test application**:
   ```bash
   # Replace <LOAD_BALANCER_URL> with actual URL
   curl http://<LOAD_BALANCER_URL>/
   curl http://<LOAD_BALANCER_URL>/version
   curl http://<LOAD_BALANCER_URL>/health
   ```

---

### Step 9: Trigger Automated Deployment

1. **Make a change** in `app/server.js`:
   ```javascript
   message: 'Blue-Green Deployment Demo - Updated!'
   ```

2. **Commit and push**:
   ```bash
   git add .
   git commit -m "Update application message"
   git push origin main
   ```

3. **Jenkins pipeline will automatically**:
   - Clone repository
   - Build Docker image
   - Push to Docker Hub
   - Deploy to inactive environment (green)
   - Run validation tests
   - Wait for approval to switch traffic

4. **Monitor pipeline**: Go to Jenkins → blue-green-deployment → Build History

5. **Approve traffic switch**: When prompted, approve to switch traffic to green

---

## 🧪 Test Cases

### Test Case 1: Verify Both Deployments Exist
```bash
kubectl get deployments -n blue-green-app
```
**Expected**: Both `myapp-blue` and `myapp-green` deployments should be visible

### Test Case 2: Validate Service Points to Correct Color
```bash
kubectl get service myapp-service -n blue-green-app -o jsonpath='{.spec.selector}'
```
**Expected**: Service selector should show current active color

### Test Case 3: Test Rollback
```bash
# Switch to green
./scripts/switch-traffic.sh

# Verify green is active
curl http://<LOAD_BALANCER_URL>/version

# Rollback to blue
./scripts/rollback.sh

# Verify blue is active again
curl http://<LOAD_BALANCER_URL>/version
```
**Expected**: Traffic switches between deployments without downtime

### Test Case 4: Automated Pipeline Build on Git Push
```bash
# Make a change
echo "// Test change" >> app/server.js
git add .
git commit -m "Test automated pipeline"
git push

# Check Jenkins
# Pipeline should automatically trigger
```
**Expected**: Jenkins pipeline starts automatically within seconds

### Test Case 5: Kubernetes Rollout Status
```bash
kubectl rollout status deployment/myapp-green -n blue-green-app
kubectl rollout status deployment/myapp-blue -n blue-green-app
```
**Expected**: Both deployments show successful rollout status

### Test Case 6: Zero-Downtime Validation
```bash
# Terminal 1: Continuous monitoring
watch -n 1 'curl -s http://<LOAD_BALANCER_URL>/version'

# Terminal 2: Switch traffic
./scripts/switch-traffic.sh
```
**Expected**: No connection errors during traffic switch

### Test Case 7: Health Check Validation
```bash
kubectl get pods -n blue-green-app
kubectl describe pod <POD_NAME> -n blue-green-app
```
**Expected**: All pods should have passing liveness and readiness probes

---

## 🛠️ Useful Commands

### Infrastructure Management
```bash
# View Terraform state
terraform show

# Destroy infrastructure
terraform destroy

# Update specific resource
terraform apply -target=aws_instance.jenkins
```

### Kubernetes Operations
```bash
# Get all resources in namespace
kubectl get all -n blue-green-app

# Check deployment status
./scripts/check-status.sh

# View logs
kubectl logs -f deployment/myapp-blue -n blue-green-app
kubectl logs -f deployment/myapp-green -n blue-green-app

# Scale deployments
kubectl scale deployment/myapp-blue --replicas=5 -n blue-green-app

# Delete deployment
kubectl delete deployment myapp-blue -n blue-green-app
```

### Docker Operations
```bash
# Build image locally
cd app
docker build -t myapp:local .

# Run locally
docker run -p 3000:3000 -e COLOR=blue myapp:local

# Check images on Jenkins server
ssh ec2-user@<JENKINS_IP> 'docker images'
```

### Jenkins Operations
```bash
# Restart Jenkins
sudo systemctl restart jenkins

# View Jenkins logs
sudo journalctl -u jenkins -f

# Check Jenkins status
sudo systemctl status jenkins
```

---

## 🔧 Troubleshooting

### Issue: Jenkins can't connect to Kubernetes
**Solution**:
```bash
# SSH into Jenkins server
ssh ec2-user@<JENKINS_IP>

# Verify kubeconfig
sudo -u jenkins kubectl get nodes

# If fails, copy kubeconfig
sudo cp /home/ec2-user/.kube/config /var/lib/jenkins/.kube/
sudo chown jenkins:jenkins /var/lib/jenkins/.kube/config
```

### Issue: Docker permission denied in Jenkins
**Solution**:
```bash
# Add jenkins to docker group
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### Issue: Pods stuck in ImagePullBackOff
**Solution**:
```bash
# Check image name in deployment YAML
kubectl describe pod <POD_NAME> -n blue-green-app

# Verify Docker Hub credentials
# Update image name in k8s/deployment-*.yaml
```

### Issue: LoadBalancer service stuck in Pending
**Solution**:
```bash
# Check AWS ELB creation
aws elb describe-load-balancers

# Verify node groups have proper IAM roles
kubectl get nodes -o wide

# Alternative: Use NodePort
kubectl patch service myapp-service -n blue-green-app -p '{"spec":{"type":"NodePort"}}'
```

### Issue: GitHub webhook not triggering Jenkins
**Solution**:
1. Verify webhook URL in GitHub (should include `/github-webhook/`)
2. Check Jenkins is accessible from internet
3. Review webhook delivery in GitHub → Settings → Webhooks → Recent Deliveries
4. Ensure GitHub Integration plugin is installed

---

## 📊 Architecture Diagram

```
┌─────────────┐
│   GitHub    │
│ (Source)    │
└──────┬──────┘
       │ Webhook
       ▼
┌──────────────────┐
│   Jenkins        │
│   (CI/CD)        │
│   - Build        │
│   - Test         │
│   - Deploy       │
└────┬────────┬────┘
     │        │
     ▼        ▼
┌─────────┐  ┌──────────────┐
│ Docker  │  │  Kubernetes  │
│   Hub   │  │    (EKS)     │
└─────────┘  └──────┬───────┘
                    │
        ┌───────────┴───────────┐
        ▼                       ▼
┌───────────────┐      ┌───────────────┐
│ Blue Deploy   │      │ Green Deploy  │
│   (v1.0.0)    │      │   (v2.0.0)    │
│   3 Pods      │      │   3 Pods      │
└───────────────┘      └───────────────┘
        │                       │
        └───────────┬───────────┘
                    ▼
            ┌───────────────┐
            │   Service     │
            │ (LoadBalancer)│
            └───────┬───────┘
                    ▼
            ┌───────────────┐
            │     Users     │
            └───────────────┘
```

---

## 🎓 Key Concepts

### Blue-Green Deployment
- **Blue Environment**: Current production version
- **Green Environment**: New version being deployed
- **Advantages**:
  - Zero-downtime deployment
  - Instant rollback capability
  - Easy testing of new version
  - Reduced risk

### CI/CD Pipeline Stages
1. **Clone**: Get latest code from GitHub
2. **Build**: Create Docker image
3. **Test**: Validate Docker image
4. **Push**: Upload to Docker Hub
5. **Deploy**: Update Kubernetes deployment
6. **Validate**: Run health checks
7. **Switch**: Update service selector
8. **Verify**: Confirm successful deployment

---

## 📚 Additional Resources

- [Kubernetes Blue-Green Deployment](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/#blue-green-deployments)
- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

---

## ✅ Test Case Results Template

| Test Case | Description | Status | Notes |
|-----------|-------------|--------|-------|
| TC1 | Both blue and green deployments exist | ✅ PASS | |
| TC2 | Service points to correct color | ✅ PASS | |
| TC3 | Rollback functionality works | ✅ PASS | |
| TC4 | Automated pipeline on Git push | ✅ PASS | |
| TC5 | Kubernetes rollout successful | ✅ PASS | |
| TC6 | Zero-downtime during switch | ✅ PASS | |
| TC7 | Health checks passing | ✅ PASS | |

---

## 🤝 Contributors

- DevOps Team
- Virtual Lab Experiment 7

---

## 📄 License

MIT License - Feel free to use this project for educational purposes.

---

## 🔄 Cleanup

To destroy all resources:

```bash
# Delete Kubernetes resources
kubectl delete namespace blue-green-app

# Delete EKS cluster (if using eksctl)
eksctl delete cluster --name blue-green-eks-cluster --region us-east-1

# Destroy Terraform infrastructure
cd terraform
terraform destroy -auto-approve
```

---

**Note**: Replace all placeholder values (YOUR_USERNAME, JENKINS_IP, LOAD_BALANCER_URL, etc.) with actual values from your deployment.
