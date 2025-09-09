// Public IP and Web Load Balancer
resource "azurerm_public_ip" "web_lb_pip" {
  name                = "${var.name_prefix}-web-lb-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "${var.name_prefix}-web-${random_string.suffix.result}"
}

resource "azurerm_lb" "web" {
  name                = "${var.name_prefix}-web-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicFrontend"
    public_ip_address_id = azurerm_public_ip.web_lb_pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "web" {
  loadbalancer_id = azurerm_lb.web.id
  name            = "web-bepool"
}

resource "azurerm_lb_probe" "web_http" {
  loadbalancer_id = azurerm_lb.web.id
  name            = "http"
  port            = 80
}

resource "azurerm_lb_rule" "web_http" {
  loadbalancer_id                = azurerm_lb.web.id
  name                           = "http"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicFrontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.web.id]
  probe_id                       = azurerm_lb_probe.web_http.id
}

// Internal LBs for Business and DB tiers
resource "azurerm_lb" "biz" {
  name                = "${var.name_prefix}-biz-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "BizFrontend"
    subnet_id                     = azurerm_subnet.subnet_biz.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_lb_backend_address_pool" "biz" {
  loadbalancer_id = azurerm_lb.biz.id
  name            = "biz-bepool"
}

resource "azurerm_lb_probe" "biz_probe" {
  loadbalancer_id = azurerm_lb.biz.id
  name            = "tcp8080"
  port            = 8080
}

resource "azurerm_lb_rule" "biz_rule" {
  loadbalancer_id                = azurerm_lb.biz.id
  name                           = "tcp8080"
  protocol                       = "Tcp"
  frontend_port                  = 8080
  backend_port                   = 8080
  frontend_ip_configuration_name = "BizFrontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.biz.id]
  probe_id                       = azurerm_lb_probe.biz_probe.id
}

resource "azurerm_lb" "db" {
  name                = "${var.name_prefix}-db-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "DbFrontend"
    subnet_id                     = azurerm_subnet.subnet_db.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_lb_backend_address_pool" "db" {
  loadbalancer_id = azurerm_lb.db.id
  name            = "db-bepool"
}

resource "azurerm_lb_probe" "db_probe" {
  loadbalancer_id = azurerm_lb.db.id
  name            = "tcp1433"
  port            = 1433
}

resource "azurerm_lb_rule" "db_rule" {
  loadbalancer_id                = azurerm_lb.db.id
  name                           = "tcp1433"
  protocol                       = "Tcp"
  frontend_port                  = 1433
  backend_port                   = 1433
  frontend_ip_configuration_name = "DbFrontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.db.id]
  probe_id                       = azurerm_lb_probe.db_probe.id
}

