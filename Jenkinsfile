pipeline {
  agent any
  stages {
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
  }
}

