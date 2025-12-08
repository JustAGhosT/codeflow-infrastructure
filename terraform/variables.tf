variable "resource_group_name" {
  type        = string
  description = "The name of the Azure Resource Group."
  default     = "autopr-rg"
}

variable "location" {
  type        = string
  description = "The Azure region where the resources will be created."
  default     = "East US"
}

variable "aks_cluster_name" {
  type        = string
  description = "The name of the AKS cluster."
  default     = "autopr-aks"
}

variable "acr_name" {
  type        = string
  description = "The name of the Azure Container Registry."
  default     = "autopracr"
}

variable "postgres_password" {
  type        = string
  description = "The password for the PostgreSQL server."
  sensitive   = true
}
