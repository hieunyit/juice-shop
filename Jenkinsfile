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
    stage('Dependency Scanning') {
      parallel {
        stage('NPM Dependency Audit') {
          steps {
            sh '''
            npm audit --audit-level=critical
            echo $?
            '''
          }
        }
        stage('OWASP Dependency Check') {
          steps {
            dependencyCheck additionalArguments: '''
              --scan './'
              --out './'
              --format 'ALL'
              --prettyPrint
            ''', odcInstallation: 'OWASP-DepCheck-12'
          }
        }
        stage('retire.js scan Dependency') {
          steps {
            sh 'retire --package'
          }
        }
      }
    }
  }
}
