pipeline {
    agent {label 'worker'}
    stages {
        stage('rspec') {
            steps {
                sh 'bundle exec rspec'
            }
        }
    }
}