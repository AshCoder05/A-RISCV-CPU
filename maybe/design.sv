// FILE: design.sv (TOP LEVEL MODULE)
// Connects: Controller + Datapath + Fetch

module riscv (
    input  logic        clk, reset,
    output logic [31:0] WriteData,  // For Debugging (Data written to RegFile/RAM)
    output logic [31:0] DataAdr,    // For Debugging (ALU Result)
    output logic        MemWrite    // For Debugging (Write Enable Signal)
);

    // 1. WIRES (The cables connecting the modules)
    logic [31:0] PC, Instr, ReadData;
    logic [31:0] PCTarget;          // Jump Address
    logic [31:0] ImmExt;            // Extended Immediate
    logic        Zero;              // From ALU to Controller
    
    // Control Signals
    logic        PCSrc, ALUSrc, RegWrite, Jump;
    logic [1:0]  ResultSrc, ImmSrc;
    logic [3:0]  ALUControl;

    // --------------------------------------------------------
    // 2. INSTANTIATE CONTROLLER (The Brain)
    // --------------------------------------------------------
    controller c (
        .op(Instr[6:0]), 
        .funct3(Instr[14:12]), 
        .funct7b5(Instr[30]),
        .Zero(Zero),
        .ResultSrc(ResultSrc),
        .MemWrite(MemWrite),
        .PCSrc(PCSrc),
        .ALUSrc(ALUSrc),
        .RegWrite(RegWrite),
        .Jump(Jump),
        .ImmSrc(ImmSrc),
        .ALUControl(ALUControl)
    );

    // --------------------------------------------------------
    // 3. INSTANTIATE DATAPATH (The Muscle)
    // --------------------------------------------------------
    datapath dp (
        .clk(clk), .reset(reset),
        .ResultSrc(ResultSrc),
        .ALUSrc(ALUSrc),
        .RegWrite(RegWrite),
        .ImmSrc(ImmSrc),
        .ALUControl(ALUControl),
        .Instr(Instr),
        .ReadData(32'b0),     // Placeholder: We have no Data RAM yet
        .ALUResult(DataAdr),  // Output: ALU Calculation
        .WriteData(WriteData),// Output: Data to write
        .Zero(Zero)
    );

    // --------------------------------------------------------
    // 4. INSTANTIATE FETCH UNIT (The Supplier)
    // --------------------------------------------------------
    fetch f (
        .clk(clk), .reset(reset),
        .PCSrc(PCSrc),        // From Controller
        .PCTarget(PCTarget),  // From Glue Logic below
        .Instr(Instr),        // To Datapath & Controller
        .PC(PC)               // Debugging
    );

    
    // the Branch Target)
    // We need to calculate where to jump: Target = PC + Immediate
    
    // A. Duplicate Sign Extension (To get the Immediate value here)
    // (We need a second instance because the one in datapath is internal)
    extend ext_top (
        .instr(Instr[31:7]),
        .immsrc(ImmSrc),
        .immext(ImmExt)
    );

    // B. Adder (Target = PC + Immediate)
    assign PCTarget = PC + ImmExt;

endmodule
