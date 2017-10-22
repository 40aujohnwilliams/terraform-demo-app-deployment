# Author: John Williams
# Site: https://github.com/40aujohnwilliams/terraform-demo-app-deployment
# Terraform Deployment Of Demo App

provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "sample-remote-state-terraform-demo"
    key    = "demo-app"
    region = "us-east-1"
  }
}
