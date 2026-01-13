#Set required provider and its version
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.25.0"
    }
  }

  required_version = ">= 1.5.0"

}

provider "aws" {
  region     = "us-west-2"
  #token = 1234567890 #placeholder for authentication token
}