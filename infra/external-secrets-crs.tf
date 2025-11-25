locals {
  secrets = var.aws_secrets_to_sync
}

resource "kubernetes_manifest" "cluster_secret_store" {
  # Use templatefile so we can inject Terraform variables (e.g. region) into the manifest
  manifest = yamldecode(templatefile("${path.module}/k8s/external-secrets/clustersecretstore.yaml.tpl", { region = var.region }))
}

resource "kubernetes_manifest" "external_secrets" {
  for_each = local.secrets

  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = each.key
      namespace = "innova"
    }
    spec = {
      refreshInterval = "1h"
      secretStoreRef = {
        name = "aws-secrets-manager"
        kind = "ClusterSecretStore"
      }
      target = {
        name = each.key
        creationPolicy = "Owner"
      }
        data = length(try(each.value.properties, [])) > 0 ? [for p in try(each.value.properties, []): {
          secretKey = p
          remoteRef = {
            key = try(each.value.arn, each.value)
            property = p
          }
        }] : [{
          secretKey = "value"
          remoteRef = {
            key = try(each.value.arn, each.value)
          }
        }]
    }
  }

  depends_on = [kubernetes_manifest.cluster_secret_store, helm_release.external_secrets]
}
