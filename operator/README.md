好的，以下是一个从 **0 到上线** 开发 Kubernetes Operator + CRD 的完整流程整理，使用的是 **kubebuilder + Go** 的主流方式，涵盖了从项目初始化到上线部署的每一步，并且结构清晰、可操作性强。

---

# ✅ Kubernetes Operator + CRD 开发上线全流程（基于 Kubebuilder）

---

## 🔨 Step 1: 安装工具链

```bash
go install sigs.k8s.io/kubebuilder/cmd@latest
go install sigs.k8s.io/controller-tools/cmd/controller-gen@latest
go install sigs.k8s.io/kustomize/kustomize/v5@latest
```

确保安装了：

- Go ≥ 1.20 (gvm 安装 1.24.0)
- Docker (25.0.5) 
> daemon.json :"exec-opts": ["native.cgroupdriver=systemd"]
> 宿主机要有 /sys/fs/cgroup/systemd/kubelet.slice/kubelet-kubepods.slice 目录
- kind (0.17.0)
> kind 也是在容器内启动的k8s，所以按照正常的定位k8s 问题的思路就可以
- kubectl (1.33.0) -- k8s 1.23.13
- 一个 k8s 集群（推荐 kind）<https://juejin.cn/post/7237680668951281721searchId=20250427113331D75B3DB34416E16FC311>

---
坑：NSDL 云桌面只支持 cgroup v1, k8s 1.25 版本以后启用了，用最新版本会有问题


## 🏗️ Step 2: 创建 Operator 工程

```bash
kubebuilder init --domain example.com --repo github.com/you/my-operator
```

你将获得一个标准化的工程结构，如：
```
.
├── api/
├── config/
├── controllers/
├── main.go
```

---

## 📦 Step 3: 创建 API 资源（CRD 类型）

```bash
kubebuilder create api --group app --version v1 --kind MyApp
```

这会创建：
- `api/v1/myapp_types.go`: 定义 CRD 的字段
- `controllers/myapp_controller.go`: 控制器逻辑

---

## ✏️ Step 4: 定义 CRD 结构

编辑 `api/v1/myapp_types.go`：

```go
type MyAppSpec struct {
  Image   string `json:"image"`
  Replicas *int32 `json:"replicas"`
}

type MyAppStatus struct {
  ReadyReplicas int32 `json:"readyReplicas"`
}
```

加上 marker：
```go
// +kubebuilder:subresource:status
// +kubebuilder:resource:shortName=ma
```

---

## ⚙️ Step 5: 自动生成 CRD 和代码

```bash
make generate        # 生成 deepcopy、client 等代码
make manifests       # 生成 CRD YAML、RBAC 配置等
```

---

## 🧠 Step 6: 编写控制器逻辑（核心逻辑）

编辑 `controllers/myapp_controller.go`：

```go
func (r *MyAppReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
    var myApp appv1.MyApp
    if err := r.Get(ctx, req.NamespacedName, &myApp); err != nil {
        return ctrl.Result{}, client.IgnoreNotFound(err)
    }

    // 示例：根据 CR 生成 Deployment
    desired := appsv1.Deployment{
        // 填写 metadata 和 spec（包含 image、replicas 等）
    }

    // 创建或更新 Deployment
    // 检查是否存在，不存在则 Create，存在则 Update
    ...
    
    // 更新 Status
    myApp.Status.ReadyReplicas = current.Status.ReadyReplicas
    r.Status().Update(ctx, &myApp)

    return ctrl.Result{}, nil
}
```

---

## 🧪 Step 7: 本地测试 Operator（推荐使用 kind）

### 7.1 启动 kind 集群：
```bash
kind create cluster --name operator-test
```

### 7.2 安装 CRD + RBAC 到集群：
```bash
make install
```

### 7.3 本地运行 controller（调试用）：
```bash
make run
```

---

## 🧪 Step 8: 编写自定义资源（测试 CR）

创建 `myapp.yaml`：

```yaml
apiVersion: app.example.com/v1
kind: MyApp
metadata:
  name: demo
spec:
  image: nginx:latest
  replicas: 2
```

应用资源：
```bash
kubectl apply -f myapp.yaml
```

观察效果：
```bash
kubectl get deployment
kubectl describe myapp demo
```

---

## 🐳 Step 9: 构建镜像并部署

```bash
make docker-build docker-push IMG=your-dockerhub/my-operator:v0.1.0
```

> 如果是本地 kind，可以用：
```bash
kind load docker-image your-dockerhub/my-operator:v0.1.0
```

---

## ☸️ Step 10: 部署 Operator 到集群中

```bash
make deploy IMG=your-dockerhub/my-operator:v0.1.0
```

确认：
```bash
kubectl get deployment -n my-operator-system
kubectl logs -f deploy/my-operator-controller-manager -n my-operator-system
```

---

## ✅ Step 11: 验证 Operator 效果

- 修改 `MyApp` 资源：看 Deployment 是否自动更新
- 删除资源：看是否自动重建
- 加 Finalizer：支持自定义删除前逻辑

---

## 📦 Step 12: 上线发布 & CI/CD

1. 镜像推送到镜像仓库（DockerHub、阿里云、Harbor）
2. 编写 Helm Chart 或 Operator Bundle
3. 配合 ArgoCD、Flux 实现 GitOps 管理 Operator
4. 添加 webhook 支持校验/默认值填充（可选）

---

## 🎁 附加建议

| 场景 | 建议 |
|------|------|
| 多资源关联 | 使用 `ownerReference` 自动级联删除 |
| 观测性 | 引入 Prometheus exporter 或 zap logging |
| 测试 | 使用 `envtest` 和 Ginkgo 做单元测试 |
| 重试策略 | 利用 `ctrl.Result{RequeueAfter: ...}` 控制 Reconcile 间隔 |

---

需要我为你：

- 搭一个完整工程模板（含 CR + Controller + 本地运行脚本）？
- 写一个实际的业务例子，比如自动部署 Redis 实例？
- 加 webhook 验证、状态管理、Finalizer 等进阶内容？

可以直接说，我可以分模块帮你搭起来。