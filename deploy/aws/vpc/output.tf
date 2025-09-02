output "vpc_id" {
    description = "VPC ID"
    value = module.vpc.default_vpc_id
}

output "public_subnets" {
    description = "VPC Public subnets"
    value = "${module.vpc.public_subnets}"
}

output "public_subnet_security_groups" {
    description = "VPC Public subnet's security groups"
    value = "${module.public_subnet_sg}"
}

output "private_subnet_security_groups" {
    description = "VPC Private subnet's security groups"
    value = "${module.private_subnet_sg}"
}