#!/usr/bin/env bash
# ~/grok-k8s-sre/run.sh
# Ép Grok Build luôn chạy đúng thư mục, đúng kubeconfig read-only, đúng PATH guard.
set -euo pipefail

GROK_HOME="$HOME/grok-k8s-sre-agent"
export KUBECONFIG="$GROK_HOME/.kube/readonly-config"

# PATH guard: bin/kubectl (chặn verb ghi + streaming) phải được ưu tiên trước kubectl thật
export PATH="$GROK_HOME/bin:$PATH"

if [[ ! -f "$KUBECONFIG" ]]; then
  echo "❌ Không tìm thấy kubeconfig tại $KUBECONFIG" >&2
  echo "   Chạy rbac/make-kubeconfig.sh trước." >&2
  exit 1
fi

# Sanity check: đảm bảo kubeconfig KHÔNG có quyền ghi trước khi mở agent
if kubectl auth can-i delete pods -A --kubeconfig="$KUBECONFIG" 2>/dev/null | grep -q '^yes$'; then
  echo "❌ ABORT: kubeconfig này có quyền delete pods — KHÔNG an toàn để chạy Agent." >&2
  exit 1
fi

cd "$GROK_HOME"
exec grok "$@"
