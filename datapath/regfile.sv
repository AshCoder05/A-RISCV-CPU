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
