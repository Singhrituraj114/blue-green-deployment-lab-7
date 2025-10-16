#!/bin/bash

# Script to check the status of blue-green deployments

NAMESPACE="blue-green-app"
SERVICE_NAME="myapp-service"

echo "======================================"
echo "Blue-Green Deployment Status"
echo "======================================"
echo ""

# Check namespace
echo "Namespace: $NAMESPACE"
kubectl get namespace $NAMESPACE 2>/dev/null || echo "Namespace not found!"
echo ""

# Check service
echo "Service Status:"
kubectl get service $SERVICE_NAME -n $NAMESPACE 2>/dev/null || echo "Service not found!"
echo ""

# Get current active color
CURRENT_COLOR=$(kubectl get service $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.selector.color}' 2>/dev/null)
echo "Active Color: $CURRENT_COLOR"
echo ""

# Check blue deployment
echo "Blue Deployment:"
kubectl get deployment myapp-blue -n $NAMESPACE 2>/dev/null || echo "Blue deployment not found"
echo ""

# Check green deployment
echo "Green Deployment:"
kubectl get deployment myapp-green -n $NAMESPACE 2>/dev/null || echo "Green deployment not found"
echo ""

# Check all pods
echo "All Pods:"
kubectl get pods -n $NAMESPACE -o wide
echo ""

# Get service endpoint
echo "Service Endpoint:"
SERVICE_URL=$(kubectl get service $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
if [ -z "$SERVICE_URL" ]; then
    SERVICE_URL=$(kubectl get service $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
fi

if [ -n "$SERVICE_URL" ]; then
    echo "http://$SERVICE_URL"
    echo ""
    echo "Test the endpoint with:"
    echo "curl http://$SERVICE_URL"
    echo "curl http://$SERVICE_URL/version"
else
    echo "LoadBalancer IP/Hostname not yet assigned"
fi
echo ""

echo "======================================"
