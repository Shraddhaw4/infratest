pipeline {
    environment {
          AWS_ACCESS_KEY_ID     = credentials('creds')
          AWS_SECRET_ACCESS_KEY = credentials('creds')
    }

   agent {label 'terraform'}
   parameters {
        choice(choices:['apply','destroy'], description: 'Users Choice', name: 'action')
    }
    stages {
       stage('Init') {
            steps {
                sh 'terraform init'
            }
        }

        stage('Plan') {
            steps {
              script {
                if (action == "apply"){
                    sh 'terraform plan -out myplan'
                } else {
                    sh 'terraform plan -destroy -out myplan'
                }
              }
            }
        }

        stage('Approval') {
            steps {
              script {
                def userInput = input(id: 'confirm', message: 'Confirmation', parameters: [ [$class: 'BooleanParameterDefinition', defaultValue: false, description: 'Confirmation', name: 'confirm'] ])
            }
          }
        }

        stage('Action') {
            steps {
                sh 'terraform ${action} --auto-approve'
            }
        }
        stage('Copy key') {
            steps {
                sh '''sudo chmod 600 /home/ec2-user/.ssh/aws_keys_pairs_3.pem
                sudo chown ec2-user:ec2-user /home/ec2-user/.ssh/aws_keys_pairs_3.pem
                cp config /home/ec2-user/.ssh/config
                '''
            }
        }
    }
}
