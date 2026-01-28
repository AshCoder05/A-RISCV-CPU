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
    logic [31:0] RAM[63:0]; // A small memory (64 instructions max)

    initial begin
        // The Program: 
        // 0: addi x1, x0, 5  (x1 = 5)
        // 4: addi x2, x1, -2 (x2 = 3)
        // 8: addi x3, x2, 10 (x3 = 13)
        RAM[0] = 32'h00500093; 
        RAM[1] = 32'hFFE08113; 
        RAM[2] = 32'h00A10193; 
    end

    // Read Logic (Word Aligned)
    // The PC increments by 4 (0, 4, 8...), but our array index is 0, 1, 2...
    // So we divide the address by 4 (a[31:2]) to find the index.
    assign rd = RAM[a[31:2]]; 
endmodule
