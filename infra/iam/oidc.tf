resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # GitHub's root CA thumbprint (kept as a variable to allow updates)
  thumbprint_list = [var.oidc_thumbprint]
}
