
variable "region" {
 type = string
 default = "eu-west-1"
 description = "This is a description!"  
}

variable "cidr_block" {
  type = string
  description = "VPC CIDR Block"
}

variable "subnet_cidr" {
}

variable "subnet_p_cidr"{
    
}

variable "private_ips" {
  type = list(string)
  description = "Web Instance Private IP address"
}

variable "image_id" {
  type = string
  
}