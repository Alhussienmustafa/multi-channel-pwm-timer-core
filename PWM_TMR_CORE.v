//------------------------------------------------------------
// Module Name: pwm_timer_core
/* Description: 
PWM/Timer Core with Wishbone Slave Interface
Implements Memory-Mapped Registers: Ctrl, Divisor, Period, DC
Supports PWM and Timer modes, down clocking, and interrupt generation
Fully Synchronous with CLK_I, with synchronizers for EXT_CLK domain
*/
// Author: AlHussein Mustafa
// Date: July 2025
//------------------------------------------------------------

module PWM_TMR_CORE (
    // Wishbone Slave Interface
    input  wire        CLK_I,      
    input  wire        RST_I,      
    input  wire [15:0] ADR_I,      
    input  wire [15:0] DAT_I,      
    output reg  [15:0] DAT_O,      
    input  wire        WE_I,       
    input  wire        STB_I,      
    input  wire        CYC_I,      
    output reg         ACK_O,      
    // Additional Inputs
    input  wire        EXT_CLK,    
    input  wire [15:0] I_DC,       
    // Outputs
    output reg  [3:0]  o_pwm   // 4 channels PWM & Interrupt Output
);

// Internal Signals
reg [15:0] main_counter1; // for channel 1
reg [15:0] main_counter2; // for channel 2
reg [15:0] main_counter3; // for channel 3
reg [15:0] main_counter4; // for channel 4
wire       selected_clk;  // Selected Clock (CLK_I or EXT_CLK)
wire       DIV_CLK;       // divided clock

// internal Registers Definition
reg [7:0]  ctrl_reg ;   
reg [15:0] divisor_reg; 
reg [15:0] period_reg1;
reg [15:0] period_reg2;
reg [15:0] period_reg3;
reg [15:0] period_reg4;
reg [15:0] dc_reg1;
reg [15:0] dc_reg2;
reg [15:0] dc_reg3;
reg [15:0] dc_reg4;      

wire clk_sel        = ctrl_reg[0]; // Bit 0: 1 = External Clock, 0 = CLK_I

// Clock Selection
assign selected_clk = clk_sel ? EXT_CLK : CLK_I;


reg [7:0] ctrl_sync [1:0]; // Synchronize ctrl_reg bits to selected_clk
// dual synchronizer for Ctrl Register
always @(posedge selected_clk or negedge RST_I) begin
    if (!RST_I) begin
        ctrl_sync[0] <= 0;
        ctrl_sync[1] <= 0;
    end
    else begin
        ctrl_sync[0] <= ctrl_reg;
        ctrl_sync[1] <= ctrl_sync[0];
    end
end

// ctrl sync output
wire [7:0] ctrl_sync_out = clk_sel ? ctrl_sync[1] : ctrl_reg;

// Ctrl Register Bits (synchronized)
wire mode_pwm       = ctrl_sync_out[1]; // Bit 1: 1 = PWM Mode, 0 = Timer Mode
wire pwm_en         = ctrl_sync_out[2]; // Bit 2: 1 = PWM, 0 = TIMER
wire tmr_cont       = ctrl_sync_out[3]; // Bit 3: 1 = Continuous run, 0 = Stop run
wire counter_en     = ctrl_sync_out[4]; // Bit 4: Main Counter Enable
wire interrupt_flag = ctrl_sync_out[5]; // Bit 5: Interrupt Flag
wire CHS_DC         = ctrl_sync_out[6]; // Bit 6: PWM Output Enable
wire counter_rst    = ctrl_sync_out[7]; // Bit 7: Main Counter Reset


//cont condition
wire cont_count     = (tmr_cont || !interrupt_flag); 

// Synchronizer for I_DC
reg [15:0] i_dc_sync [1:0];
always @(posedge selected_clk or negedge RST_I) begin
    if (!RST_I) begin
        i_dc_sync[0] <= 0;
        i_dc_sync[1] <= 0;
    end
    else begin
        i_dc_sync[0] <= I_DC;
        i_dc_sync[1] <= i_dc_sync[0];
    end
end

wire [15:0] i_dc_sync_out = clk_sel ? i_dc_sync[1] : I_DC;

