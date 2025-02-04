#!/bin/bash

set -e

echo "🔍 Verificando e importando recursos existentes..."

# Verifica e importa bucket S3
if aws s3api head-bucket --bucket fitce-bucket-deploy 2>/dev/null; then
  echo "✅ Bucket S3 'fitce-bucket-deploy' encontrado"
  terraform import aws_s3_bucket.deploy_bucket fitce-bucket-deploy || true
else
  echo "ℹ️ Bucket S3 'fitce-bucket-deploy' não encontrado"
fi

# Verifica e importa IAM Roles
for role in DeveloperRole DevOpsRole AutomationRole; do
  ROLE_EXISTS=$(aws iam get-role --role-name $role --query 'Role.RoleName' --output text 2>/dev/null || echo "")
  if [[ "$ROLE_EXISTS" == "$role" ]]; then
    echo "✅ Role '$role' encontrada"
    terraform import aws_iam_role.${role,,}_role $role || true
  else
    echo "ℹ️ Role '$role' não encontrada"
  fi
done

# Verifica e importa IAM Policies
for policy in DeveloperS3Access DevOpsS3Access AutomationS3Access; do
  POLICY_ARN=$(aws iam list-policies --scope Local --query "Policies[?PolicyName=='$policy'].Arn" --output text 2>/dev/null || echo "")
  if [[ -n "$POLICY_ARN" ]]; then
    echo "✅ Policy '$policy' encontrada"
    terraform import aws_iam_policy.${policy,,}_policy $POLICY_ARN || true
  else
    echo "ℹ️ Policy '$policy' não encontrada"
  fi
done

# Verifica e importa Role Policy Attachments
for role in DeveloperRole DevOpsRole AutomationRole; do
  for policy in DeveloperS3Access DevOpsS3Access AutomationS3Access; do
    ATTACHED_ARN=$(aws iam list-attached-role-policies --role-name $role --query "AttachedPolicies[?PolicyName=='$policy'].PolicyArn" --output text 2>/dev/null || echo "")
    if [[ -n "$ATTACHED_ARN" ]]; then
      echo "✅ Policy '$policy' anexada à role '$role'"
      terraform import aws_iam_role_policy_attachment.${role,,}_policy_attachment "$role/$ATTACHED_ARN" || true
    else
      echo "ℹ️ Policy '$policy' não está anexada à role '$role'"
    fi
  done
done

echo "🔍 Verificação de recursos concluída"