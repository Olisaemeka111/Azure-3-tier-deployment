// Public IP and Web Load Balancer
// Replace Public LB with Application Gateway WAF v2
resource "azurerm_public_ip" "appgw_pip" {
  name                = "${var.name_prefix}-appgw-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "appgw" {
  name                = "${var.name_prefix}-appgw"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    name = var.app_gateway_sku
    tier = var.app_gateway_sku
  }

  autoscale_configuration {
    min_capacity = var.app_gateway_capacity
  }

  gateway_ip_configuration {
    name      = "appgatewayipcfg"
    subnet_id = azurerm_subnet.subnet_appgw.id
  }

  frontend_port {
    name = "port80"
    port = 80
  }

  frontend_port {
    name = "port443"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "frontend"
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  http_listener {
    name                           = "listener80"
    frontend_ip_configuration_name = "frontend"
    frontend_port_name             = "port80"
    protocol                       = "Http"
  }

  http_listener {
    name                           = "listener443"
    frontend_ip_configuration_name = "frontend"
    frontend_port_name             = "port443"
    protocol                       = "Https"
    ssl_certificate_name           = null
  }

  backend_address_pool {
    name = "web-backendpool"
  }

  backend_http_settings {
    name                  = "http"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
  }

  request_routing_rule {
    name                       = "rule80"
    rule_type                  = "Basic"
    http_listener_name         = "listener80"
    backend_address_pool_name  = "web-backendpool"
    backend_http_settings_name = "http"
  }
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

