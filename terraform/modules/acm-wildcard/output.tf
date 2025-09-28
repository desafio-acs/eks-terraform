output "wildcard_certificate_arn" {
  description = "ARN do certificado ACM wildcard"
  value       = aws_acm_certificate.wildcard.arn
}
