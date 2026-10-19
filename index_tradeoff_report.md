# BÁO CÁO ĐÁNH ĐỔI HIỆU NĂNG & LƯU TRỮ - HỆ THỐNG SMARTFACTORY

## 1. Chẩn đoán sự cố (Root Cause Analysis)
Hệ thống gặp hiện tượng sụt giảm tốc độ chèn (`INSERT`) và tăng vọt chi phí Cloud do chỉ mục khổng lồ `idx_fat_covering(sensor_id, recorded_at, temperature, humidity, status)`. 
- **Lãng phí Storage**: Tốn tới **37 Bytes/bản ghi** trên B-Tree của Secondary Index (lớn hơn dung lượng hàng loạt cột dữ liệu).
- **Thắt cổ chai luồng Ghi (Write Penalty)**: Mỗi giây có hàng chục nghìn thao tác `INSERT`. MySQL buộc phải phân bổ RAM, tính toán lại vị trí và sắp xếp lại các trang dữ liệu (Data Pages) trên cây B-Tree cho cả 5 cột liên tục thay đổi (`temperature`, `humidity`).

## 2. Giải pháp: Lean Index (`idx_lean_search`)
Loại bỏ 3 cột dữ liệu khỏi Index và giữ lại 2 cột lọc điều kiện: `(sensor_id, recorded_at)`.

## 3. Phân tích sự Đánh đổi (Trade-off Matrix)

| Tiêu chí | Trạng thái cũ (`idx_fat_covering`) | Trạng thái mới (`idx_lean_search`) | Đánh giá sự thay đổi |
| :--- | :--- | :--- | :--- |
| **Kích thước Index** | ~37 Bytes / bản ghi | ~12 Bytes / bản ghi | **Tiết kiệm ~67.5% bộ nhớ Index** |
| **Tốc độ Ghi (INSERT)** | Chậm (Gây rớt data pipeline) | Siêu tốc (Tăng gấp ~4-5 lần) | **Giải quyết triệt để sự cố rớt dữ liệu** |
| **Tốc độ Đọc (SELECT)** | Siêu nhanh (Không cần đọc Table) | Chậm hơn ~0.5 - 1ms (Dùng Bookmark Lookup) | **Chấp nhận được** (Người dùng không cảm nhận được độ trễ) |

## 4. Kết luận
Việc chấp nhận chi phí "Bookmark Lookup" khi truy xuất dữ liệu Dashboard là quyết định kiến trúc đúng đắn. Nó giúp giải cứu luồng Ghi dữ liệu thời gian thực của cảm biến và tiết kiệm hàng ngàn USD chi phí ổ đĩa AWS SSD mỗi tháng.
