variable "secret_key" {
  type = string
  sensitive = true
}
variable "access_key" {
  type = string
  default = "AKIAS4NLLIVVNRCNKJ4D"
}
variable "region" {
  type = string
  default = "eu-central-1"
}
# The default VPC
variable "vpc_id" {
  type = string
  default = "vpc-0f8f8e6d696058c1b"
}