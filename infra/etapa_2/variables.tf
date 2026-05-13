variable "aws_region" {
  default = "us-east-1"
}

variable "project_name" {
  default = "devops-parcial2"
}

variable "key_pair_name" {}

variable "db_password" {
  sensitive = true
}
