`timescale 1ns / 1ps

module tb_UART_TOP;

    // ======================================================
    // 1. KHAI BÁO THAM SỐ VÀ TÍN HIỆU
    // ======================================================
    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 4;
    parameter BAUD_RATE  = 115200;
    parameter CLK_FREQ   = 50_000_000;

    parameter CLK_PERIOD = 20;

    parameter BAUDTICK   = CLK_FREQ / (BAUD_RATE * 16);
    parameter BIT_PERIOD = CLK_PERIOD * BAUDTICK * 16;

    logic clk;
    logic rst_n;
    logic uartrx_i;
    logic uarttx_o;

    // Bộ nhớ lưu Golden Vectors nạp từ file Python
    logic [7:0] expected_mem [0:255]; 
    integer total_expected_bytes = 0;

    integer test_idx;
    integer error_count;
    integer pass_count;

    logic [7:0] rx_data_out;

    // ======================================================
    // 2. KHỞI TẠO DUT
    // ======================================================
    UART_TOP #(
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH),
        .BAUD_RATE  (BAUD_RATE),
        .CLK_FREQ   (CLK_FREQ)
    ) dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .uartrx_i (uartrx_i),
        .uarttx_o (uarttx_o)
    );

    // ======================================================
    // 3. TẠO CLOCK 50 MHz
    // ======================================================
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // ======================================================
    // 4. TASK GỬI 1 BYTE UART - LSB FIRST
    // ======================================================
    task automatic send_byte(input logic [7:0] data_in);
        integer i;
        begin
            @(negedge clk);
            uartrx_i = 1'b0;
            #(BIT_PERIOD);

            for (i = 0; i < DATA_WIDTH; i = i + 1) begin
                uartrx_i = data_in[i];
                #(BIT_PERIOD);
            end

            uartrx_i = 1'b1;
            #(BIT_PERIOD);

            $display("[%0t ns] SENT: 0x%02h", $time, data_in);
        end
    endtask

    // ======================================================
    // 5. KỊCH BẢN KIỂM THỬ (NẠP GOLDEN MODEL)
    // ======================================================
    initial begin
        rst_n       = 1'b0;
        uartrx_i    = 1'b1;
        test_idx    = 0;
        error_count = 0;
        pass_count  = 0;

        // Đọc dữ liệu từ file hex do Python tạo ra
        $readmemh("golden_vectors.hex", expected_mem);

        // Tính tổng số byte mong đợi thu được từ file
        while (expected_mem[total_expected_bytes] !== 8'hxx && total_expected_bytes < 256) begin
            total_expected_bytes = total_expected_bytes + 1;
        end

        // Reset DUT
        repeat (10) @(negedge clk);
        rst_n = 1'b1;
        repeat (20) @(negedge clk);

        $display("========================================");
        $display(" START UART_TOP ECHO LOOPBACK TEST");
        $display(" Loaded %0d bytes from Golden Model", total_expected_bytes);
        $display(" BIT_PERIOD = %0d ns", BIT_PERIOD);
        $display("========================================");

        // Test 1
        $display("[%0t ns] Test 1: Send 0xA5", $time);
        send_byte(8'hA5);
        #(BIT_PERIOD * 15);

        // Test 2
        $display("[%0t ns] Test 2: Send 0x5A", $time);
        send_byte(8'h5A);
        #(BIT_PERIOD * 15);

        // Test 3: Burst test
        $display("[%0t ns] Test 3: Burst 0x31, 0x32, 0x33", $time);
        send_byte(8'h31);
        send_byte(8'h32);
        send_byte(8'h33);

        #(BIT_PERIOD * 40);

        $display("========================================");
        $display(" TEST SUMMARY");
        $display(" PASS COUNT : %0d / %0d", pass_count, total_expected_bytes);
        $display(" ERROR COUNT: %0d", error_count);

        if (error_count == 0 && pass_count == total_expected_bytes && total_expected_bytes > 0)
            $display(" >>> UART_TOP TEST PASSED <<<");
        else
            $display(" >>> UART_TOP TEST FAILED <<<");

        $display("========================================");
        $finish;
    end

    // ======================================================
    // 6. MONITOR VÀ SO SÁNH DỮ LIỆU TỰ ĐỘNG
    // ======================================================
    initial begin
        forever begin
            // 1. Chờ cạnh xuống của Start bit
            @(negedge uarttx_o);

            // 2. Đợi 0.5 chu kỳ bit để đến giữa Start bit
            #(BIT_PERIOD / 2);

            if (uarttx_o === 1'b0) begin
                // 3. Đợi 1 chu kỳ bit để tới giữa bit D0
                #(BIT_PERIOD);

                // 4. Đọc 8 bit data, LSB first
                for (integer i = 0; i < DATA_WIDTH; i = i + 1) begin
                    rx_data_out[i] = uarttx_o;
                    #(BIT_PERIOD);
                end

                // 5. So sánh với Golden Vector
                if (test_idx < total_expected_bytes) begin
                    if (rx_data_out === expected_mem[test_idx]) begin
                        pass_count = pass_count + 1;
                        $display("[%0t ns] PASS: Byte #%0d | Expected: 0x%02h | Received: 0x%02h",
                                 $time, test_idx + 1, expected_mem[test_idx], rx_data_out);
                    end else begin
                        error_count = error_count + 1;
                        $display("[%0t ns] FAIL: Byte #%0d | Expected: 0x%02h | Received: 0x%02h",
                                 $time, test_idx + 1, expected_mem[test_idx], rx_data_out);
                    end
                end else begin
                    error_count = error_count + 1;
                    $display("[%0t ns] ERROR: Unexpected Extra TX Byte 0x%02h", $time, rx_data_out);
                end

                test_idx = test_idx + 1;
            end
        end
    end

    // ======================================================
    // 7. WATCHDOG
    // ======================================================
    initial begin
        #20_000_000;
        $display("ERROR: Simulation timeout");
        $finish;
    end

endmodule