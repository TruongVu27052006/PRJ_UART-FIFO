module UART_TX #(
  parameter DATA_WIDTH = 8
) (
  input  logic clk,
  input  logic rst_n,
  input  logic [DATA_WIDTH-1:0] uarttx_i,
  input  logic s_tick_i,
  input  logic txstart_i,
  output logic uarttx_o,
  output logic txdone_o
);

  localparam IDLE  = 2'b00;
  localparam START = 2'b01;
  localparam DATA  = 2'b10;
  localparam STOP  = 2'b11;

  localparam SB_TICK = 16;
  localparam DATABIT = $clog2(DATA_WIDTH);

  logic [3:0] scount, n_scount;
  logic [DATABIT:0] bcount, n_bcount;
  logic [DATA_WIDTH-1:0] b, n_b;
  logic [1:0] state, n_state;
  logic n_txdone;
  logic n_tx;

  always_comb begin: proc_state
    n_state  = state;
    n_scount = scount;
    n_bcount = bcount;
    n_txdone = 1'b0;
    n_tx     = uarttx_o;
    n_b      = b;

    case (state)
      IDLE: begin
        n_tx = 1'b1;
        if (txstart_i && !txdone_o) begin
          n_state  = START;
          n_b      = uarttx_i;
          n_scount = 4'd0;
        end
      end

      START: begin
        n_tx = 1'b0;
        if (s_tick_i) begin
          if (scount == 4'd15) begin
            n_state  = DATA;
            n_scount = 4'd0;
            n_bcount = '0;
          end else begin
            n_scount = scount + 4'b1;
          end
        end
      end

      DATA: begin
        n_tx = b[0];
        if (s_tick_i) begin
          if (scount == 4'd15) begin
            n_scount = 4'd0;
            n_b = {1'b0, b[DATA_WIDTH-1 : 1]};
            if (bcount == DATA_WIDTH - 1) begin
              n_state = STOP;
            end else begin
              n_bcount = bcount + 4'b1;
            end
          end else begin
            n_scount = scount + 4'b1;
          end
        end
      end

      STOP: begin
        n_tx = 1'b1;
        if (s_tick_i) begin
          if (scount == SB_TICK - 1) begin
            n_txdone = 1'b1;
            n_state  = IDLE;
          end else begin
            n_scount = scount + 4'b1;
          end
        end
      end

      default: n_state = IDLE;
    endcase
  end

  always_ff @(posedge clk or negedge rst_n) begin: proc_output
    if (!rst_n) begin
      state    <= IDLE;
      scount   <= 4'd0;
      bcount   <= '0;
      b        <= '0;
      uarttx_o <= 1'b1;
      txdone_o <= 1'b0;
    end else begin
      state    <= n_state;
      scount   <= n_scount;
      bcount   <= n_bcount;
      b        <= n_b;
      uarttx_o <= n_tx;
      txdone_o <= n_txdone;
    end
  end

endmodule
