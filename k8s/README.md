# AI Toolkit Kubernetes 部署指南

本目录包含将 AI Toolkit 部署到 Kubernetes 集群所需的配置文件。

## 文件说明

- `namespace.yaml` - 命名空间定义，所有资源将部署到 `ai-toolkit` 命名空间
- `deployment.yaml` - 主部署配置，包含容器、资源限制、卷挂载等
- `service.yaml` - 服务配置，用于暴露应用端口
- `pvc.yaml` - 持久化卷声明，用于数据存储
- `secret.yaml.example` - 密钥配置示例（包含敏感信息）

## 前置要求

1. 已配置的 Kubernetes 集群
2. 集群中已安装 NVIDIA GPU 设备插件（用于 GPU 支持）
3. 具有足够权限的 kubectl 配置
4. 已配置的存储类（StorageClass）

## 部署步骤

### 1. 创建命名空间

首先创建命名空间：

```bash
kubectl apply -f namespace.yaml
```

或者使用部署脚本自动创建（推荐）：

```bash
cd k8s
./deploy.sh
```

### 2. 创建密钥

首先，复制示例密钥文件并设置你的认证令牌：

```bash
cp secret.yaml.example secret.yaml
# 编辑 secret.yaml，设置你的 auth-token
```

然后创建密钥：

```bash
kubectl apply -f secret.yaml
```

### 3. 创建持久化卷声明

创建所有需要的 PVC：

```bash
kubectl apply -f pvc.yaml
```

**注意**：根据你的实际需求调整 PVC 中的存储大小和存储类名称。

### 4. 部署应用

创建 Deployment：

```bash
kubectl apply -f deployment.yaml
```

### 5. 创建服务

创建 Service 以暴露应用：

```bash
kubectl apply -f service.yaml
```

### 6. 检查部署状态

```bash
# 检查 Pod 状态
kubectl get pods -n ai-toolkit -l app=ai-toolkit

# 检查服务状态
kubectl get svc -n ai-toolkit ai-toolkit

# 查看 Pod 日志
kubectl logs -n ai-toolkit -l app=ai-toolkit -f
```

## 配置说明

### 命名空间

所有资源都部署在 `ai-toolkit` 命名空间中，这样可以：
- 隔离资源，避免与其他应用冲突
- 便于管理和清理
- 支持多环境部署（如 dev、staging、prod）

所有 kubectl 命令都需要使用 `-n ai-toolkit` 参数来指定命名空间。

### GPU 支持

部署配置中包含了 GPU 资源请求和限制。确保：

1. 集群节点已安装 NVIDIA GPU
2. 已安装 [NVIDIA Device Plugin](https://github.com/NVIDIA/k8s-device-plugin)
3. 节点标签正确（如果需要使用 nodeSelector）

### 存储配置

所有数据存储在单个 PVC (`ai-toolkit-storage`) 中，通过不同的子目录进行组织：

- `huggingface-cache/`: HuggingFace 模型缓存（建议至少 100Gi）
- `database/`: 数据库文件（10Gi 通常足够）
- `datasets/`: 训练数据集（根据数据集大小调整）
- `output/`: 训练输出和模型（根据需求调整）
- `config/`: 配置文件（5Gi 通常足够）

**优势**：
- 简化存储管理，只需管理一个 PVC
- 更灵活的存储分配，所有目录共享同一存储池
- 减少 PVC 数量，降低管理复杂度

**注意**：根据你的实际需求调整 PVC 中的总存储大小。默认设置为 1Ti，包含所有子目录的存储需求。

### 服务类型

在 `service.yaml` 中，服务类型设置为 `LoadBalancer`。根据你的环境，可以改为：

- `ClusterIP`: 仅在集群内部访问
- `NodePort`: 通过节点端口访问
- `LoadBalancer`: 通过云提供商的负载均衡器访问（需要云环境支持）

### 资源限制

在 `deployment.yaml` 中，资源限制设置为：

- CPU: 请求 2 核，限制 8 核
- 内存: 请求 8Gi，限制 32Gi
- GPU: 1 个 GPU

根据你的实际硬件和需求调整这些值。

## 访问应用

部署完成后，根据服务类型访问应用：

- **LoadBalancer**: 使用 `kubectl get svc ai-toolkit` 获取 EXTERNAL-IP
- **NodePort**: 使用 `<节点IP>:<NodePort>`
- **ClusterIP**: 仅在集群内部访问

默认端口为 `8675`，访问地址为：`http://<IP>:8675`

## 故障排查

### Pod 无法启动

```bash
# 查看 Pod 详细信息
kubectl describe pod -n ai-toolkit -l app=ai-toolkit

# 查看 Pod 日志
kubectl logs -n ai-toolkit -l app=ai-toolkit
```

### GPU 不可用

```bash
# 检查节点 GPU 资源
kubectl describe node <node-name> | grep nvidia.com/gpu

# 检查设备插件
kubectl get daemonset -n kube-system | grep nvidia

# 检查 Pod 的 GPU 分配
kubectl describe pod -n ai-toolkit -l app=ai-toolkit | grep nvidia.com/gpu
```

### 存储问题

```bash
# 检查 PVC 状态
kubectl get pvc -n ai-toolkit ai-toolkit-storage

# 查看 PVC 详细信息
kubectl describe pvc -n ai-toolkit ai-toolkit-storage

# 如果需要查看存储使用情况，可以进入 Pod 查看
kubectl exec -it -n ai-toolkit <pod-name> -- df -h /app/ai-toolkit
```

## 更新部署

更新镜像版本：

```bash
kubectl set image deployment/ai-toolkit ai-toolkit=ostris/aitoolkit:<new-tag> -n ai-toolkit
```

或者编辑 deployment.yaml 后重新应用：

```bash
kubectl apply -f deployment.yaml
```

## 删除部署

使用清理脚本（推荐）：

```bash
cd k8s
./cleanup.sh
```

或手动删除：

```bash
kubectl delete -f service.yaml
kubectl delete -f deployment.yaml
kubectl delete -f pvc.yaml  # 注意：这会删除所有数据
kubectl delete -f secret.yaml
kubectl delete -f namespace.yaml  # 可选：删除整个命名空间
```

## 注意事项

1. **数据持久化**: PVC 中的数据在删除 PVC 后会被删除（取决于存储类配置）。请确保重要数据已备份。

2. **GPU 节点选择**: 如果集群中有专门的 GPU 节点，可以在 `deployment.yaml` 中配置 `nodeSelector` 来指定节点。

3. **认证令牌**: 确保在生产环境中使用强密码作为认证令牌，以保护 UI 访问。

4. **资源监控**: 建议配置资源监控和告警，确保 Pod 有足够的资源运行。

