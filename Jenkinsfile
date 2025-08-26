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
  }
  post {
    always {
      defectDojoPublisher artifact: 'gitleaks-report.json', autoCreateEngagements: false, autoCreateProducts: false, engagementId: '1', productId: '1', environmentId: '3', scanType: 'Gitleaks Scan'
    }
  }
}
