variable "project" {
  type        = string
  default     = "tf-ansible-k3s-argocd-azure"
  description = "Short project name used in resource naming and tags."
}

variable "location" {
  type        = string
  default     = "southeastasia"
  description = "Azure region (Singapore is closest low-latency region to Dhaka)."
}

variable "vm_size" {
  type        = string
  default     = "Standard_B2s"
  description = "Burstable VM: pay for baseline, burst on demand. Cost-optimization choice."
}

variable "admin_username" {
  type    = string
  default = "azureuser"
}

variable "allowed_ssh_cidr" {
  type        = string
  description = "Your public IP in CIDR form, e.g. 203.0.113.4/32. Least-privilege SSH."
}

variable "budget_amount" {
  type        = number
  default     = 20
  description = "Monthly USD budget for the resource group; alerts at 80% and 100%."
}

variable "alert_email" {
  type        = string
  description = "Email for budget + Azure Monitor alerts."
}

variable "auto_shutdown_time" {
  type        = string
  default     = "2000"
  description = "Daily VM auto-shutdown (HHmm, 24h). Stops overnight billing."
}

variable "auto_shutdown_tz" {
  type    = string
  default = "Bangladesh Standard Time"
}

variable "tags" {
  type = map(string)
  default = {
    project     = "tf-ansible-k3s-argocd-azure"
    owner       = "ahnaf"
    managed_by  = "terraform"
    cost_center = "portfolio"
  }
}
