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
    stage('Snyk Open Source') {
      steps {
        script {
          snykSecurity(
              snykInstallation: 'snyk',
              snykTokenId: 'snyk',
              failOnIssues: false,
              failOnError: true,  
              additionalArguments: '''
                  --all-projects
                  --detection-depth=4
                  --json-file-output=snyk-oss-results.json
                  --sarif-file-output=snyk-oss-results.sarif
                  --report
              '''.stripIndent().trim()
          )
        }
      }
    }
    stage('Snyk Container Security') {
      steps {
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
          '''
          snykSecurity(
            snykInstallation: 'snyk',
            snykTokenId: 'snyk',
            failOnIssues: false,
            failOnError: true,  
            additionalArguments: '''
                --command=container test $dockerImageName
                --json-file-output=snyk-container-results.json
                --sarif-file-output=snyk-container-results.sarif
                --exclude-base-image-vulns
                --report
            '''.stripIndent().trim()
          )
        }
      }
    }
  }
  post {
    always {
      script {
        sh '''
          python3 report/vuln_report.py report/*.sarif report/*.json
        '''
        
      }
    }
  }
}
