`timescale 1ns/1ps

module async_fifo_tb;

    // Write Domain Signals (100 MHz -> 10ns period)
    reg        wr_clk;
    reg        wr_rst_n;
    reg        wr_en;
    reg  [7:0] data_in;
    wire       full;

    // Read Domain Signals (~71.4 MHz -> 14ns period)
    reg        rd_clk;
    reg        rd_rst_n;
    reg        rd_en;
    wire [7:0] data_out;
    wire       empty;

    // Instantiate the Asynchronous FIFO
    async_fifo uut (
        .wr_clk   (wr_clk),
        .wr_rst_n (wr_rst_n),
        .wr_en    (wr_en),
        .data_in  (data_in),
        .full     (full),
        .rd_clk   (rd_clk),
        .rd_rst_n (rd_rst_n),
        .rd_en    (rd_en),
        .data_out (data_out),
        .empty    (empty)
    );

    // Generate Two Independent Asynchronous Clocks
    always #5 wr_clk = ~wr_clk; // 10ns period (100 MHz)
    always #7 rd_clk = ~rd_clk; // 14ns period (~71.4 MHz)

    integer i;

    initial begin
        $dumpfile("async_fifo.vcd");
        $dumpvars(0, async_fifo_tb);

        $display("Time\t wr_en\t data_in\t full\t |\t rd_en\t data_out\t empty");
        $monitor("%0t\t %b\t %h\t\t %b\t |\t %b\t %h\t\t %b", 
                 $time, wr_en, data_in, full, rd_en, data_out, empty);

        // 1. Initialize & Reset Both Clock Domains
        wr_clk = 0; wr_rst_n = 0; wr_en = 0; data_in = 8'h00;
        rd_clk = 0; rd_rst_n = 0; rd_en = 0;
        #25;
        wr_rst_n = 1;
        rd_rst_n = 1;

        // 2. Write 16 bytes on wr_clk to fill the FIFO (full becomes 1)
        for (i = 1; i <= 16; i = i + 1) begin
            @(negedge wr_clk);
            if (!full) begin
                wr_en   = 1;
                data_in = i;
            end
        end
        @(negedge wr_clk);
        wr_en = 0;

        // Wait 30ns so the 2-Flop synchronizer passes wr_ptr_gray into rd_clk
        #30;

        // 3. Read all 16 bytes out on the slower rd_clk (empty becomes 1)
        for (i = 1; i <= 16; i = i + 1) begin
            @(negedge rd_clk);
            if (!empty) begin
                rd_en = 1;
            end
        end
        @(negedge rd_clk);
        rd_en = 0;

        #40 $finish;
    end

endmodule