pipeline {
  agent any
  tools {
    nodejs 'nodejs22.18.0'
  }
  enviroment {
    SONAR_SCANNER_HOME = tool 'sonarqube-scanner-720'
  }

  stages {
    stage('Installing Dependencies') {
      steps {
        sh 'npm install --no-audit'
      }
    }
    stage('Gitleaks scan secret') {
      steps {
        catchError(buildResult: 'SUCCESS', message: 'Oops! it will be fixed in future releases', stageResult: 'UNSTABLE') {
          sh 'gitleaks detect --source . --redact --report-format sarif --report-path gitleaks-report.sarif'
        }
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
    stage('SAST Scanning') {
      parallel {
        stage('Semgrep scan') {
          steps {
            catchError(buildResult: 'SUCCESS', message: 'Oops! it will be fixed in future releases', stageResult: 'UNSTABLE') {
              sh '''
                semgrep \
                  --config p/owasp-top-ten \
                  --config p/security-audit \
                  --config p/secrets \
                  --config p/javascript \
                  --config p/nodejsscan \
                  --config r/javascript.lang.security.nodejs
              '''
            }
          }
        }
        stage('Nodejsscan scan') {
          steps {
            catchError(buildResult: 'SUCCESS', message: 'Oops! it will be fixed in future releases', stageResult: 'UNSTABLE') {
              sh '''
                njsscan --json --output njsscan-report.json .
              '''
            }
          }
        }
        stage('Sonarqube scan') {
          steps {
            withSonarQubeEnv(credentialsId: 'sonar-qube-server') {
              $SONAR_SCANNER_HOME/bin/sonar-scanner \
                -Dsonar.projectKey=juice-shop
                -Dsonar.sources=app.js
            }
          }
        }
      }
    }
  }
}
