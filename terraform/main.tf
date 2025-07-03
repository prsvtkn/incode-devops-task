module "network" {
  source = "./modules/network"

  aws_region               = var.aws_region
  vpc_cidr                 = var.vpc_cidr
  private_subnets_cidrs    = var.private_subnets_cidrs
  public_subnets_cidrs     = var.public_subnets_cidrs
  availability_zones       = var.availability_zones
  listener_certificate_arn = var.listener_certificate_arn

  common_tags = var.common_tags
}

module "iam" {
  source = "./modules/iam"

  aws_region              = var.aws_region

  common_tags = var.common_tags

}

module "ecr" {
  source = "./modules/ecr"

  image_tag_mutability = var.image_tag_mutability
  repository_names     = var.repository_names

  common_tags = var.common_tags

  depends_on = [
    module.iam,
    module.network
  ]
}

module "fargate" {
  source = "./modules/fargate"

  aws_region        = var.aws_region
  retention_in_days = var.fargate_logs_retention

  common_tags = var.common_tags

  depends_on = [
    module.iam,
    module.network
  ]
}

module "aurora-postgresql" {
  source = "./modules/aurora-postgresql"

  aws_region                     = var.aws_region
  vpc_id                         = module.network.vpc_id
  cluster_identifier             = var.cluster_identifier
  database_name                  = var.database_name
  db_subnet_group_name           = var.db_subnet_group_name
  availability_zones             = var.availability_zones
  aurora_cluster_members         = var.aurora_cluster_members
  aurora_cluster_master_username = var.aurora_cluster_master_username

  common_tags = var.common_tags

  depends_on = [
    module.iam,
    module.network
  ]
}
