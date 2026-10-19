-- ============================================================================
-- DỰ ÁN: SMARTFACTORY - TỐI ƯU HÓA HỆ THỐNG IOT
-- Tác giả: Database Optimization Expert
-- Mục tiêu: Loại bỏ Fat Covering Index, khởi tạo Lean Index để cân bằng Read/Write/Storage
-- ============================================================================

USE smartfactory_db;

-- ----------------------------------------------------------------------------
-- BƯỚC 1: ĐÁNH GIÁ TRẠNG THÁI HỆ THỐNG TRƯỚC KHI TỐI ƯU
-- ----------------------------------------------------------------------------

-- 1.1. Kiểm tra kích thước Bảng và Index hiện tại (Chạy trên môi trường thực tế)
SHOW TABLE STATUS LIKE 'SensorLogs';

-- 1.2. Kiểm tra hiệu năng truy vấn Dashboard với "Fat Covering Index"
-- Kết quả dự kiến: Cột Extra xuất hiện "Using index" (Covering Index hoạt động)
EXPLAIN SELECT temperature, humidity, status 
FROM SensorLogs 
WHERE sensor_id = 105 AND recorded_at >= '2026-06-20';


-- ----------------------------------------------------------------------------
-- BƯỚC 2: TIẾN HÀNH TỐI ƯU HÓA INDEX (RE-INDEXING)
-- ----------------------------------------------------------------------------

-- 2.1. Xóa Fat Index gây thắt cổ chai luồng Ghi (Write Bottleneck) và lãng phí bộ nhớ
ALTER TABLE SensorLogs DROP INDEX idx_fat_covering;

-- 2.2. Tạo Lean Index chỉ chứa các cột dùng làm điều kiện lọc (WHERE/ORDER BY)
CREATE INDEX idx_lean_search ON SensorLogs(sensor_id, recorded_at);


-- ----------------------------------------------------------------------------
-- BƯỚC 3: XÁC MINH VÀ CHỨNG MINH KẾT QUẢ
-- ----------------------------------------------------------------------------

-- 3.1. Kiểm tra lại kế hoạch thực thi (Execution Plan) sau khi đổi Index
-- Kết quả dự kiến:
-- - Cột key: Nhận diện và sử dụng 'idx_lean_search'
-- - Cột type: Giữ nguyên 'range' hoặc 'ref' (Truy vấn vẫn tận dụng tốt B-Tree Index)
-- - Cột Extra: MẤT dòng "Using index" (Do MySQL thực hiện Bookmark Lookup về Clustered Index để lấy temperature, humidity, status)
EXPLAIN SELECT temperature, humidity, status 
FROM SensorLogs 
WHERE sensor_id = 105 AND recorded_at >= '2026-06-20';

-- 3.2. Kiểm tra lại dung lượng Index_length sau khi tối ưu
SHOW TABLE STATUS LIKE 'SensorLogs';
