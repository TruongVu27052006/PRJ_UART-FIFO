
module UART_RX #(
    parameter DATA_WIDTH    = 8,
    parameter TICKS_PER_BIT = 16,
    parameter HALF_BIT_TICK = TICKS_PER_BIT / 2,
    parameter SB_TICK       = TICKS_PER_BIT - 1
)(
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  uartrx_i,
    input  logic                  s_tick_i,
    output logic                  rxdone_o,
    output logic [DATA_WIDTH-1:0] uartrx_o
);

    //================================================
    // 1. Synchronize asynchronous UART input
    //================================================
    logic rx_meta;
    logic rx_sync;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
        end else begin
            rx_meta <= uartrx_i;
            rx_sync <= rx_meta;
        end
    end

    //================================================
    // 2. FSM states
    //================================================
    localparam [1:0] IDLE  = 2'b00;
    localparam [1:0] START = 2'b01;
    localparam [1:0] DATA  = 2'b10;
    localparam [1:0] STOP  = 2'b11;

    logic [1:0] state;

    // Counter widths depend on configuration
    localparam TICK_COUNT_WIDTH =
        (TICKS_PER_BIT <= 2) ? 1 : $clog2(TICKS_PER_BIT);

    localparam BIT_COUNT_WIDTH =
        (DATA_WIDTH <= 2) ? 1 : $clog2(DATA_WIDTH);

    logic [TICK_COUNT_WIDTH-1:0] tick_count;
    logic [BIT_COUNT_WIDTH-1:0]  bit_count;
    logic [DATA_WIDTH-1:0]       data_reg;

    //================================================
    // 3. UART receiver
    //================================================
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= IDLE;
            tick_count <= 0;
            bit_count  <= 0;
            data_reg   <= 0;
            uartrx_o   <= 0;
            rxdone_o  <= 1'b0;
        end else begin
            rxdone_o <= 1'b0;

            case (state)

                IDLE: begin
                    tick_count <= 0;
                    bit_count  <= 0;

                    if (rx_sync == 1'b0) begin
                        state      <= START;
                        tick_count <= 0;
                    end
                end

                START: begin
                    if (s_tick_i) begin
                        if (tick_count == HALF_BIT_TICK - 1) begin
                            tick_count <= 0;

                            if (rx_sync == 1'b0)
                                state <= DATA;
                            else
                                state <= IDLE;
                        end else begin
                            tick_count <= tick_count + 1'b1;
                        end
                    end
                end

                DATA: begin
                    if (s_tick_i) begin
                        if (tick_count == TICKS_PER_BIT - 1) begin
                            tick_count <= 0;
                            data_reg[bit_count] <= rx_sync;

                            if (bit_count == DATA_WIDTH - 1) begin
                                bit_count <= 0;
                                state <= STOP;
                            end else begin
                                bit_count <= bit_count + 1'b1;
                            end
                        end else begin
                            tick_count <= tick_count + 1'b1;
                        end
                    end
                end

                STOP: begin
                    if (s_tick_i) begin
                        if (tick_count == SB_TICK) begin
                            tick_count <= 0;
                            state <= IDLE;

                            if (rx_sync == 1'b1) begin
                                uartrx_o  <= data_reg;
                                rxdone_o <= 1'b1;
                            end
                        end else begin
                            tick_count <= tick_count + 1'b1;
                        end
                    end
                end

                default: begin
                    state      <= IDLE;
                    tick_count <= 0;
                    bit_count  <= 0;
                end

            endcase
        end
    end
endmodule
