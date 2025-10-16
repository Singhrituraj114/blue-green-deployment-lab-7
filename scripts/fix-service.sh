#!/bin/bash

# This script fixes the service type and adds necessary security group rules

# Get the EKS cluster security group
CLUSTER_SG=$(aws eks describe-cluster --name blue-green-eks-cluster --region ap-south-1 --query 'cluster.resourcesVpcConfig.clusterSecurityGroupId' --output text)
NODE_SG=$(aws ec2 describe-security-groups --region ap-south-1 --filters "Name=tag:aws:eks:cluster-name,Values=blue-green-eks-cluster" --query 'SecurityGroups[?contains(GroupName, `node`)].GroupId' --output text | head -n1)

echo "Cluster Security Group: $CLUSTER_SG"
echo "Node Security Group: $NODE_SG"

# Add ingress rule to allow NodePort traffic (30000-32767)
if [ ! -z "$NODE_SG" ]; then
    echo "Adding NodePort ingress rule to node security group..."
    aws ec2 authorize-security-group-ingress \
        --region ap-south-1 \
        --group-id $NODE_SG \
        --protocol tcp \
        --port 30080 \
        --cidr 0.0.0.0/0 2>/dev/null || echo "Rule may already exist"
fi

# Update the Kubernetes service to NodePort
echo "Deleting old LoadBalancer service..."
kubectl delete service myapp-service -n blue-green-app 2>/dev/null || echo "Service doesn't exist"

echo "Creating NodePort service..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
  namespace: blue-green-app
  labels:
    app: myapp
spec:
  type: NodePort
  selector:
    app: myapp
    color: green
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3000
    nodePort: 30080
    name: http
  sessionAffinity: ClientIP
EOF

echo ""
echo "Service updated! You can now access the app at:"
echo ""

# Get node external IPs
NODES=$(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="ExternalIP")].address}')
for NODE_IP in $NODES; do
    echo "http://${NODE_IP}:30080"
done

echo ""
echo "Or get the EKS node IPs:"
aws ec2 describe-instances --region ap-south-1 \
    --filters "Name=tag:eks:cluster-name,Values=blue-green-eks-cluster" "Name=instance-state-name,Values=running" \
    --query 'Reservations[*].Instances[*].PublicIpAddress' \
    --output text | tr '\t' '\n' | while read IP; do
        echo "http://${IP}:30080"
    done
