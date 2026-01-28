// --- 1. TOP LEVEL CPU WRAPPER (Updated with RAM) ---
module riscv (
    input  logic        clk, reset,
    output logic [31:0] WriteData,  
    output logic [31:0] DataAdr,    
    output logic        MemWrite    
);
    logic [31:0] PC, Instr, ReadData;
    logic [31:0] PCTarget, ImmExt;
    logic        Zero;
    logic        PCSrc, ALUSrc, RegWrite, Jump;
    logic [1:0]  ResultSrc, ImmSrc;
    logic [3:0]  ALUControl;

    // Controller
    controller c (
        .op(Instr[6:0]), .funct3(Instr[14:12]), .funct7b5(Instr[30]),
        .Zero(Zero), .ResultSrc(ResultSrc), .MemWrite(MemWrite),
        .PCSrc(PCSrc), .ALUSrc(ALUSrc), .RegWrite(RegWrite),
        .Jump(Jump), .ImmSrc(ImmSrc), .ALUControl(ALUControl)
    );

    // Datapath
    datapath dp (
        .clk(clk), .reset(reset),
        .ResultSrc(ResultSrc), .ALUSrc(ALUSrc),
        .RegWrite(RegWrite), .ImmSrc(ImmSrc),
        .ALUControl(ALUControl), .Instr(Instr),
        .ReadData(ReadData), // <--- CONNECTED TO RAM NOW!
        .ALUResult(DataAdr), .WriteData(WriteData), .Zero(Zero)
    );

    // Fetch Unit
    fetch f (
        .clk(clk), .reset(reset),
        .PCSrc(PCSrc), .PCTarget(PCTarget),
        .Instr(Instr), .PC(PC)
    );

    // DATA MEMORY (The New Module)
    dmem dmem_inst (
        .clk(clk),
        .we(MemWrite),
        .a(DataAdr),
        .wd(WriteData),
        .rd(ReadData)
    );

    // Branch Logic
    extend ext_top (.instr(Instr[31:7]), .immsrc(ImmSrc), .immext(ImmExt));
    assign PCTarget = PC + ImmExt; 

endmodule

module controller (
    input  logic [6:0] op,
    input  logic [2:0] funct3,
    input  logic       funct7b5, // Bit 30 of instruction (0 for add, 1 for sub)
    input  logic       Zero,
    output logic [1:0] ResultSrc,
    output logic       MemWrite,
    output logic       PCSrc, ALUSrc,
    output logic       RegWrite, Jump,
    output logic [1:0] ImmSrc,
    output logic [3:0] ALUControl
);

    logic [1:0] ALUOp;
    logic       Branch;

    // 1. MAIN DECODER
    maindec md (
        .op(op),
        .ResultSrc(ResultSrc),
        .MemWrite(MemWrite),
        .Branch(Branch),
        .ALUSrc(ALUSrc),
        .RegWrite(RegWrite),
        .Jump(Jump),
        .ImmSrc(ImmSrc),
        .ALUOp(ALUOp)
    );

    // 2. ALU DECODER
    aludec ad (
        .opb5(op[5]),
        .funct3(funct3),
        .funct7b5(funct7b5),
        .ALUOp(ALUOp),
        .ALUControl(ALUControl)
    );

    // Branch Logic: PC Source is 1 if (Branch & Zero) OR Jump
    assign PCSrc = (Branch & Zero) | Jump;

endmodule

// --- SUB-MODULE: MAIN DECODER ---
module maindec (
    input  logic [6:0] op,
    output logic [1:0] ResultSrc,
    output logic       MemWrite,
    output logic       Branch, ALUSrc,
    output logic       RegWrite, Jump,
    output logic [1:0] ImmSrc,
    output logic [1:0] ALUOp
);
    logic [10:0] controls;

    assign {RegWrite, ImmSrc, ALUSrc, MemWrite, ResultSrc, Branch, ALUOp, Jump} = controls;

    always_comb begin
        case(op)
            // lw (Load Word)
            7'b0000011: controls = 11'b1_00_1_0_01_0_00_0;
            // sw (Store Word)
            7'b0100011: controls = 11'b0_01_1_1_00_0_00_0;
            // R-Type (add, sub, etc.)
            7'b0110011: controls = 11'b1_xx_0_0_00_0_10_0;
            // beq (Branch Equal)
            7'b1100011: controls = 11'b0_10_0_0_00_1_01_0;
            // I-Type ALU (addi)
            7'b0010011: controls = 11'b1_00_1_0_00_0_10_0;
            // jal (Jump)
            7'b1101111: controls = 11'b1_11_x_0_10_0_xx_1;
            default:    controls = 11'b0_00_0_0_00_0_00_0;
        endcase
    end
