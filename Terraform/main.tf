resource "azurerm_resource_group" "rg" {
  name = "rg-hackathon-aks"
  location = "East US"
}

resource "azurerm_virtual_network" "vnet" {
  name = "aks-sreeni-vnet081125"
  address_space = ["10.2.15.0/16"]
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "public" {
  name = "sreeni-snet-public081125"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "private" {
  name = "-sreeni-snet-private081125"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.0.2.0/24"]
}

resource "azurerm_container_registry" "acr" {
  name = "sreeni-acr-hackathon081125" 
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  sku = "Standard"
  admin_enabled = true
}

resource "random_pet" "prefix" {
  prefix = var.resource_group_name_prefix
  length = 1
}

resource "azurerm_kubernetes_cluster" "aks" {
  name = "aks-cluster-hackathon081125"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix = "aks-devops"
  node_resource_group = "aks-node-rg" # Dedicated node resource group

  default_node_pool {
    name = "sreeni-pool081125"
    node_count = 2
    vm_size = "Standard_DS2_v2"
    vnet_subnet_id = azurerm_subnet.private.id # Use private subnet
    type = "System"
  }

  identity {
    type = "SystemAssigned"
  }

  addon_profile {
    oms_agent {
      enabled = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.workspace.id
    }
  }

 role_based_access_control_enabled = true
}

resource "azurerm_log_analytics_workspace" "workspace" {
  name = "log-aks-sreeni-workspace"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku = "PerGB2018"
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}

