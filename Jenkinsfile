pipeline {
    agent any
    stages {
        stage('Setup') {
            steps {
                sh 'gem install bundler'
                sh 'bundle install'
            }
        }
        stage('Test') {
            steps {
                sh 'bundle exec rspec'
            }
        }
    }
}