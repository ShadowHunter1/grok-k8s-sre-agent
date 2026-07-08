# Cluster Topology (Static Reference)

> File này chỉ ghi thông tin TĨNH (node, hardware, config ít đổi).
> Mỗi section có sẵn LỆNH CẬP NHẬT ngay phía trên — chạy lệnh, paste kết quả
> đè vào bảng bên dưới, KHÔNG cần đổi cấu trúc file.
> Cập nhật khi: thêm/bớt node, đổi label/taint, đổi storageclass.
> KHÔNG dùng file này cho namespace động — xem context/02-namespaces-map.md.

---

## Cluster Info

<!-- LỆNH CẬP NHẬT:
kubectl version -o json | jq -r '.serverVersion.gitVersion'
kubectl get nodes --no-headers | wc -l
-->
- Distro: Rancher RKE2
- Kubernetes version: <điền>
- Node count: <điền>
- Storage: NFS via nfs-subdir-external-provisioner (mountOptions: nfsvers=4.1)
- Registry: private registry nội bộ tại <url>
- Monitoring: Rancher Monitoring (kube-prometheus-stack); dashboard ConfigMap
  nằm ở namespace `cattle-dashboards`
- Ingress controller: nginx, entrypoint chung <domain>

---

## Node Roles & Hardware

<!-- LỆNH CẬP NHẬT:
kubectl get nodes -o custom-columns=NAME:.metadata.name,ROLE:.metadata.labels.node-role\\.kubernetes\\.io/control-plane,CPU:.status.allocatable.cpu,MEM:.status.allocatable.memory,ZONE:.metadata.labels.topology\\.kubernetes\\.io/zone

# Xem taint riêng:
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
-->
| Node | Role | Zone/Label | Taint | Allocatable CPU/Mem | Ghi chú |
|---|---|---|---|---|---|
| node-1 | control-plane | | NoSchedule | | |
| node-2 | worker | ssd=true | - | | |

---

## StorageClass

<!-- LỆNH CẬP NHẬT:
kubectl get storageclass -o custom-columns=NAME:.metadata.name,PROVISIONER:.provisioner,MOUNT_OPTS:.mountOptions
-->
| Name | Provisioner | mountOptions | Ghi chú |
|---|---|---|---|
| nfs-client | nfs-subdir-external-provisioner | nfsvers=4.1 | Đã fix lỗi NLM/lockd bị firewall chặn ở NFSv3 |

---

## Ingress / Network

<!-- LỆNH CẬP NHẬT:
kubectl get ingressclass
kubectl get svc -n <ingress-namespace> -l app.kubernetes.io/component=controller
-->
- IngressClass: nginx
- Domain pattern: `<service>.<domain>`
