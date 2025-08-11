variable "domain_name" {
  type        = string
  default     = ""
}

variable "subdomain" {
  type        = string
  default     = "url"
}

variable "alb_dns_name" {
  type        = string
}

variable "alb_zone_id" {
  type        = string
}

variable "tags" {
  type        = map(string)
}