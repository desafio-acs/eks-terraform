# -----------------------------------------------------
# 1. Componentes Essenciais (Recomendados)
# -----------------------------------------------------

# CORE DNS (Serviço de Descoberta)
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "coredns"
  
  depends_on = [
    aws_eks_cluster.eks_cluster,
  ]
}

# KUBE-PROXY (Gerenciamento de Regras de Rede/IPtables)
resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "kube-proxy"
  
  depends_on = [
    aws_eks_cluster.eks_cluster,
  ]
}

# VPC CNI (Rede do Pod)
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "vpc-cni"
  
  depends_on = [
    aws_eks_cluster.eks_cluster,
  ]
}


# -----------------------------------------------------
# 2. EBS CSI DRIVER (Armazenamento Persistente) e IAM
# -----------------------------------------------------

# 2a. DEFINIÇÃO DA POLICY DE CONFIANÇA (ASSUME ROLE POLICY)
# Permite que o Service Account do EBS CSI Driver (kube-system:ebs-csi-controller-sa)
# assuma esta Role via OIDC.
data "aws_iam_policy_document" "ebs_csi_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      identifiers = [aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer]
      type        = "Federated"
    }
    
    condition {
      test     = "StringEquals"
      # Referência direta ao OIDC Issuer do recurso aws_eks_cluster
      variable = "${aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      # O Service Account específico usado pelo Addon
      variable = "${aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }
  }
}

# 2b. CRIAÇÃO DA ROLE IAM
resource "aws_iam_role" "ebs_csi_role" {
  name               = "${var.project_name}-ebs-csi-role"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role_policy.json
}

# 2c. ANEXAÇÃO DA POLÍTICA GERENCIADA DA AWS
resource "aws_iam_role_policy_attachment" "ebs_csi_attachment" {
  role       = aws_iam_role.ebs_csi_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverServiceRole" 
}

# 2d. CRIAÇÃO DO ADDON E REFERÊNCIA À ROLE
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.eks_cluster.name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi_role.arn
  
  depends_on = [
    aws_eks_cluster.eks_cluster,
    aws_iam_role_policy_attachment.ebs_csi_attachment,
  ]
}
