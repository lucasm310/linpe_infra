variable "tags" {
  default = {
    project = "linpe"
    version = "v1"
  }
}

variable "cognito_fields" {
  default = ["email", "name", "birthdate", "phone_number", "custom:curso", "custom:nivel"]
}

variable "cognito_custom_fields" {
  default = ["curso", "nivel"]
}

variable "cognito_groups" {
  default = ["diretoria", "ligantes", "geral"]
}

variable "cognito_urls" {
  default = {
    "dev"  = ["https://app.dev.linpe.com.br/","http://localhost:3000/"]
    "prod" = ["https://app.linpe.com.br/"]
  }
}

variable "google_id" {
  type = string
}

variable "google_secret" {
  type = string
}

variable "documentos_fields" {
  default = ["documentoID", "data_cadastro"]
}

variable "eventos_fields" {
  default = ["eventosID"]
}

variable "noticias_fields" {
  default = ["noticiaID"]
}

variable "cache_default_ttl" {
  default = 60
}

variable "cache_max_ttl" {
  default = 360
}

variable "domain_site" {
  default = {
    "dev"  = "www.dev.linpe.com.br"
    "prod" = "www.linpe.com.br"
  }
}

variable "domain_app" {
  default = {
    "dev"  = "app.dev.linpe.com.br"
    "prod" = "app.linpe.com.br"
  }
}
