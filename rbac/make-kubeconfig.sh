#!/usr/bin/env bash
# make-kubeconfig.sh
# Tạo kubeconfig read-only cho Grok Build Agent từ ServiceAccount grok-readonly.
# Chạy script này SAU KHI đã: kubectl apply -f clusterrole-grok-readonly.yaml
set -euo pipefail

# ==== CHỈNH LẠI CHO ĐÚNG MÔI TRƯỜNG CỦA BẠN ====
K8S_API_ENDPOINT="${K8S_API_ENDPOINT:-https://<K8S_API_ENDPOINT>:6443}"
CA_CERT_PATH="${CA_CERT_PATH:-/etc/kubernetes/pki/ca.crt}"   # RKE2: /etc/rancher/rke2/rke2.yaml chứa CA, hoặc /var/lib/rancher/rke2/server/tls/server-ca.crt
TOKEN_DURATION="${TOKEN_DURATION:-8760h}"                     # 1 năm, nhớ set nhắc rotate
OUT_DIR="${OUT_DIR:-$HOME/grok-k8s-sre-agent/.kube}"
OUT_FILE="$OUT_DIR/readonly-config"
# ================================================

mkdir -p "$OUT_DIR"

echo "==> Tạo token cho ServiceAccount grok-readonly (namespace grok-agent, TTL=$TOKEN_DURATION)"
TOKEN=$(kubectl create token grok-readonly -n grok-agent --duration="$TOKEN_DURATION")

echo "==> Build kubeconfig tại: $OUT_FILE"
kubectl config set-cluster k8s-readonly \
  --server="$K8S_API_ENDPOINT" \
  --certificate-authority="$CA_CERT_PATH" \
  --embed-certs=true \
  --kubeconfig="$OUT_FILE"

kubectl config set-credentials grok-readonly \
  --token="$TOKEN" \
  --kubeconfig="$OUT_FILE"

kubectl config set-context grok-readonly-ctx \
  --cluster=k8s-readonly \
  --user=grok-readonly \
  --namespace=default \
  --kubeconfig="$OUT_FILE"

kubectl config use-context grok-readonly-ctx --kubeconfig="$OUT_FILE"

chmod 600 "$OUT_FILE"
chown "$(id -u):$(id -g)" "$OUT_FILE"

echo ""
echo "==> Kiểm chứng quyền (BẮT BUỘC phải trả về 'no' hết các dòng dưới đây):"
for verb in delete patch create apply; do
  result=$(KUBECONFIG="$OUT_FILE" kubectl auth can-i "$verb" pods -A 2>/dev/null || true)
  echo "  can-i $verb pods -A -> $result"
done

echo ""
echo "==> Kiểm chứng quyền đọc (phải trả về 'yes'):"
result=$(KUBECONFIG="$OUT_FILE" kubectl auth can-i get pods -A 2>/dev/null || true)
echo "  can-i get pods -A -> $result"

echo ""
echo "✅ Xong. Kubeconfig read-only đã sẵn sàng tại: $OUT_FILE"
echo "⚠️  Nhớ: token hết hạn sau $TOKEN_DURATION — đặt lịch chạy lại script này để rotate."
