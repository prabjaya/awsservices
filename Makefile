.PHONY: help init plan apply destroy docker-build docker-run clean

help:
	@echo "Available commands:"
	@echo "  make init          - Initialize Terraform"
	@echo "  make plan          - Run Terraform plan"
	@echo "  make apply         - Apply Terraform changes"
	@echo "  make destroy       - Destroy infrastructure"
	@echo "  make docker-build  - Build Docker image"
	@echo "  make docker-run    - Run Docker container locally"
	@echo "  make clean         - Clean temporary files"

init:
	cd infrastructure && terraform init

plan:
	cd infrastructure && terraform plan -var="db_password=$(DB_PASSWORD)"

apply:
	cd infrastructure && terraform apply -var="db_password=$(DB_PASSWORD)"

destroy:
	cd infrastructure && terraform destroy -var="db_password=$(DB_PASSWORD)"

docker-build:
	cd application && docker build -t python-microservice:latest .

docker-run:
	docker run -p 8000:8000 \
		-e DATABASE_URL="$(DATABASE_URL)" \
		-e AUDIT_LAMBDA_NAME="$(AUDIT_LAMBDA_NAME)" \
		-e AWS_REGION="$(AWS_REGION)" \
		python-microservice:latest

clean:
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	find . -type f -name "*.pyo" -delete
	cd infrastructure && rm -rf .terraform tfplan
