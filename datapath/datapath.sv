


module datapath (
    input  logic        clk, reset,
    input  logic [1:0]  ResultSrc, 
    input  logic        ALUSrc,      // NEW: Control signal for the Mux
    input  logic        RegWrite,
    input  logic [1:0]  ImmSrc,      // NEW: Control signal for Extender
    input  logic [3:0]  ALUControl,
    input  logic [31:0] Instr,       // The full instruction!
    input  logic [31:0] ReadData,    // Data from RAM (ignore for now)
  output logic [31:0] ALUResult, WriteData,
    output logic        Zero
);

    logic [31:0] PC; // Program Counter (We'll add this next)
    logic [31:0] SrcA, SrcB;
    logic [31:0] Result;
    logic [31:0] ImmExt;  // Output of Sign Extender

    // 1. REGISTER FILE
    regfile rf (
      .clk(clk), .we3(RegWrite),
        .a1(Instr[19:15]),  // RS1 comes from these bits
        .a2(Instr[24:20]),  // RS2 comes from these bits
        .a3(Instr[11:7]),   // RD  comes from these bits
        .wd3(Result), 
        .rd1(SrcA), 
      .rd2(WriteData)
    );

    // 2. SIGN EXTENDER (Instantiate it here!)
    // TODO: Connect Instr[31:7] and ImmSrc
    extend ext ( .instr(Instr[31:7]), 
    .immsrc(ImmSrc),     
    .immext(ImmExt));

    // 3. ALU MUX (The critical Logic)
    // If ALUSrc is 0, we use ReadData2 (WriteData).
    // If ALUSrc is 1, we use ImmExt.
 	assign SrcB = ALUSrc ? ImmExt : WriteData ;

    // 4. ALU
    alu my_alu (
        .A(SrcA), .B(SrcB), .ALUControl(ALUControl),
        .Result(ALUResult), .Zero(Zero)
    );

    // Output Logic
    assign Result = ALUResult; // (Simplifying for now)
endmodule
