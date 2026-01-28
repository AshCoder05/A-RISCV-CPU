

module datapath_tb;
    // 1. Declare Signals
    logic        clk, reset;
    logic [1:0]  ResultSrc;
    logic        ALUSrc, RegWrite;
    logic [1:0]  ImmSrc;
    logic [3:0]  ALUControl;
    logic [31:0] Instr, ReadData;
    
    // OUTPUTS from the Datapath
    logic [31:0] ALUResult;
    logic [31:0] WriteData; 
    logic        Zero;

    // 2. Instantiate Datapath
    datapath dut (
        .clk(clk), .reset(reset),
        .ResultSrc(ResultSrc),
        .ALUSrc(ALUSrc),
        .RegWrite(RegWrite),
        .ImmSrc(ImmSrc),
        .ALUControl(ALUControl),
        .Instr(Instr),
        .ReadData(ReadData),
        .ALUResult(ALUResult), 
        .WriteData(WriteData), 
        .Zero(Zero)
    );

    // 3. Clock
    always #5 clk = ~clk;

    // 4. Test
    initial begin
        $dumpfile("dump.vcd"); $dumpvars;
        clk = 0; reset = 1; ReadData = 0; ResultSrc = 0;
        #10 reset = 0;

        // TEST: addi x1, x0, 5
        $display("Testing: addi x1, x0, 5");
        Instr = 32'h00500093; 
        RegWrite = 1; ImmSrc = 2'b00; ALUSrc = 1; ALUControl = 4'b0000;
        #10; 

        if (ALUResult === 5) $display("[PASS] Result is 5");
        else                 $display("[FAIL] Result is %d", ALUResult);

        $finish;
    end
endmodule
