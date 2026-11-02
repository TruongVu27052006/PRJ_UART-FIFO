module BAUD_GEN #(
    parameter CLK_FREQ   = 50_000_000, // Tần số clock hệ thống (VD: 50 MHz)
    parameter BAUD_RATE  = 115200,     // Tốc độ baud mong muốn
    parameter OVERSAMPLING = 16        // Tỷ lệ lấy mẫu (thường là 16 cho UART)
)(
    input  logic clk,
    input  logic rst_n,
    output logic s_tick_o
);

    // MAX = CLK_FREQ / (BAUD_RATE * OVERSAMPLING) - 1
    localparam int MAX_COUNT = CLK_FREQ / (BAUD_RATE * OVERSAMPLING) - 1;
    
    // Tính toán số bit cần thiết cho bộ đếm
    localparam int COUNTER_WIDTH = $clog2(MAX_COUNT + 1);

    logic [COUNTER_WIDTH-1:0] count_reg, count_next;

    // Khối thanh ghi
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_reg <= '0;
        end else begin
            count_reg <= count_next;
        end
    end

    // Khối logic tổ hợp: Tính toán giá trị đếm tiếp theo và tạo xung tick
    always_comb begin
        if (count_reg == MAX_COUNT) begin
            count_next = '0;
            s_tick_o   = 1'b1;
        end else begin
            count_next = count_reg + 1'b1;
            s_tick_o   = 1'b0;
        end
    end

endmodule
