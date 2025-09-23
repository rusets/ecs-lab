terraform {
  backend "s3" {
    bucket       = "tf-state-rusets-097635932419"
    key          = "docker-ecs-deployment/infra.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    # encrypt   = true  # при желании
  }
}