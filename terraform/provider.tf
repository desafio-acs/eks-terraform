terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.14"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.30"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.0"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.1"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "5.10.1"
    }
  }
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks_cluster.cluster_name
  depends_on = [ module.eks_cluster ]
}

provider "aws" {
  region = var.region
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "kubernetes" {
  host                   = module.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(module.eks_cluster.certificate_authority)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "kubectl" {
  host                   = module.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(module.eks_cluster.certificate_authority)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

provider "helm" {
  kubernetes = {
    host                   = module.eks_cluster.endpoint
    cluster_ca_certificate = base64decode(module.eks_cluster.certificate_authority)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}
