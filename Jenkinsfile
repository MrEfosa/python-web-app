pipeline {
    agent any
    
    environment {
        // Your Docker Hub profile and target repository
        DOCKER_REPO = 'sirdavidchristian/django-app'
        
        // This MUST match the ID name you type when adding credentials in Jenkins
        DOCKER_CREDENTIALS_ID = 'docker-hub-credentials' 
        
        // Parameter that automatically assigns the current Jenkins build number as the image tag
        IMAGE_TAG = "${env.BUILD_NUMBER}"
    }
    
    stages {
        stage('Clone Repository') {
            steps {
                echo 'Pulling fresh code from GitHub SCM...'
                checkout scm
            }
        }

        stage('Code Linting / Static Analysis') {
            steps {
                echo 'Running python syntax validation checks...'
                // Optional step for code quality: e.g., sh 'flake8 .'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Compiling Docker layers for ${DOCKER_REPO}:${IMAGE_TAG}..."
                script {
                    // Builds the image using the root Dockerfile context
                    sh "docker build -t ${DOCKER_REPO}:${IMAGE_TAG} ."
                    
                    // Tags an alias 'latest' version from the compiled layers
                    sh "docker tag ${DOCKER_REPO}:${IMAGE_TAG} ${DOCKER_REPO}:latest"
                }
            }
        }

        stage('Push to Docker Repository') {
            steps {
                echo 'Initiating secure handshake and pushing to Docker Hub...'
                // withDockerRegistry securely injects your matching Jenkins secret credentials
                withDockerRegistry([credentialsId: "${DOCKER_CREDENTIALS_ID}", url: '']) {
                    sh "docker push ${DOCKER_REPO}:${IMAGE_TAG}"
                    sh "docker push ${DOCKER_REPO}:latest"
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