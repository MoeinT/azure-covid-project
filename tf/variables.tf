variable "mssql_login" {
  description = "Database administrator login"
  type        = string
  sensitive   = true
}

variable "mssql_password" {
  description = "Database administrator password"
  type        = string
  sensitive   = true
}

variable "db_access_token" {
  type      = string
  sensitive = true
}

# variable "snowflake_password" {
#   type = string 
# }

variable "snowflake_username" {
  type    = string
  default = "Moein"
}

variable "Snowflake_account_name" {
  type    = string
  default = "fe90524.west-europe.azure"
}