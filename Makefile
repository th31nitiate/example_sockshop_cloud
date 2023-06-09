## Ensure to chaneg terraform project details
GCLOUD_PROJECT=peppy-glyph-388514
GCLOUD_CMD=$(shell which gcloud)
TERRAFORM_CMD=$(shell which terraform)
WORKING_DIR=$(shell pwd)
KUBERNETERS_DIR=$(WORKING_DIR)/kubernetes
DOCKER_DIR=$(WORKING_DIR)/docker
TERRAFORM_DIR=$(WORKING_DIR)/terraform
GOLANG_DIR=$(WORKING_DIR)/golang
CRED_HELPER=credential.https://source.developers.google.com.helper gcloud.sh
DOCKER_GIT=git -C $(DOCKER_DIR)
KUBERNETERS_GIT=git -C $(KUBERNETERS_DIR)
REPO_BASE_URL=https://source.developers.google.com/p
CLOUD_FUNC_BUCKET=monitor-test-590932908
CLOUD_FUNC_FILE=gocode4345at.zip


deploy_all: upload_cloud_funcation import_containers deploy_ingress init_push_kube_repo

test_env:
	echo $(GCLOUD_PROJECT)


# Ensure the gcloud command is installed & authenticated also enable need API
init_environment:
	$(GCLOUD_CMD) init
	gcloud services enable run.googleapis.com
	gcloud services enable sourcerepo.googleapis.com
	gcloud services enable pubsub.googleapis.com
	gcloud services enable eventarc.googleapis.com
	gcloud services enable container.googleapis.com
	gcloud services enable cloudbuild.googleapis.com
	gcloud services enable artifactregistry.googleapis.com
	gcloud services enable cloudbuild.googleapis.com
	gcloud services enable cloudfunctions.googleapis.com
	gcloud services enable secretmanager.googleapis.com
	git config --global $(CRED_HELPER)
	git config --global init.defaultBranch main


# Prepare the cloud funcation and upload it seprately. Many methods
# for deploying funcation this most convient in this instence
upload_cloud_funcation:
	gcloud storage buckets create --no-public-access-prevention gs://$(CLOUD_FUNC_BUCKET)
	gcloud storage buckets add-iam-policy-binding --member=allAuthenticatedUsers --role=roles/storage.objectViewer gs://$(CLOUD_FUNC_BUCKET)
	zip -j -r -9 $(CLOUD_FUNC_FILE) $(GOLANG_DIR)
	export TF_VAR_cloud_func_bucket=$(CLOUD_FUNC_BUCKET)
	export TF_VAR_cloud_func_file=$(CLOUD_FUNC_FILE)
	gsutil cp $(CLOUD_FUNC_FILE) gs://$(CLOUD_FUNC_BUCKET)


# We deploy the ingress diffirently to demonstrate usage of diffirent deployment methods
deploy_ingress:
	@sleep 5
	gcloud builds submit --config kubernetes/nginx_ingress/deploy_ingress.yaml


# Deploy kubernetes code to repo. This triggers a cloud event to pereform a build
init_push_kube_repo:
	@sleep 5
	$(KUBERNETERS_GIT) init
	$(KUBERNETERS_GIT) remote add google "$(REPO_BASE_URL)/$(GCLOUD_PROJECT)/r/kube_charts"
	$(KUBERNETERS_GIT) add .
	$(KUBERNETERS_GIT) commit -m 'Initial commit'
	$(KUBERNETERS_GIT) push --all google


# This push the code to git repo and trigger cloud event to perform a build
import_containers: terraform_apply
	sleep 5
	$(DOCKER_GIT) init
	$(DOCKER_GIT) remote add google "$(REPO_BASE_URL)/$(GCLOUD_PROJECT)/r/docker_files"
	$(DOCKER_GIT) add .
	$(DOCKER_GIT) commit -m 'Initial commit'
	$(DOCKER_GIT) push --all google


# Initilize then apply terraform
terraform_init:
	$(TERRAFORM_CMD) -chdir=$(TERRAFORM_DIR) init

terraform_apply: terraform_init
	TF_VAR_cloud_func_bucket=$(CLOUD_FUNC_BUCKET) TF_VAR_cloud_func_file=$(CLOUD_FUNC_FILE) $(TERRAFORM_CMD) -chdir=$(TERRAFORM_DIR) apply

terraform_destroy:
	TF_VAR_cloud_func_bucket=$(CLOUD_FUNC_BUCKET) TF_VAR_cloud_func_file=$(CLOUD_FUNC_FILE) $(TERRAFORM_CMD) -chdir=$(TERRAFORM_DIR) destroy

apply_tf: terraform_init terraform_plan terraform_apply

clean:
	@ rm -rf dist
