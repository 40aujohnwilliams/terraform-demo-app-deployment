# Author: John Williams
# Site: https://github.com/40aujohnwilliams/terraform-demo-app-deployment
# Terraform Deployment Of Demo App

name            = "Terraform Demo App"
cidr_block      = "10.4.0.0/16"
azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnets  = ["10.4.0.0/19", "10.4.32.0/19", "10.4.64.0/19"]
private_subnets = ["10.4.96.0/19", "10.4.128.0/19", "10.4.160.0/19"]
