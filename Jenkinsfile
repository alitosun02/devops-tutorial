pipeline {
    agent any

    environment {
        IMAGE_NAME = 'alitosun02/python-devops-app'
        K3S_IP     = '3.126.138.119'
        KUBECONFIG_PATH = '/home/ubuntu/.kube/config'
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'GitHub deposu cekiliyor...'
                git branch: 'main', url: 'https://github.com/alitosun02/devops-tutorial.git'
            }
        }

        stage('Build') {
            steps {
                echo 'Docker image build ediliyor...'
                sh 'docker build -t $IMAGE_NAME:$BUILD_NUMBER -t $IMAGE_NAME:latest ./app'
            }
        }

        stage('Test') {
            steps {
                echo 'Testler calistiriliyor...'
                sh 'docker run --rm $IMAGE_NAME:latest pytest -v'
            }
        }

        stage('Push') {
            steps {
                echo 'Docker Hub a gonderiliyor...'
                withCredentials([usernamePassword(credentialsId: 'dockerhub-cred', usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
                    sh '''
                        echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin
                        docker push $IMAGE_NAME:$BUILD_NUMBER
                        docker push $IMAGE_NAME:latest
                    '''
                }
            }
        }

        stage('Deploy to k3s') {
            steps {
                echo 'Kubernetes e deploy ediliyor...'
                sshagent(credentials: ['aws-ssh-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ubuntu@$K3S_IP "KUBECONFIG=$KUBECONFIG_PATH kubectl set image deployment/python-app python-app=$IMAGE_NAME:$BUILD_NUMBER && KUBECONFIG=$KUBECONFIG_PATH kubectl rollout status deployment/python-app"
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline basariyla tamamlandi! Uygulama Kubernetes te guncellendi.'
        }
        failure {
            echo 'Pipeline basarisiz oldu, loglari kontrol et.'
        }
    }
}