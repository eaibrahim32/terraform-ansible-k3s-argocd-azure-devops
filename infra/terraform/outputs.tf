output "vm_public_ip" {
  value       = azurerm_public_ip.main.ip_address
  description = "SSH + app entrypoint."
}

output "ssh_command" {
  value       = "ssh -i infra/terraform/.ssh/id_rsa ${var.admin_username}@${azurerm_public_ip.main.ip_address}"
  description = "Ready-to-run SSH command."
}

output "acr_login_server" {
  value = azurerm_container_registry.main.login_server
}

output "key_vault_name" {
  value = azurerm_key_vault.main.name
}

output "app_secret_name" {
  value = azurerm_key_vault_secret.app_secret.name
}

output "log_analytics_workspace" {
  value = azurerm_log_analytics_workspace.main.name
}
