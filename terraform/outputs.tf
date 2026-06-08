output "vm1_public_ip" {
  value = azurerm_public_ip.pip[0].ip_address
}

output "vm2_public_ip" {
  value = azurerm_public_ip.pip[1].ip_address
}