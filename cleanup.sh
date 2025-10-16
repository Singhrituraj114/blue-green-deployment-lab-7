#!/bin/bash

# Cleanup script to destroy all resources

echo "======================================"
echo "Blue-Green Deployment - Cleanup"
echo "======================================"
echo ""

read -p "This will destroy ALL resources. Are you sure? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "Step 1: Deleting Kubernetes resources..."
kubectl delete namespace blue-green-app --ignore-not-found=true

echo ""
echo "Step 2: Checking for EKS cluster..."
CLUSTER_NAME="blue-green-eks-cluster"
if aws eks describe-cluster --name $CLUSTER_NAME &> /dev/null; then
    echo "Deleting EKS cluster..."
    eksctl delete cluster --name $CLUSTER_NAME --region us-east-1 --wait
else
    echo "No EKS cluster found."
fi

echo ""
echo "Step 3: Destroying Terraform infrastructure..."
cd terraform
terraform destroy -auto-approve

echo ""
echo "======================================"
echo "Cleanup Complete!"
echo "======================================"
echo ""
echo "All resources have been destroyed."
