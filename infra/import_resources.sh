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
    case $role in
      DeveloperRole)
        terraform import aws_iam_role.developer_role $role || true
        ;;
      DevOpsRole)
        terraform import aws_iam_role.devops_role $role || true
        ;;
      AutomationRole)
        terraform import aws_iam_role.automation_role $role || true
        ;;
    esac
  else
    echo "ℹ️ Role '$role' não encontrada"
  fi
done

# Verifica e importa IAM Policies
for policy in DeveloperS3Access DevOpsS3Access AutomationS3Access; do
  POLICY_ARN=$(aws iam list-policies --scope Local --query "Policies[?PolicyName=='$policy'].Arn" --output text 2>/dev/null || echo "")
  if [[ -n "$POLICY_ARN" ]]; then
    echo "✅ Policy '$policy' encontrada"
    case $policy in
      DeveloperS3Access)
        terraform import aws_iam_policy.developer_policy $POLICY_ARN || true
        ;;
      DevOpsS3Access)
        terraform import aws_iam_policy.devops_policy $POLICY_ARN || true
        ;;
      AutomationS3Access)
        terraform import aws_iam_policy.automation_policy $POLICY_ARN || true
        ;;
    esac
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
      case $role in
        DeveloperRole)
          terraform import aws_iam_role_policy_attachment.developer_policy_attachment "$role/$ATTACHED_ARN" || true
          ;;
        DevOpsRole)
          terraform import aws_iam_role_policy_attachment.devops_policy_attachment "$role/$ATTACHED_ARN" || true
          ;;
        AutomationRole)
          terraform import aws_iam_role_policy_attachment.automation_policy_attachment "$role/$ATTACHED_ARN" || true
          ;;
      esac
    else
      echo "ℹ️ Policy '$policy' não está anexada à role '$role'"
    fi
  done
done

echo "🔍 Verificação de recursos concluída"