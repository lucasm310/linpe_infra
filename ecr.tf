resource "aws_ecr_repository" "linpe_ecr" {
  name                 = "linpe-${terraform.workspace}"
  image_tag_mutability = "MUTABLE"
  tags                 = merge(var.tags, { enviroment = terraform.workspace })
}
