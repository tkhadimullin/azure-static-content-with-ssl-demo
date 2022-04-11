resource "azurerm_static_site" "main" {
  name                = "${var.prefix}-swa"
  resource_group_name = azurerm_resource_group.main.name
  location            = "eastus2" //'westus2,centralus,eastus2,westeurope,eastasia'
}

resource "azurerm_static_site_custom_domain" "main" {
  static_site_id  = azurerm_static_site.main.id
  domain_name     = "${azurerm_dns_cname_record.swa.name}.${azurerm_dns_cname_record.swa.zone_name}"
  validation_type = "cname-delegation"
}

resource "null_resource" "publish_swa" {
  triggers = {
    script_checksum = sha1(join("", [for f in fileset("content", "*") : filesha1("content/${f}")]))
  }
  provisioner "local-exec" {
    working_dir = path.module
    interpreter = ["bash", "-c"]
    command     = <<EOT
docker run --rm -e INPUT_AZURE_STATIC_WEB_APPS_API_TOKEN=${azurerm_static_site.main.api_key} -e DEPLOYMENT_PROVIDER=DevOps -e GITHUB_WORKSPACE=/working_dir -e INPUT_APP_LOCATION=. -v `pwd`/content:/working_dir mcr.microsoft.com/appsvc/staticappsclient:stable ./bin/staticsites/StaticSitesClient upload --verbose true
EOT
  }
  depends_on = [
    azurerm_static_site.main
  ]
}

