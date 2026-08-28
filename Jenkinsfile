pipeline {
    agent any
    
    environment {
        DOCKER_REPO = 'sirdavidchris/django-app'
        DOCKER_CREDENTIALS_ID = 'docker-hub-credentials' 
        IMAGE_TAG = "${env.BUILD_NUMBER}"
    }
    
    stages {
        stage('Clone Repository') {
            steps {
                echo 'Pulling fresh code from GitHub SCM...'
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Compiling Docker layers for ${DOCKER_REPO}:${IMAGE_TAG}..."
                script {
                    sh "docker build -t ${DOCKER_REPO}:${IMAGE_TAG} ."
                    sh "docker tag ${DOCKER_REPO}:${IMAGE_TAG} ${DOCKER_REPO}:latest"
                }
            }
        }

       stage('Push to Docker Repository') {
            steps {
                echo 'Logging securely into Docker Hub using stdin...'
                withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                    script {
                        sh "echo \$PASS | docker login -u \$USER --password-stdin"                        
                        sh "docker push ${DOCKER_REPO}:${IMAGE_TAG}"
                    }
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
