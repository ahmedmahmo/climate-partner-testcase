data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}
data "aws_vpc" "this" {
  id = var.vpc_id
}
data "aws_internet_gateway" "this" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.this.id]
  }
}