readProperties = loadConfigurationFile 'buildConfiguration'
pipeline {
  agent any
  environment {
      TOKEN = credentials('gh-token')
      TF_PLUGIN_CACHE_DIR = '/plugins'
  }
  triggers { pollSCM('H/5 * * * *') }
  stages {
    stage('run foodcritic'){
      agent {
        docker {
          image readProperties.imageChefdk
          }
        }
      when { expression{ env.BRANCH_NAME ==~ /dev.*/ || env.BRANCH_NAME ==~ /PR.*/ || env.BRANCH_NAME ==~ /feat.*/ } }
      steps{
        echo "############ Running Foodcritic ############"
        sh 'foodcritic -B cookbook/apt/ || exit 0'
      }
      post{
        always {
          warnings canComputeNew: false, canResolveRelativePaths: false, categoriesPattern: '', consoleParsers: [[parserName: 'Foodcritic']], defaultEncoding: '', excludePattern: '', healthy: '100', includePattern: '', messagesPattern: '', unHealthy: ''
        }
      }
    }
    stage('run rubocop'){
      agent {
        docker {
          image readProperties.imageChefdk
        }
      }
      when { expression{ env.BRANCH_NAME ==~ /dev.*/ || env.BRANCH_NAME ==~ /PR.*/ || env.BRANCH_NAME ==~ /feat.*/ } }
      steps{
        echo "############ Running Rubocop ############"
        sh 'rubocop –L cookbooks/apt/ || exit 0'
      }
    }
    stage('unit test'){
      agent {
        docker {
          image readProperties.imageChefdk
        }
      }
      when { expression{ env.BRANCH_NAME ==~ /dev.*/ || env.BRANCH_NAME ==~ /PR.*/ || env.BRANCH_NAME ==~ /feat.*/ } }
      steps{
        echo "############ Running UnitTest ############"
        sh 'chef exec rspec'
      }
    }
    stage("Approval step"){
      agent none
      when { expression{ env.BRANCH_NAME ==~ /dev.*/ || env.BRANCH_NAME ==~ /PR.*/ || env.BRANCH_NAME ==~ /feat.*/ } }
      steps{
        input message: "Do you want to create a PR to master branch?", ok: 'Approve'
      }
    }
    stage('Generate PR'){
      agent {
        docker {
          image readProperties.imagePipeline
        }
      }
      when { expression{ env.BRANCH_NAME ==~ /dev.*/ || env.BRANCH_NAME ==~ /PR.*/ || env.BRANCH_NAME ==~ /feat.*/ } }
      steps{
        createPR "jenkinsdou", readProperties.title, "master", env.BRANCH_NAME, "xfrarod"
        slackSend baseUrl: readProperties.slack, channel: '#cloudeng_notification', color: '#00FF00', message: "Please review and approve PR to merge changes to dev branch : https://github.com/xfrarod/tl_chef_cookbooks/pulls"
        }
    }
    stage('Knife cookbook upload'){
      agent {
        docker {
          image readProperties.imageChefdk
        }
      }
      //when { expression{ env.BRANCH_NAME == "master" } }
      steps{
        sh 'knife cookbook upload -o /cookbook apt -V'
      }
    }
  }
  post {
    success {
      slackSend baseUrl: readProperties.slack, channel: '#cloudeng_notification', color: '#00FF00', message: "SUCCESSFUL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})"
    }
    failure {
      script{
        def commiter_user = sh "git log -1 --format='%ae'"
        slackSend baseUrl: readProperties.slack, channel: '##cloudeng_notification', color: '#FF0000', message: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})"
      }
    }
    //always {
      //    sh "docker system prune -f"
    //}
  }
}
