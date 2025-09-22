data "aws_iam_policy_document" "eso_ssm" {
  statement {
    actions   = ["ssm:GetParameter", "ssm:GetParameters"]
    resources = ["arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/*"]
  }
  statement {
    actions   = ["kms:Decrypt"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.${data.aws_region.current.name}.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "eso_ssm" {
  name        = "${var.project_name}-eso-ssm"
  description = "Allow ESO to read SSM parameters and decrypt if needed"
  policy      = data.aws_iam_policy_document.eso_ssm.json
}

resource "aws_iam_role" "eso_irsa" {
  name = "${var.project_name}-eso-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Federated = module.eks.oidc_provider_arn },
      Action    = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "${replace(module.eks.oidc_provider, "https://", "")}:sub" : "system:serviceaccount:external-secrets:external-secrets",
          "${replace(module.eks.oidc_provider, "https://", "")}:aud" : "sts.amazonaws.com"
        }
      }
    }]
  })
  tags = { Project = var.project_name }
}

resource "aws_iam_role_policy_attachment" "eso_irsa_attach" {
  role       = aws_iam_role.eso_irsa.name
  policy_arn = aws_iam_policy.eso_ssm.arn
}
