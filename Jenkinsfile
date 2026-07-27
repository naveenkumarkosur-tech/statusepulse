
pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                echo 'Source code Checkouted successfully'
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }
    }
}
