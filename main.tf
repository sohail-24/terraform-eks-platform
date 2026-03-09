module "vpc" {
  source = "./modules/vpc"

  vpc_cidr     = "10.0.0.0/16"
  project_name = var.project_name

  public_subnet_1_cidr  = "10.0.1.0/24"
  public_subnet_2_cidr  = "10.0.2.0/24"
  private_subnet_1_cidr = "10.0.3.0/24"
  private_subnet_2_cidr = "10.0.4.0/24"
}

module "eks" {
  source = "./modules/eks"

  cluster_name    = "${var.project_name}-eks"
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
}

module "alb_controller" {

  source = "./platform/alb-controller"

  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider     = module.eks.oidc_provider

  vpc_id = module.vpc.vpc_id
}

module "argocd" {

  source = "./platform/argocd"

  cluster_name = module.eks.cluster_name

  depends_on = [
    module.alb_controller
  ]
}
