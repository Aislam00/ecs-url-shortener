variable "domain_name" {
  type        = string
  description = "Domain name for the certificate"
}

variable "hosted_zone_id" {
  type        = string
  description = "Route53 hosted zone ID"
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}