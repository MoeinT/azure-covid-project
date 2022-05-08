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

