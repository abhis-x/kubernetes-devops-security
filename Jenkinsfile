pipeline {
  agent any

  stages {
      stage('Build Artifact') {
            steps {
              sh "mvn clean package -DskipTests=true"
              archive 'target/*.jar' ///
            }
        }   
stage('Unit testing') {
            steps {
              sh "mvn test"
            }
            post {
              always {
                junit 'target/surefire-reports/*.xml'
                jacoco execPattern: 'target/jacoco.exec'
        }
            } 
            }     

             stage('Mutation Tests - PIT') {
                steps {
                  sh "mvn org.pitest:pitest-maven:mutationCoverage"  
                }
                 post {
                  always{
                    pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
                  }
                 } 
             } 

              stage('SonarQube - SAST') {
                    steps {
                      withSonarQubeEnv('SonarQube') {
                        sh "mvn sonar:sonar \
                 	              -Dsonar.projectKey=devsecops-numeric-application 
                 	              -Dsonar.host.url=http://devsecops-demo.eastus.cloudapp.azure.com:9000
                                -Dsonar.login=sqp_e15a68f2136a1e8b685899ecd29030d023983671"
         }
                    }
              }

            stage('Docker Build and Push') {
      steps {
        withDockerRegistry([credentialsId: "docker-hub", url: ""]) {
          sh 'printenv'
          sh 'sudo docker build -t abhix01/numeric-app:""$GIT_COMMIT"" .'
          sh 'docker push abhix01/numeric-app:""$GIT_COMMIT""'
        }
      }
    } 
    stage('K8S Deployment - DEV') {
      steps {
         
            withKubeConfig([credentialsId: 'kubeconfig']) {
              sh "sed -i 's#replace#abhix01/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
              sh "kubectl apply -f k8s_deployment_service.yaml"
            }
      }
    }
  }
}