variable "mssql_admin_login" {
  description = "Database administrator login"
  type        = string
  sensitive   = true
}

variable "mssql_admin_password" {
  description = "Database administrator password"
  type        = string
  sensitive   = true
}