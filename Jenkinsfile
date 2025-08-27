pipeline {
  agent any
  environment {
    DOCKER_PASSWORD = credentials('docker-hub-password')
  }

    stage('Docker Build and Push') {
      steps {
        sh 'podman login docker.io -u hieuny -p $DOCKER_PASSWORD'
        sh 'podman build -t docker.io/hieuny/juice-shop:$GIT_COMMIT .'
        sh 'podman push docker.io/hieuny/juice-shop:$GIT_COMMIT'
      }
    }
    stage('Sign with Cosign'){
      steps {
        withCredentials([file(credentialsId: 'cosign-private-key', variable: 'COSIGN_KEY')]) {
          sh 'cosign sign --key $COSIGN_KEY docker.io/hieuny/juice-shop:$GIT_COMMIT'
        }
      }
    }
}

