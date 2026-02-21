`timescale 1ns/1ps

module regfile #(
    parameter WIDTH = 32,
    parameter DEPTH = 32,
    parameter ADDRW = $clog2(DEPTH)
)(
    input  logic              clk,
    input  logic              we,
    input  logic [ADDRW-1:0]  waddr,
    input  logic [WIDTH-1:0]  wdata,
    input  logic [ADDRW-1:0]  raddr1,
    input  logic [ADDRW-1:0]  raddr2,
    output logic [WIDTH-1:0]  rdata1,
    output logic [WIDTH-1:0]  rdata2,
    input  logic              fault_enable,
    input  logic [ADDRW-1:0]  fault_addr,
    input  logic [WIDTH-1:0]  fault_mask,
    input  logic [1:0]        fault_type  // 0=None, 1=Flip, 2=Stuck-0, 3=Stuck-1
);

    logic [WIDTH-1:0] mem [0:DEPTH-1];

    // Initialize memory to zero
    initial begin
        for (int i = 0; i < DEPTH; i++) mem[i] = 32'h0;
    end

    // Synchronous Write: x0 is hardwired to zero 
    always_ff @(posedge clk) begin
        if (we && waddr != 0)
            mem[waddr] <= wdata;
    end

    // Fault Injection Function [cite: 39, 43]
    function automatic [WIDTH-1:0] inject_fault(input [WIDTH-1:0] val, input [ADDRW-1:0] addr);
        if (fault_enable && (addr == fault_addr)) begin
            case (fault_type)
                2'b01: return val ^ fault_mask;   // bit-flip
                2'b10: return val & ~fault_mask;  // stuck-at-0
                2'b11: return val | fault_mask;   // stuck-at-1
                default: return val;
            endcase
        end else return val;
    endfunction

    // Combinatorial Read with Bypass Network 
    // If reading and writing the same address, forward wdata directly.
    assign rdata1 = (raddr1 == 0) ? 32'h0 : 
                    ((we && (waddr == raddr1)) ? inject_fault(wdata, raddr1) : inject_fault(mem[raddr1], raddr1));
                    
    assign rdata2 = (raddr2 == 0) ? 32'h0 : 
                    ((we && (waddr == raddr2)) ? inject_fault(wdata, raddr2) : inject_fault(mem[raddr2], raddr2));

endmodule
