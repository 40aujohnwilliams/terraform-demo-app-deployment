# Author: John Williams
# Site: https://github.com/40aujohnwilliams/terraform-demo-app-deployment
# Terraform Deployment Of Demo App

# CIDR Breakdown
# Master CIDR:
#   10.4.0.0/16
# Baby CIDRs:
#  10.4.0.0/19
#  10.4.32.0/19
#  10.4.64.0/19
#  10.4.96.0/19
#  10.4.128.0/19
#  10.4.160.0/19
#  10.4.192.0/19
#  10.4.224.0/19

#-------------------------------------------------------------------------------
# Variables

variable name            { type = "string" }
variable cidr_block      { type = "string" }
variable azs             { type = "list" }
variable public_subnets  { type = "list" }
variable private_subnets { type = "list" }

#-------------------------------------------------------------------------------
# VPC/Environment

module "vpc" {
  source = "git::git@github.com:40aujohnwilliams/vpc.git?ref=1.0.0"

  name            = "${var.name}"
  cidr_block      = "${var.cidr_block}"
  azs             = ["${var.azs}"]
  public_subnets  = ["${var.public_subnets}"]
  private_subnets = ["${var.private_subnets}"]
}
