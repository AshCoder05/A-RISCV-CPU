
module fetch_tb;

    logic        clk, reset;
    logic [31:0] PC, PCNext;
    logic [31:0] Instr;

    // 1. INSTANTIATE THE MODULES
    // We are manually wiring them together here to test the loop.
    
    // The PC Register
    flopr #(32) pcreg (
        .clk(clk), .reset(reset), 
        .d(PCNext), 
        .q(PC)
    );

    // The Adder (Logic: PCNext = PC + 4)
    adder pcadd (
        .a(PC), 
        .b(32'd4), 
        .y(PCNext)
    );

    // The Instruction Memory (Input: PC, Output: Instruction)
    imem imem_inst (
        .a(PC), 
        .rd(Instr)
    );

    // 2. CLOCK
    always #5 clk = ~clk;

    // 3. TEST
    initial begin
        $dumpfile("dump.vcd"); $dumpvars;
        $display("Time | PC       | Instruction (Hex)");
        $display("-------------------------------------");

        clk = 0; reset = 1;
        #10 reset = 0;

        // Cycle 1 (Address 0)
        // Expected: 0x00500093 (addi x1, x0, 5)
        #9; 
        $display("%4t | %h | %h", $time, PC, Instr);

        // Cycle 2 (Address 4)
        // Expected: 0xFFE08113 (addi x2, x1, -2)
        #10;
        $display("%4t | %h | %h", $time, PC, Instr);

        // Cycle 3 (Address 8)
        // Expected: 0x00A10193 (addi x3, x2, 10)
        #10;
        $display("%4t | %h | %h", $time, PC, Instr);

        $finish;
    end
endmodule
