// TESTBENCH FOR 32-BIT ALU
module alu_tb;

    // 1. Declare signals
    logic [31:0] A, B;
    alu_ops    ALUControl;
    logic [31:0] Result;
    logic        Zero;

    // 2. Instantiate the ALU
    alu dut (
        .A(A), 
        .B(B), 
        .ALUControl(ALUControl), 
        .Result(Result), 
        .Zero(Zero)
    );

    // 3. Test Procedure
    initial begin
        $dumpfile("dump.vcd"); 
        $dumpvars;
        $display("Starting ALU Test...");

        // --- TEST 1: ADDITION ---
        A = 10; B = 20; ALUControl = ALU_ADD;
        #10; // Wait for logic to settle
        if (Result !== 30) $display("[FAIL] ADD: 10+20 = %d (Expected 30)", Result);
        else               $display("[PASS] ADD: 10+20 = 30");

        // --- TEST 2: SUBTRACTION ---
        A = 50; B = 20; ALUControl = ALU_SUB;
        #10;
        if (Result !== 30) $display("[FAIL] SUB: 50-20 = %d (Expected 30)", Result);
        else               $display("[PASS] SUB: 50-20 = 30");

        // --- TEST 3: ZERO FLAG ---
        A = 50; B = 50; ALUControl = ALU_SUB;
        #10;
        if (Zero !== 1)    $display("[FAIL] Zero Flag: Expected 1, Got %b", Zero);
        else               $display("[PASS] Zero Flag: 50-50 Correctly detected Zero");

        // --- TEST 4: SLT (Set Less Than) ---
        // Case A: 10 < 20 (True -> Should be 1)
        A = 10; B = 20; ALUControl = ALU_SLT;
        #10;
        if (Result !== 1)  $display("[FAIL] SLT: 10 < 20 should be 1, Got %d", Result);
        else               $display("[PASS] SLT: 10 < 20 is True");

        // Case B: 20 < 10 (False -> Should be 0)
        A = 20; B = 10; ALUControl = ALU_SLT;
        #10;
        if (Result !== 0)  $display("[FAIL] SLT: 20 < 10 should be 0, Got %d", Result);
        else               $display("[PASS] SLT: 20 < 10 is False");

        // --- TEST 5: LOGIC (AND) ---
      // A = 1010 (10), B = 1100 (12),AND should be 1000 (8)
        A = 32'hA; B = 32'hC; ALUControl = ALU_AND;
        #10;
        if (Result !== 32'h8) $display("[FAIL] AND: A&C = %h (Expected 8)", Result);
        else                  $display("[PASS] AND: A&C = 8");

        $display("Test Complete.");
    end

endmodule
