pipeline {
  agent any
  tools {
    nodejs 'nodejs22.18.0'
  }
  environment {
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
          sh '''
            gitleaks detect --source . --redact \
              --report-format json \
              --report-path gitleaks-report.json
          '''
          defectDojoPublisher artifact: 'gitleaks-report.json', autoCreateEngagements: false, autoCreateProducts: false, engagementId: '1', productId: '1', scanType: 'Gitleaks Scan'
        }
      }
    }
    stage('DefectDojoPublisher') {
      steps {
          defectDojoPublisher artifact: 'gitleaks-report.json', autoCreateEngagements: false, autoCreateProducts: false, engagementId: '1', productId: '1', scanType: 'Gitleaks Scan'
        }
      }
    }
    stage('Dependency Scanning') {
      parallel {
        stage('NPM Dependency Audit') {
          steps {
            catchError(buildResult: 'SUCCESS', message: 'Oops! it will be fixed in future releases', stageResult: 'UNSTABLE') {
              sh '''
              npm audit --audit-level=critical --json > npm-audit-report.json
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
              --disableArchive
              --prettyPrint
            ''', odcInstallation: 'OWASP-DepCheck-12'
          }
        }
        stage('retire.js scan Dependency') {
          steps {
            catchError(buildResult: 'SUCCESS', message: 'Oops! it will be fixed in future releases', stageResult: 'UNSTABLE') {
              sh 'retire --path .  --outputformat json --outputpath retire-report.json'
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
                semgrep scan \
                  --config p/owasp-top-ten \
                  --config p/security-audit \
                  --config p/secrets \
                  --config p/javascript \
                  --metrics=off \
                  --exclude node_modules --exclude dist --exclude build --exclude coverage --exclude .git \
                  --timeout 10 \
                  --error \
                  --json --json-output=semgrep-report.json \
                  --sarif --sarif-output=semgrep-report.sarif
              '''
            }
          }
        }
        stage('Nodejsscan scan') {
          steps {
            catchError(buildResult: 'SUCCESS', message: 'Oops! it will be fixed in future releases', stageResult: 'UNSTABLE') {
              sh '''
                njsscan --recursive . \
                  --exclude node_modules,dist,build,coverage,.git \
                  --json --output njsscan-report.json
              '''
            }
          }
        }
        stage('Sonarqube scan') {
          steps {
            withSonarQubeEnv('SonarQube Server') {
              sh '''
                $SONAR_SCANNER_HOME/bin/sonar-scanner \
                  -Dsonar.projectKey=juice-shop \
              '''
            }
          }
        }
      }
    }
  }
}
