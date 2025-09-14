pipeline {
  agent any
  tools {
    nodejs 'nodejs22.18.0'
  }
  environment {
    SONAR_SCANNER_HOME = tool 'sonarqube-scanner-720'
    DOCKER_PASSWORD = credentials('docker-hub-password')
    DOJO_URL = 'http://localhost:8081'
    DOJO_TOKEN = credentials('defectdojo-api-token')
    PRODUCT_ID = '1'
    PRODUCT_NAME = 'Juice Shop'
    ENGAGEMENT_ID = '1'
    ENGAGEMENT_NAME = 'Jenkins'
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
            mkdir report
            gitleaks detect --source . --redact \
              --report-format json \
              --gitleaks-ignore-path . \
              --report-path report/gitleaks-report.json
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
              npm audit --audit-level=critical --json > report/npm-audit-report.json
              '''
            }
          }
        }
        stage('OWASP Dependency Check') {
          steps {
            catchError(buildResult: 'SUCCESS', message: 'Oops! it will be fixed in future releases', stageResult: 'UNSTABLE') {
              dependencyCheck additionalArguments: '''
                --scan './'
                --out './report'
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
              sh 'retire --severity high --path .  --outputformat json --outputpath report/retire-report.json'
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
                  --json --json-output=report/semgrep-report.json
              '''
            }
          }
        }
        stage('Nodejsscan scan') {
          steps {
            catchError(buildResult: 'SUCCESS', message: 'Oops! it will be fixed in future releases', stageResult: 'UNSTABLE') {
              sh '''
                njsscan --sarif -o report/njsscan-report.sarif .
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
                  -Dsonar.exclusions=**/test/**
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
                  dockerImageName=$(
                    awk 'BEGIN{IGNORECASE=1}
                         toupper($1)=="FROM"{
                           count++
                           img=""; stg=""
                           for(i=2;i<=NF;i++){
                             t=$i
                             if (t ~ /^--platform=/) continue
                             if (toupper(t)=="AS"){ if (i+1<=NF) stg=$(i+1); break }
                             if (img=="") img=t
                           }
                           if (stg!="") stages[tolower(stg)]=1
                           if (img!="") {
                             if (!(tolower(img) in stages)) {
                               if (first_external=="") first_external=img
                               last_external=img
                             }
                             last_any=img
                           }
                         }
                         END{
                           if (count<=1) print (first_external!=""?first_external:last_any);
                           else          print (last_external!=""?last_external:last_any);
                         }' Dockerfile
                  )
                  trivy image --scanners vuln --severity HIGH,CRITICAL --exit-code 1 -f json -o report/trivy-report.json $dockerImageName
                 '''
               }
            }
          }
        }
        stage('OPA Conftest') {
          steps {
            catchError(buildResult: 'SUCCESS', message: 'Oops! it will be fixed in future releases', stageResult: 'UNSTABLE') {
               script {
                 sh '''
                   conftest test --parser dockerfile -p policy Dockerfile  --output sarif > report/opa-report.sarif
                 '''
               }
            }
          }
        }
      }
    }
  }
  post {
    always {
      script {
        sh '''
          python3 report/vuln_report.py *.sarif *.json
        '''
        
      }
    }
  }
}
