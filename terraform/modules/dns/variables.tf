variable "domain_name" {
  description = "Domain name (leave empty to skip DNS)"
  type        = string
  default     = ""
}

variable "subdomain" {
  description = "Subdomain for the app"
  type        = string
  default     = "url"
}

variable "alb_dns_name" {
  description = "ALB DNS name"
  type        = string
}

variable "alb_zone_id" {
  description = "ALB zone ID"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}