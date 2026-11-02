from collections import deque

# ======================================================
# 1. Khai báo tham số hệ thống (Map 1-1 với SystemVerilog)
# ======================================================
DATA_WIDTH   = 8
BAUD_RATE    = 115_200
CLK_FREQ     = 50_000_000
OVERSAMPLING = 16
BAUDTICK     = CLK_FREQ // (BAUD_RATE * OVERSAMPLING)
ADDR_WIDTH   = 4
FIFO_DEPTH   = 1 << ADDR_WIDTH  # 2^4 = 16 bytes


CLK_PERIOD   = 20  # 20ns (50MHz)
BIT_PERIOD   = CLK_PERIOD * BAUDTICK * OVERSAMPLING  # 8,640 ns / bit


# ======================================================
# 2. Mô hình hóa phần cứng (Golden Model của TOP_MODULE)
# ======================================================
class FifoGolden:
    """Mô hình hóa khối fifo.sv (Cơ chế FWFT, sâu 16 bytes)"""
    def __init__(self, depth=FIFO_DEPTH):
        self.depth = depth
        self.mem = deque()

    @property
    def empty_o(self):
        return len(self.mem) == 0

    @property
    def full_o(self):
        return len(self.mem) == self.depth

    @property
    def rd_data_o(self):
        # Cơ chế FWFT: Dữ liệu luôn trồi sẵn ở ngõ ra khi kho không rỗng
        return self.mem[0] if not self.empty_o else None

    def write(self, data):
        if not self.full_o:
            self.mem.append(data & 0xFF)

    def read(self):
        if not self.empty_o:
            self.mem.popleft()


class UartTopGolden:
    """Mô hình hóa khối TOP_MODULE.sv"""
    def __init__(self):
        self.fifo_rx = FifoGolden(FIFO_DEPTH)
        self.fifo_tx = FifoGolden(FIFO_DEPTH)
        self.rx_shift_reg = 0x00

    def uart_rx_process(self, bit_stream):
        """
        Mô phỏng khối UART_RX: Nhận chuỗi 10 bit (1 Start + 8 Data LSB + 1 Stop)
        Thực hiện dịch bit y hệt câu lệnh: next_b = {rx, b[7:1]}
        """
        start_bit = bit_stream[0]
        data_bits = bit_stream[1:9]
        stop_bit  = bit_stream[9]

        assert start_bit == 0, "Lỗi khung truyền: Start bit phải bằng 0!"
        assert stop_bit == 1,  "Lỗi khung truyền: Stop bit phải bằng 1!"

        self.rx_shift_reg = 0x00
        shift_history = [f"{self.rx_shift_reg:02x}"]

        for bit in data_bits:
            # Dịch phải 1 bit và nhét bit mới vào MSB (bit 7)
            self.rx_shift_reg = ((bit & 1) << 7) | (self.rx_shift_reg >> 1)
            shift_history.append(f"{self.rx_shift_reg:02x}")

        # In ra quá trình dịch thanh ghi (giống hệt trên Waveform ModelSim)
        print(f"      [UART_RX Shift Reg] {' -> '.join(shift_history)}")

        # Khi rxdone_o = 1 -> Ghi vào FIFO_RX (wr_en = rx_done)
        self.fifo_rx.write(self.rx_shift_reg)

    def handshake_process(self):
        """
        Mô phỏng mạch Handshake: assign en_transfer = (~rx_empty) & (~tx_full)
        Chuyển dữ liệu từ FIFO_RX sang FIFO_TX
        """
        while (not self.fifo_rx.empty_o) and (not self.fifo_tx.full_o):
            transfer_data = self.fifo_rx.rd_data_o
            self.fifo_tx.write(transfer_data)
            self.fifo_rx.read()

    def uart_tx_process(self):
        """
        Mô phỏng khối UART_TX: Khi tx_start = ~tx_empty, phát từng frame 10-bit ra uarttx_o
        """
        tx_bit_stream = []
        while not self.fifo_tx.empty_o:
            tx_data = self.fifo_tx.rd_data_o
            
            # Đóng gói frame UART: Start(0) + 8 bit Data (LSB first) + Stop(1)
            frame = [0] + [(tx_data >> i) & 1 for i in range(8)] + [1]
            tx_bit_stream.append(frame)

            # Phát xong 1 byte -> txdone_o = 1 kích hoạt rd_en của FIFO_TX
            self.fifo_tx.read()

        return tx_bit_stream


