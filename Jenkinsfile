pipeline {
    agent any
    
    environment {
        // Docker Hub credentials
        DOCKERHUB_USERNAME = 'rituraj0'
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        
        // Image details
        IMAGE_NAME = "${DOCKERHUB_USERNAME}/blue-green-app"
        IMAGE_TAG = "${BUILD_NUMBER}"
        FULL_IMAGE = "${IMAGE_NAME}:${IMAGE_TAG}"
        
        // Kubernetes namespace
        K8S_NAMESPACE = 'blue-green-app'
        
        // Deployment color (toggle between blue and green)
        // This can be determined dynamically based on current active deployment
        DEPLOYMENT_COLOR = getInactiveColor()
    }
    
    stages {
        stage('Clone Repository') {
            steps {
                echo 'Cloning repository...'
                git branch: 'main', 
                    url: 'https://github.com/Singhrituraj114/blue-green-deployment-lab-7.git'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo "Building Docker image: ${FULL_IMAGE}"
                dir('app') {
                    sh """
                        docker build -t ${FULL_IMAGE} .
                        docker tag ${FULL_IMAGE} ${IMAGE_NAME}:latest
                    """
                }
            }
        }
        
        stage('Test Docker Image') {
            steps {
                echo 'Testing Docker image...'
                sh """
                    docker run --rm ${FULL_IMAGE} node --version
                    echo 'Image test passed!'
                """
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                echo 'Pushing image to Docker Hub...'
                sh """
                    echo \$DOCKERHUB_CREDENTIALS_PSW | docker login -u \$DOCKERHUB_CREDENTIALS_USR --password-stdin
                    docker push ${FULL_IMAGE}
                    docker push ${IMAGE_NAME}:latest
                    docker logout
                """
            }
        }
        
        stage('Update Kubernetes Manifests') {
            steps {
                echo "Updating ${DEPLOYMENT_COLOR} deployment with new image..."
                sh """
                    # Update the deployment YAML with new image
                    sed -i 's|image: .*|image: ${FULL_IMAGE}|g' k8s/deployment-${DEPLOYMENT_COLOR}.yaml
                    
                    # Update VERSION environment variable only (not PORT)
                    sed -i '/name: VERSION/{n;s|value: ".*"|value: "${IMAGE_TAG}"|;}' k8s/deployment-${DEPLOYMENT_COLOR}.yaml
                """
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                echo "Deploying to ${DEPLOYMENT_COLOR} environment..."
                sh """
                    # Create namespace if it doesn't exist
                    kubectl create namespace ${K8S_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
                    
                    # Apply the deployment
                    kubectl apply -f k8s/deployment-${DEPLOYMENT_COLOR}.yaml
                    
                    # Wait for deployment to be ready
                    kubectl rollout status deployment/myapp-${DEPLOYMENT_COLOR} -n ${K8S_NAMESPACE} --timeout=5m
                    
                    # Verify deployment
                    kubectl get deployment myapp-${DEPLOYMENT_COLOR} -n ${K8S_NAMESPACE}
                    kubectl get pods -n ${K8S_NAMESPACE} -l color=${DEPLOYMENT_COLOR}
                """
            }
        }
        
        stage('Validation Tests') {
            steps {
                echo "Running validation tests on ${DEPLOYMENT_COLOR} deployment..."
                sh """
                    # Get pod name
                    POD_NAME=\$(kubectl get pods -n ${K8S_NAMESPACE} -l color=${DEPLOYMENT_COLOR} -o jsonpath='{.items[0].metadata.name}')
                    
                    # Test health endpoint
                    kubectl exec -n ${K8S_NAMESPACE} \$POD_NAME -- wget -q -O- http://localhost:3000/health
                    
                    # Test version endpoint
                    kubectl exec -n ${K8S_NAMESPACE} \$POD_NAME -- wget -q -O- http://localhost:3000/version
                    
                    echo 'Validation tests passed!'
                """
            }
        }
        
        stage('Switch Traffic') {
            steps {
                script {
                    // First, ensure the service exists
                    echo "Ensuring service exists..."
                    sh """
                        # Create service if it doesn't exist
                        if ! kubectl get service myapp-service -n ${K8S_NAMESPACE} &> /dev/null; then
                            echo "Service doesn't exist. Creating service..."
                            kubectl apply -f k8s/service.yaml
                            echo "Waiting for LoadBalancer to be ready..."
                            sleep 30
                        else
                            echo "Service already exists."
                        fi
                    """
                    
                    def userInput = input(
                        id: 'SwitchTraffic',
                        message: "Switch traffic to ${DEPLOYMENT_COLOR} version?",
                        parameters: [
                            choice(
                                name: 'CONFIRM',
                                choices: ['No', 'Yes'],
                                description: 'Confirm traffic switch'
                            )
                        ]
                    )
                    
                    if (userInput == 'Yes') {
                        echo "Switching service to ${DEPLOYMENT_COLOR}..."
                        sh """
                            # Update service selector to point to new color
                            kubectl patch service myapp-service -n ${K8S_NAMESPACE} -p '{"spec":{"selector":{"app":"myapp","color":"${DEPLOYMENT_COLOR}"}}}'
                            
                            # Verify service update
                            kubectl get service myapp-service -n ${K8S_NAMESPACE} -o yaml
                            
                            # Get service endpoint
                            kubectl get service myapp-service -n ${K8S_NAMESPACE}
                            
                            echo 'Traffic successfully switched to ${DEPLOYMENT_COLOR}!'
                        """
                    } else {
                        echo 'Traffic switch cancelled. ${DEPLOYMENT_COLOR} deployment is ready but not active.'
                    }
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                echo 'Verifying deployment status...'
                sh """
                    # Check both deployments
                    echo '=== Blue Deployment ==='
                    kubectl get deployment myapp-blue -n ${K8S_NAMESPACE} || echo 'Blue deployment not found'
                    
                    echo '=== Green Deployment ==='
                    kubectl get deployment myapp-green -n ${K8S_NAMESPACE} || echo 'Green deployment not found'
                    
                    echo '=== Service Status ==='
                    kubectl get service myapp-service -n ${K8S_NAMESPACE}
                    kubectl describe service myapp-service -n ${K8S_NAMESPACE} | grep Selector
                    
                    echo '=== All Pods ==='
                    kubectl get pods -n ${K8S_NAMESPACE} -o wide
                """
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline completed successfully!'
            sh """
                echo 'Deployment Summary:'
                echo '===================='
                echo 'Image: ${FULL_IMAGE}'
                echo 'Deployed to: ${DEPLOYMENT_COLOR}'
                echo 'Namespace: ${K8S_NAMESPACE}'
                echo 'Build Number: ${BUILD_NUMBER}'
                
                # Get service URL
                SERVICE_URL=\$(kubectl get service myapp-service -n ${K8S_NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
                if [ -z "\$SERVICE_URL" ]; then
                    SERVICE_URL=\$(kubectl get service myapp-service -n ${K8S_NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
                fi
                echo 'Service URL: http://'\$SERVICE_URL
            """
        }
        
        failure {
            echo 'Pipeline failed!'
            sh """
                echo 'Checking logs for debugging...'
                kubectl get pods -n ${K8S_NAMESPACE} -l color=${DEPLOYMENT_COLOR}
                
                # Get logs from failed pods if any
                kubectl get pods -n ${K8S_NAMESPACE} -l color=${DEPLOYMENT_COLOR} --field-selector=status.phase!=Running || true
            """
        }
        
        always {
            echo 'Cleaning up...'
            sh """
                # Clean up local Docker images to save space
                docker rmi ${FULL_IMAGE} || true
                docker system prune -f || true
            """
        }
    }
}

// Function to determine which color is currently inactive
def getInactiveColor() {
    try {
        def currentColor = sh(
            script: "kubectl get service myapp-service -n blue-green-app -o jsonpath='{.spec.selector.color}' 2>/dev/null || echo 'blue'",
            returnStdout: true
        ).trim()
        
        if (currentColor == 'blue') {
            return 'green'
        } else {
            return 'blue'
        }
    } catch (Exception e) {
        // Default to green if service doesn't exist yet
        return 'green'
    }
}
