resource "aws_ecr_repository" "repos" {
  count = length(var.repository_names)
  name  = var.repository_names[count.index]

  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(var.common_tags, { Name = var.repository_names[count.index] })
}
