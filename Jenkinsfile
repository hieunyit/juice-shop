pipeline {
  agent any
  stages {
    stage('Config') {    
      steps {
        withAWS(credentials: 'aws-jenkins', region: 'ap-southeast-1') {
          sh '''
           cat <<_EOF_ > td.json
{
  "family": "juice-shop-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "arn:aws:iam::065525255066:role/juice-shop-task-exec-role",
  "containerDefinitions": [
    {
      "name": "juice-shop-container",
      "image": "hieuny/juice-shop:dfe583d9400f5a2b30038913c004136183dc3658",
      "portMappings": [
        {
          "containerPort": 3000,
          "protocol": "tcp"
        }
      ],
      "essential": true,
      "healthCheck": {
        "command": [
          "CMD-SHELL",
          "curl -f http://localhost:3000/ || exit 1"
        ],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      },
      "environment": [
        {
          "name": "NODE_ENV",
          "value": "production"
        }
      ],
      "cpu": 512,
      "memory": 1024,
      "memoryReservation": 512
    }
  ]
}
_EOF_
        '''
        }
      }
    }
    stage('Deploy') {
      steps {
        withAWS(credentials: 'aws-jenkins', region: 'ap-southeast-1') {
          sh ''' 
            aws ecs register-task-definition --output json --cli-input-json file://td.json
            aws ecs update-service --cluster juice-shop-cluster --service juice-shop-svc --task-definition juice-shop-task  --desired-count 1 --output json --capacity-provider-strategy capacityProvider=FARGATE_SPOT,weight=1,base=0 --force-new-deployment
          '''
        }
      }
    }
  }
}

