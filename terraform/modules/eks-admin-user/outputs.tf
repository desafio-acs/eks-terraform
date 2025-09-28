output "eks_admin_users" {
  value = aws_iam_user.eks_admin
}

output "aws_auth_config_map_name" {
  # REFERÊNCIA CORRIGIDA: Usa kubernetes_config_map_v1_data
  # O nome do ConfigMap é um atributo de nível superior, não dentro de metadata[0]
  # No entanto, o bloco metadata[0] ainda está presente no recurso v1_data.
  value = kubernetes_config_map_v1_data.aws_auth_update.metadata[0].name
}

output "aws_auth_config_map_data" {
  # REFERÊNCIA CORRIGIDA: Usa kubernetes_config_map_v1_data
  value = kubernetes_config_map_v1_data.aws_auth_update.data
}

# -----------------------------------------------------------
# NOVOS OUTPUTS para a Access Key
# -----------------------------------------------------------

output "eks_admin_access_keys" {
  description = "Access keys para os usuários criados. Use estas credenciais para configurar o AWS CLI."
  value = {
    for name, key in aws_iam_access_key.eks_admin_key : name => {
      access_key_id     = key.id
      # A secret_key é SENSÍVEL e só é mostrada UMA vez.
      secret_access_key = key.secret
      user_name         = key.user
    }
  }
  # Marque o output como sensível para ocultar a Secret Key de logs não confidenciais.
  sensitive = true
}