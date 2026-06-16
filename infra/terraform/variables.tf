variable "aws_region" {
  description = "Region de AWS donde se despliega la infraestructura"
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre base del proyecto usado como prefijo en todos los recursos"
  default     = "devops-parcial2"
}

variable "vpc_cidr" {
  description = "Bloque CIDR de la VPC"
  default     = "10.0.0.0/16"
}

variable "subnet_1_cidr" {
  description = "Bloque CIDR de la subnet en AZ a"
  default     = "10.0.10.0/24"
}

variable "subnet_2_cidr" {
  description = "Bloque CIDR de la subnet en AZ b"
  default     = "10.0.20.0/24"
}

variable "node_instance_type" {
  description = "Tipo de instancia para los nodos del cluster EKS"
  default     = "t3.medium"
}

variable "node_desired_size" {
  description = "Cantidad deseada de nodos en el Node Group"
  default     = 2
}

variable "node_max_size" {
  description = "Cantidad maxima de nodos en el Node Group"
  default     = 2
}

variable "node_min_size" {
  description = "Cantidad minima de nodos en el Node Group"
  default     = 1
}
