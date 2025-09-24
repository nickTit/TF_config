terraform {
  backend "s3" {
    bucket = "backbucket11"
    key = "./terraform.tfstate"
    dynamodb_table = "backend"
    encrypt = true
    region = "eu-north-1"
  }
}

