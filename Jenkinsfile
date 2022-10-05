def tfCmd(String command, String options = '') {
	ACCESS = "export AWS_PROFILE=${PROFILE} && export TF_ENV_profile=${PROFILE}"
	sh ("cd $WORKSPACE/main && ${ACCESS} && terraform init") // main
	sh ("cd $WORKSPACE/base && ${ACCESS} && terraform init") // base
	sh ("cd $WORKSPACE/main && terraform workspace select ${ENV_NAME} || terraform workspace new ${ENV_NAME}")
	sh ("echo ${command} ${options}") 
        sh ("cd $WORKSPACE/main && ${ACCESS} && terraform init && terraform ${command} ${options} && terraform show -no-color > show-${ENV_NAME}.txt")
}

pipeline {
  agent { node { label 'tf-slave' } }

	environment {
		AWS_DEFAULT_REGION = "${params.AWS_REGION}"
		PROFILE = "${params.PROFILE}"
		ACTION = "${params.ACTION}"
		PROJECT_DIR = "terraform/main"
  }
	options {
        buildDiscarder(logRotator(numToKeepStr: '30'))
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
  }
	parameters {

		choice (name: 'AWS_REGION',
				choices: ['ap-southeast-1','ap-east-1', 'ap-notheast-1'],
				description: 'Default at ap-southeast-1 "SG", ap-east-1 "HK", ap-notheast-1 "TK"')
		string (name: 'ENV_NAME',
			   defaultValue: 'tf-m-demoapp-dev',
			   description: 'Environment, Project or Customer name. Sample tf-{cusid}-{app}-{env}')
		choice (name: 'ACTION',
				choices: [ 'plan', 'apply', 'destroy'],
				description: 'Terraform Command plan|apply|destroy')
		string (name: 'PROFILE',
			   defaultValue: 'orionuser',
			   description: 'Optional. Target AWS profile defaults to orionuser')
		string (name: 'EMAIL',
			   defaultValue: 'orion.else.consult@gmail.com',
			   description: 'Optional. Email notification')
    }
	stages {
		stage('Checkout & Environment Prep'){
			steps {
				script {
					wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
						withCredentials([
							[ $class: 'AmazonWebServicesCredentialsBinding',
								accessKeyVariable: 'AWS_ACCESS_KEY_ID',
								secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
								credentialsId: 'Orion-AWS-access',
								]])
							{
							try {
								echo "Setting up Terraform"
								def tfHome = tool name: 'terraform-0.12.17',
									type: 'org.jenkinsci.plugins.terraform.TerraformInstallation'
									env.PATH = "${tfHome}:${env.PATH}"
									currentBuild.displayName += "[$AWS_REGION]::[$ACTION]"
									sh("""
										/usr/local/bin/aws configure --profile ${PROFILE} set aws_access_key_id ${AWS_ACCESS_KEY_ID}
										/usr/local/bin/aws configure --profile ${PROFILE} set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY}
										/usr/local/bin/aws configure --profile ${PROFILE} set region ${AWS_REGION}
										export AWS_PROFILE=${PROFILE}
										export TF_ENV_profile=${PROFILE}
										mkdir -p /home/jenkins/.terraform.d/plugins/linux_amd64
									""")
									tfCmd('version')
							} catch (ex) {
                                echo 'Err: Incremental Build failed with Error: ' + ex.toString()
								currentBuild.result = "UNSTABLE"
							}
						}
					}
				}
			}
		}		
		stage('terraform plan') {
			when { anyOf
					{
						environment name: 'ACTION', value: 'plan';
						environment name: 'ACTION', value: 'apply'
					}
				}
			steps {
				dir("${PROJECT_DIR}") {
					script {
						wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
							withCredentials([
								[ $class: 'AmazonWebServicesCredentialsBinding',
									accessKeyVariable: 'AWS_ACCESS_KEY_ID',
									secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
									credentialsId: 'Orion-AWS-access',
									]])
								{
								try {
									tfCmd('plan', '-detailed-exitcode -out=tfplan')
								} catch (ex) {
									if (ex == 2 && "${ACTION}" == 'apply') {
										currentBuild.result = "UNSTABLE"
									} else if (ex == 2 && "${ACTION}" == 'plan') {
										echo "Update found in plan tfplan"
										sh """
										ls -l tfplan
										"""
									} else {
										echo "Try running terraform again in debug mode"
									}
								}
							}
						}
					}
				}
			}
		}
		stage('terraform apply') {
			when { anyOf
					{
						environment name: 'ACTION', value: 'apply'
					}
				}
			steps {
				dir("${PROJECT_DIR}") {
					script {
						wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
							withCredentials([
								[ $class: 'AmazonWebServicesCredentialsBinding',
									accessKeyVariable: 'AWS_ACCESS_KEY_ID',
									secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
									credentialsId: 'Orion-AWS-access',
									]])
								{
								try {
									tfCmd('apply', 'tfplan')
                                    /*echo "[Apply] tfCmd apply tfplan"*/
								} catch (ex) {
                                    currentBuild.result = "UNSTABLE"
								}
							}
						}
					}
				}
			}
			post {
				always {
					archiveArtifacts artifacts: "keys/key-${ENV_NAME}.*", fingerprint: true
					archiveArtifacts artifacts: "main/show-${ENV_NAME}.txt", fingerprint: true
				}
			}
		}
		stage('terraform destroy') {    
			when { anyOf
					{
						environment name: 'ACTION', value: 'destroy';
					}
				}
			steps {
				script {
					def IS_APPROVED = input(
						message: "Destroy ${ENV_NAME} !?!",
						ok: "Yes",
						parameters: [
							string(name: 'IS_APPROVED', defaultValue: 'No', description: 'To confirm the deletion, type Yes in the box')
						]
					)
					if (IS_APPROVED != 'Yes') {
						currentBuild.result = "ABORTED"
						error "User cancelled"
					}
				}
				dir("${PROJECT_DIR}") {
					script {
						wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
							withCredentials([
								[ $class: 'AmazonWebServicesCredentialsBinding',
									accessKeyVariable: 'AWS_ACCESS_KEY_ID',
									secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
									credentialsId: 'Orion-AWS-access',
									]])
								{
								try {
									tfCmd('destroy', '-auto-approve')
								} catch (ex) {
									currentBuild.result = "UNSTABLE"
								}
							}
						}
					}
				}
			}
		}	
  	}
  post
    {
			always{
			echo "Mail section"
			emailext (
			body: """
				<p>${ENV_NAME} - Jenkins Pipeline ${ACTION} Summary</p>
				<p>Jenkins url: <a href='${env.BUILD_URL}/>link</a></p>
				<p>Pipeline Blueocean： <a href='${env.JENKINS_URL}blue/organizations/jenkins/${env.JOB_NAME}/detail/${env.JOB_NAME}/${env.BUILD_NUMBER}/pipeline'>${env.JOB_NAME}(pipeline page)</a></p>
			${env.JENKINS_URL}blue/organizations/jenkins/${env.JOB_NAME}/detail/${env.JOB_NAME}/${env.BUILD_NUMBER}/pipeline
				<ul>
				<li> Branch built: '${env.BRANCH_NAME}' </li>
				<li> ACTION: $ACTION</li>
				<li> REGION: ${AWS_REGION}</li>
				</ul>
				""",
				recipientProviders: [[$class: 'DevelopersRecipientProvider'], [$class: 'RequesterRecipientProvider']],
				to: "${EMAIL}",
				subject: "[${ENV_NAME}] - ${env.JOB_NAME}-${env.BUILD_NUMBER} [$AWS_REGION][$ACTION]",
				attachLog: true
				)
        }
    }
}
