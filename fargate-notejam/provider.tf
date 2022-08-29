terraform {
  required_version = ">= 0.13.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.22"
    }
  }

  backend "s3" {
    bucket = "tf-state-fargate-notejam"
    region = "eu-central-1"
    key = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}