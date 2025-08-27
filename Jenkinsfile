pipeline {
  agent any
  tools {
    nodejs 'nodejs22.18.0'
  }
  environment {
    SONAR_SCANNER_HOME = tool 'sonarqube-scanner-720'
    DOJO_URL = 'http://localhost:8081'
    DOJO_TOKEN = credentials('defectdojo-api-token')
    PRODUCT_ID = '1'
    ENGAGEMENT_ID = '1'
    API_SCAN_CFG_ID = '1'
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
              --gitleaks-ignore-path . \
              --report-path gitleaks-report.json
          '''
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
              '''
            }
          }
        }
        stage('OWASP Dependency Check') {
          steps {
            catchError(buildResult: 'SUCCESS', message: 'Oops! it will be fixed in future releases', stageResult: 'UNSTABLE') {
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
        }
        stage('retire.js scan Dependency') {
          steps {
            catchError(buildResult: 'SUCCESS', message: 'Oops! it will be fixed in future releases', stageResult: 'UNSTABLE') {
              sh 'retire --severity high --path .  --outputformat json --outputpath retire-report.json'
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
                  --json --json-output=semgrep-report.json
              '''
            }
          }
        }
        stage('Nodejsscan scan') {
          steps {
            catchError(buildResult: 'SUCCESS', message: 'Oops! it will be fixed in future releases', stageResult: 'UNSTABLE') {
              sh '''
                njsscan --sarif -o njsscan-report.sarif .
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
    
    stage('Vulnerability Scan - Docker'){
      parallel {
        stage('Trivy scan') {
          steps {
            catchError(buildResult: 'SUCCESS', message: 'Oops! it will be fixed in future releases', stageResult: 'UNSTABLE') {
               script {
                 sh '''
                  dockerImageName=$(awk 'NR==1 {print $2}' Dockerfile)
                  trivy image --severity HIGH,CRITICAL -f json -o trivy-result.json $dockerImageName
                 '''
               }
            }
          }
        }
        stage('OPA Conftest') {
          steps {
            catchError(buildResult: 'SUCCESS', message: 'Oops! it will be fixed in future releases', stageResult: 'UNSTABLE') {
               script {
                 sh """
                   podman run --rm -v \$(pwd):/project \
                      openpolicyagent/conftest test \
                      --policy policy Dockerfile
                 """
               }
            }
          }
        }
      }
    }
  }
  post {
    always {
      defectDojoPublisher artifact: 'gitleaks-report.json', autoCreateEngagements: false, autoCreateProducts: false, engagementId: '1', productId: '1', scanType: 'Gitleaks Scan'
      defectDojoPublisher artifact: 'npm-audit-report.json', autoCreateEngagements: false, autoCreateProducts: false, engagementId: '1', productId: '1', scanType: 'NPM Audit v7+ Scan'
      defectDojoPublisher artifact: 'dependency-check-report.xml', autoCreateEngagements: false, autoCreateProducts: false, engagementId: '1', productId: '1', scanType: 'Dependency Check Scan'
      defectDojoPublisher artifact: 'retire-report.json', autoCreateEngagements: false, autoCreateProducts: false, engagementId: '1', productId: '1', scanType: 'Retire.js Scan'
      defectDojoPublisher artifact: 'semgrep-report.json', autoCreateEngagements: false, autoCreateProducts: false, engagementId: '1', productId: '1', scanType: 'Semgrep JSON Report'
      defectDojoPublisher artifact: 'njsscan-report.sarif', autoCreateEngagements: false, autoCreateProducts: false, engagementId: '1', productId: '1', scanType: 'SARIF'
       script {
          sh '''
            curl -sS -X POST "$DOJO_URL/api/v2/import-scan/" \
              -H "Authorization: Token $DOJO_TOKEN" \
              -F "scan_type=SonarQube API Import" \
              -F "product_id=$PRODUCT_ID" \
              -F "engagement_id=$ENGAGEMENT_ID" \
              -F "api_scan_configuration=$API_SCAN_CFG_ID"
          '''
        }
    }
  }
}
