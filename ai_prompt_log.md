# AI PROMPT LOG: TRA CỨU KIẾN TRÚC INDEX & TÍNH TOÁN DUNG LƯỢNG MYISAM/INNODB

## Session Context
- **Role**: Database Optimization Expert & Assistant
- **Task**: Tính toán chính xác dung lượng Byte phân bổ trên B-Tree Index cho InnoDB Engine.

---

### Prompt 1: Tra cứu cơ chế lưu trữ Secondary Index trong InnoDB
> **User**: *Giải thích cách InnoDB lưu trữ Secondary Index và tại sao thêm cột vào Secondary Index lại làm tăng dung lượng ổ cứng?*
> 
> **AI Assistant**: Trong InnoDB, bảng dữ liệu chính được lưu dưới dạng **Clustered Index** theo Primary Key (`log_id`). Mỗi **Secondary Index** tạo ra một cây B-Tree riêng biệt. Mỗi Node lá trong Secondary Index sẽ chứa:
> 1. Cột dữ liệu khai báo trong Index.
> 2. Giá trị của Primary Key (`log_id` - 8 Bytes) để trỏ về bảng gốc (Bookmark Lookup).
> Do đó, khi khai báo càng nhiều cột vào Secondary Index, kích thước mỗi Node trên B-Tree càng phình to, dẫn đến tốn RAM Buffer Pool và ổ cứng SSD.

---

### Prompt 2: Tính toán Byte chi tiết cho Fat Index vs. Lean Index
> **User**: *Tính toán kích thước dung lượng (Byte calculation) tính trên 1 bản ghi giữa `idx_fat_covering` và `idx_lean_search` trong MySQL.*
> 
> **AI Assistant**: 
> - **Cấu trúc cột & Kích thước Byte**:
>   - `sensor_id`: `INT` = 4 Bytes
>   - `recorded_at`: `DATETIME` = 5 Bytes
>   - `temperature`: `DECIMAL(5,2)` = 3 Bytes
>   - `humidity`: `DECIMAL(5,2)` = 3 Bytes
>   - `status`: `VARCHAR(20)` (UTF8MB4) = ~20-22 Bytes (trung bình)
>   - Con trỏ `log_id` (Primary Key `BIGINT` đính kèm mặc định): 8 Bytes
> 
> - **So sánh Dung lượng trên 1 Bản ghi**:
>   - **`idx_fat_covering`**: $4 + 5 + 3 + 3 + 22 + 8 = \mathbf{45\text{ Bytes/record}}$
>   - **`idx_lean_search`**: $4 + 5 + 8 = \mathbf{17\text{ Bytes/record}}$
> 
> **Kết luận**: Chuyển sang Lean Index giúp tiết kiệm **62.2%** kích thước lưu trữ của Index trên ổ đĩa và RAM.
