module de10_lite_top (
    input  logic        ADC_CLK_10, // Onboard 10MHz or 50MHz clock
    input  logic [9:0]  SW,         // Toggle switches
    input  logic [1:0]  KEY,        // Push buttons
    output logic [9:0]  LEDR        // Red LEDs
);

    // Clock Divider: Slows down the clock so you can see LED changes
    logic clk_slow;
    logic [24:0] clk_count;
    always_ff @(posedge ADC_CLK_10) begin
        clk_count <= clk_count + 1;
    end
    assign clk_slow = clk_count[24]; // Approx 0.3Hz

    // Internal Signals
    logic [31:0] rdata1_out;
    
    // Mapping Hardware to Register File [cite: 39]
    // SW[9]: fault_enable
    // SW[8:7]: fault_type
    // SW[4:0]: fault_addr (selecting which register to corrupt)
    // KEY[0]: Write Enable (active low on DE10)
    
    regfile #(32, 32) dut (
        .clk(clk_slow),
        .we(~KEY[0]),               // Manual write trigger
        .waddr(5'd1),               // Hardcoded write to Reg 1 for testing
        .wdata(32'hFFFFFFFF),       // Writing all 1s
        .raddr1(SW[4:0]),           // Read address selected by switches
        .raddr2(5'd0),
        .rdata1(rdata1_out),
        .rdata2(),
        .fault_enable(SW[9]),
        .fault_addr(SW[4:0]),       // Apply fault to the same addr we read
        .fault_mask(32'h00000001),  // Inject fault into Bit 0
        .fault_type(SW[8:7])
    );

    // Display the lower 10 bits of rdata1 on LEDs [cite: 25, 45]
    assign LEDR = rdata1_out[9:0];

endmodule
