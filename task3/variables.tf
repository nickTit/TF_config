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
  default = "eu-north-1a"
}

variable "public_address" {
  type = list(string)
  default = ["172.16.0.0/24", "172.16.1.0/24", "172.16.2.0/24"]
}