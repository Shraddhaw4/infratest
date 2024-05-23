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
        stage('Copy key file') {
             steps {
                    withCredentials([sshUserPrivateKey(
                         credentialsId: 'creds',
                         keyFileVariable: 'ssh-key')])
                    {
                         sh 'cp "$ssh-key" Jenkins-Server.pem'
                    }
             }
        }
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
    }
}
