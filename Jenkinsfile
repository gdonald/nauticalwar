pipeline {
    agent any
    stages {
        stage('Setup') {
            steps {
                sh('''
                    {
                        . ~/.rbenv
                    } &> /dev/null
                    gem install bundler
                    bundle install
                ''')
            }
        }
        stage('Test') {
            steps {
                sh 'bundle exec rspec'
            }
        }
    }
}