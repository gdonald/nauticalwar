pipeline {
    agent {label 'worker_node1'}
    stages {
        stage('source') {
            steps {
                git 'ssh://gd@darkclear.io:2217/git/nauticalwar'
            }
        }
        stage('rspec') {
            steps {
                sh 'bundle exec rspec'
            }
        }
    }
}