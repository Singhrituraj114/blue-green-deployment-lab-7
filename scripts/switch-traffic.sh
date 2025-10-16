#!/bin/bash

# Script to manually switch traffic between blue and green deployments

NAMESPACE="blue-green-app"
SERVICE_NAME="myapp-service"

# Get current color
CURRENT_COLOR=$(kubectl get service $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.selector.color}')

echo "Current active deployment: $CURRENT_COLOR"

# Determine target color
if [ "$CURRENT_COLOR" = "blue" ]; then
    TARGET_COLOR="green"
else
    TARGET_COLOR="blue"
fi

echo "Target deployment: $TARGET_COLOR"

# Check if target deployment exists and is ready
READY_REPLICAS=$(kubectl get deployment myapp-$TARGET_COLOR -n $NAMESPACE -o jsonpath='{.status.readyReplicas}')
DESIRED_REPLICAS=$(kubectl get deployment myapp-$TARGET_COLOR -n $NAMESPACE -o jsonpath='{.spec.replicas}')

if [ -z "$READY_REPLICAS" ] || [ "$READY_REPLICAS" != "$DESIRED_REPLICAS" ]; then
    echo "Error: Target deployment $TARGET_COLOR is not ready!"
    echo "Ready replicas: $READY_REPLICAS, Desired replicas: $DESIRED_REPLICAS"
    exit 1
fi

# Switch traffic
echo "Switching traffic to $TARGET_COLOR..."
kubectl patch service $SERVICE_NAME -n $NAMESPACE -p "{\"spec\":{\"selector\":{\"app\":\"myapp\",\"color\":\"$TARGET_COLOR\"}}}"

echo "Traffic switched successfully!"
echo ""
echo "Service status:"
kubectl get service $SERVICE_NAME -n $NAMESPACE
echo ""
echo "Current selector:"
kubectl get service $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.selector}' | jq
