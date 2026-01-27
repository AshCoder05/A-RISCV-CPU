
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
