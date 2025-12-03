# AWS Cognito Module for Zero Trust Authentication
# Provides authentication for HR Portal and Workspace access

# =============================================================================
# COGNITO USER POOL - Central Identity Store
# =============================================================================

resource "aws_cognito_user_pool" "main" {
  name = "${var.cluster_name}-user-pool"

  # Password Policy - Strong passwords required
  password_policy {
    minimum_length                   = 12
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 1
  }

  # MFA Configuration - Required for Zero Trust
  mfa_configuration = "ON"

  software_token_mfa_configuration {
    enabled = true
  }

  # Account Recovery
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # User Attributes
  schema {
    name                     = "email"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    required                 = true

    string_attribute_constraints {
      min_length = 5
      max_length = 256
    }
  }

  schema {
    name                     = "department"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    required                 = false

    string_attribute_constraints {
      min_length = 1
      max_length = 100
    }
  }

  schema {
    name                     = "employee_id"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = false
    required                 = false

    string_attribute_constraints {
      min_length = 1
      max_length = 50
    }
  }

  # Auto-verification
  auto_verified_attributes = ["email"]

  # Email Configuration
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # User Pool Add-ons (Advanced Security)
  user_pool_add_ons {
    advanced_security_mode = "ENFORCED"
  }

  # Admin Create User Config
  admin_create_user_config {
    allow_admin_create_user_only = true # Only admins can create users

    invite_message_template {
      email_subject = "Welcome to Innovatech - Your Account"
      email_message = "Hello {username}, your temporary password is {####}. Please change it upon first login."
      sms_message   = "Your Innovatech username is {username} and temporary password is {####}"
    }
  }

  # Device Configuration
  device_configuration {
    challenge_required_on_new_device      = true
    device_only_remembered_on_user_prompt = true
  }

  tags = {
    Name        = "${var.cluster_name}-user-pool"
    Environment = var.environment
    Purpose     = "Zero Trust Authentication"
  }
}

# =============================================================================
# USER POOL DOMAIN
# =============================================================================

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.cluster_name}-auth"
  user_pool_id = aws_cognito_user_pool.main.id
}

# =============================================================================
# USER GROUPS - Role-Based Access Control
# =============================================================================

# HR Administrators Group - Full access to HR Portal
resource "aws_cognito_user_group" "hr_admin" {
  name         = "hr-admin"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "HR Administrators - Full access to HR Portal"
  precedence   = 1
}

# HR Staff Group - Standard HR Portal access
resource "aws_cognito_user_group" "hr_staff" {
  name         = "hr-staff"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "HR Staff - Standard access to HR Portal"
  precedence   = 2
}

# Employees Group - Workspace access only
resource "aws_cognito_user_group" "employees" {
  name         = "employees"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Regular Employees - Workspace access only"
  precedence   = 3
}

# Managers Group - Can view team workspaces
resource "aws_cognito_user_group" "managers" {
  name         = "managers"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Managers - Can view team member workspaces"
  precedence   = 2
}

# =============================================================================
# APP CLIENTS
# =============================================================================

# HR Portal App Client
resource "aws_cognito_user_pool_client" "hr_portal" {
  name         = "hr-portal-client"
  user_pool_id = aws_cognito_user_pool.main.id

  # OAuth Settings
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["email", "openid", "profile"]

  callback_urls = var.hr_portal_callback_urls
  logout_urls   = var.hr_portal_logout_urls

  supported_identity_providers = ["COGNITO"]

  # Token Validity
  access_token_validity  = 1  # 1 hour
  id_token_validity      = 1  # 1 hour
  refresh_token_validity = 24 # 24 hours

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "hours"
  }

  # Security Settings
  prevent_user_existence_errors = "ENABLED"
  enable_token_revocation       = true

  # Explicit Auth Flows
  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  generate_secret = true
}

# Workspace App Client (for employee workspace access)
resource "aws_cognito_user_pool_client" "workspace" {
  name         = "workspace-client"
  user_pool_id = aws_cognito_user_pool.main.id

  # OAuth Settings
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["email", "openid", "profile"]

  callback_urls = var.workspace_callback_urls
  logout_urls   = var.workspace_logout_urls

  supported_identity_providers = ["COGNITO"]

  # Token Validity - Shorter for workspaces
  access_token_validity  = 1 # 1 hour
  id_token_validity      = 1 # 1 hour
  refresh_token_validity = 8 # 8 hours (work day)

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "hours"
  }

  # Security Settings
  prevent_user_existence_errors = "ENABLED"
  enable_token_revocation       = true

  # Explicit Auth Flows
  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  generate_secret = true
}

# =============================================================================
# RESOURCE SERVER (API Scopes)
# =============================================================================

resource "aws_cognito_resource_server" "api" {
  identifier   = "https://api.${var.domain_name}"
  name         = "Innovatech API"
  user_pool_id = aws_cognito_user_pool.main.id

  scope {
    scope_name        = "hr.read"
    scope_description = "Read HR data"
  }

  scope {
    scope_name        = "hr.write"
    scope_description = "Write HR data"
  }

  scope {
    scope_name        = "workspace.access"
    scope_description = "Access own workspace"
  }

  scope {
    scope_name        = "workspace.admin"
    scope_description = "Administer workspaces"
  }
}

# =============================================================================
# IDENTITY POOL (for AWS credentials)
# =============================================================================

resource "aws_cognito_identity_pool" "main" {
  identity_pool_name               = "${var.cluster_name}-identity-pool"
  allow_unauthenticated_identities = false
  allow_classic_flow               = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.hr_portal.id
    provider_name           = aws_cognito_user_pool.main.endpoint
    server_side_token_check = true
  }

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.workspace.id
    provider_name           = aws_cognito_user_pool.main.endpoint
    server_side_token_check = true
  }

  tags = {
    Name        = "${var.cluster_name}-identity-pool"
    Environment = var.environment
  }
}

# IAM Role for authenticated users
resource "aws_iam_role" "cognito_authenticated" {
  name = "${var.cluster_name}-cognito-authenticated"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.main.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.cluster_name}-cognito-authenticated"
    Environment = var.environment
  }
}

# Attach role to identity pool
resource "aws_cognito_identity_pool_roles_attachment" "main" {
  identity_pool_id = aws_cognito_identity_pool.main.id

  roles = {
    "authenticated" = aws_iam_role.cognito_authenticated.arn
  }

  role_mapping {
    identity_provider         = "${aws_cognito_user_pool.main.endpoint}:${aws_cognito_user_pool_client.hr_portal.id}"
    ambiguous_role_resolution = "AuthenticatedRole"
    type                      = "Token"
  }
}
