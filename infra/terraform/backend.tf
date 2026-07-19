# Remote state = prod discipline. State lives in an Azure Storage container,
# locked via blob lease, never on a laptop and never in git.
#
# Bootstrap ONCE before `terraform init`:
#   az group create -n tfstate-rg -l southeastasia
#   az storage account create -n <globally-unique> -g tfstate-rg --sku Standard_LRS
#   az storage container create -n tfstate --account-name <globally-unique>
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "REPLACE_WITH_UNIQUE_SA"
    container_name       = "tfstate"
    key                  = "capstone.terraform.tfstate"
  }
}
