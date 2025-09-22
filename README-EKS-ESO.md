# EKS + External Secrets Operator (SSM → Pod)

- IRSA-bound ESO controller has IAM perms to read SSM Parameter Store and KMS:Decrypt.
- `ClusterSecretStore` points to AWS Parameter Store in your region.
- `ExternalSecret` copies `/myapp/APP_MESSAGE` into K8s Secret `myapp-config`.
- App `Deployment` uses that K8s Secret as env vars.

## Rotate secret
Update SSM value, ESO syncs to K8s automatically within ~1m (configurable).
