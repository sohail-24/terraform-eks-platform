############################################
# VPC
############################################

module "vpc" {

  source = "./modules/vpc"

  vpc_cidr     = "10.0.0.0/16"
  project_name = var.project_name

  public_subnet_1_cidr  = "10.0.1.0/24"
  public_subnet_2_cidr  = "10.0.2.0/24"
  private_subnet_1_cidr = "10.0.3.0/24"
  private_subnet_2_cidr = "10.0.4.0/24"
}

############################################
############################################
# EKS
############################################

module "eks" {
  source = "./modules/eks"

  cluster_name       = "${var.project_name}-eks"
  vpc_id             = module.vpc.vpc_id
  private_subnets    = module.vpc.private_subnets
  node_instance_type = "t2.medium"
  desired_size       = 4
  node_disk_size     = 20

  depends_on = [
    module.vpc
  ]
}


############################################
# ALB Controller
############################################

module "alb_controller" {

  source = "./platform/alb-controller"

  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider     = module.eks.oidc_provider

  vpc_id = module.vpc.vpc_id

  depends_on = [
    module.eks
  ]
}

############################################
# ArgoCD
############################################

module "argocd" {

  source = "./platform/argocd"

  cluster_name = module.eks.cluster_name

  depends_on = [
    module.alb_controller
  ]
}

############################################
# S3 Media Bucket
############################################

module "django_media_s3" {

  source = "./modules/s3"

  bucket_name = "sohail-django-media-2026-001"
}

############################################
# IAM (IRSA)
############################################

module "iam" {

  source = "./modules/iam"

  cluster_name = module.eks.cluster_name
  bucket_name  = "sohail-django-media-2026-001"

  depends_on = [
    module.eks
  ]
}

############################################
# EBS CSI (TEMPORARILY DISABLED)
############################################

#module "ebs_csi" {
#  source = "./platform/ebs-csi"

#  oidc_provider_arn = module.eks.oidc_provider_arn
#}

############################################
# 🔥 CLEANUP BEFORE DESTROY (VERY IMPORTANT) (DISABLED - HANDLED BY destroy.yml)
############################################

#resource "null_resource" "cleanup_k8s" {

#  provisioner "local-exec" {
#    when = destroy
#    command = <<EOT
#echo "🔥 Deleting ArgoCD App..."
#kubectl delete application django-ecommerce -n argocd --ignore-not-found=true

#echo "🔥 Deleting ecommerce namespace..."
#kubectl delete namespace ecommerce --ignore-not-found=true

#echo "⏳ Waiting for AWS Load Balancer cleanup..."
#sleep 120
#EOT
#  }

#  depends_on = [
#    module.argocd
#  ]
#}


