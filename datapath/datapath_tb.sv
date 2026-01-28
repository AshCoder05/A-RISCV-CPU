
// TESTBENCH FOR CPU DATAPATH
module datapath_tb;

    // 1. Declare Signals to connect to the Datapath
    logic        clk, reset;
    logic [1:0]  ResultSrc;
    logic        ALUSrc;
    logic        RegWrite;
    logic [1:0]  ImmSrc;
    logic [3:0]  ALUControl;
    logic [31:0] Instr;
    logic [31:0] ReadData;
    logic [31:0] ALUResult, WriteData;
    logic        Zero;

    // 2. Instantiate the Datapath
    datapath dut (
        .clk(clk), .reset(reset),
        .ResultSrc(ResultSrc),   // 00 for now (ALU Result)
        .ALUSrc(ALUSrc),         // 1 for Immediate
        .RegWrite(RegWrite),     // 1 to write to register
        .ImmSrc(ImmSrc),         // 00 for I-Type
        .ALUControl(ALUControl), // 0000 for ADD
        .Instr(Instr),           // The Instruction Code
        .ReadData(ReadData),     // 0 (We have no RAM yet)
        .ALUResult(ALUResult), 
        .RegData2(RegData2), 
        .Zero(Zero)
    );

    // 3. Clock Generation
    always #5 clk = ~clk;

    // 4. Test Procedure
    initial begin
        $dumpfile("dump.vcd"); $dumpvars;
        
        // Initialize
        clk = 0; reset = 1; 
        ReadData = 0; ResultSrc = 0;
        #10 reset = 0;

        // ---------------------------------------------------------
        // INSTRUCTION: addi x1, x0, 5
        // Machine Code: 00500093 (Hex)
        // ---------------------------------------------------------
        $display("-------------------------------------------");
        $display("Testing: addi x1, x0, 5");
        
        // A. Put the Instruction on the bus
        Instr = 32'h00500093; 

        // B. Set Control Signals (Simulating the Decoder)
        RegWrite   = 1;       // We want to save the result
        ImmSrc     = 2'b00;   // It is an I-Type Instruction
        ALUSrc     = 1;       // Use the Immediate (5), not Register B
        ALUControl = 4'b0000; // ALU operation is ADD

        // C. Wait for the Clock Edge (Writing happens here)
        #10; 

        // D. Check the result
        // The ALU should output 5, and it should be inside x1.
        if (ALUResult === 5) begin
             $display("[PASS] Success! ALU calculated 5.");
             $display("       Signals: ImmExt=%d, SrcA=%d", dut.ImmExt, dut.SrcA);
        end else begin
             $display("[FAIL] Expected 5, got %d", ALUResult);
        end

        // ---------------------------------------------------------
        // OPTIONAL: Test a second instruction (addi x2, x1, -2)
        // Machine Code: FFE08113 (x2 = x1 + (-2)) -> x2 should be 3
        // ---------------------------------------------------------
        $display("Testing: addi x2, x1, -2");
        Instr = 32'hFFE08113;
        // Control signals stay the same for addi
        #10;

        if (ALUResult === 3) begin
             $display("[PASS] Success! 5 + (-2) = 3.");
        end else begin
             $display("[FAIL] Expected 3, got %d", ALUResult);
        end

        $finish;
    end
endmodule
