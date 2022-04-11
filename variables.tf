variable "location" {
  type        = string
  description = "Azure Region Location"
}

variable "prefix" {
  type        = string
  description = "Project prefix"
}

variable "subscription_id" {
  type = string
}

variable "parent_dns_zone" {
  type = string
}

variable "parent_subscription_id" {
  type = string
}
