output "instance_url" {
  value = "http://${azurerm_public_ip.myterraformpublicip.ip_address}:${var.instance_port}"
  #value = "http://${data.azurerm_public_ip.example.ip_address}:${var.instance_port}"
}
