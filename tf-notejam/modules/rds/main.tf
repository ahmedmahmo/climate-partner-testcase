variable "name" {}
variable "environment" {}
variable "username" {}
variable "subnets" {}

resource "random_password" "db" {
  length = 10
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.name}-${var.environment}-subnet-group"
  subnet_ids = var.subnets.*.id

  tags = {
    Name = "${var.name}-${var.environment}"
  }
}

resource "aws_db_instance" "main" {
  allocated_storage     = 10
  max_allocated_storage = 20
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  name                 = var.name
  username             = var.username
  password             = random_password.db.result
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.main.name
}

output "db_password" {
  value = random_password.db.result
}