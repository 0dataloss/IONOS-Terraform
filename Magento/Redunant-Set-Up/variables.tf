variable "IONOS_user" {
  description = "Username for basic authentication of API"
  type = string
  sensitive = true
}

variable "IONOS_password" {
  description = "Password for basic authentication of API"
  type = string
  sensitive = true
}

variable "console_password" {
  description = "Password for root user via console"
  type = string
  sensitive = true
}

variable "ssh_pub_key" {
  description = "Public Key to be added to the VMs"
  type = string
  sensitive = true
}

variable "origin_IP01" {
  description = "Public IP address allowed to connect"
  type = string
  sensitive = true
}