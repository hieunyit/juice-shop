pipeline {
  agent any
  tools {
    nodejs 'nodejs22.18.0'
  }

  stages {
    stage('Installing Dependencies') {
      steps {
        sh 'npm install --no-audit'
      }
    }
  }
}
