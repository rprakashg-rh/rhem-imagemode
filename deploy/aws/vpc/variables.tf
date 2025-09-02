variable "my_ip" {
    description = "IP Address block of current local machine"
    type = string
    default = "136.27.40.26/32"    
}

variable "stack" {
  description = "name"
  type = string
  default = "edge_network"
}

variable "region" {
  description = "AWS region"
  type = string
  default = "us-west-2"
}