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
    SNYK_TOKEN = credentials('snyk')
  }

  stages {
    stage('Snyk Open Source') {
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
            snyk container test --severity-threshold=high --json-file-output=snyk-image.json  $dockerImageName
          '''
        }
      }
    }

  }
}
