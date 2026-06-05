pipeline {
    agent none // Do not run anything on the global host machine
    
    environment {
        DOCKER_REPO           = 'sirdavidchris/django-app'
        DOCKER_CREDENTIALS_ID = 'docker-hub-credentials' 
        IMAGE_TAG             = "${env.BUILD_NUMBER}"
    }
    
    stages {
        stage('Code Linting & Security') {
            agent { 
                docker { image 'python:3.11-slim' } 
            }
            steps {
                echo 'Running linting inside an isolated Python environment...'
                sh 'pip install --no-cache-dir flake8 && flake8 .'
            }
        }

        stage('Vulnerability Scan') {
            agent { 
                docker { image 'aquasec/trivy:latest' } 
            }
            steps {
                echo 'Scanning project files for known vulnerabilities...'
                sh 'trivy fs .'
            }
        }

        stage('Build & Push Image') {
            agent { 
                docker { 
                    image 'docker:stable'
                    // We pass the socket into this specific container so it can build images
                    args '-v /var/run/docker.sock:/var/run/docker.sock' 
                } 
            }
            steps {
                echo "Compiling and pushing Docker layers using an isolated Docker CLI agent..."
                withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS_ID}", passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                    sh """
                        docker build -t ${DOCKER_REPO}:${IMAGE_TAG} -t ${DOCKER_REPO}:latest .
                        echo "\$PASS" | docker login -u "\$USER" --password-stdin
                        docker push ${DOCKER_REPO}:${IMAGE_TAG}
                        docker push ${DOCKER_REPO}:latest
                    """
                }
            }
        }

        stage("Deploy to aws-ec2-instance") {
            steps {
                echo "Deploying image to AWS EC2 instance..."

                sshagent(['aws-ec2-instance']) {
                    script {
                        def EC2_IP = "54.165.131.131"
                        def SSH_USER = "ubuntu"

                        sh """
                            ssh -o StrictHostKeyChecking=no ${SSH_USER}@${EC2_IP} '
                            docker stop django-app || true 
                            docker rm django-app || true 
                            docker pull ${DOCKER_REPO}:${IMAGE_TAG} 
                            docker run -d --name django-app --restart unless-stopped -p 80:8000 ${DOCKER_REPO}:${IMAGE_TAG}
                            docker image prune -f
                            '
                        """
                    }
                }
            }
        }
        stage('Clean Up') {
            steps {
                echo 'Purging temporary local build images to free up disk space...'
                sh "docker rmi ${DOCKER_REPO}:${IMAGE_TAG}"
                sh "docker rmi ${DOCKER_REPO}:latest"
            }
        }
    }

    post {
        success {
            echo "=========================================================================="
            echo " Success! Continuous Integration complete. Your image is live."
            echo " Repository: https://hub.docker.com/r/${DOCKER_REPO}"
            echo "=========================================================================="
        }
        failure {
            echo " Pipeline failed. Please inspect individual stage logs above for errors."
        }
    }
}