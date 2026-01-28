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
