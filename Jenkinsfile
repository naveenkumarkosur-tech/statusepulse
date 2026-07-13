
pipeline {
    agent any

    stages {

        stage('Clone') {
            steps {
                echo 'Source code cloned successfully'
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
