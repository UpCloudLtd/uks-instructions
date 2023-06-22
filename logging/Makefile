.DEFAULT_GOAL := full

.PHONY: init
init:
	( cd terraform ; terraform init )

.PHONY: plan
plan:
	( cd terraform ; terraform plan -var-file="config.tfvars" )

.PHONY: output
output:
	(cd terraform ; terraform output )

.PHONY: apply
apply:
	( cd terraform ; terraform apply -var-file="config.tfvars" )

.PHONY: destroy
destroy:
	( cd terraform ; terraform destroy -var-file="config.tfvars" )
