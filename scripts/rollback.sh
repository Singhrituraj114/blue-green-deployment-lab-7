#!/bin/bash

# Script to rollback to previous deployment

NAMESPACE="blue-green-app"
SERVICE_NAME="myapp-service"

# Get current color
CURRENT_COLOR=$(kubectl get service $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.selector.color}')

echo "Current active deployment: $CURRENT_COLOR"

# Determine rollback color (previous deployment)
if [ "$CURRENT_COLOR" = "blue" ]; then
    ROLLBACK_COLOR="green"
else
    ROLLBACK_COLOR="blue"
fi

echo "Rolling back to: $ROLLBACK_COLOR"

# Check if rollback deployment exists
if ! kubectl get deployment myapp-$ROLLBACK_COLOR -n $NAMESPACE &> /dev/null; then
    echo "Error: Rollback deployment $ROLLBACK_COLOR does not exist!"
    exit 1
fi

# Perform rollback
echo "Rolling back to $ROLLBACK_COLOR..."
kubectl patch service $SERVICE_NAME -n $NAMESPACE -p "{\"spec\":{\"selector\":{\"app\":\"myapp\",\"color\":\"$ROLLBACK_COLOR\"}}}"

echo "Rollback completed successfully!"
echo ""
echo "Service status:"
kubectl get service $SERVICE_NAME -n $NAMESPACE
echo ""
echo "Active deployment:"
kubectl get deployment myapp-$ROLLBACK_COLOR -n $NAMESPACE
