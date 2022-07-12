variable "db_access_token" {
  type      = string
  sensitive = true
}

variable "snowflake_username" {
  type    = string
  default = "Moein"
}

variable "Snowflake_account_name" {
  type    = string
}