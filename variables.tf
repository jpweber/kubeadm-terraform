variable "aws_region" {
  type    = "string"
  default = "us-east-2"
}

variable "aws_profile" {
  type    = "string"
  default = ""
}

variable "key_name" {
  type    = "string"
  default = "id_rsa"
}

variable "public_subnet_blocks" {
  type        = "map"
  description = "CIDR blocks for each public subnet of vpc"

  default = {
    "0" = "10.1.1.0/24"
    "1" = "10.1.2.0/24"
    "2" = "10.1.3.0/24"
  }
}

variable "private_subnet_blocks" {
  type        = "map"
  description = "Private subnet of vpc"

  default = {
    "0" = "10.1.4.0/24"
    "1" = "10.1.5.0/24"
    "2" = "10.1.6.0/24"
  }
}

variable "vpc_cidr_block" {
  type        = "string"
  description = "CIRD blocks for vpc"
  default     = "10.1.0.0/16"
}

variable "stage" {
  type    = "string"
  default = "staging"
}

variable "route53_internal_domain" {
  type    = "string"
  default = ""
}

variable "num_public_subnets" {
  default = 3
}

variable "num_private_subnets" {
  type    = "string"
  default = 3
}

variable "max_nodes" {
  type    = "string"
  default = "19"
}

variable "control_plane_num" {
  type    = "string"
  default = 2
}

variable "nodes_num" {
  type    = "string"
  default = 2
}

variable "k8s_token" {
  type = "string"
}

variable "route53_zone_id" {
  type    = "string"
  default = ""
}

variable "route53_elb_cname" {
  type    = "string"
  default = ""
}

variable "ami_id" {
  type = "string"
}
