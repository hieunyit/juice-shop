pipeline {
  agent any
  environment {
    DOCKER_PASSWORD = credentials('docker-hub-password')
  }
  stages {
    stage('Docker Build and Push') {
      steps {
        sh '''
          docker login -u hieuny -p $DOCKER_PASSWORD
          docker build -t hieuny/juice-shop:$GIT_COMMIT .
          docker push docker.io/hieuny/juice-shop:$GIT_COMMIT | tee push.log
          grep -m1 -oE 'sha256:[0-9a-f]{64}' push.log > digest.txt
        '''
      }
    }
    stage('Sign with Cosign'){
      steps {
        withCredentials([file(credentialsId: 'cosign-private-key', variable: 'COSIGN_KEY'),string(credentialsId: 'cosign-pass', variable: 'COSIGN_PASSWORD')]) {
          sh '''
            DIGEST=$(cat digest.txt)
            cosign sign -y --key $COSIGN_KEY docker.io/hieuny/juice-shop@$DIGEST
          '''
        }
      }
    }
  }
}