// Synchronizers for registers crossing from CLK_I to EXT_CLK
reg [15:0] divisor_sync [1:0];
reg [15:0] period_sync1 [1:0];
reg [15:0] period_sync2 [1:0];
reg [15:0] period_sync3 [1:0];
reg [15:0] period_sync4 [1:0];
reg [15:0] dc_sync1 [1:0];
reg [15:0] dc_sync2 [1:0];
reg [15:0] dc_sync3 [1:0];
reg [15:0] dc_sync4 [1:0];

// dual synchronizers implementaion (divisor+period+duty cucle)
always @(posedge selected_clk or negedge RST_I) begin
    if (!RST_I) begin
        divisor_sync[0] <= 0;
        divisor_sync[1] <= 0;

        period_sync1[0] <= 0;
        period_sync1[1] <= 0;
        dc_sync1[0] <= 0;
        dc_sync1[1] <= 0;

        period_sync2[0] <= 0;
        period_sync2[1] <= 0;
        dc_sync2[0] <= 0;
        dc_sync2[1] <= 0;

        period_sync3[0] <= 0;
        period_sync3[1] <= 0;
        dc_sync3[0] <= 0;
        dc_sync3[1] <= 0;

        period_sync4[0] <= 0;
        period_sync4[1] <= 0;
        dc_sync4[0] <= 0;
        dc_sync4[1] <= 0;
    end
    else begin
        divisor_sync[0] <= divisor_reg;
        divisor_sync[1] <= divisor_sync[0];

        period_sync1[0] <= period_reg1;
        period_sync1[1] <= period_sync1[0];

        period_sync2[0] <= period_reg2;
        period_sync2[1] <= period_sync2[0];

        period_sync3[0] <= period_reg3;
        period_sync3[1] <= period_sync3[0];

        period_sync4[0] <= period_reg4;
        period_sync4[1] <= period_sync4[0];

        dc_sync1[0] <= dc_reg1;
        dc_sync1[1] <= dc_sync1[0];

        dc_sync2[0] <= dc_reg2;
        dc_sync2[1] <= dc_sync2[0];

        dc_sync3[0] <= dc_reg3;
        dc_sync3[1] <= dc_sync3[0];

        dc_sync4[0] <= dc_reg4;
        dc_sync4[1] <= dc_sync4[0];
    end
end
 //Sync Outputs
wire [15:0] divisor_sync_out = clk_sel ? divisor_sync[1] : divisor_reg;

wire [15:0] period_sync_out1 = clk_sel ? period_sync1[1] : period_reg1;
wire [15:0] period_sync_out2 = clk_sel ? period_sync2[1] : period_reg2;
wire [15:0] period_sync_out3 = clk_sel ? period_sync3[1] : period_reg3;
wire [15:0] period_sync_out4 = clk_sel ? period_sync4[1] : period_reg4;

wire [15:0] dc_sync_out1 = clk_sel ? dc_sync1[1] : dc_reg1;
wire [15:0] dc_sync_out2 = clk_sel ? dc_sync2[1] : dc_reg2;
wire [15:0] dc_sync_out3 = clk_sel ? dc_sync3[1] : dc_reg3;
wire [15:0] dc_sync_out4 = clk_sel ? dc_sync4[1] : dc_reg4;

// dc sync output
wire [15:0] dc_used_syn = CHS_DC ? i_dc_sync_out : dc_sync_out1; //only the first channel can use the input dc register

// Down Clocking Logic
assign CLK_EN = (divisor_sync_out == 0 || divisor_sync_out == 1) ? 0 : 1;

// Integer Clock Divider Instantiation
CLK_Division CLK_Division (
    .ref_clk(CLK_I),
    .rst(RST_I),
    .clk_En(CLK_EN),
    .Div_rat(divisor_sync_out),
    .Div_Clk(DIV_CLK)
);


// For Wishbone Operations
wire wb_valid    = STB_I & CYC_I;      // Valid Wishbone transaction
wire [4:0] addr_low = ADR_I[4:0];      // Use lower 3 bits for register selection

// Wishbone Write & Read Logic in all registers
always @(posedge CLK_I, negedge RST_I) begin
    if (!RST_I) begin
