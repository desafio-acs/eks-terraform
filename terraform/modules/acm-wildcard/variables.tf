variable "cloudflare_zone_id" {
  description = "ID da zona Cloudflare do domínio"
  type        = string
}

variable "tags" {
  type        = map(any)
  description = "Tags to be added to AWS resources"
}
