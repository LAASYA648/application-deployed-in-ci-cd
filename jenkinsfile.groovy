pipeline {
    agent any

    environment {
        IMAGE = "sakshith123/pythonapp"
        AWS_REGION = "us-east-1"
        CLUSTER_NAME = "sakshith_01-cluster"
        AWS_PROFILE = "eks-profile"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/SAKSHITH22/pythonapp.git'
            }
        }

        stage('Set Dynamic Tag') {
            steps {
                script {
                    def timestamp = new Date().format('yyyyMMdd-HHmm')
                    env.TAG = "v${env.BUILD_ID}-${timestamp}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t $IMAGE:$TAG ."
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                        docker push $IMAGE:$TAG
                    """
                }
            }
        }

        stage('Update Deployment YAML') {
            steps {
                sh "sed -i 's|image:.*|image: $IMAGE:$TAG|' deployment.yaml"
            }
        }

        stage('Configure AWS & Kubeconfig') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {
                    sh """
                        aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID --profile $AWS_PROFILE
                        aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY --profile $AWS_PROFILE
                        aws configure set region $AWS_REGION --profile $AWS_PROFILE
                        aws eks --region $AWS_REGION update-kubeconfig --name $CLUSTER_NAME --profile $AWS_PROFILE
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh """
                    export AWS_PROFILE=$AWS_PROFILE
                    kubectl apply -f deployment.yaml
                    kubectl apply -f service.yaml
                    kubectl rollout status deployment/pythonapp-deployment --timeout=120s
                """
            }
        }
    }
}