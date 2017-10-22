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
# VPC/Environment for Demo App

module "vpc" {
  source = "git::git@github.com:40aujohnwilliams/vpc.git?ref=1.0.0"

  name            = "${var.name}"
  cidr_block      = "${var.cidr_block}"
  azs             = ["${var.azs}"]
  public_subnets  = ["${var.public_subnets}"]
  private_subnets = ["${var.private_subnets}"]
}

#-------------------------------------------------------------------------------
# SSH Public Key for Demo App

resource "aws_key_pair" "deploy_key" {
  key_name_prefix = "terraformdemo-"
  public_key      = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDRKrb/3Q/WNRiRY9LdA6/njxfqLiExp7bBZr3tNn4OpkQ1G852P8D3m3pjTuMY8EK4tEo6rNm5Pc6U+2CHzpZtC4sokFrN8yvgsZ/MKmDz1TBFYT6MtziKMTrOHrB3Ah6dWdr2CtV8dKqxQsBmBmxbI0dXzgnn5+XSKXUznvwUtuip0ZgBH3MXMW01egeOxWR+ooNIB9FGuo981T0IOEFoqfDH6UjZnP9PofzrGibU62e302XVPfLMD41yjkF7eatu8ng8ZeXG6nEZFRmwcChNgJ8Yx6SKYOElV2SAm4V52Jp8++gcozDqWzqVvZqyJodaR6QqltPaQPCXAlB9jAVAWkBOLNrYNJBbv1pj3K2YMttTOoeaII7TR0ZBU02SBtzTwkEBSQnvauKoV1PlTa/uVXjiVHNt8sTXJVxHUnj1jecNdZ2iGLPlAu2+RBWH/HFuk7GAO4uf+gzp25CqsYyluusgnkOXClBHRYb5hJpRZdge8r7O5NadcM7yc7N3VA6LqROp09hlntBQHF5bM1LH4L/y5+tdliUuam6zhxpMeFaVmX4EqAGlODXeZ3ZR1r70CJhpTlbS7llPLKptQJ0DlhKf2aM9cpEc+TabE/zAvbcoXiY+ZB7jMjb4ZcBTQNT7C21DiedOzt8mxlgnpsdE1IooRuQMDrtmfPzpJoOeIw=="
}

#-------------------------------------------------------------------------------
# Security Groups for Demo App

resource "aws_default_security_group" "default" {
  vpc_id = "${module.vpc.vpc}"

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name      = "${var.name} Default Security Group"
    terraform = true
  }
}

resource "aws_security_group" "ssh" {
  vpc_id = "${module.vpc.vpc}"

  name        = "${var.name} SSH from World"
  description = "${var.name} SSH from World"

  tags {
    Name      = "${var.name} SSH from World"
    terraform = true
  }
}

resource "aws_security_group_rule" "ssh_from_world" {
  security_group_id = "${aws_security_group.ssh.id}"
  type            = "ingress"
  from_port       = 22
  to_port         = 22
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ssh_allow_all_outbound" {
  security_group_id = "${aws_security_group.ssh.id}"
  type            = "egress"
  from_port       = 0
  to_port         = 65535
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
}

resource "aws_security_group" "http" {
  vpc_id = "${module.vpc.vpc}"

  name        = "${var.name} HTTP from World"
  description = "${var.name} HTTP from World"

  tags {
    Name      = "${var.name} HTTP from World"
    terraform = true
  }
}

resource "aws_security_group_rule" "http_from_world" {
  security_group_id = "${aws_security_group.http.id}"
  type            = "ingress"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "http_allow_all_outbound" {
  security_group_id = "${aws_security_group.http.id}"
  type            = "egress"
  from_port       = 0
  to_port         = 65535
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
}

#-------------------------------------------------------------------------------
# Launch Configuration for Demo App

data "aws_ami" "demo_app" {
  most_recent = true

  filter {
    name   = "name"
    values = ["terraform-demo-app-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["295732248240"]
}

resource "aws_launch_configuration" "demo_app" {
  name_prefix     = "Terraform Demo App "
  image_id        = "${data.aws_ami.demo_app.id}"
  instance_type   = "t2.micro"
  key_name        = "${aws_key_pair.deploy_key.key_name}"
  security_groups = ["${aws_default_security_group.default.id}",
                     "${aws_security_group.ssh.id}",
                     "${aws_security_group.http.id}"]

  lifecycle {
    create_before_destroy = true
  }
}

#-------------------------------------------------------------------------------
# Autoscaling Group for Demo App

resource "aws_autoscaling_group" "demo_app" {
  name_prefix = "Demo App "
  launch_configuration = "${aws_launch_configuration.demo_app.name}"
  min_size = 3
  max_size = 3
  vpc_zone_identifier = ["${module.vpc.public_subnets}"]
  load_balancers = ["${aws_elb.demo_app.name}"]

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key = "Name"
    value = "Demo App"
    propagate_at_launch = true
  }

  tag {
    key = "terraform"
    value = true
    propagate_at_launch = true
  }
}

#-------------------------------------------------------------------------------
# Load Balancer for Demo App

resource "aws_elb" "demo_app" {
  name_prefix = "Demo"
  subnets = ["${module.vpc.public_subnets}"]
  security_groups = ["${aws_default_security_group.default.id}",
                     "${aws_security_group.http.id}"]

  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  tags {
    Name = "Demo App Load Balancer"
    terraform = true
  }
}
