pipeline {

    agent any

    options {
        disableConcurrentBuilds()
    }

    environment {
        PATH = "${JENKINS_HOME}/.rbenv/bin:${JENKINS_HOME}/.rbenv/shims:/usr/local/bin:/sbin:/usr/sbin:/bin:/usr/bin"
        RBENV_VERSION = '2.5.3'
        BUNDLER_VERSION = '1.17.3'
    }

    stages {

        stage('rbenv') {
          steps {
            sh 'rbenv install --skip-existing $RBENV_VERSION'
          }
        }

        stage('bundler') {
            steps {
                sh 'gem list --silent -i bundler -v "$BUNDLER_VERSION" || gem install bundler -v "$BUNDLER_VERSION"'
                sh 'bundle install'
            }
        }

        stage('rspec') {
            steps {
                sh 'bundle exec rspec spec --format documentation'
            }
        }
    }
}
