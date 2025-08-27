pipeline {
  agent any
  stages {
    stage('Deploy - AWS EC2') {
      steps {
        withAWS(credentials: 'aws-jenkins', region: 'ap-southeast-1') {
          sshagent(['ssh-key']) {
            sh '''
              EC2_HOST=$(aws ec2 describe-instances | jq -r '.Reservations[].Instances[] | select(.Tags[].Value == "server-dev") | .NetworkInterfaces[].Association.PublicIp')
              echo $EC2_HOST
              ssh -o StrictHostKeyChecking=no ubuntu@$EC2_HOST 'id'
            '''
          }
        }
      }
    }
  }
}

