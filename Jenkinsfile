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
    stage('Snyk Open Source') {
      steps {
        script {
          snykSecurity(
              snykInstallation: 'snyk',
              snykTokenId: 'snyk',
              failOnIssues: false,
              failOnError: true,  
              additionalArguments: '--all-projects --detection-depth=4'
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
