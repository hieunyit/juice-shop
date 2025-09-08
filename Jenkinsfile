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
                  trivy image --scanners vuln --severity HIGH,CRITICAL --exit-code 1 -f json -o trivy-report.json $dockerImageName
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
                   conftest test --parser dockerfile -p policy Dockerfile  --output sarif > opa-report.sarif
                 '''
               }
            }
          }
        }
      }
    }
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
    stage('Verify Image'){
      steps {
        withCredentials([file(credentialsId: 'cosign-public-key', variable: 'COSIGN_PUBLIC_KEY')]) {
          script {
            sh '''
              DIGEST=$(cat digest.txt)
              if cosign verify --key $COSIGN_PUBLIC_KEY docker.io/hieuny/juice-shop@$DIGEST > /dev/null; then
                echo "✅ Cosign verify OK: $IMG"
                exit 0
              else
                 echo "❌ Cosign verify FAILED: $IMG"
                 exit 1
              fi
            '''
          }
        }
      }
    }
    stage('Deploy to Prod?') {
      steps {
        timeout(time: 1, unit: 'DAYS') {
          input message: 'Deploy to Production?', ok: 'YES! Let us try this on Production'
        }
      }
    }
    stage('Deploy - AWS EC2') {
      steps {
        withAWS(credentials: 'aws-jenkins', region: 'ap-southeast-1') {
          sshagent(['ssh-key']) {
            sh '''
              EC2_HOST=$(aws ec2 describe-instances | jq -r '.Reservations[].Instances[] | select(.Tags[].Value == "server-dev") | .NetworkInterfaces[].Association.PublicIp')
              ssh -o StrictHostKeyChecking=no ubuntu@$EC2_HOST "
                if docker ps -a | grep -q "juice-shop"; then
                  echo "Container found. Stopping ..."
                  docker stop "juice-shop" && docker rm "juice-shop"
                  echo "Container stop and removed"
                fi
                  docker run -d --name juice-shop -p 3000:3000 hieuny/juice-shop:b4e66e4a7ddcb0f9c95ce07a4240786da9bab5d9
              "
            '''
          }
        }
      }
    }
    stage('Integration Testing - AWS EC2') {
      steps {
        withAWS(credentials: 'aws-jenkins', region: 'ap-southeast-1') {
          script {
            sh '''
              sleep 20s
              URL=$(aws ec2 describe-instances | jq -r '.Reservations[].Instances[] | select(.Tags[].Value == "server-dev") | .NetworkInterfaces[].Association.PublicIp')
              echo "URL Data - $URL"
              if [ -n "$URL" ]; then
                http_code=$(curl -s -o /dev/null -w "%{http_code}" http://$URL:3000)
                echo "http_code - $http_code"
                if [ "$http_code" -eq 200 ]; then
                  echo "HTTP Status Code Tests Passed"
                else
                  echo "One or more test(s) failed"
                  exit 1
                fi
              fi
            '''
          }
        }
      }
    }
   stage('DAST - OWASP ZAP') {
     steps {
       withAWS(credentials: 'aws-jenkins', region: 'ap-southeast-1') {
         script {
           sh '''
              URL=$(aws ec2 describe-instances | jq -r '.Reservations[].Instances[] | select(.Tags[].Value == "server-dev") | .NetworkInterfaces[].Association.PublicIp')
              chmod 777 $(pwd)
              docker run -v $(pwd):/zap/wrk/:rw -t ghcr.io/zaproxy/zaproxy:stable zap-full-scan.py -t http://$URL:3000 -x zap-report.xml -r zap-report.html
           '''
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
      defectDojoPublisher artifact: 'trivy-report.json', autoCreateEngagements: false, autoCreateProducts: false, engagementId: '1', productId: '1', scanType: 'Trivy Scan'
      defectDojoPublisher artifact: 'opa-report.sarif', autoCreateEngagements: false, autoCreateProducts: false, engagementId: '1', productId: '1', scanType: 'SARIF'
       script {
          sh '''
            TEST_ID=$(curl -sS -H "Authorization: Token $DOJO_TOKEN" "$DOJO_URL/api/v2/tests/?engagement=$ENGAGEMENT_ID&scan_type=SonarQube%20API%20Import" | jq -r '.results[0].id')
            if [ -n "$TEST_ID" ]; then
              curl -sS -X POST "$DOJO_URL/api/v2/import-scan/" \
                -H "Authorization: Token $DOJO_TOKEN" \
                -F "scan_type=SonarQube API Import" \
                -F "product_name=$PRODUCT_NAME" \
                -F "engagement_name=$ENGAGEMENT_NAME" \
                -F "product_id=$PRODUCT_ID" \
                -F "engagement_id=$ENGAGEMENT_ID" \
                -F "api_scan_configuration=$API_SCAN_CFG_ID"
            else
              curl -sS -X POST "$DOJO_URL/api/v2/import-scan/" \
                -H "Authorization: Token $DOJO_TOKEN" \
                -F "scan_type=SonarQube API Import" \
                -F "product_name=$PRODUCT_NAME" \
                -F "engagement_name=$ENGAGEMENT_NAME" \
                -F "product_id=$PRODUCT_ID" \
                -F "engagement_id=$ENGAGEMENT_ID" \
                -F "api_scan_configuration=$API_SCAN_CFG_ID"
            fi
          '''
        }
    }
  }
}
