variable "cluster_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

# This create 2 worker nodes.

variable "node_instance_type" {
  type    = string
  default = "c7i-flex.large"
}

variable "desired_size" {
  type    = number
  default = 4
}
