# Test Cases Documentation

## Virtual Lab Experiment 7 - Blue-Green Deployment

### Test Environment
- **Kubernetes Cluster**: EKS
- **Application**: Node.js with Express
- **Container Registry**: Docker Hub
- **CI/CD Tool**: Jenkins
- **IaC Tools**: Terraform + Ansible

---

## Detailed Test Cases

### TC1: Verify Both Blue and Green Deployments Exist

**Objective**: Ensure both blue and green deployments are running simultaneously in the cluster

**Prerequisites**:
- Kubernetes cluster is running
- Namespace `blue-green-app` exists

**Test Steps**:
1. Execute command to list deployments:
   ```bash
   kubectl get deployments -n blue-green-app
   ```

2. Verify both deployments exist:
   ```bash
   kubectl get deployment myapp-blue -n blue-green-app
   kubectl get deployment myapp-green -n blue-green-app
   ```

3. Check pod status for both colors:
   ```bash
   kubectl get pods -n blue-green-app -l color=blue
   kubectl get pods -n blue-green-app -l color=green
   ```

**Expected Results**:
- Both `myapp-blue` and `myapp-green` deployments should be listed
- Each deployment should have 3 replicas (or configured number)
- All pods should be in `Running` state
- Ready status should be `3/3` for each deployment

**Actual Results**:
```
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
myapp-blue     3/3     3            3           10m
myapp-green    3/3     3            3           5m
```

**Status**: ✅ PASS / ❌ FAIL

**Notes**:

---

### TC2: Validate Service Points to Correct Color Deployment

**Objective**: Verify that the Kubernetes service selector correctly routes traffic to the intended deployment (blue or green)

**Prerequisites**:
- Both deployments are running
- Service `myapp-service` exists

**Test Steps**:
1. Check current service selector:
   ```bash
   kubectl get service myapp-service -n blue-green-app -o jsonpath='{.spec.selector}'
   ```

2. Verify service endpoints:
   ```bash
   kubectl get endpoints myapp-service -n blue-green-app
   ```

3. Test application response:
   ```bash
   SERVICE_URL=$(kubectl get service myapp-service -n blue-green-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
   curl http://$SERVICE_URL/version
   ```

4. Verify the color matches the service selector:
   ```bash
   kubectl describe service myapp-service -n blue-green-app | grep Selector
   ```

**Expected Results**:
- Service selector should show `app=myapp,color=<active-color>`
- Endpoints should list IPs from pods of the active color only
- Application `/version` endpoint should return the active color
- No traffic should route to inactive deployment

**Actual Results**:
```json
{
  "version": "2.0.0",
  "color": "green",
  "buildNumber": "42"
}
```

**Status**: ✅ PASS / ❌ FAIL

**Notes**:

---

### TC3: Rollback by Switching Service Back to Previous Version

**Objective**: Demonstrate rollback capability by switching traffic from current to previous deployment

**Prerequisites**:
- Both deployments are healthy
- Current active deployment is known

**Test Steps**:
1. Note current active color:
   ```bash
   CURRENT=$(kubectl get service myapp-service -n blue-green-app -o jsonpath='{.spec.selector.color}')
   echo "Current: $CURRENT"
   ```

2. Test current version:
   ```bash
   curl http://$SERVICE_URL/version
   ```

3. Execute rollback script:
   ```bash
   ./scripts/rollback.sh
   ```

4. Verify traffic switched:
   ```bash
   kubectl get service myapp-service -n blue-green-app -o jsonpath='{.spec.selector.color}'
   ```

5. Test rolled back version:
   ```bash
   curl http://$SERVICE_URL/version
   ```

6. Verify no downtime during switch:
   ```bash
   # Run in separate terminal during rollback
   while true; do curl -s http://$SERVICE_URL/health || echo "FAILED"; sleep 1; done
   ```

**Expected Results**:
- Rollback script completes successfully
- Service selector updates to previous color
- Application version changes to previous version
- No HTTP errors during traffic switch
- Response time remains consistent

**Actual Results**:
- Before rollback: `{"color": "green", "version": "2.0.0"}`
- After rollback: `{"color": "blue", "version": "1.0.0"}`
- Total downtime: 0 seconds
- Failed requests: 0

**Status**: ✅ PASS / ❌ FAIL

**Notes**:

---

### TC4: Automated Pipeline Builds and Deploys on Git Push

**Objective**: Verify Jenkins pipeline automatically triggers on GitHub push events

**Prerequisites**:
- Jenkins is running and accessible
- GitHub webhook is configured
- Pipeline job `blue-green-deployment` exists

**Test Steps**:
1. Make a code change:
   ```bash
   echo "// Test change $(date)" >> app/server.js
   ```

2. Commit and push:
   ```bash
   git add .
   git commit -m "Test automated pipeline trigger"
   git push origin main
   ```

3. Monitor Jenkins:
   - Check Jenkins dashboard
   - Verify build triggers within 10 seconds
   - Monitor build progress

4. Verify build stages:
   ```bash
   # Check Jenkins console output for:
   # - Clone Repository
   # - Build Docker Image
   # - Push to Docker Hub
   # - Deploy to Kubernetes
   # - Validation Tests
   # - Switch Traffic (manual approval)
   ```

5. Check deployment updated:
   ```bash
   kubectl get deployment myapp-green -n blue-green-app -o jsonpath='{.spec.template.spec.containers[0].image}'
   ```

**Expected Results**:
- Jenkins build triggers within 10 seconds of push
- All pipeline stages complete successfully
- Docker image is built with new BUILD_NUMBER tag
- Image is pushed to Docker Hub
- Kubernetes deployment is updated
- New pods are created and become ready
- Old pods remain until traffic switch

