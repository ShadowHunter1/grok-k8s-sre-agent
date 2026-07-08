# SETUP.md — Grok Build Agent cho K8s Troubleshooting (Read-only)

Thực hiện trên **server quản lý** (nơi có quyền admin kubectl vào cluster
và nơi bạn sẽ chạy Grok Build).

## Bước 0 — Giải nén gói vào home directory

```bash
cd ~
unzip grok-k8s-sre-agent.zip
cd grok-k8s-sre-agent
```

## Bước 1 — Cài Grok Build CLI (nếu chưa có)

```bash
curl -fsSL https://x.ai/cli/install.sh | bash
grok --version   # kiểm tra
```

## Bước 2 — Apply RBAC read-only vào cluster

Dùng kubeconfig admin hiện có của bạn (KHÔNG phải kubeconfig sẽ tạo cho Agent):

```bash
kubectl apply -f rbac/clusterrole-grok-readonly.yaml
```

Kiểm tra:
```bash
kubectl get sa grok-readonly -n grok-agent
kubectl get clusterrole grok-readonly-sre
kubectl get clusterrolebinding grok-readonly-sre
```

> Nếu cluster của bạn chưa cài `metrics-server`, phần `kubectl top` trong
> AGENTS.md sẽ không hoạt động dù RBAC đã cấp quyền — đây là giới hạn của
> cluster, không phải RBAC.

## Bước 3 — Tạo kubeconfig read-only cho Agent

Sửa biến môi trường cho đúng cluster của bạn rồi chạy:

```bash
export K8S_API_ENDPOINT="https://172.16.48.5:6443"
export CA_CERT_PATH="/etc/rancher/rke2/server-ca.crt"   # RKE2: đường dẫn CA thật trên server
export TOKEN_DURATION="8760h"                            # 1 năm, tự chọn theo policy

bash rbac/make-kubeconfig.sh
```

Script sẽ tự kiểm chứng quyền (in ra `can-i delete/patch/create` phải là
`no`, `can-i get` phải là `yes`). Nếu sai, dừng lại kiểm tra trước khi đi tiếp.

## Bước 4 — Cấp quyền thực thi cho script

```bash
chmod +x run.sh
chmod +x bin/kubectl
chmod 600 .kube/readonly-config
```

## Bước 5 — Thêm alias vào shell

```bash
echo "alias grok-sre='$HOME/grok-k8s-sre-agent/run.sh'" >> ~/.bashrc   # hoặc ~/.zshrc
source ~/.bashrc
```

## Bước 6 — Điền thông tin cluster thật vào file context

Trước khi dùng thật, điền dữ liệu cluster của bạn vào các file sau (mỗi
file đã có sẵn lệnh `kubectl` cần chạy để lấy thông tin, ghi ngay phía
trên bảng cần điền):

```bash
$EDITOR context/01-cluster-topology.md     # node, storageclass, ingress
$EDITOR context/02-namespaces-map.md       # namespace tĩnh + pattern namespace động
$EDITOR context/03-known-issues-playbook.md
$EDITOR context/04-naming-conventions.md
```

## Bước 7 — Chạy thử

```bash
grok-sre
```

Trong phiên Agent, thử hỏi:
```
Pod nào trong namespace nifi đang không Running?
```

Kiểm tra Agent:
- Có đọc `context/*.md` trước khi gọi kubectl không (xem log/trace nếu CLI hỗ trợ)
- Có luôn kèm `-n <namespace>` thay vì `-A` không
- Có từ chối khi bạn thử yêu cầu "restart pod này giúp tôi" không

## Bảo trì định kỳ

| Việc | Tần suất | Lệnh |
|---|---|---|
| Rotate token kubeconfig | Trước khi hết `TOKEN_DURATION` | Chạy lại `rbac/make-kubeconfig.sh` |
| Cập nhật `context/01` (node/storage) | Khi có thay đổi hạ tầng | Xem lệnh ghi sẵn trong file |
| Cập nhật `context/02` (namespace tĩnh) | Khi thêm/bớt service | Xem lệnh ghi sẵn trong file |
| Audit RBAC chưa bị mở rộng ngoài ý muốn | Định kỳ (khuyến nghị hàng tháng) | `kubectl describe clusterrole grok-readonly-sre` |

## Ghi chú bảo mật

- `.kube/readonly-config` chứa token — **không commit vào git**, giữ `chmod 600`.
- Không cấp quyền đọc `secrets` cho ClusterRole này (đã loại trừ có chủ đích).
  Nếu sau này cần đọc 1 secret cụ thể để debug, tạo `Role`/`RoleBinding`
  riêng ở đúng 1 namespace, không mở rộng ClusterRole.
- `bin/kubectl` chỉ là lớp phòng thủ phụ — lớp chính vẫn là RBAC ở API
  server. Đừng tin tưởng tuyệt đối vào wrapper script.
