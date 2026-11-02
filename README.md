📌 Các tính năng chính
Kiến trúc lõi: Thiết kế RTL dạng module bao gồm các khối độc lập: Khối Phát (uart_tx), Khối Thu (uart_rx), và Khối Tạo Tốc độ Baud (baud_gen).

Bộ đệm dữ liệu: Tích hợp các bộ đệm FIFO FWFT (First-Word Fall-Through) với độ trễ bằng không (zero-latency), giúp luồng dữ liệu RX/TX truyền phát đạt hiệu suất cao mà không gặp phải hiện tượng thắt cổ chai về băng thông (throughput).

Chế độ tự động Loopback: Được tích hợp ở mức phần cứng ngay trong module Top với cơ chế bắt tay (handshake) liền mạch (en_transfer = ~rx_empty & ~tx_full) cho phép kiểm tra phản hồi (echo testing) tức thì.

Khả năng cấu hình cao: Tham số hóa hoàn toàn độ rộng dữ liệu (DATA_WIDTH), số xung baud lấy mẫu (BAUDTICK), và độ sâu của bộ đệm FIFO (ADDR_WIDTH), giúp tích hợp vào hệ thống một cách linh hoạt.

Kiểm tra xác minh (Verification): Cung cấp testbench SystemVerilog toàn diện (tb_top_module.sv) chạy trên Questa/ModelSim, sử dụng Mô hình Vàng (Golden Model) được tạo bằng Python (golden_vectors.hex) phục vụ cho quá trình tự động kiểm tra (self-checking) và các kịch bản đọc chùm (burst-read).

📁 Cấu trúc thư mục
SRC/ : Chứa mã nguồn SystemVerilog RTL (top_module.sv, uart_rx.sv, uart_tx.sv, baud_gen.sv, fifo.sv) và môi trường Testbench (tb_top_module.sv, golden_vectors.hex).

REPORT/ : Chứa tài liệu dự án chi tiết, sơ đồ khối kiến trúc và các kết quả dạng sóng (waveform).

📖 Tài liệu
Các đặc tả kỹ thuật chi tiết, cấu hình tham số và báo cáo kết quả mô phỏng (simulation verification) đều có sẵn trong thư mục REPORT/.

# PROJECT UART

- Khối module top UART_TOP

<!-- Kéo thả hình ảnh sơ đồ UART_TOP của bạn vào dòng dưới đây để thay thế link -->
<img width="976" height="623" alt="UART-UART_TOP drawio" src="https://github.com/user-attachments/assets/6b42033e-4607-4656-964e-cb000370f5c2" />


---

Danh sách tín hiệu I/O các module

## Mục lục

* [UART_TOP](#uart_top)
* [UART_RX](#uart_rx)
* [UART_TX](#uart_tx)
* [BAUD_GEN](#baud_gen)
* [FIFO](#fifo)

---

### UART_TOP

File: `UART_TOP.sv`

| Tín hiệu | Hướng | Kiểu/Độ rộng | Ghi chú |
| :--- | :--- | :--- | :--- |
| uartrx_i | input | logic | Chân nhận dữ liệu RX |
| uarttx_o | output | logic | Chân truyền dữ liệu TX |
| clk | input | logic | Clock hệ thống |
| rst_n | input | logic | Reset, active-low |

<br>

### UART_RX

File: `UART_RX.sv`

| Tín hiệu | Hướng | Kiểu/Độ rộng | Ghi chú |
| :--- | :--- | :--- | :--- |
| uartrx_i | input | logic | Dữ liệu nối tiếp nhận vào |
| s_tick_i | input | logic | Xung nhịp lấy mẫu baud |
| rxdone_o | output | logic | Cờ báo nhận xong 1 byte |
| uartrx_o | output | logic [7:0] | Dữ liệu song song ngõ ra |

<br>

### UART_TX

File: `UART_TX.sv`

| Tín hiệu | Hướng | Kiểu/Độ rộng | Ghi chú |
| :--- | :--- | :--- | :--- |
| uarttx_i | input | logic [7:0] | Dữ liệu song song cần truyền |
| txstart_i | input | logic | Xung bắt đầu truyền dữ liệu |
| s_tick_i | input | logic | Xung nhịp lấy mẫu baud |
| txdone_o | output | logic | Cờ báo truyền xong 1 byte |
| uarttx_o | output | logic | Dữ liệu nối tiếp truyền ra |

<br>

### BAUD_GEN

File: `BAUD_GEN.sv`

| Tín hiệu | Hướng | Kiểu/Độ rộng | Ghi chú |
| :--- | :--- | :--- | :--- |
| clk | input | logic | Clock hệ thống |
| rst_n | input | logic | Reset, active-low |
| s_tick_o | output | logic | Xung tạo tốc độ baud ngõ ra |

<br>

### FIFO

File: `FIFO.sv`

| Tín hiệu | Hướng | Kiểu/Độ rộng | Ghi chú |
| :--- | :--- | :--- | :--- |
| clk | input | logic | Clock hệ thống (ký hiệu tam giác) |
| rst_n | input | logic | Reset, active-low |
| wr_en | input | logic | Tín hiệu cho phép ghi (Write Enable) |
| wr_data_i | input | logic [7:0] | Dữ liệu ghi vào FIFO |
| rd_en | input | logic | Tín hiệu cho phép đọc (Read Enable) |
| rd_data_o | output | logic [7:0] | Dữ liệu đọc ra từ FIFO |
| empty_o | output | logic | Cờ báo FIFO đang rỗng |
| full_o | output | logic | Cờ báo FIFO đã đầy |
