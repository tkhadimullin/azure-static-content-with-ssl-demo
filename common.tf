resource "random_string" "storage_suffix" {
  length  = 4
  special = false
}

data "azurerm_dns_zone" "parent_dns_zone" {
  provider            = azurerm.parent
  name                = var.parent_dns_zone
  resource_group_name = "wiseowls-vpn-server"
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-${var.location}-rg"
  location = var.location
}

resource "azurerm_dns_zone" "static" {
  name                = "static.${data.azurerm_dns_zone.parent_dns_zone.name}"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_dns_ns_record" "static" {
  provider            = azurerm.parent
  name                = "static"
  zone_name           = data.azurerm_dns_zone.parent_dns_zone.name
  resource_group_name = "wiseowls-vpn-server"
  ttl                 = 60
  records             = azurerm_dns_zone.static.name_servers
}