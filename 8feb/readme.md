### Jenkinsfile with Post-Build Trigger to Another Job

This will trigger another pipeline job after this one completes.

<code>
    
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

</code>

<br>

### Explanation

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



###


==================

Assignment: create 2 jenkins jobs:
1. devStage -> testStage
2. devStage -> main branch -> Main123.java -> run { groovy scripts }
3. testStage -> test branch -> Test123.java -> run { groovy scripts }
4. scdhule cron job -> its a event based trigger -> PUSH event
==================	==================	==================	==================	==================	==================	==================

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
            build job: 'Test'
        }
    }
}



=================================
pipeline {
    agent any

    stages {
        stage('Checkout Code') {
            steps {
                git 'https://github.com/sidoncode/TPCSJava.git'
            }
        }

        stage('Build') {
            steps {
                echo 'Compiling Java code...'
                bat 'javac AFG.java'
            }
        }

        stage('Run') {
            steps {
                echo 'Running Java program...'
                bat 'java AFG'
            }
        }
    }
}

----------------------------------

file should me class name  "MultiplyTwoNumbers"


public class MultiplyTwoNumbers {

    public static void main(String[] args) {

        float first = 1.5f;
        float second = 2.0f;

        float product = first * second;

        System.out.println("The product is: " + product);
    }
}



-----------------------------


pipeline {
    agent any

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main',
                url: 'https://github.com/Paras52/Jenkins_pipline_8feb'
            }
        }

        stage('Build') {
            steps {
                echo 'Compiling Java code...'
                bat 'javac MultiplyTwoNumbers.java'
            }
        }

        stage('Run') {
            steps {
                echo 'Running Java program...'
                bat 'java MultiplyTwoNumbers'
            }
        }
    }
}
}

