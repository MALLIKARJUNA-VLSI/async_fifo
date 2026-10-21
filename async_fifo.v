module async_fifo (
    // 1. Write Clock Domain Ports
    input  wire       wr_clk,
    input  wire       wr_rst_n,
    input  wire       wr_en,
    input  wire [7:0] data_in,
    output wire       full,

    // 2. Read Clock Domain Ports
    input  wire       rd_clk,
    input  wire       rd_rst_n,
    input  wire       rd_en,
    output reg  [7:0] data_out,
    output wire       empty
);

    // 3. 16x8 Memory Array (16 slots, 8 bits wide)
    reg [7:0] fifo_mem [0:15];

    // 4. 5-Bit Binary and Gray Pointers (4-bit address + 1 MSB wrap bit)
    reg  [4:0] wr_ptr_bin, rd_ptr_bin;
    wire [4:0] wr_ptr_gray, rd_ptr_gray;

    // 5. 2-Flop Synchronizer Registers for Clock Domain Crossing (CDC)
    reg [4:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2; // wr_ptr crossing into rd_clk
    reg [4:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2; // rd_ptr crossing into wr_clk

    // 6. Binary-to-Gray Conversion (Parallel XOR 1-Liners)
    assign wr_ptr_gray = wr_ptr_bin ^ (wr_ptr_bin >> 1);
    assign rd_ptr_gray = rd_ptr_bin ^ (rd_ptr_bin >> 1);

    // 7. Block 1: Write Clock Domain Logic
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_ptr_bin <= 5'd0;
        end else if (wr_en && !full) begin
            fifo_mem[wr_ptr_bin[3:0]] <= data_in; // Bottom 4 bits index 0..15
            wr_ptr_bin <= wr_ptr_bin + 1'b1;
        end
    end

    // 8. Block 2: Read Clock Domain Logic
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_ptr_bin <= 5'd0;
            data_out   <= 8'd0;
        end else if (rd_en && !empty) begin
            data_out   <= fifo_mem[rd_ptr_bin[3:0]]; // Bottom 4 bits index 0..15
            rd_ptr_bin <= rd_ptr_bin + 1'b1;
        end
    end

    // 9. Block 3: Synchronize rd_ptr_gray into Write Clock Domain (2-Flop CDC)
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            rd_ptr_gray_sync1 <= 5'd0;
            rd_ptr_gray_sync2 <= 5'd0;
        end else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end
    end

    // 10. Block 4: Synchronize wr_ptr_gray into Read Clock Domain (2-Flop CDC)
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            wr_ptr_gray_sync1 <= 5'd0;
            wr_ptr_gray_sync2 <= 5'd0;
        end else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end
    end

    // 11. Full and Empty Flag Logic (Evaluated in Gray Code)
    assign empty = (rd_ptr_gray == wr_ptr_gray_sync2);
    assign full  = (wr_ptr_gray == {~rd_ptr_gray_sync2[4:3], rd_ptr_gray_sync2[2:0]});

endmodule