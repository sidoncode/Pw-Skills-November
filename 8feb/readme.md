### Jenkinsfile with Post-Build Trigger to Another Job

This will trigger another pipeline job after this one completes.

pipeline {
    agent any

    triggers {
        githubPush()
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/<username>/<repo>.git'
            }
        }

        stage('Build') {
            steps {
                echo 'Compiling Java code...'
                bat 'javac HelloWorld.java'
            }
        }

        stage('Run') {
            steps {
                echo 'Running Java program...'
                bat 'java HelloWorld'
            }
        }
    }

    post {
        success {
            echo 'Triggering downstream job...'
            build job: 'Second-Pipeline-Job'
        }
    }
}

Explanation

post { success { ... } } runs only if the pipeline succeeds.

build job: 'Second-Pipeline-Job' triggers another Jenkins job.

Replace:

Second-Pipeline-Job


with the exact name of your target pipeline.

Optional: Pass parameters to the next job
post {
    success {
        build job: 'Second-Pipeline-Job',
              parameters: [
                  string(name: 'ENV', value: 'dev')
              ]
    }
}

Trigger regardless of success or failure
post {
    always {
        build job: 'Second-Pipeline-Job'
    }
}
