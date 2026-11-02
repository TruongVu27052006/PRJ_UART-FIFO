module FIFO #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input  logic rst_n,
    input  logic clk,
    input  logic wr_en,
    input  logic [DATA_WIDTH-1:0] wr_data_i,
    input  logic rd_en,
    output logic [DATA_WIDTH-1:0] rd_data_o,
    output logic full_o,
    output logic empty_o
);
// mang nho
    logic [DATA_WIDTH-1:0] fifo_mem [0:(1 << ADDR_WIDTH) - 1];

// con tro doc, ghi va bo dem
    logic [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
    logic [ADDR_WIDTH-1:0] next_wr_ptr, next_rd_ptr;
    logic [ADDR_WIDTH:0]    fifo_count, next_fifo_count;
// trang thai rong va day
    assign full_o  = (fifo_count == (1 << ADDR_WIDTH));
    assign empty_o = (fifo_count == 0);

// FWFT: 
    assign rd_data_o = fifo_mem[rd_ptr];


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            fifo_count <= 0;
        end
        else begin
        wr_ptr <= next_wr_ptr;
        rd_ptr <= next_rd_ptr;
        fifo_count <= next_fifo_count;
        end
    end

    always_comb begin
        next_wr_ptr = wr_ptr;
        next_rd_ptr = rd_ptr;
        next_fifo_count = fifo_count;
        //mo ta hanh vi doc va ghi 
        if (wr_en && !full_o) begin
            next_wr_ptr = wr_ptr + 1'b1;
        end
        if (rd_en && !empty_o) begin
            next_rd_ptr = rd_ptr + 1'b1;
        end
        
        case ({wr_en && !full_o, rd_en && !empty_o})
            2'b10: begin
            next_fifo_count = fifo_count + 1'b1; // ghi
            end
            2'b01: begin
            next_fifo_count = fifo_count - 1'b1; // doc
            end
            default: begin
            next_fifo_count = fifo_count; // khong co hanh vi
            end
        endcase
    end

    always_ff @(posedge clk) begin
        if (wr_en && !full_o) begin
            fifo_mem[wr_ptr] <= wr_data_i;
        end
    end
endmodule
