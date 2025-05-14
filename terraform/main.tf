terraform {
  required_providers {
    keycloak = {
      source  = "keycloak/keycloak"
      version = "5.1.1"
    }
  }
}

provider "keycloak" {
  client_id = "admin-cli" # Default Keycloak client for admin operations
  username  = var.keycloak_admin
  password  = var.keycloak_admin_password
  url       = var.keycloak_url
}

resource "keycloak_realm" "acmeco" {
  realm                 = var.keycloak_realm
  enabled               = true
  display_name          = "acmeco Realm"
  login_theme           = "keycloak"
  access_token_lifespan = "3600s"
}

resource "keycloak_openid_client" "express_api_client" {
  realm_id                     = keycloak_realm.acmeco.id
  client_id                    = var.keycloak_admin_client_id
  client_secret                = var.keycloak_admin_client_secret
  name                         = "Express API Client"
  enabled                      = true
  access_type                  = "CONFIDENTIAL"
  standard_flow_enabled        = false
  direct_access_grants_enabled = true
  service_accounts_enabled     = true
}

resource "keycloak_openid_client" "react_client" {
  realm_id                     = keycloak_realm.acmeco.id
  client_id                    = var.keycloak_client_id
  name                         = "React Client"
  enabled                      = true
  access_type                  = "PUBLIC"
  standard_flow_enabled        = true
  implicit_flow_enabled        = false
  direct_access_grants_enabled = true
  root_url                     = var.react_app_api_url
  valid_redirect_uris = [
    "*"
  ]
  web_origins = ["https://app.acmeco.com"]
}

# Create a normal user in the acmeco realm
resource "keycloak_user" "normal_user" {
  realm_id = keycloak_realm.acmeco.id # Explicitly tied to the acmeco realm
  username = "normal_user"
  enabled  = true

  email      = "normal_user@example.com"
  first_name = "Normal"
  last_name  = "User"
}

# Create an admin user in the acmeco realm
resource "keycloak_user" "admin_user" {
  realm_id = keycloak_realm.acmeco.id # Explicitly tied to the acmeco realm
  username = "admin_user"
  enabled  = true

  email      = "admin_user@example.com"
  first_name = "Admin"
  last_name  = "User"
}

# Define the admin role in the acmeco realm
resource "keycloak_role" "admin_role" {
  realm_id    = keycloak_realm.acmeco.id # Explicitly tied to the acmeco realm
  name        = "admin"
  description = "Admin role with full access"
}

# Get the realm-management client (needed to fetch built-in roles)
data "keycloak_openid_client" "realm_management" {
  realm_id  = keycloak_realm.acmeco.id
  client_id = "realm-management"
}

# Get the realm-admin role from the built-in realm-management client
data "keycloak_role" "realm_admin" {
  realm_id  = keycloak_realm.acmeco.id
  client_id = data.keycloak_openid_client.realm_management.id
  name      = "realm-admin"
}

# Assign the built-in realm-admin role to admin_user
resource "keycloak_user_roles" "admin_user_realm_admin" {
  realm_id = keycloak_realm.acmeco.id
  user_id  = keycloak_user.admin_user.id

  role_ids = [
    data.keycloak_role.realm_admin.id, # Assign the Keycloak admin role
    keycloak_role.admin_role.id
  ]
}

resource "keycloak_openid_user_realm_role_protocol_mapper" "realm_roles_mapper_react" {
  realm_id            = keycloak_realm.acmeco.id
  client_id           = keycloak_openid_client.react_client.id
  name                = "realm-roles-mapper"
  claim_name          = "realm_access.roles"
  claim_value_type    = "String"
  multivalued         = true
  add_to_id_token     = true
  add_to_access_token = true
}
resource "keycloak_openid_user_realm_role_protocol_mapper" "realm_roles_mapper_express" {
  realm_id            = keycloak_realm.acmeco.id
  client_id           = keycloak_openid_client.express_api_client.id
  name                = "realm-roles-mapper"
  claim_name          = "realm_access.roles"
  claim_value_type    = "String"
  multivalued         = true
  add_to_id_token     = true
  add_to_access_token = true
}

resource "keycloak_openid_client_service_account_role" "express_api_view_users" {
  realm_id                = keycloak_realm.acmeco.id
  service_account_user_id = keycloak_openid_client.express_api_client.service_account_user_id
  client_id               = data.keycloak_openid_client.realm_management.id
  role                    = "view-users"
}

resource "keycloak_openid_audience_protocol_mapper" "express_api_audience" {
  realm_id                 = keycloak_realm.acmeco.id
  client_id                = keycloak_openid_client.react_client.id
  name                     = "express-api-audience"
  included_client_audience = "express-api"
  add_to_id_token          = true
  add_to_access_token      = true
}
