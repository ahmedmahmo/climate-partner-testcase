locals {
  name = "notejam"
  environment = "development"
  private_subnets = [
    "172.31.50.0/24",
    "172.31.51.0/24"
  ]
  public_subnets = [
    "172.31.48.0/24",
    "172.31.59.0/24"
  ]
  image_tag = "latest"
}

module "ecr" {
  source = "./modules/ecr"

  name = local.name
  environment = local.environment
}

module "vpc_components" {
  source = "./modules/vpc"

  availability_zones = data.aws_availability_zones.available.names
  environment = local.environment
  internet_gateway_id = data.aws_internet_gateway.this.id
  name = local.name
  private_subnets = local.private_subnets
  public_subnets = local.public_subnets
  vpc_id = data.aws_vpc.this.id
}

module "security_groups" {
  depends_on = [
    module.vpc_components
  ]

  source = "./modules/security_groups"

  container_port = 80
  environment    = local.environment
  name           = local.name
  vpc_id         = data.aws_vpc.this.id
}

module "alb" {
  depends_on = [
    module.vpc_components,
    module.security_groups
  ]

  source = "./modules/alb"
  alb_security_groups = [module.security_groups.alb]
  environment         = local.environment
  name                = local.name
  subnets             = module.vpc_components.public_subnets
  vpc_id              = data.aws_vpc.this.id
}

module "ecs" {
  depends_on = [
    module.alb
  ]
  source = "./modules/ecs"
  aws_alb_target_group_arn = module.alb.aws_alb_target_group_arn
  container_cpu = 256
  container_environment = [
    { name = "ENVIRONMENT",
      value = "development" },
    { name = "PORT",
      value = 80 }
  ]
  container_image = module.ecr.aws_ecr_repository_url
  container_memory = 512
  container_port = 80
  ecs_service_security_groups = [module.security_groups.ecs_tasks]
  environment = local.environment
  name = local.name
  region = var.region
  service_desired_count = 2
  subnets = module.vpc_components.private_subnets
}

module "rds" {
  source = "./modules/rds"

  environment = local.environment
  name        = local.name
  subnets     = module.vpc_components.private_subnets
  username    = local.name
}

output "image" {
  value = module.ecr.aws_ecr_repository_url
}

output "dns" {
  value = module.alb.alb_endpoint
}

output "rds_password" {
  value = module.rds.db_password
  sensitive = true
}