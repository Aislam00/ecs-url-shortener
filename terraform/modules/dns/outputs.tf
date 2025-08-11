output "app_url" {
  description = "Application URL"
  value       = var.domain_name != "" ? "http://${var.subdomain}.${var.domain_name}" : ""
}