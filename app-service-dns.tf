resource "azurerm_dns_cname_record" "app_service" {
  name                = "appservice"
  zone_name           = azurerm_dns_zone.static.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 60
  record              = azurerm_app_service.main.default_site_hostname
}

resource "azurerm_dns_txt_record" "app_service" {
  name                = "asuid.${azurerm_dns_cname_record.app_service.name}"
  zone_name           = azurerm_dns_zone.static.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 60
  record {
    value = azurerm_app_service.main.custom_domain_verification_id
  }
}