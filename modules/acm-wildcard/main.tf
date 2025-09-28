terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.10"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

resource "aws_acm_certificate" "wildcard" {
  # FUNÇÃO: Cria o recurso do certificado SSL/TLS no AWS Certificate Manager.
  # ESTE RECURSO DEVE PERMANECER DESCOMENTADO.
  domain_name       = "*.thesams.site" 
  validation_method = "DNS"
  subject_alternative_names = ["thesams.site"] 

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}


# BLOCos COMENTADOS: SOLUÇÃO PARA CONFLITO DE CERTIFICADO JÁ VALIDADO

# O certificado já foi validado na AWS Console. O Terraform estava falhando ao tentar
# recriar estes CNAMEs. Comentar estes blocos impede a tentativa de recriação.

/*
resource "cloudflare_dns_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.wildcard.domain_validation_options : dvo.domain_name => dvo
  }

  zone_id = var.cloudflare_zone_id
  name    = trimsuffix(each.value.resource_record_name, ".${each.value.domain_name}.")
  type    = each.value.resource_record_type
  content = each.value.resource_record_value
  ttl     = 60 
  proxied = false
}
*/

/*
resource "aws_acm_certificate_validation" "wildcard" {
  certificate_arn = aws_acm_certificate.wildcard.arn

  validation_record_fqdns = [
    for dvo in aws_acm_certificate.wildcard.domain_validation_options : dvo.resource_record_name
  ]

  # O depends_on foi comentado junto com o recurso 'cloudflare_dns_record.validation'.
  # depends_on = [cloudflare_dns_record.validation] 
}
*/