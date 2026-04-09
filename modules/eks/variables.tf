variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the EKS cluster"
  type        = string
}

variable "private_subnets" {
  description = "Private subnet IDs for EKS nodes"
  type        = list(string)
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS worker nodes"
  type        = string
  default     = "t2.medium"
}

variable "desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 4
}

variable "node_disk_size" {
  description = "Disk size (GB) for EKS worker nodes"
  type        = number
  default     = 20
}
