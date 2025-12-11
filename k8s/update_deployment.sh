#!/bin/bash

set -e

echo "=========================================="
echo "更新 AI Toolkit Deployment"
echo "=========================================="
echo ""

# 检查 kubectl 是否可用
if ! command -v kubectl &> /dev/null; then
    echo "错误: 未找到 kubectl 命令，请先安装 kubectl"
    exit 1
fi

echo "步骤 1/3: 重新应用 Deployment 配置..."
kubectl apply -f deployment.yaml -n ai-toolkit

echo ""
echo "步骤 2/3: 等待 Deployment 更新..."
kubectl rollout status deployment/ai-toolkit -n ai-toolkit --timeout=300s

echo ""
echo "步骤 3/3: 检查 Pod 状态..."
kubectl get pods -n ai-toolkit -l app=ai-toolkit

echo ""
echo "=========================================="
echo "更新完成！"
echo "=========================================="
echo ""
echo "如果 Pod 仍然有问题，可以尝试删除 Pod 让它重新创建："
echo "  kubectl delete pod -n ai-toolkit -l app=ai-toolkit"
echo ""
echo "查看 Pod 日志："
echo "  kubectl logs -n ai-toolkit -l app=ai-toolkit -f"
echo ""

