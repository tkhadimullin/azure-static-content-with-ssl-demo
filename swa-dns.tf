resource "azurerm_dns_cname_record" "swa" {
  name                = "swa"
  zone_name           = azurerm_dns_zone.static.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 60
  record              = azurerm_static_site.main.default_host_name
}