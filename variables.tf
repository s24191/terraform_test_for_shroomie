variable "prefix" {
  default = "ShroomTest"
}
variable "location" {
  default = "North Europe"

}
variable "client_id" {
  description = "Client ID of the Service Principal"
}

variable "client_secret" {
  description = "Client Secret of the Service Principal"
}

variable "tenant_id" {
  description = "Tenant ID of the Azure account"
}

variable "subscription_id" {
  description = "Subscription ID of the Azure account"
}