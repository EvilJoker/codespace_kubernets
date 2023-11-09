为了学习 Kubernetes Operator 的开发，使用 Minikube 部署是一个不错的方式，因为 Minikube 可以在本地创建一个小型的 Kubernetes 集群，便于开发和测试。以下是一些步骤，帮助你开始开发一个 Kubernetes Operator 并在 Minikube 上部署它：

# 1. **安装 Minikube 和 kubectl**：

   首先，确保你已经在本地安装了 Minikube 和 `kubectl`。你可以按照 Minikube 官方文档的说明进行安装：https://minikube.sigs.k8s.io/docs/start/

# 2. **启动 Minikube**：

   在终端中运行以下命令，启动 Minikube 集群：

   ```shell
   minikube start
   ```

# 3. **开发 Operator**：
[官网入门](https://sdk.operatorframework.io/docs/building-operators/golang/quickstart/)
[深度讲解](https://sdk.operatorframework.io/docs/building-operators/golang/tutorial/)
[博客](https://zhuanlan.zhihu.com/p/515524518)
   开发 Kubernetes Operator 通常涉及以下步骤：
   
   a. 选择一个 Operator 框架或库，如 Operator SDK、Kubebuilder 等： Operator SDK
## 初始化项目
1. 初始化： operator-sdk init --domain example.com --repo github.com/example/memcached-operator
2. 创建api： operator-sdk create api --group cache --version v1alpha1 --kind Memcached --resource --controller
> api/v1alpha1/memcached_types.go api 类型定义
> controllers/memcached_controller.go 控制器定义
3. 创建和生成镜像：make docker-build docker-push IMG="example.com/memcached-operator:v0.0.1"
> 必须在 host 上使用 sudo 

## 项目结构介绍
https://book.kubebuilder.io/cronjob-tutorial/basic-project
+ go.mod：与我们的项目相匹配的新 Go 模块，带有 基本依赖关系
+ Makefile：为构建和部署控制器制定目标
+ PROJECT：用于脚手架新组件的 Kubebuilder 元数据
+ config 配置文件
> 1. [kustomize 配置格式](https://zhuanlan.zhihu.com/p/92153378) 
kustomize 是一套resource 模板。格式：  base +resources 。 resources 是 蓝图模板，base 声明了resources的集合
> 2. 比如 manager 是 manager 的配置， rbac 是文件的配置

+ main.go 入口文件

### main.go 文件介绍
https://book.kubebuilder.io/cronjob-tutorial/empty-main
> 1. 设置了一些标识
> 2. 创建一个 manager.Manager 对象，它跟踪运行所有的 controller 和 webhook，以及设置 将 cache 和 lient 共享到 API 服务器（请注意，我们告诉管理器 我们的计划）
> 3. ctrl.Options 中的 cache 可以限制监控的资源。

### api 的介绍
+ group-verision： 组是功能相关性聚合， 一个组有多个版本
+ kind: 每个 group-version 有很多 API types, 称为 kinds
+ resource: resource 是 api 中使用的 kind, 比如 deploy 中使用的 pod 就是一种 resource。
> 比如 deployments/scale 和 replicasets/scale 中的 scale 都是 resource

+ gvk / gvr， GroupVersionKind GroupVersionResource

+ groupversion_info.go zz_generated.deepcopy.go 不要编辑，默认生成的。zz_generated.deepcopy.go 是 深copy 方法


#### 创建一个 api
operator-sdk create api --group cache --version v1alpha1 --kind Memcached --resource --controller

+ gv :group.domain/v1alpha1, 生成的文件 api/v1alpha1 生成 memcached_types.go

memcached_types.go 中 定义了 api的对象。包括 spec, status 最终注册到 api 组中

#### 设计 api
https://book.kubebuilder.io/cronjob-tutorial/api-design
创建的是壳子，如何新加成员

### controller 介绍
+ 每个 controller 专注一个 根 kind ，但是可以和其他kind 交互
+ reconciler 协调器(核心逻辑): 放了和 api 交互的 client 端 和 kind 的 schema。 用来从 api-servce 获取 数据

```go
// CronJobReconciler reconciles a CronJob object
type CronJobReconciler struct {
    client.Client
    Scheme *runtime.Scheme
}
```
```
reconcile 详细解释
https://zhuanlan.zhihu.com/p/515524518 
https://sdk.operatorframework.io/docs/building-operators/golang/tutorial/

reconciler
1. 获取 CR 的实际状态  status ， 并执行逻辑到达期望的 CR 状态。
2. 每当 watch 的 CR 或resource 产生 event 时， 都会运行 reconciler ，如果命中就返回一些值
> 系统是事件驱动的，每产生 event ，命中的  reconciler 会被运行
3. 每个controller 都有 reconciler，其中 Reconcile 实现协调循环。
> reconcile 接受 request ， namespace/Name 键，用于从缓存中查找主资源对象 比如 cornjob


```




+ 权限 RBAC， 控制器在集群上运行的，所以需要 controller-tools 配置权限。
> 清单 at 是通过 controller-gen 使用以下命令从上述标记生成的：ClusterRoleconfig/rbac/role.yaml
> make manifests

### 添加 webhook 
暂不关注
https://book.kubebuilder.io/cronjob-tutorial/webhook-implementation

+ 日志 句柄、上下文

## memcahe operator 实践
https://sdk.operatorframework.io/docs/building-operators/golang/tutorial/
### 1 创建 工程
operator-sdk init --domain example.com --repo github.com/example/memcached-operator
+ domain 域名, 意味着 api 前缀

### 2 创建 api
operator-sdk create api --group cache --version v1alpha1 --kind Memcached --resource --controller

+ 生成 api/vialpha1/memcached_types.go : api 对象(spec ,status 等) -- schema
> 修改完 后， 运行 make generate --- 会调用  controller-gen ， 更新zz_generated.deepcopy.go 等方法
+ 生成 api/vialpha1/zz_generated.deepcopy.go : 拷贝方法
+ 生成 controller/groupversion_info.go : gv
+ 生成 controller/memcached_controller.go : 核心逻辑

### 3. 生成 CRD 清单

config/crd/bases/cache.example.com_memcacheds.yaml

+ make manifests 生成 CRD 清单--- kustomize 格式，k8s 识别的 yaml 模板

### 4. 实现控制器
memcached_controller.go 

+ main.go 中实现 创建一个 manager . 
> 1. 注册协调器  reconciler
> 2. 注册记录器 recorder 注册记录器
> 3. 启动 SetupWithManager

+ controllers/memcached_controller.go
> reconcile
> 1. 获取 memcached 对象
> 2. 获取 memcached 对象的 状态
> 3. 返回值 ：
>> a. 有错误/有错误，停止协调 return ctrl.Result{}, nil
>> b. 需要再次协调 return ctrl.Result{RequeueAfter: 5 * time.Minute}, nil

### 5. RBAC 清单
//+kubebuilder:rbac:groups=cache.example.com,resources=memcacheds,verbs=get;list;watch;create;update;patch;delete
这个是 标记，会生成 ClusterRoleconfig/rbac/role.yaml

+ 执行 make manifests

### 6 编译
+ Makefile 中  IMG ?= $(IMAGE_TAG_BASE):$(VERSION) 是镜像
+ make docker-build 编译镜像
> devcontainer 中无法编译，需要在主机上运行，先下载 Dockerfile的基础镜像

### 7 部署




gvk 实例
{
    "kind": "CronJob",
    "apiVersion": "batch.tutorial.kubebuilder.io/v1",
    ...
}

> 对于 crd， kind 和 资源一一对应

#
   b. 创建自定义资源定义（Custom Resource Definition，CRD）来定义你的 Operator 需要管理的自定义资源。
   > 
   > 构建：

   c. 编写 Operator 控制器逻辑，以便监视和管理自定义资源的状态。

   d. 构建和测试你的 Operator。

4. **部署 Operator**：

   一旦你的 Operator 开发完成，你可以使用以下步骤在 Minikube 上部署它：

   a. 构建 Operator 的 Docker 镜像。

   b. 将 Operator 镜像加载到 Minikube 集群中，以便集群可以访问该镜像。

   c. 创建 Operator 的 ServiceAccount、ClusterRole 和 ClusterRoleBinding，以便 Operator 具有足够的权限来管理资源。

   d. 部署 Operator 的 Deployment。

   e. 创建和配置 Custom Resource（使用你定义的 CRD）以测试 Operator 的功能。

5. **测试 Operator**：

   创建和操作自定义资源以测试 Operator 的行为。确保 Operator 正确地响应自定义资源的状态变化，执行相应的操作并更新状态。

6. **学习和调试**：

   使用 Minikube 部署后，你可以使用 `kubectl` 命令来查看日志、检查 Operator 控制器的状态以及调试问题。你还可以查看 Minikube 的仪表板以监视集群资源。

这是一个非常高层次的概述，开发 Kubernetes Operator 可能涉及到更多的细节和步骤，具体取决于你的 Operator 的需求和用例。建议参考 Operator SDK 或 Kubebuilder 的文档，以获取更详细的开发指南和示例。