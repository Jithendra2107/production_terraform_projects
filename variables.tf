variable "cidr_vpc" {
  description = "Cidr Block Range for Vpc"
  default     = "10.0.0.0/16"
}

variable "cidr_pub_sub-1" {
  description = "Cidr Block Range for Public Subnet 1"
  default     = "10.0.1.0/24"
}

variable "cidr_pub_sub-2" {
  description = "Cidr Block Range for Public Subnet 2"
  default     = "10.0.2.0/24"
}

variable "cidr_prt_sub-1" {
  description = "Cidr Block Range for Private Subnet 1"
  default     = "10.0.11.0/24"
}

variable "cidr_prt_sub-2" {
  description = "Cidr Block Range for Private Subnet 2"
  default     = "10.0.12.0/24"
}
