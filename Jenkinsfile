pipeline {

    agent any

    options {
        disableConcurrentBuilds()
    }

    environment {
        PATH = "${JENKINS_HOME}/.rbenv/bin:${JENKINS_HOME}/.rbenv/shims:/usr/local/bin:/sbin:/usr/sbin:/bin:/usr/bin"
        RBENV_VERSION = '2.5.3'
    }

    stages {

        stage('rbenv') {
          steps {
            sh 'rbenv install --skip-existing $RBENV_VERSION'
          }
        }

        stage('setup') {
            steps {
                sh 'gem install bundler'
                sh 'bundle install'
            }
        }

        stage('test') {
            steps {
                sh 'bundle exec rspec'
            }
        }
    }
}