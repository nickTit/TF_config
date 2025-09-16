variable "region" {
  default = "eu-north-1"
}
variable "secret_key" {
  type = string
}
variable "access_key" {
  type = string
}
variable "availability_zone" {
  type = list(string)
  default = [ "eu-north-1a","eu-north-1b" ] # 1=private
}


variable "private_addresses" {
  type = set(string)
  description = "adresses for private subnet"
  default = [ "172.16.10.0/24", "172.16.11.0/24", "172.16.12.0/24"  ]
}

variable "public_addresses" {
  type = set(string)
  description = "adresses for public subnet"
  default = [ "172.16.0.0/24", "172.16.1.0/24", "172.16.2.0/24"  ]
}