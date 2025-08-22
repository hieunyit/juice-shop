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
    stage('Gitleaks scan secret') {
      steps {
        sh 'gitleaks detect --source . --redact'
      }
    }
    stage('Dependency Scanning') {
      parallel {
        stage('NPM Dependency Audit') {
          steps {
            catchError(buildResult: 'SUCCESS', message: 'Oops! it will be fixed in future releases', stageResult: 'UNSTABLE') {
              sh '''
              npm audit --audit-level=critical
              echo $?
              '''
            }
          }
        }
        stage('OWASP Dependency Check') {
          steps {
            dependencyCheck additionalArguments: '''
              --scan './'
              --out './'
              --format 'ALL'
              --exclude '**/test/files/**'
              --prettyPrint
            ''', odcInstallation: 'OWASP-DepCheck-12'
          }
        }
        stage('retire.js scan Dependency') {
          steps {
            catchError(buildResult: 'SUCCESS', message: 'Oops! it will be fixed in future releases', stageResult: 'UNSTABLE') {
              sh 'retire --path .'
            }
          }
        }
      }
    }
  }
}
