resource "aws_dynamodb_table" "table_documentos" {
  name         = "linpe_documentos-${terraform.workspace}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "documentoID"
  range_key    = "data_cadastro"
  tags         = merge(var.tags, { enviroment = terraform.workspace })
  dynamic "attribute" {
    for_each = var.documentos_fields
    content {
      name = attribute.value
      type = "S"
    }
  }
}

resource "aws_dynamodb_table" "table_eventos" {
  name         = "linpe_eventos-${terraform.workspace}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "eventosID"
  tags         = merge(var.tags, { enviroment = terraform.workspace })
  dynamic "attribute" {
    for_each = var.eventos_fields
    content {
      name = attribute.value
      type = "S"
    }
  }
}

resource "aws_dynamodb_table" "table_noticias" {
  name         = "linpe_noticias-${terraform.workspace}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "noticiaID"
  tags         = merge(var.tags, { enviroment = terraform.workspace })
  dynamic "attribute" {
    for_each = var.noticias_fields
    content {
      name = attribute.value
      type = "S"
    }
  }
}