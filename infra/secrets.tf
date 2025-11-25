locals {
  secrets_map = var.aws_secrets_to_sync
}

resource "kubernetes_secret" "aws_synced" {
  for_each = local.secrets_map

  metadata {
    name      = each.key
    namespace = "innova"
  }

  data = {
    # store the whole secret string under the key 'value'
    value = base64encode(data.aws_secretsmanager_secret_version.secret_values[each.key].secret_string)
  }

  type = "Opaque"
}

data "aws_secretsmanager_secret" "secret_objs" {
  for_each = local.secrets_map
  arn      = each.value
}

data "aws_secretsmanager_secret_version" "secret_values" {
  for_each = local.secrets_map
  secret_id = each.value
}
