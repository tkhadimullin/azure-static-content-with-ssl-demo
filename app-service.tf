resource "azurerm_container_registry" "acr" {
  name                = "${replace(var.prefix, "/[-_]/", "")}${lower(random_string.storage_suffix.result)}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "null_resource" "build_container" {
  triggers = {
    script_checksum = sha1(join("", [for f in fileset("content", "*") : filesha1("content/${f}")]))
  }
  provisioner "local-exec" { command = "docker login -u ${azurerm_container_registry.acr.admin_username} -p ${azurerm_container_registry.acr.admin_password} ${azurerm_container_registry.acr.login_server}" }
  provisioner "local-exec" { command = "docker build ./content/ -t ${azurerm_container_registry.acr.login_server}/static-site:latest" }
  provisioner "local-exec" { command = "docker push ${azurerm_container_registry.acr.login_server}/static-site:latest" }
  provisioner "local-exec" { command = "docker logout ${azurerm_container_registry.acr.login_server}" }
  depends_on = [
    azurerm_container_registry.acr
  ]
}

resource "azurerm_app_service_plan" "main" {
  name                = "${var.prefix}-asp"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Basic"
    size = "B1"
  }
}

resource "azurerm_app_service" "main" {
  name                = "${var.prefix}-app-svc"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  app_service_plan_id = azurerm_app_service_plan.main.id

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = false
    DOCKER_REGISTRY_SERVER_URL          = azurerm_container_registry.acr.login_server
    DOCKER_REGISTRY_SERVER_USERNAME     = azurerm_container_registry.acr.admin_username
    DOCKER_REGISTRY_SERVER_PASSWORD     = azurerm_container_registry.acr.admin_password
  }

  site_config {
    linux_fx_version = "DOCKER|${azurerm_container_registry.acr.name}.azurecr.io/static-site:latest"
    always_on        = "true"
  }

  depends_on = [
    null_resource.build_container
  ]
}

resource "azurerm_app_service_custom_hostname_binding" "main" {
  hostname            = trim(azurerm_dns_cname_record.app_service.fqdn, ".")
  app_service_name    = azurerm_app_service.main.name
  resource_group_name = azurerm_resource_group.main.name
  depends_on          = [azurerm_dns_txt_record.app_service]

  # Ignore ssl_state and thumbprint as they are managed using
  # azurerm_app_service_certificate_binding.main
  lifecycle {
    ignore_changes = [ssl_state, thumbprint]
  }
}

resource "azurerm_app_service_managed_certificate" "main" {
  custom_hostname_binding_id = azurerm_app_service_custom_hostname_binding.main.id
}

resource "azurerm_app_service_certificate_binding" "example" {
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.main.id
  certificate_id      = azurerm_app_service_managed_certificate.main.id
  ssl_state           = "SniEnabled"
}