endmodule

// --- SUB-MODULE: ALU DECODER ---
module aludec (
    input  logic       opb5,
    input  logic [2:0] funct3,
    input  logic       funct7b5,
    input  logic [1:0] ALUOp,
    output logic [3:0] ALUControl
);
    logic  RtypeSub;
    assign RtypeSub = funct7b5 & opb5; // True if instruction is SUB

    always_comb begin
        case(ALUOp)
            2'b00: ALUControl = 4'b0000; // LW/SW -> Add
            2'b01: ALUControl = 4'b1000; // BEQ   -> Sub
            default: case(funct3) // R-Type or I-Type
                3'b000: if (RtypeSub) ALUControl = 4'b1000; // SUB
                        else          ALUControl = 4'b0000; // ADD
                3'b010: ALUControl = 4'b0010; // SLT
                3'b110: ALUControl = 4'b0110; // OR
                3'b111: ALUControl = 4'b0111; // AND
                default: ALUControl = 4'bxxx; 
            endcase
        endcase
    end
endmodule

module fetch (
    input  logic        clk, reset,
    input  logic        PCSrc,       // 0 = Next Instr (PC+4), 1 = Jump (Target)
    input  logic [31:0] PCTarget,    // The Address to Jump to (from Datapath)
    output logic [31:0] Instr,       // The Instruction Code -> To Datapath
    output logic [31:0] PC           // The Current PC Address -> To Datapath
);

    logic [31:0] PCNext, PCPlus4;

    // 1. INSTANTIATE PC REGISTER
    flopr #(32) pcreg (
        .clk(clk), .reset(reset), 
        .d(PCNext), 
        .q(PC)
    );

    // 2. INSTANTIATE ADDER (Calculates PC + 4)
    adder pcadd (
        .a(PC), 
        .b(32'd4), 
        .y(PCPlus4)
    );

    // 3. INSTANTIATE INSTRUCTION MEMORY
    imem imem_inst (
        .a(PC), 
        .rd(Instr)
    );

    // 4. NEXT PC MUX LOGIC
    // If PCSrc is 1, we Jump. If 0, we just go to the next line (PC+4).
    assign PCNext = PCSrc ? PCTarget : PCPlus4;

endmodule

// PROGRAM COUNTER (PC) 
module flopr #(parameter WIDTH = 32) (
    input  logic             clk, reset,
    input  logic [WIDTH-1:0] d, 
    output logic [WIDTH-1:0] q
);
    always_ff @(posedge clk, posedge reset)
        if (reset) q <= 0;
        else       q <= d;
endmodule

//ADDER
module adder (
    input  logic [31:0] a, b,
    output logic [31:0] y
);
    assign y = a + b;
endmodule

//INSTRUCTION MEMORY (ROM)
module imem (
    input  logic [31:0] a,
    output logic [31:0] rd
);
    logic [31:0] RAM[63:0];
    initial begin
        // THE TEST PROGRAM:
        // 1. addi x1, x0, 5    (x1 = 5)
        RAM[0] = 32'h00500093; 
        
        // 2. sw x1, 84(x0)     (Write '5' to Mem Address 84)
        // Machine Code: 00102a23
        RAM[1] = 32'h00102a23; 

        // 3. lw x2, 20(x0)    Read from where we just wrote!
        RAM[2] = 32'h01402103;
    end
    assign rd = RAM[a[31:2]]; 
endmodule

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
    input  logic [3:0] ALUControl,
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

// --- 3. SIGN EXTENDER (You were missing this!) ---
module extend (
    input  logic [31:7] instr,
    input  logic [1:0]  immsrc,
    output logic [31:0] immext
);
    always_comb begin
        case(immsrc)
            2'b00: immext = {{20{instr[31]}}, instr[31:20]}; // I-Type
            2'b01: immext = {{20{instr[31]}}, instr[31:25], instr[11:7]}; // S-Type
            2'b10: immext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}; // B-Type
            2'b11: immext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0}; // J-Type
            default: immext = 32'bx;
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
  output logic [31:0] ALUResult, WriteData,
    output logic        Zero
);

    logic [31:0] PC; 
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

    // 2. SIGN EXTENDER
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
    assign Result = ALUResult;
endmodule

// ============================================================
// DATA MEMORY (RAM)
// ============================================================
module dmem (
    input  logic        clk, we,
    input  logic [31:0] a, wd,
    output logic [31:0] rd
);
    logic [31:0] RAM[63:0];

    // Read Logic (Combinational) returns data at address 'a'
    assign rd = RAM[a[31:2]]; // Word aligned

    // Write Logic (Synchronous)
    always_ff @(posedge clk) begin
        if (we) RAM[a[31:2]] <= wd;
    end
endmodule

