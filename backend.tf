terraform {
  backend "azurerm" {
    resource_group_name  = "ShroomTest-resources"
    storage_account_name = "terraformtestshroomie"
    container_name       = "prod-tfstate"
    key                  = "prod.terraform.tfstate"
  }
}
