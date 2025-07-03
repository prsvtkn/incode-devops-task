terraform {
  required_version = "~> 1.12.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.100" # 6.0 was published ~2w ago, let's use more stable version
    }
  }

  backend "s3" {
    bucket          = ""
    key             = ""
    region          = ""
    dynamodb_table  = "" # This is a depreated parameter and I have to use "use_lockfile", but I have not researched how a bucket can be used to lock state
  }
}

provider "aws" {
  region = "eu-central-1"
}
