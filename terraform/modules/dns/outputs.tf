output "app_url" {
  value       = var.domain_name != "" ? "http://${var.subdomain}.${var.domain_name}" : ""
}