# ======================================================
# 3. Các hàm mô phỏng Testbench (Task send_byte & Monitor)
# ======================================================
sim_time = 0
dut = UartTopGolden()
golden_log = []

def send_byte(data_in):
    """Mô phỏng task send_byte(input logic [7:0] data_in) trong SystemVerilog"""
    global sim_time
    # Tạo khung truyền 10 bit: Start(0) + 8 Data bits (LSB-first) + Stop(1)
    bit_stream = [0] + [(data_in >> i) & 1 for i in range(8)] + [1]
    
    # Thời gian truyền 10 bit (1 Start + 8 Data + 1 Stop)
    sim_time += BIT_PERIOD * 10
    
    # Đưa chuỗi bit vào cổng uartrx_i của DUT
    dut.uart_rx_process(bit_stream)
    # Mạch Handshake tự động đẩy dữ liệu từ FIFO_RX sang FIFO_TX
    dut.handshake_process()

def monitor_and_wait(wait_bits):
    """Mô phỏng khối initial forever @(negedge uarttx_o) để bắt dữ liệu Echo"""
    global sim_time
    tx_frames = dut.uart_tx_process()
    
    for frame in tx_frames:
        # Kiểm tra Start bit == 0
        if frame[0] == 0:
            # Lấy mẫu 8 bit Data (từ LSB đến MSB)
            rx_data_out = 0
            for i in range(8):
                rx_data_out |= (frame[i + 1] << i)
            
            # Cộng thời gian truyền 1 frame (10 bit) và in kết quả
            echo_time = sim_time + (BIT_PERIOD * 10)
            print(f" ---> [{echo_time} ns] DUT Echo Received: 0x{rx_data_out:02x}")
            golden_log.append(rx_data_out)

    sim_time += BIT_PERIOD * wait_bits


# ======================================================
# 4. Kịch bản kiểm thử trực tiếp (Direct Stimulus)
# ======================================================
if __name__ == "__main__":
    # Reset 100ns + đợi 100ns
    sim_time = 200
    print("=== STARTING UART ECHO LOOPBACK TEST (PYTHON GOLDEN MODEL) ===")

    # --- Test 1: Truyền 1 byte đơn lẻ ---
    print(f"\n[{sim_time} ns] Test 1: Gui byte 0xA5 (1010_0101)")
    send_byte(0xA5)
    monitor_and_wait(15)

    # --- Test 2: Truyền 1 byte khác ---
    print(f"\n[{sim_time} ns] Test 2: Gui byte 0x5A (0101_1010)")
    send_byte(0x5A)
    monitor_and_wait(15)

    # --- Test 3: Bắn dồn dập (Burst Test) để test FIFO ---
    print(f"\n[{sim_time} ns] Test 3: Gui burst 3 bytes lien tiep (0x31, 0x32, 0x33)")
    send_byte(0x31)  # Ký tự '1'
    send_byte(0x32)  # Ký tự '2'
    send_byte(0x33)  # Ký tự '3'
    monitor_and_wait(40)

    print("\n=== SIMULATION COMPLETE ===")

    # Xuất file Golden Vectors để đối chiếu tự động với SystemVerilog
    with open("golden_vectors.hex", "w") as f:
        for val in golden_log:
            f.write(f"{val:02x}\n")
    print("Đã xuất đáp án chuẩn ra file 'golden_vectors.hex':", [f"0x{x:02x}" for x in golden_log])