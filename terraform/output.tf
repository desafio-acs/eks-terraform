# output "oidc" {
#   value = module.eks_cluster.oidc
# }

# output "ca" {
#   value = module.eks_cluster.certificate_authority
# }

# output "endpoint" {
#   value = module.eks_cluster.endpoint
# }

output "admin_user_keys" {
  description = "Access Key e Secret Key para o usuário admin do EKS."
  value       = module.eks_admin_users.eks_admin_access_keys
  sensitive   = true
}

output "wildcard_certificate_arn" {
  description = "ARN do certificado wildcard do módulo"
  value       = module.acm_wildcard.wildcard_certificate_arn
}
