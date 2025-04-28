
# kind-dev.yaml

这个配置文件定义了一个名为 dev-cluster 的 Kubernetes 集群，包含一个 control-plane 节点和一个 worker 节点。control-plane 节点上还定义了两个额外的端口映射，将容器内的 80 和 443 端口分别映射到宿主机的 80 和 443 端口。

创建集群（单节点集群）

kind create cluster --config kind-dev.yaml  


停止集群

kind delete cluster --name dev-cluster 