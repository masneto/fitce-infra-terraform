provider "aws" {
  region = "sa-east-1"
}

# Criar um Bucket S3 para armazenar os builds
resource "aws_s3_bucket" "deploy_bucket" {
  bucket = "fitce-bucket-deploy"
}

# Criar pastas dentro do bucket (prefixos simulam diretórios no S3)
resource "aws_s3_object" "folders" {
  for_each = toset(["dev/", "hom/", "prod/"])
  
  bucket = aws_s3_bucket.deploy_bucket.id
  key    = each.value
}

# Criar Role IAM para Desenvolvedores
resource "aws_iam_role" "developer_role" {
  name = "DeveloperRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action = "sts:AssumeRole"
      },
      {
        Effect = "Allow"
        Principal = { Federated = "arn:aws:iam::481665110400:oidc-provider/token.actions.githubusercontent.com" }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
            "token.actions.githubusercontent.com:sub": "repo:masneto/fitce-platform:ref:refs/heads/develop"
          }
        }
      }
    ]
  })
}

# Criar Role IAM para DevOps
resource "aws_iam_role" "devops_role" {
  name = "DevOpsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action = "sts:AssumeRole"
      },
      {
        Effect = "Allow"
        Principal = { Federated = "arn:aws:iam::481665110400:oidc-provider/token.actions.githubusercontent.com" }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
            "token.actions.githubusercontent.com:sub": [
              "repo:masneto/fitce-platform:ref:refs/heads/develop",
              "repo:masneto/fitce-platform:ref:refs/heads/release/*",
              "repo:masneto/fitce-platform:ref:refs/heads/main"
            ]
          }
        }
      }
    ]
  })
}

# Criar Role IAM para Automação
resource "aws_iam_role" "automation_role" {
  name = "AutomationRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action = "sts:AssumeRole"
      },
      {
        Effect = "Allow"
        Principal = { Federated = "arn:aws:iam::481665110400:oidc-provider/token.actions.githubusercontent.com" }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
            "token.actions.githubusercontent.com:sub": [
              "repo:masneto/fitce-platform:ref:refs/heads/develop",
              "repo:masneto/fitce-platform:ref:refs/heads/release/*",
              "repo:masneto/fitce-platform:ref:refs/heads/main"
            ]
          }
        }
      }
    ]
  })
}

# Criar Política de Permissão para Desenvolvedores (Acesso somente à pasta "dev")
resource "aws_iam_policy" "developer_policy" {
  name        = "DeveloperS3Access"
  description = "Permite acesso à pasta dev no S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:ListBucket"]
      Resource = [aws_s3_bucket.deploy_bucket.arn]
      Condition = {
        StringLike = { "s3:prefix" = "dev/*" }
      }
    }, {
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:PutObject"]
      Resource = "${aws_s3_bucket.deploy_bucket.arn}/dev/*"
    }]
  })
}

# Anexar Política de Desenvolvedor à Role
resource "aws_iam_role_policy_attachment" "developer_policy_attachment" {
  role       = aws_iam_role.developer_role.name
  policy_arn = aws_iam_policy.developer_policy.arn
}

# Criar Política de Permissão para DevOps (Acesso total ao S3)
resource "aws_iam_policy" "devops_policy" {
  name        = "DevOpsS3Access"
  description = "Permite acesso total ao S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:*"]
      Resource = ["${aws_s3_bucket.deploy_bucket.arn}/*"]
    }]
  })
}

# Anexar Política de DevOps à Role
resource "aws_iam_role_policy_attachment" "devops_policy_attachment" {
  role       = aws_iam_role.devops_role.name
  policy_arn = aws_iam_policy.devops_policy.arn
}

# Criar Política de Permissão para Automação (Acesso à pasta "dev", "hom" e "prod")
resource "aws_iam_policy" "automation_policy" {
  name        = "AutomationS3Access"
  description = "Permite acesso às pastas dev, hom e prod no S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:ListBucket"]
      Resource = [aws_s3_bucket.deploy_bucket.arn]
      Condition = {
        StringLike = { "s3:prefix" = ["dev/*", "hom/*", "prod/*"] }
      }
    }, {
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:PutObject"]
      Resource = [
        "${aws_s3_bucket.deploy_bucket.arn}/dev/*",
        "${aws_s3_bucket.deploy_bucket.arn}/hom/*",
        "${aws_s3_bucket.deploy_bucket.arn}/prod/*"
      ]
    }]
  })
}

# Anexar Política de Automação à Role
resource "aws_iam_role_policy_attachment" "automation_policy_attachment" {
  role       = aws_iam_role.automation_role.name
  policy_arn = aws_iam_policy.automation_policy.arn
}