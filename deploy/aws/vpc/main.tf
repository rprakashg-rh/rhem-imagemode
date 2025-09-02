provider "aws" {
    region = var.region
}

data "aws_availability_zones" "available" {}

locals {
    vpc_cidr        = "10.0.0.0/16"
    stack_name      = var.stack
    azs             = slice(data.aws_availability_zones.available.names, 0, 3)
    priority        = 100
    
    tags = {
        owner: "Ram Gopinathan"
        email: "ram.gopinathan@redhat.com"
        stack: local.stack_name
    }
}