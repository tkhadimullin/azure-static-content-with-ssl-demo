resource "azurerm_storage_account" "main" {
  name                     = "${replace(var.prefix, "/[-_]/", "")}${lower(random_string.storage_suffix.result)}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  static_website {
    index_document = "index.html"
  }
}

resource "azurerm_storage_blob" "main" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.main.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html"
  source                 = "./content/index.html"
}

resource "azurerm_cdn_profile" "main" {
  name                = "${var.prefix}-cdn-profile"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard_Microsoft"
}

resource "azurerm_cdn_endpoint" "main" {
  name                = "${var.prefix}-cdn-endpoint"
  profile_name        = azurerm_cdn_profile.main.name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  origin {
    name      = azurerm_storage_account.main.name
    host_name = azurerm_storage_account.main.primary_web_host
  }
}

resource "azurerm_cdn_endpoint_custom_domain" "main" {
  name            = "storage-account"
  cdn_endpoint_id = azurerm_cdn_endpoint.main.id
  host_name       = "${azurerm_dns_cname_record.static.name}.${azurerm_dns_zone.static.name}"
  depends_on = [
    azurerm_dns_cname_record.static
  ]

  cdn_managed_https {
    protocol_type    = "ServerNameIndication"
    certificate_type = "Dedicated"
  }
}