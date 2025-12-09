variable "resource_group_name" {
  type        = string
  description = "The name of the Azure Resource Group. Pattern: org-env-proj-rg-region (e.g., nl-prod-codeflow-rg-san)"
  default     = "nl-prod-codeflow-rg-san"
}

variable "location" {
  type        = string
  description = "The Azure region where the resources will be created."
  default     = "East US"
}

variable "aks_cluster_name" {
  type        = string
  description = "The name of the AKS cluster. Pattern: org-env-proj-aks-region (e.g., nl-prod-codeflow-aks-san)"
  default     = "nl-prod-codeflow-aks-san"
}

variable "acr_name" {
  type        = string
  description = "The name of the Azure Container Registry. Pattern: orgprojacr (e.g., nlprodcodeflowacr)"
  default     = "nlprodcodeflowacr"
}

variable "postgres_password" {
  type        = string
  description = "The password for the PostgreSQL server."
  sensitive   = true
}
