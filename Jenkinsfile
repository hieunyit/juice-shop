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
    stage('Installing Dependencies') {
      steps {
        cache(
          maxCacheSize: 550,
          caches: [
            arbitraryFileCache(
              cacheName: 'npm-dependency-cache',
              cacheValidityDecidingFile: 'package-lock.json',
              includes: '**/*',
              path: 'node_modules'
            )
          ]
        ) {
          sh 'npm install --no-audit'
        }
      }
    }
    stage('Snyk Open Source') {
      steps {
        script {
          sh '''
            snyk test --severity-threshold=high --json-file-output=snyk-sca.json 
          '''
        }
      }
    }

  }
}
