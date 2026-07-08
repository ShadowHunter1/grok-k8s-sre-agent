# Namespace → Service Ownership Map

> Namespace ở đây chia làm 2 nhóm — Agent PHẢI xử lý khác nhau:
> - **STATIC**: workload cố định, bảng dưới đây là nguồn tin cậy (source of
>   truth). Đọc file, không cần query API để biết "namespace X có gì".
> - **DYNAMIC**: workload tạo/xóa liên tục, bảng dưới đây CHỈ để biết
>   *pattern/quy luật* (namespace nào thuộc nhóm động, đặt tên theo dạng gì).
>   TUYỆT ĐỐI không coi danh sách cụ thể trong bảng là còn đúng — luôn
>   live-query (`kubectl get pods -n <ns>`) trước khi kết luận.

---

## STATIC — Namespace cố định (tin theo file, không cần query để biết cấu trúc)

<!-- LỆNH CẬP NHẬT (chạy khi có namespace mới hoặc đổi workload):
kubectl get deploy,sts,ds -n <namespace> -o custom-columns=KIND:.kind,NAME:.metadata.name,LABELS:.metadata.labels
-->
| Service | Namespace | Workload type / name | Label selector gợi ý |
|---|---|---|---|
| MongoDB | datalake | StatefulSet: mongodb | app.kubernetes.io/name=mongodb |
| Kafka | datalake | StatefulSet/Deployment: kafka | app.kubernetes.io/name=kafka |
| NiFi | nifi | StatefulSet: nifi | app=nifi |
| MinIO | datalake | Deployment/StatefulSet: minio | app=minio |
| Apache Ranger | ranger | Deployment: ranger-admin | app=ranger |
| Ranger PostgreSQL | ranger | StatefulSet: ranger-postgresql | app=postgresql |
| Superset | lakehouse-poc | Deployment: superset | app=superset |
| Airflow scheduler | lakehouse-poc | Deployment: airflow-scheduler | app=airflow,component=scheduler |
| Airflow webserver | lakehouse-poc | Deployment: airflow-webserver | app=airflow,component=webserver |
| Prometheus/Alertmanager | cattle-monitoring-system | StatefulSet | app.kubernetes.io/name=prometheus |
| Grafana | cattle-monitoring-system | Deployment: grafana | app.kubernetes.io/name=grafana |
| ArgoCD | argocd | Deployment: argocd-server | app.kubernetes.io/part-of=argocd |

---

## DYNAMIC — Namespace sinh động (chỉ ghi pattern, KHÔNG ghi danh sách cụ thể)

<!-- LỆNH CẬP NHẬT (chạy định kỳ để cập nhật DANH SÁCH NAMESPACE, không phải nội dung bên trong):
kubectl get ns -l <label-phân-biệt-namespace-động-nếu-có>
# hoặc nếu theo naming pattern:
kubectl get ns | grep -E '<pattern>'
-->
| Namespace pattern | Mục đích | Naming convention | Ghi chú cho Agent |
|---|---|---|---|
| `job-*` | Namespace tạo cho batch job/notebook tạm | `job-<id>` | Luôn live-query, không giả định pod nào đang chạy |
| `<điền pattern thật>` | <điền> | <điền> | |

**Quy tắc bắt buộc khi làm việc với namespace động:**
1. Không bao giờ trả lời "namespace X có pod Y" chỉ dựa vào file này.
2. Luôn chạy `kubectl get pods -n <ns>` (đã filter/scoped) để xác nhận trạng
   thái hiện tại trước khi chẩn đoán.
3. Nếu user hỏi mà không rõ namespace động cụ thể, hỏi lại tên namespace
   thay vì quét toàn bộ (`-A`) — vì số lượng namespace động có thể lớn và
   quét hết sẽ tốn token.
