#!/bin/bash

set -e

echo "=========================================="
echo "AI Toolkit Kubernetes 部署脚本"
echo "=========================================="
echo ""

# 检查 kubectl 是否可用
if ! command -v kubectl &> /dev/null; then
    echo "错误: 未找到 kubectl 命令，请先安装 kubectl"
    exit 1
fi

# 检查是否已创建 secret
if [ ! -f "secret.yaml" ]; then
    echo "警告: 未找到 secret.yaml 文件"
    echo "正在从示例文件创建..."
    cp secret.yaml.example secret.yaml
    echo ""
    echo "请编辑 secret.yaml 文件，设置你的认证令牌，然后重新运行此脚本"
    echo "或者直接运行: kubectl create secret generic ai-toolkit-secret -n ai-toolkit --from-literal=auth-token=your_password"
    exit 1
fi

# 部署步骤
echo "步骤 1/5: 创建命名空间..."
kubectl apply -f namespace.yaml

echo ""
echo "步骤 2/5: 创建密钥..."
kubectl apply -f secret.yaml

echo ""
echo "步骤 3/5: 创建持久化卷声明..."
kubectl apply -f pvc.yaml

echo ""
echo "步骤 4/5: 部署应用..."
kubectl apply -f deployment.yaml

echo ""
echo "步骤 5/5: 创建服务..."
kubectl apply -f service.yaml

echo ""
echo "=========================================="
echo "部署完成！"
echo "=========================================="
echo ""
echo "检查部署状态:"
echo "  kubectl get pods -n ai-toolkit -l app=ai-toolkit"
echo ""
echo "查看服务:"
echo "  kubectl get svc -n ai-toolkit ai-toolkit"
echo ""
echo "查看日志:"
echo "  kubectl logs -n ai-toolkit -l app=ai-toolkit -f"
echo ""
echo "等待 Pod 就绪后，可以通过服务访问应用"
echo ""

