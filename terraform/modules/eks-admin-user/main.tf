# -----------------------------------------------------------
# Configuração do Provedor Kubernetes
# -----------------------------------------------------------

# Pega as informações de endpoint do cluster EKS
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

# Pega o token de autenticação para o cluster EKS
data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

# Configura o provedor Kubernetes usando as credenciais do cluster EKS
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# -----------------------------------------------------------
# Criação de Usuários IAM
# -----------------------------------------------------------

# Cria usuários IAM com base na variável 'users'
resource "aws_iam_user" "eks_admin" {
  for_each      = { for u in var.users : u.name => u }
  name          = each.value.name
  path          = lookup(each.value, "path", "/")
  force_destroy = lookup(each.value, "force_destroy", false)
}

# -----------------------------------------------------------
# Criação de Access Key para CLI/API
# -----------------------------------------------------------

resource "aws_iam_access_key" "eks_admin_key" {
  for_each = aws_iam_user.eks_admin
  user     = each.value.name
}

# -----------------------------------------------------------
# 1. Permissão de Acesso ao Control Plane (IAM Policy)
# (Resolve o erro do 'aws eks update-kubeconfig')
# -----------------------------------------------------------

# Anexa a política INLINE com as permissões EKS de leitura/administração que você especificou.
resource "aws_iam_user_policy" "eks_user_control_plane_access" {
  for_each = aws_iam_user.eks_admin
  name     = "${each.value.name}-eks-read-admin-access-samuel"
  user     = each.value.name

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "eks:ListEksAnywhereSubscriptions",
          "eks:ListDashboardData",
          "eks:DescribeFargateProfile",
          "eks:ListTagsForResource",
          "eks:DescribeInsight",
          "eks:ListAccessEntries",
          "eks:ListAddons",
          "eks:DescribeEksAnywhereSubscription",
          "eks:DescribeAddon",
          "eks:DescribeInsightsRefresh",
          "eks:ListAssociatedAccessPolicies",
          "eks:DescribeNodegroup",
          "eks:ListDashboardResources",
          "eks:ListUpdates",
          "eks:DescribeAddonVersions",
          "eks:ListIdentityProviderConfigs",
          "eks:ListNodegroups",
          "eks:DescribeAddonConfiguration",
          "eks:DescribeAccessEntry",
          "eks:DescribePodIdentityAssociation",
          "eks:ListInsights",
          "eks:DescribeClusterVersions",
          "eks:ListPodIdentityAssociations",
          "eks:ListFargateProfiles",
          "eks:DescribeIdentityProviderConfig",
          "eks:DescribeUpdate",
          "eks:AccessKubernetesApi",
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:ListAccessPolicies"
        ],
        "Resource" : "*"
      }
    ]
  })
}


# -----------------------------------------------------------
# 2. Permissão de Acesso ao Data Plane (aws-auth ConfigMap)
# (Resolve o erro "configmaps already exists")
# -----------------------------------------------------------

# LER o ConfigMap aws-auth existente
data "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
}

# CALCULAR o novo conteúdo de 'mapUsers'
locals {
  # 1. Lista dos novos usuários IAM para adicionar (system:masters)
  new_map_users_list = [
    for u in aws_iam_user.eks_admin :
    {
      userarn  = u.arn
      username = u.name
      groups   = ["system:masters"]
    }
  ]
    
  # 2. Decodifica a lista de mapUsers existente (ou lista vazia se não existir)
  existing_map_users = yamldecode(
    try(data.kubernetes_config_map.aws_auth.data["mapUsers"], "[]")
  )
    
  # 3. Combina as listas existente e nova
  combined_map_users = concat(local.existing_map_users, local.new_map_users_list)

  # 4. CRIA UM MAPA para remover duplicados, usando 'userarn' como chave única.
  unique_map_users_map = {
    for user in local.combined_map_users : user.userarn => user...
  }

  # 5. Volta para uma lista apenas com entradas únicas (os VALORES do mapa).
  final_map_users_list = values(local.unique_map_users_map)
  
  # 6. Codifica em YAML
  final_map_users_yaml = yamlencode(local.final_map_users_list)
}

# ATUALIZA A CHAVE 'mapUsers' no ConfigMap existente
# O recurso kubernetes_config_map_v1_data faz um PATCH, evitando o erro de criação.
resource "kubernetes_config_map_v1_data" "aws_auth_update" {
  force     = true 
  
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapUsers = local.final_map_users_yaml
  }

  field_manager = "terraform"
  
  depends_on = [
    aws_iam_user.eks_admin,
    data.kubernetes_config_map.aws_auth,
  ]
}
