pipeline {
  agent { label 'swarm'}
  environment {
      TOKEN = credentials('gh-token')
      TF_PLUGIN_CACHE_DIR = '/plugins'
  }
  triggers { pollSCM('H/5 * * * *') }
  stages {
    stage('Foodcritic'){
      when { expression{ env.BRANCH_NAME ==~ /dev.*/ || env.BRANCH_NAME ==~ /PR.*/ || env.BRANCH_NAME ==~ /feat.*/ } }
      steps{
        sh 'foodcritic -B cookbook/apt/ || exit 0'
      }
      post{
        always {
          warnings canComputeNew: false, canResolveRelativePaths: false, categoriesPattern: '', consoleParsers: [[parserName: 'Foodcritic']], defaultEncoding: '', excludePattern: '', healthy: '100', includePattern: '', messagesPattern: '', unHealthy: ''
        }
      }
    }
    stage('Rubocop'){
      when { expression{ env.BRANCH_NAME ==~ /dev.*/ || env.BRANCH_NAME ==~ /PR.*/ || env.BRANCH_NAME ==~ /feat.*/ } }
      steps{
        sh 'sudo su --command "/opt/chefdk/embedded/bin/rubocop –L cookbook/apt/ -r rubocop/formatter/checkstyle_formatter -f RuboCop::Formatter::CheckstyleFormatter -o int-lint-results.xml" || exit 0'
      }
      post{
        always {
          checkstyle canComputeNew: false, canRunOnFailed: true, defaultEncoding: '', healthy: '', pattern: 'int-lint-results.xml', unHealthy: ''
        }
      }
    }
    stage('ChefSpec'){
      when { expression{ env.BRANCH_NAME ==~ /dev.*/ || env.BRANCH_NAME ==~ /PR.*/ || env.BRANCH_NAME ==~ /feat.*/ } }
      steps{
        echo 'ChefSpec test'
      }
    }
    stage("Kitchen test"){
      when { expression{ env.BRANCH_NAME ==~ /dev.*/ || env.BRANCH_NAME ==~ /PR.*/ || env.BRANCH_NAME ==~ /feat.*/ } }
      steps{
        script {
          kitchenParallel (this.getInstances())
        }
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
      when { expression{ env.BRANCH_NAME ==~ /dev.*/ || env.BRANCH_NAME ==~ /PR.*/ || env.BRANCH_NAME ==~ /feat.*/ } }
      steps{
        echo "PR has been created"
        //createPR "jenkinsdou", "PR Created Automatically by Jenkins", "master", env.BRANCH_NAME, "xfrarod"
        //slackSend baseUrl: "https://shutterfly.slack.com/services/hooks/jenkins-ci/", channel: '#cloudeng_notification', color: '#00FF00', message: "Please review and approve PR to merge changes to dev branch : https://github.com/xfrarod/tl_chef_cookbooks/pulls"
        }
    }
    stage('Knife cookbook upload'){
      when { expression{ env.BRANCH_NAME == 'master'} }
      steps{
        sh 'knife cookbook upload custom_nginx -V'
      }
    }
  }
  post {
    success {
      slackSend baseUrl: "https://shutterfly.slack.com/services/hooks/jenkins-ci/", channel: '#cloudeng_notification', color: '#00FF00', message: "SUCCESSFUL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})"
      echo "success"
    }
    failure {
      script{
        def commiter_user = sh "git log -1 --format='%ae'"
        slackSend baseUrl: "https://shutterfly.slack.com/services/hooks/jenkins-ci/", channel: '#cloudeng_notification', color: '#FF0000', message: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})"
      }
    }
  }
}

/*def createPR (user, title, tobranch, frombranch, org){
  def COMMIT_MESSAGE = sh(script:'git log -1 --pretty=%B',
      returnStdout: true).trim()
  sh "if [ ! -d ~/.config ]; then mkdir ~/.config;fi"
  sh 'echo "github.com:" >> ~/.config/hub'
  sh "echo \"- user: ${user}\" >> ~/.config/hub"
  sh "echo \"  oauth_token: ${env.TOKEN}\" >> ~/.config/hub"
  sh 'echo "  protocol: https" >> ~/.config/hub'
  try {
      sh "git checkout ${env.BRANCH_NAME}"
      sh "hub pull-request -m \"${title}\n ${COMMIT_MESSAGE} \n From Jenkins job: ${env.BUILD_URL} \" -b ${org}:${tobranch} -h ${org}:${frombranch}"
  }catch(Exception e) {
      echo "PR already created"
  }
}*/

def ArrayList<String> getInstances(){
    def tkInstanceNames = []
		def lines = sh(script: 'cd cookbook/custom_nginx/; kitchen list', returnStdout: true).split('\n')
			for (int i = 1; i < lines.size(); i++) {
				tkInstanceNames << lines[i].tokenize(' ')[0]
			}
			return tkInstanceNames
}

def kitchenParallel (ArrayList<String> instanceNames) {
    def parallelNodes = [:]

    for (int i = 0; i < instanceNames.size(); i++) {
        def instanceName = instanceNames.get(i)
        parallelNodes["tk-${instanceName}"] = {
					result = sh(script: 'cd cookbook/custom_nginx/; kitchen test --destroy always ' + instanceName, returnStatus: true)
						if (result != 0) {
							echo "kitchen returned non-zero exit status"
							echo "Archiving test-kitchen logs"
							archive(includes: ".kitchen/logs/${instanceName}.log")
							error("kitchen returned non-zero exit status")
						}
				}
    }

    parallel parallelNodes
}
