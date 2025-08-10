terraform {
  backend "s3" {
    bucket         = "ecs-url-shortener-global-terraform-state-11e19a9a"
    key            = "envs/dev/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "ecs-url-shortener-global-terraform-lock"
    encrypt        = true
  }
}