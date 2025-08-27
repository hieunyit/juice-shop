pipeline {
  agent any
  stages {
    stage('Deploy - AWS EC2'){
      withAWS(credentials: 'aws-jenkins', region: 'ap-southeast-1') {
        sshagent(['ssh-key']) {
          sh '''
            EC2_HOST=$(aws ec2 describe-instances | jq -r '.Reservations[].Instances[] | select(.Tags[].Value == "server-dev") | .NetworkInterfaces[].Association.PublicIp')
            ssh -o StrictHostKeyChecking=no ec2-user@$EC2_HOST 'id'
          '''
        }
      }
    }
  }
}

