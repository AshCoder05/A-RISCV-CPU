
// TESTBENCH FOR REGISTER FILE
module regfile_tb;

    logic        clk;
    logic        we3;           // Write Enable
    logic [4:0]  a1, a2, a3;    // Addresses
    logic [31:0] wd3;           // Write Data
    logic [31:0] rd1, rd2;      // Read Data

    regfile dut (
        .clk(clk),
        .we3(we3),
        .a1(a1), .a2(a2), .a3(a3),
        .wd3(wd3),
        .rd1(rd1), .rd2(rd2)
    );

    // 3. Clock Generation (Period = 10ns)
    always #5 clk = ~clk;

    // 4. Test Procedure
    initial begin
        $dumpfile("dump.vcd"); $dumpvars;
        $display("Starting RegFile Test...");
        
        // Initialize
        clk = 0; we3 = 0; 
        a1 = 0; a2 = 0; a3 = 0; wd3 = 0;
        #10; // Wait a cycle

        //TEST 1: Write 42 to Register x1
        $display("Test 1: Writing 42 to x1...");
        we3 = 1;      // Enable Write
        a3  = 5'd1;   // Address = 1
        wd3 = 32'd42; // Data = 42
        #10;          // Wait for Clock Edge (Write happens here)
        we3 = 0;      // Disable Write

        // Read it back
        a1 = 5'd1;
        #1; 
        if (rd1 === 42) $display("[PASS] x1 contains 42");
        else            $display("[FAIL] x1 = %d (Expected 42)", rd1);


        //TEST 2: Try to Overwrite x0 (Should Fail silently)
        $display("Test 2: Trying to write 99 to x0...");
        we3 = 1;
        a3  = 5'd0;   // Address = 0 (Forbidden!)
        wd3 = 32'd99;
        #10; 
        we3 = 0;

        // Read x0 back
        a1 = 5'd0;
        #1;
        if (rd1 === 0) $display("[PASS] x0 is still 0 (Write Ignored)");
        else           $display("[FAIL] x0 was overwritten with %d!", rd1);


        //TEST 3: Dual Read (Read x1 and x0 at same time)
        $display("Test 3: Reading x1 and x0 simultaneously...");
        a1 = 5'd1; // Should be 42
        a2 = 5'd0; // Should be 0
        #1;
        if (rd1 === 42 && rd2 === 0) $display("[PASS] Dual Read Successful");
        else                         $display("[FAIL] Read Error: x1=%d, x0=%d", rd1, rd2);

        $finish;
    end
endmodule
