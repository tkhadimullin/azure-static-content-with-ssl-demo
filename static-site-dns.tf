resource "azurerm_dns_cname_record" "static" {
  name                = "storage-account"
  zone_name           = azurerm_dns_zone.static.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 60
  record              = azurerm_cdn_endpoint.main.host_name
}

resource "azurerm_dns_cname_record" "static_cdnverify" {
  name                = "cdnverify.storage-account"
  zone_name           = azurerm_dns_zone.static.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 60
  record              = "cdnverify.${azurerm_cdn_endpoint.main.host_name}"
}