# Script to create EKS cluster using AWS CLI
# This is a workaround since eksctl is not available locally

Write-Host "=========================================="
Write-Host "Creating EKS Cluster via AWS CLI"
Write-Host "=========================================="
Write-Host ""

$ClusterName = "blue-green-eks-cluster"
$Region = "ap-south-1"
$VpcId = "vpc-044ea14595bed94dc"
$SubnetId = "subnet-04d8ae0788df6523b"
$RoleArn = "arn:aws:iam::847850006863:role/blue-green-deployment-eks-cluster-role"

Write-Host "Creating EKS cluster: $ClusterName"
Write-Host "This will take 15-20 minutes..."
Write-Host ""

# Create EKS cluster
aws eks create-cluster `
  --name $ClusterName `
  --region $Region `
  --role-arn $RoleArn `
  --resources-vpc-config subnetIds=$SubnetId `
  --output json

if ($?) {
    Write-Host ""
    Write-Host "✅ Cluster creation initiated!"
    Write-Host ""
    Write-Host "Waiting for cluster to become active..."
    Write-Host "This will take about 15-20 minutes."
    Write-Host ""
    
    # Wait for cluster to be active
    aws eks wait cluster-active --name $ClusterName --region $Region
    
    if ($?) {
        Write-Host ""
        Write-Host "✅ Cluster is active!"
        Write-Host ""
        Write-Host "Now creating node group..."
        
        # Create managed node group
        aws eks create-nodegroup `
          --cluster-name $ClusterName `
          --nodegroup-name "standard-workers" `
          --region $Region `
          --node-role "arn:aws:iam::847850006863:role/blue-green-deployment-eks-node-role" `
          --subnets $SubnetId `
          --instance-types "t3.small" `
          --scaling-config minSize=2,maxSize=2,desiredSize=2 `
          --output json
        
        Write-Host ""
        Write-Host "✅ EKS cluster and node group creation complete!"
        Write-Host ""
        Write-Host "Next: Configure kubectl on Jenkins server"
    }
} else {
    Write-Host "❌ Failed to create cluster"
}
