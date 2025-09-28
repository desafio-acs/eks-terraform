variable "cluster_name" {
  type        = string
  description = "Nome do cluster EKS"
}

variable "users" {
  type = list(object({
    name          = string
    path          = optional(string, "/")
    force_destroy = optional(bool, false)
  }))
  description = "Lista de usuários IAM a criar e adicionar como admins no Kubernetes"
}

variable "tags" {
  type        = map(any)
  description = "Tags to be added to AWS resources"
}
