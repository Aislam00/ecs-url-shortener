terraform {
  backend "s3" {
    bucket         = "ecs-url-shortener-global-terraform-state-14a6817b"
    key            = "envs/dev/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "ecs-url-shortener-global-terraform-lock"
    encrypt        = true
  }
}
