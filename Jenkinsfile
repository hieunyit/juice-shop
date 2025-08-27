pipeline {
  agent any
  environment {
    DOCKER_PASSWORD = credentials('docker-hub-password')
  }
  stages {
    stage('Docker Build and Push') {
      steps {
        sh '''
          podman login docker.io -u hieuny -p $DOCKER_PASSWORD
          podman build --cgroup-manager=cgroupfs -t docker.io/hieuny/juice-shop:$GIT_COMMIT .
          podman push --digestfile digest.txt docker.io/hieuny/juice-shop:$GIT_COMMIT
        '''
      }
    }
    stage('Sign with Cosign'){
      steps {
        withCredentials([file(credentialsId: 'cosign-private-key', variable: 'COSIGN_KEY'),string(credentialsId: 'cosign-pass', variable: 'COSIGN_PASSWORD')]) {
          sh '''
            DIGEST=$(cat digest.txt)
            export COSIGN_YES=true
            cosign sign -y --key $COSIGN_KEY docker.io/hieuny/juice-shop@$DIGEST
          '''
        }
      }
    }
  }
}

