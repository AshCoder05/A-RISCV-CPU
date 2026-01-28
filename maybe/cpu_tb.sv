// ============================================================
// FILE: testbench.sv
// Function: Runs the RISC-V CPU and checks if it works
// ============================================================
module testbench;
    logic        clk, reset;
    logic [31:0] WriteData, DataAdr;
    logic        MemWrite;

    // 1. INSTANTIATE YOUR CPU
    riscv dut (
        .clk(clk), 
        .reset(reset),
        .WriteData(WriteData), 
        .DataAdr(DataAdr), 
        .MemWrite(MemWrite)
    );

    // 2. GENERATE CLOCK (Ticks every 5 time units)
    always #5 clk = ~clk;

    // 3. RUN THE TEST
    initial begin
        $dumpfile("dump.vcd"); $dumpvars;
        
        $display("---------------------------------------------------------------");
        $display("Time | PC       | Instr    | State | ALU Result (DataAdr)");
        $display("---------------------------------------------------------------");
        
        // Initialize
        clk = 0; reset = 1;
        
        // Hold Reset for a moment
        #20 reset = 0;

        // Run simulation for enough cycles to finish the program
        #150; 
        $finish;
    end
    
    // 4. MONITOR OUTPUTS
    // Print the status every time the clock goes DOWN
    always @(negedge clk) begin
        if(!reset) begin
            $display("%4t | %h | %h | %s | %d", 
                     $time, 
                     dut.f.PC,          // Access internal PC
                     dut.f.Instr,       // Access internal Instruction
                     (MemWrite ? "WRITE" : " R/W "), 
                     DataAdr            // The calculation result
            );
        end
    end
endmodule
