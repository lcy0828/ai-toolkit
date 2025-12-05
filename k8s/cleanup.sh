#!/bin/bash

set -e

echo "=========================================="
echo "AI Toolkit Kubernetes 清理脚本"
echo "=========================================="
echo ""

# 检查 kubectl 是否可用
if ! command -v kubectl &> /dev/null; then
    echo "错误: 未找到 kubectl 命令，请先安装 kubectl"
    exit 1
fi

# 确认删除
read -p "警告: 这将删除所有部署资源。是否继续? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消"
    exit 1
fi

# 询问是否删除 PVC（包含数据）
echo ""
read -p "是否删除持久化卷声明 (PVC)? 这将删除所有数据! (y/N): " -n 1 -r
echo
DELETE_PVC=false
if [[ $REPLY =~ ^[Yy]$ ]]; then
    DELETE_PVC=true
fi

# 询问是否删除命名空间
echo ""
read -p "是否删除命名空间 ai-toolkit? 这将删除命名空间中的所有资源! (y/N): " -n 1 -r
echo
DELETE_NS=false
if [[ $REPLY =~ ^[Yy]$ ]]; then
    DELETE_NS=true
fi

# 删除步骤
echo ""
echo "步骤 1/5: 删除服务..."
kubectl delete -f service.yaml --ignore-not-found=true

echo ""
echo "步骤 2/5: 删除部署..."
kubectl delete -f deployment.yaml --ignore-not-found=true

echo ""
echo "步骤 3/5: 删除密钥..."
kubectl delete -f secret.yaml --ignore-not-found=true

if [ "$DELETE_PVC" = true ]; then
    echo ""
    echo "步骤 4/5: 删除持久化卷声明..."
    kubectl delete -f pvc.yaml --ignore-not-found=true
    echo ""
    echo "所有 PVC 已删除（数据已丢失）"
else
    echo ""
    echo "步骤 4/5: 跳过 PVC 删除（数据已保留）"
fi

if [ "$DELETE_NS" = true ]; then
    echo ""
    echo "步骤 5/5: 删除命名空间..."
    kubectl delete -f namespace.yaml --ignore-not-found=true
    echo ""
    echo "命名空间已删除"
else
    echo ""
    echo "步骤 5/5: 跳过命名空间删除"
fi

echo ""
echo "=========================================="
echo "清理完成！"
echo "=========================================="

