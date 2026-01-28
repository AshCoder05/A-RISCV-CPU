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
