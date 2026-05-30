data "azurerm_client_config" "current" {}

locals {
  cloud_native   = var.secrets_backend == "cloud_native"
  cn_secret_name = "${var.name_prefix}-stack"
  key_vault_name = substr(replace("${var.name_prefix}-${random_string.kv_suffix.result}", "_", "-"), 0, 24)

  supabase_public_url = "http://${azurerm_public_ip.this.ip_address}:8000"
  site_url            = "http://${azurerm_public_ip.this.ip_address}:${var.web_http_port}"

  cloud_native_access = local.cloud_native ? {
    provider             = "azure"
    region               = var.region
    secret_name          = local.cn_secret_name
    azure_key_vault_name = azurerm_key_vault.this[0].name
  } : null
}

resource "random_string" "kv_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_resource_group" "this" {
  name     = "${var.name_prefix}-rg"
  location = var.region
  tags     = var.tags
}

resource "azurerm_virtual_network" "this" {
  name                = "${var.name_prefix}-vnet"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.42.0.0/16"]
  tags                = var.tags
}

resource "azurerm_subnet" "this" {
  name                 = "${var.name_prefix}-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.42.1.0/24"]
}

resource "azurerm_network_security_group" "this" {
  name                = "${var.name_prefix}-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags

  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.ssh_allowed_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "web"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443", "3000", "8000", "8443"]
    source_address_prefix      = var.web_allowed_cidr
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "this" {
  name                = "${var.name_prefix}-pip"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "this" {
  name                = "${var.name_prefix}-nic"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }
}

resource "azurerm_network_interface_security_group_association" "this" {
  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}

# --- Cloud-native secrets (Azure Key Vault) ---

resource "azurerm_key_vault" "this" {
  count = local.cloud_native ? 1 : 0

  name                       = local.key_vault_name
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  tags                       = var.tags
}

# Allow the deploying principal to write the secret.
resource "azurerm_key_vault_access_policy" "deployer" {
  count = local.cloud_native ? 1 : 0

  key_vault_id = azurerm_key_vault.this[0].id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = ["Get", "Set", "List", "Delete", "Purge"]
}

resource "azurerm_key_vault_secret" "stack" {
  count = local.cloud_native ? 1 : 0

  name         = local.cn_secret_name
  value        = jsonencode(var.secret_values)
  key_vault_id = azurerm_key_vault.this[0].id

  depends_on = [azurerm_key_vault_access_policy.deployer]
}

# Allow the VM's managed identity to read the secret at boot.
resource "azurerm_key_vault_access_policy" "vm" {
  count = local.cloud_native ? 1 : 0

  key_vault_id = azurerm_key_vault.this[0].id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_virtual_machine.this.identity[0].principal_id

  secret_permissions = ["Get"]
}

# --- Bootstrap script ---

module "bootstrap" {
  source = "../bootstrap"

  supabase_public_url      = local.supabase_public_url
  site_url                 = local.site_url
  additional_redirect_urls = var.additional_redirect_urls
  app_repo_url             = var.app_repo_url
  app_repo_ref             = var.app_repo_ref
  web_http_port            = var.web_http_port
  data_device              = "/dev/disk/azure/scsi1/lun0"

  secrets_backend = var.secrets_backend
  vault           = try(var.external_secrets_access.vault, null)
  doppler         = try(var.external_secrets_access.doppler, null)
  cloud_native    = local.cloud_native_access
}

# --- Virtual machine + data disk ---

resource "azurerm_linux_virtual_machine" "this" {
  name                  = "${var.name_prefix}-vm"
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  size                  = var.instance_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.this.id]
  custom_data           = base64encode(module.bootstrap.user_data)
  tags                  = var.tags

  identity {
    type = "SystemAssigned"
  }

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

resource "azurerm_managed_disk" "data" {
  name                 = "${var.name_prefix}-data"
  location             = azurerm_resource_group.this.location
  resource_group_name  = azurerm_resource_group.this.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb
  tags                 = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  managed_disk_id    = azurerm_managed_disk.data.id
  virtual_machine_id = azurerm_linux_virtual_machine.this.id
  lun                = 0
  caching            = "ReadWrite"
}

# --- Optional DNS ---

resource "azurerm_dns_a_record" "this" {
  count = var.dns_zone_name != "" ? 1 : 0

  name                = var.dns_record_name
  zone_name           = var.dns_zone_name
  resource_group_name = var.dns_zone_resource_group
  ttl                 = 300
  records             = [azurerm_public_ip.this.ip_address]
  tags                = var.tags
}
