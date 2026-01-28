// 32-BIT ARITHMETIC LOGIC UNIT (ALU)


typedef enum logic [3:0] {
    ALU_ADD = 4'b0000,
    ALU_SUB = 4'b1000,
    ALU_AND = 4'b0111,
    ALU_OR  = 4'b0110,
    ALU_XOR = 4'b0100,
  	ALU_SLL = 4'b0001,
    ALU_SRL = 4'b0101, 
    ALU_SLT = 4'b0010
} alu_ops;

module alu (
    input  logic [31:0] A, B,
    input  alu_ops     ALUControl,
    output logic [31:0] Result,
    output logic        Zero
);

    always @(*) begin
      case (ALUControl)
            ALU_ADD:  Result = A + B;
            ALU_SUB:  Result = A - B;
            ALU_AND:  Result = A & B;
            ALU_OR:   Result = A | B;
            ALU_XOR:  Result = A ^ B;
            ALU_SLL:  Result = A << B[4:0]; // Shift amount is bottom 5 bits
            ALU_SRL:  Result = A >> B[4:0]; 
            
            //if A < B
            ALU_SLT:  Result = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;

            default:  Result = 0; // Default safety
        endcase
    end

    // If Result is 0, Zero becomes 1. 
    // The CPU uses this for BEQ (Branch if Equal).
    assign Zero = (Result == 0);

endmodule


// 32 x 32-BIT REGISTER FILE
module regfile (
    input  logic        clk,
    input  logic        we3,           // Write Enable (1 = Write, 0 = Read only)
    input  logic [4:0]  a1, a2, a3,    // Addresses: Read1, Read2, Write
    input  logic [31:0] wd3,           // Write Data
    output logic [31:0] rd1, rd2       // Read Data Outputs
);

    // 1. Create the Memory Array (32 registers, 32 bits each)
    logic [31:0] rf [31:0];

    // 2. READ LOGIC (Combinational / Asynchronous)
    // If address is 0, return 0 (Hardwired Zero). 
    // Otherwise, return the value in the array.
  always @(*) begin
        rd1 = (a1 != 0) ? rf[a1] : 32'b0;
        rd2 = (a2 != 0) ? rf[a2] : 32'b0;
    end

    // 3. WRITE LOGIC (Sequential / Synchronous)
    // Only write on the rising edge of the clock.
    // Never write to address 0.
    always @(posedge clk) begin
        if (we3 && (a3 != 0)) begin
            rf[a3] <= wd3;
        end
    end

endmodule

module extend (
    input  logic [31:7] instr,    // Top bits of the instruction
    input  logic [1:0]  immsrc,   // Control signal: What type of instruction is this?
    output logic [31:0] immext    // The 32-bit result
);
    
    always_comb begin
        case(immsrc)
            // 00: I-Type (addi, lw) - 12-bit signed
            // Take bit 31 (sign), repeat it 20 times, then append bits 31-20
            2'b00: immext = {{20{instr[31]}}, instr[31:20]};
            
            // 01: S-Type (sw) - 12-bit signed (split across two places)
            2'b01: immext = {{20{instr[31]}}, instr[31:25], instr[11:7]};

            // 10: B-Type (beq) - 13-bit signed (weird ordering!)
            2'b10: immext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
            
            // 11: J-Type (jal) - 20-bit signed
            2'b11: immext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
            
            default: immext = 32'bx; // Undefined
        endcase
    end
endmodule

module datapath (
    input  logic        clk, reset,
    input  logic [1:0]  ResultSrc, 
    input  logic        ALUSrc,      // NEW: Control signal for the Mux
    input  logic        RegWrite,
    input  logic [1:0]  ImmSrc,      // NEW: Control signal for Extender
    input  logic [3:0]  ALUControl,
    input  logic [31:0] Instr,       // The full instruction!
    input  logic [31:0] ReadData,    // Data from RAM (ignore for now)
  output logic [31:0] ALUResult, RegData2,
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
      .rd2(RegData2)
    );

    // 2. SIGN EXTENDER (Instantiate it here!)
    extend ext ( .instr(Instr[31:7]), 
    .immsrc(ImmSrc),     
    .immext(ImmExt));

    // 3. ALU MUX (The critical Logic)
  // If ALUSrc is 0, we use ReadData2 (RegData2).
    // If ALUSrc is 1, we use ImmExt.
 	 assign SrcB = ALUSrc ? ImmExt : RegData2 ;

    // 4. ALU
    alu my_alu (
        .A(SrcA), .B(SrcB), .ALUControl(ALUControl),
        .Result(ALUResult), .Zero(Zero)
    );

    // Output Logic
    assign Result = ALUResult; // (Simplifying for now)
endmodule
