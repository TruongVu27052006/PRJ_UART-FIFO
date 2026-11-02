A robust, highly configurable UART (Universal Asynchronous Receiver-Transmitter) IP with integrated FWFT FIFOs and automated loopback capabilities, implemented in SystemVerilog.

---

### 📌 Features

*   **Core Architecture:** Modular RTL design featuring independent Transmitter (`uart_tx`), Receiver (`uart_rx`), and Baud Rate Generator (`baud_gen`) blocks.
*   **Data Buffering:** Incorporates zero-latency FWFT (First-Word Fall-Through) FIFOs for highly efficient RX/TX data streaming without throughput bottlenecks.
*   **Auto-Loopback Mode:** Hardware-level integration in the Top module with a seamless handshake mechanism (`en_transfer = ~rx_empty & ~tx_full`) for instant echo testing.
*   **Highly Configurable:** Fully parameterized `DATA_WIDTH`, oversampling baud ticks (`BAUDTICK`), and FIFO depth (`ADDR_WIDTH`) for flexible system integration.
*   **Verification:** Comprehensive SystemVerilog testbench (`tb_top_module.sv`) running in Questa/ModelSim, utilizing a Python-generated Golden Model (`golden_vectors.hex`) for automated self-checking and burst-read scenarios.

---

### 📁 Repository Structure

*   `SRC/` : SystemVerilog RTL source codes (`top_module.sv`, `uart_rx.sv`, `uart_tx.sv`, `baud_gen.sv`, `fifo.sv`) and Testbench environment (`tb_top_module.sv`, `golden_vectors.hex`).
*   `REPORT/` : Comprehensive project documentation, architectural block diagrams, and waveform results.

---

### 📖 Documentation

Detailed specifications, parameter configurations, and simulation verification reports are available in the [REPORT/](REPORT/) directory.

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
