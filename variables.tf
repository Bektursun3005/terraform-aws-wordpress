variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "Amazon Linux 2 AMI ID for the WordPress EC2 instance (region-specific)."
  type        = string
  default     = "ami-09e6f87a47903347c"
}

variable "instance_type" {
  description = "EC2 instance type for WordPress."
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of an existing EC2 key pair used for SSH access."
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to SSH into the WordPress instance, for example your public IP with /32."
  type        = string
}

variable "db_engine_version" {
  description = "MySQL engine version for RDS."
  type        = string
  default     = "8.0"
}

variable "db_username" {
  description = "Master username for the RDS MySQL instance."
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Master password for the RDS MySQL instance. Pass it with TF_VAR_db_password or a git-ignored terraform.tfvars file."
  type        = string
  sensitive   = true
}