// reset all registers
        ctrl_reg[7:6]    <= 2'b00;
        ctrl_reg[4:0]    <= 5'b00000;
        divisor_reg      <= 16'h0
        period_reg1      <= 16'h0000;
        period_reg2      <= 16'h0000;
        period_reg3      <= 16'h0000;
        period_reg4      <= 16'h0
        dc_reg1          <= 16'h0000;
        dc_reg2          <= 16'h0000;
        dc_reg3          <= 16'h0000;
        dc_reg4          <= 16'h0
        DAT_O            <= 16'h0000;  
        ACK_O            <= 1'b0;
    end
    else if (wb_valid) begin
        if (WE_I) begin     //write operation
            ACK_O <= 1;
            case (addr_low)
                0:  ctrl_reg     <= DAT_I[7:0];
                2:  divisor_reg  <= DAT_I;
                4:  period_reg1  <= DAT_I;
                6:  dc_reg1      <= DAT_I;
                8:  dc_reg2      <= DAT_I;
                10: dc_reg3      <= DAT_I;
                12: dc_reg4      <= DAT_I;
                14: period_reg2  <= DAT_I;
                16: period_reg3  <= DAT_I;
                18: period_reg4  <= DAT_I;
            endcase
        end
        else if (!WE_I) begin  //read operation
            ACK_O <= 1;
            case (addr_low)
                0:  DAT_O       <= {8'h0, ctrl_reg};
                2:  DAT_O       <= divisor_reg;
                4:  DAT_O       <= period_reg1;
                6:  DAT_O       <= dc_used_syn;
                8:  DAT_O       <= dc_reg2;
                10: DAT_O       <= dc_reg3;
                12: DAT_O       <= dc_reg4;
                14: DAT_O       <= period_reg2;
                16: DAT_O       <= period_reg3;
                18: DAT_O       <= period_reg4;
                default: DAT_O  <= 16'h0000;
            endcase
        end
    end
    else if (counter_rst) begin // clear flag condition
        ctrl_reg[5]   <= 0;
    end
    else if ((main_counter1 == (period_sync_out1-1)) && !mode_pwm) begin // tmr mode
        ctrl_reg[5] <= 1;
    end

    else ACK_O <= 0;
end

// Main Counters
always @(posedge DIV_CLK) begin
    if (counter_rst) begin
        main_counter1 <= 0;
        main_counter2 <= 0;
        main_counter3 <= 0;
        main_counter4 <= 0;
    end
    else if (counter_en && cont_count) begin
        main_counter1 <= main_counter1 + 1'b1;
        if ((main_counter1 == (period_sync_out1-1)) && !mode_pwm) begin //tmr mode
            main_counter1 <= 0;
        end
        else if (mode_pwm) begin //pwm mode
            main_counter2 <= main_counter2 + 1'b1;
            main_counter3 <= main_counter3 + 1'b1;
            main_counter4 <= main_counter4 + 1'b1;
            if (main_counter1 == (period_sync_out1-1))  main_counter1 <= 0;
            if (main_counter2 == (period_sync_out2-1))  main_counter2 <= 0;
            if (main_counter3 == (period_sync_out3-1))  main_counter3 <= 0;
            if (main_counter4 == (period_sync_out4-1))  main_counter4 <= 0;
            end
        end
    end

// PWM/timer Outputs Logic
always @(posedge selected_clk or negedge RST_I) begin
    if (!RST_I || counter_rst) begin
        o_pwm[0] <= 1'b0;
        o_pwm[1] <= 1'b0;
        o_pwm[2] <= 1'b0;
        o_pwm[3] <= 1'b0;
    end
    else if (mode_pwm && pwm_en && counter_en) begin
        o_pwm[0] <= (main_counter1 < dc_used_syn);      // PWM channel 1 output in PWM Mode
        o_pwm[1] <= (main_counter2 < dc_sync_out2);     // PWM channel 2 output in PWM Mode
        o_pwm[2] <= (main_counter3 < dc_sync_out3);     // PWM channel 3 output in PWM Mode
        o_pwm[3] <= (main_counter4 < dc_sync_out4);     // PWM channel 4 output in PWM Mode
    end
    else if (!mode_pwm && interrupt_flag) begin
        o_pwm[0] <= 1'b1; // Interrupt output in Timer Mode ch1 only
    end
end

endmodule
