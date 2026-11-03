module UART_TOP #(
    parameter DATA_WIDTH = 8,       // Kích thước dữ liệu của FIFO
    parameter ADDR_WIDTH = 4,      // Số lượng ô chứa của FIFO
    parameter BAUD_RATE  = 115200,
    parameter CLK_FREQ   = 50_000_000
) (
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic                    uartrx_i,
    output logic                    uarttx_o
);

    //========= Khai báo các tín hiệu kết nối nội bộ =========
    logic                    s_tick;
    
    // UART_RX -> FIFO_RX
    logic                    rx_done;
    logic [DATA_WIDTH-1:0]   rx_data; 
    
    // Tín hiệu từ FIFO_RX 
    logic                    rx_empty;
    logic                    full_o; // Chưa dùng đến nhưng vẫn khai báo
    
    // FIFO_TX -> UART_TX
    logic                    tx_done;
    logic                    tx_empty;    
    logic                    tx_start;    
    logic [DATA_WIDTH-1:0]   tx_data; 
    logic                    tx_full;
    
    // Tín hiệu chuyển tiếp tự động (Loopback)
    logic                    en_transfer;
    logic [DATA_WIDTH-1:0]   transfer_data;

    // Logic tổ hợp nội bộ
    
    // Tạo tx_start từ tx_empty (Qua cổng NOT)
    assign tx_start = ~tx_empty;

    assign en_transfer = (~rx_empty) & (~tx_full);

    //========= Khởi tạo các module con (Instances) =========
    
    BAUD_GEN #(
        .BAUD_RATE(BAUD_RATE),
        .CLK_FREQ(CLK_FREQ)
    ) u_baud_gen (
        .clk      (clk),
        .rst_n    (rst_n),
        .s_tick_o (s_tick)          // 1 bit
    );
    //==================================================
    UART_RX #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_uart_rx (
        .clk      (clk),
        .rst_n    (rst_n),
        .uartrx_i (uartrx_i),
        .s_tick_i (s_tick),
        .rxdone_o (rx_done),        // 1 bit
        .uartrx_o (rx_data)         // 8 bit
    );
    //==================================================
    FIFO #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_fifo_rx (
        .clk      (clk),
        .rst_n    (rst_n),
        .wr_en    (rx_done),        // 1 bit
        .wr_data_i(rx_data),        // 8 bit
        .rd_en    (en_transfer),
        .empty_o  (rx_empty),
        .full_o   (),               // Bỏ trống nếu không dùng tới
        .rd_data_o(transfer_data)   // 8 bit
    );
    //==================================================
    FIFO #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_fifo_tx (
        .clk      (clk),
        .rst_n    (rst_n),
        .wr_en    (en_transfer),    // 1 bit
        .wr_data_i(transfer_data),  // 8 bit
        .rd_en    (tx_done),        // 1 bit
        .empty_o  (tx_empty),       // 1 bit và qua cổng NOT
        .full_o   (tx_full),
        .rd_data_o(tx_data)         // 8 bit
    );
    //==================================================
    UART_TX #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_uart_tx (
        .clk      (clk),
        .rst_n    (rst_n),
        .s_tick_i (s_tick),
        .txstart_i (tx_start),      // 1 bit và qua cổng NOT
        .uarttx_i (tx_data),        // 8 bit
        .uarttx_o (uarttx_o),
        .txdone_o (tx_done)         // 1 bit
    );

endmodule