**Actual Results**:
- Webhook received: ✅
- Build triggered: ✅
- Build time: X minutes Y seconds
- Image tag: `myapp:42`
- Deployment updated: ✅

**Status**: ✅ PASS / ❌ FAIL

**Notes**:

---

### TC5: Kubernetes Deployment Rollout Status is Successful

**Objective**: Verify Kubernetes deployments complete successfully without errors

**Prerequisites**:
- Deployments are created or updated
- Image is available in registry

**Test Steps**:
1. Check rollout status for blue:
   ```bash
   kubectl rollout status deployment/myapp-blue -n blue-green-app --timeout=5m
   ```

2. Check rollout status for green:
   ```bash
   kubectl rollout status deployment/myapp-green -n blue-green-app --timeout=5m
   ```

3. Verify rollout history:
   ```bash
   kubectl rollout history deployment/myapp-blue -n blue-green-app
   kubectl rollout history deployment/myapp-green -n blue-green-app
   ```

4. Check pod events:
   ```bash
   kubectl get events -n blue-green-app --sort-by='.lastTimestamp'
   ```

5. Verify all pods are healthy:
   ```bash
   kubectl get pods -n blue-green-app -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,READY:.status.conditions[?(@.type==\"Ready\")].status
   ```

**Expected Results**:
- Rollout status shows "successfully rolled out"
- No error events in pod events
- All pods show STATUS=Running
- All pods show READY=True
- Liveness and readiness probes passing

**Actual Results**:
```
deployment "myapp-blue" successfully rolled out
deployment "myapp-green" successfully rolled out
```

**Status**: ✅ PASS / ❌ FAIL

**Notes**:

---

### TC6: Zero-Downtime Validation During Traffic Switch

**Objective**: Ensure no service disruption occurs during blue-green traffic switch

**Prerequisites**:
- Both deployments are healthy
- Load testing tool available (curl, ab, or similar)

**Test Steps**:
1. Start continuous monitoring:
   ```bash
   # Terminal 1
   while true; do
     RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://$SERVICE_URL/)
     TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
     if [ "$RESPONSE" != "200" ]; then
       echo "[$TIMESTAMP] ERROR: HTTP $RESPONSE"
     else
       echo "[$TIMESTAMP] OK: HTTP $RESPONSE"
     fi
     sleep 0.5
   done
   ```

2. Execute traffic switch:
   ```bash
   # Terminal 2
   ./scripts/switch-traffic.sh
   ```

3. Monitor response times:
   ```bash
   # Terminal 3
   while true; do
     curl -w "Time: %{time_total}s\n" -o /dev/null -s http://$SERVICE_URL/
     sleep 1
   done
   ```

4. Analyze results:
   - Count failed requests
   - Measure maximum response time
   - Check for any errors

**Expected Results**:
- 0 failed requests during switch
- No HTTP 5xx errors
- No connection refused errors
- Response time increase < 100ms
- Continuous availability: 100%

**Actual Results**:
- Total requests during switch: 50
- Failed requests: 0
- Success rate: 100%
- Max response time: 45ms
- Average response time: 32ms

**Status**: ✅ PASS / ❌ FAIL

**Notes**:

---

### TC7: Health Check Validation

**Objective**: Verify all pods have properly configured and passing health checks

**Prerequisites**:
- Deployments are running
- Health check endpoints are implemented

**Test Steps**:
1. Check pod health status:
   ```bash
   kubectl get pods -n blue-green-app -o custom-columns=NAME:.metadata.name,READY:.status.conditions[?(@.type==\"Ready\")].status,RESTARTS:.status.containerStatuses[0].restartCount
   ```

2. Test liveness probe:
   ```bash
   POD_NAME=$(kubectl get pods -n blue-green-app -l color=blue -o jsonpath='{.items[0].metadata.name}')
   kubectl exec -n blue-green-app $POD_NAME -- curl -s http://localhost:3000/health
   ```

3. Test readiness probe:
   ```bash
   kubectl describe pod $POD_NAME -n blue-green-app | grep -A 10 "Readiness"
   ```

4. Verify probe configurations:
   ```bash
   kubectl get deployment myapp-blue -n blue-green-app -o jsonpath='{.spec.template.spec.containers[0].livenessProbe}'
   kubectl get deployment myapp-blue -n blue-green-app -o jsonpath='{.spec.template.spec.containers[0].readinessProbe}'
   ```

5. Check restart count:
   ```bash
   kubectl get pods -n blue-green-app --sort-by='.status.containerStatuses[0].restartCount'
   ```

**Expected Results**:
- All pods show READY=True
- Health endpoint returns HTTP 200
- Liveness probe: httpGet on /health
- Readiness probe: httpGet on /health
- Restart count: 0 for all pods
- No probe failures in events

**Actual Results**:
```json
{
  "status": "healthy",
  "timestamp": "2025-10-16T10:30:00.000Z"
}
```

**Status**: ✅ PASS / ❌ FAIL

**Notes**:

---

## Test Execution Summary

| Test Case | Description | Status | Execution Time | Blocker |
|-----------|-------------|--------|----------------|---------|
| TC1 | Both deployments exist | | | |
| TC2 | Service routing validation | | | |
| TC3 | Rollback functionality | | | |
| TC4 | Automated CI/CD trigger | | | |
| TC5 | Rollout status | | | |
| TC6 | Zero-downtime validation | | | |
| TC7 | Health check validation | | | |

**Overall Status**: 

**Test Date**: 

**Tested By**: 

**Environment**: 

**Notes**:

---

## Defects Found

| ID | Severity | Description | Status | Resolution |
|----|----------|-------------|--------|------------|
| | | | | |

---

## Recommendations

1. 
2. 
3. 

---

## Conclusion

[Document overall test results and deployment readiness]
