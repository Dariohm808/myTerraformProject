provider "aws" {
  profile = "default"
  region  = "us-east-2"

  default_tags {
    tags = {
      Environment     = "Test"
      Service         = "Example"
      HashiCorp-Learn = "aws-default-tags"
    }
  }
}