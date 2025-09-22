# 🐳 Dockerized App → AWS EKS + External Secrets (SSM → Pod)

This repo deploys a sample Node.js app to **AWS EKS**. Secrets come from **SSM Parameter Store** via **External Secrets Operator** (ESO) using **IRSA**. No secrets in Terraform state.

## Quick Steps
1. Create SSM parameter:
   ```bash
   aws ssm put-parameter --name "/myapp/APP_MESSAGE" --type "SecureString" --value "Hello from SSM via External Secrets!" --overwrite
   ```
2. Create ECR and push an image:
   ```bash
   cd infra && terraform init
   terraform apply -target=aws_ecr_repository.this -auto-approve
   ECR=$(terraform output -raw ecr_repository_url)
   aws ecr get-login-password --region $(aws configure get region) | docker login --username AWS --password-stdin "$ECR"
   docker build -t myapp:latest ../app
   docker tag myapp:latest "$ECR:latest"
   docker push "$ECR:latest"
   ```
3. Apply the rest (VPC, EKS, ESO):
   ```bash
   terraform apply -auto-approve
   aws eks update-kubeconfig --region $(aws configure get region) --name docker-eks
   ```
4. Create SecretStore/ExternalSecret and deploy app:
   ```bash
   kubectl apply -f ../k8s/external-secrets/clustersecretstore.yaml
   kubectl apply -f ../k8s/external-secrets/externalsecret.yaml
   ../scripts/kubectl_apply.sh "$ECR:latest"
   kubectl get svc -n app -o wide
   ```

Open the EXTERNAL-IP DNS in your browser and check `/health`.
