//------------------------------------------------------------
// Module Name: pwm_timer_core
/* Description: 
Directed Test bench for PWM/Timer Core using tasks and test the main cases and show it in the waveform  
*/
// Author: AlHussein Mustafa
// Date: July 2025
//------------------------------------------------------------

`timescale 100ns/1ns

module pwm_timer_core_tb();
    reg         CLK_I;      
    reg         RST_I;     
    reg  [15:0] ADR_I;      
    reg  [15:0] DAT_I;      
    
    reg         WE_I;       
    reg         STB_I;      
    reg         CYC_I;

    reg         EXT_CLK; 
    reg  [15:0] I_DC;    

    wire [15:0] DAT_O_DUT;     
    wire        ACK_O_DUT;

    wire [3:0]  o_pwm_dut;

integer   i;         //counter
reg[15:0] period_i;  //size of timer counter

parameter CLK_PERIOD     = 2; //50MHZ
parameter EX_CLK_PERIOD  = 4; //250MHZ

PWM_TMR_CORE DUT(
    // Wishbone Slave Int
    .CLK_I(CLK_I),      
    .RST_I(RST_I),      
    .ADR_I(ADR_I),      
    .DAT_I(DAT_I),      
    .DAT_O(DAT_O_DUT),  
    .WE_I(WE_I),       
    .STB_I(STB_I),      
    .CYC_I(CYC_I),      
    .ACK_O(ACK_O_DUT),  
    // Additional Input
    .EXT_CLK(EXT_CLK),  
    .I_DC(I_DC),       
    // Outputs
    .o_pwm(o_pwm_dut)   
);

// CLK Generation
initial begin
    CLK_I = 0; // Initialize clock
    forever #(CLK_PERIOD/2) CLK_I = ~CLK_I; // Toggle every CLK_PERIOD/2
end

//External CLK Generation
initial begin
    EXT_CLK = 0; // Initialize clock
    forever #(EX_CLK_PERIOD/2) EXT_CLK = ~EXT_CLK; // Toggle every EX_CLK_PERIOD/2
end


initial begin
    //INITIALIZATION
    INITIALIZATION;
    //TEST CASE 0
    RST_ASSERTION;
    //TEST CASE 1
    WRITE(4, 16'h0013);
    //TEST CASE 2
    READ(4);
    //TEST CASE 3
    TIMER_MODE_CONFG(10, 8'b0001_0100, 16'h0000, 1'b0); //Stop timer runs continuously (without Clear the interrupt flag or enable cont bit) Watch the main counter
    #50
    //TEST CASE 4
    TIMER_MODE_CONFG(15, 8'b0001_1100, 16'h0001, 1'b0); //Cont timer runs continuously (without Clear the interrupt flag but enable cont bit) Watch the main counter
    #50
    //TEST CASE 5
    WRITE(0, (8'b0001_1100 | (1 << 7))); //set counter reset
    TIMER_MODE_CONFG(20, 8'b0001_0100, 16'h0000, 1'b1); //Cont timer runs continuously (without enable cont bit but Clear the interrupt flag) Watch the main counter
    #100
    //TEST CASE 6 (DC = 25%)
    WRITE(0, (8'b0001_0110 | (1 << 7))); //set counter reset when we change between the modes
    PWM_MODE_CONFG(64'h0008_000c_0010_0014, 64'h0002_0003_0004_0005, 8'b0001_0110, 16'h0000); 
    #300
    //TEST CASE 7 (DC = 50%)
    PWM_MODE_CONFG(64'h0008_000c_0010_0014, 64'h0004_0006_0008_000a, 8'b0001_0110, 16'h0001); //DC = 50%
    #300
    //TEST CASE 8 (DC = 75%) With Using External DC REG for channel 1
    I_DC = 15; // will ignore the dc reg value for channel 1
    PWM_MODE_CONFG(64'h0008_000c_0010_0014, 64'h0006_0009_000c_0000, 8'b0101_0110, 16'h0001);
    #300
    //TEST CASE 9 (DC = 90%) With Using External DC REG for channel 1 && divider by 2
    WRITE(0, (8'b0101_0110 | (1 << 7))); //set counter reset
    I_DC = 16'h0009; // will ignore the dc reg value for channel 1
    PWM_MODE_CONFG(64'h0014_000a_001e_000a, 64'h0012_0009_001b_0000, 8'b0101_0110, 16'h0002);
    #300
    //TEST CASE 10 (DC = 40%) With Using Internal DC REG for channel 1 && divider by 10
    WRITE(0, (8'b0001_0110 | (1 << 7))); //set counter reset (16'h0095)
    I_DC = 16'h002d; // will ignore the I_DC reg value for channel 1
    PWM_MODE_CONFG(64'h001e_0014_000a_0005, 64'h000c_0008_0004_0002, 8'b0001_0110, 16'h000a);
    #300
    /**************************Using Two Clock Domains*******************************/
    //TEST CASE 11 (DC = 50%) With Using Internal DC REG for channel 1 && divider by 8
    WRITE(0, (8'b0001_0111 | (1 << 7))); //set counter reset
    I_DC = 16'h0008; // will ignore the I_DC value for channel 1
    PWM_MODE_CONFG(64'h0008_000c_0010_0014, 64'h0004_0006_0008_000a, 8'b0001_0111, 16'h0008);
    #500
    //TEST CASE 12
    WRITE(0, (8'b0001_0101 | (1 << 7))); //set counter reset
    TIMER_MODE_CONFG(10, 8'b0001_0101, 16'h0001, 1'b1); //Cont timer runs continuously (without enable cont bit but Clear the interrupt flag) Watch the main counter
    #200
    //TEST CASE 13
    WRITE(0, (8'b0001_0101 | (1 << 7))); //set counter reset
    TIMER_MODE_CONFG(10, 8'b0001_1101, 16'h000, 1'b0); //Cont timer runs continuously (without Clear the interrupt flag but enable cont bit) Watch the main counter
    #200
    $stop ;
end

//INITIALIZATION
task INITIALIZATION;
begin
    RST_I    = 1;
    ADR_I    = 0;     
    DAT_I    = 0;     
    WE_I     = 0;      
    STB_I    = 0;  
    CYC_I    = 0; 
    I_DC     = 0;     
    i        = 0;
    period_i = 0;
    @(negedge CLK_I);
end
endtask

// reset test case
task RST_ASSERTION; 
begin
    //drive
    RST_I    = 0;
    @(negedge CLK_I);
    RST_I    = 1;
    @(negedge CLK_I);
end
endtask

// write task by value and the address of the register
task WRITE(input [4:0] address, input [15:0] value);
begin
    @(negedge CLK_I);
    ADR_I[4:0] = address;
    DAT_I      = value;
    CYC_I      = 1;
    STB_I      = 1;
    WE_I       = 1;
    @(negedge CLK_I);
    CYC_I      = 0;
    STB_I      = 0;
end
endtask

// read task by the address of the register
task READ(input [4:0] address);
begin
    ADR_I[4:0] = address;
    CYC_I      = 1;
    STB_I      = 1;
    WE_I       = 0;
    @(negedge CLK_I);
    CYC_I      = 0;
    STB_I      = 0;
end
endtask

//timer mode task
task TIMER_MODE_CONFG(input [15:0] PERIOD, input [7:0] TIMER_CONFIG_TYPE, input [15:0] Divider, input Interrupt_Clear);
begin
    //write on the control registers
    WRITE(2, Divider);
    /* should be the first one to start the main counter with the correct clk & time ignoring the glitch
    that caused by changing the period at the same edge */
    WRITE(4, PERIOD);
    WRITE(0, TIMER_CONFIG_TYPE); // should be the last one to start the main counter at the suitable time
    
    //more counting to compensate for the clk divider that changes the main counter period
    period_i = (Divider == 0 || Divider == 1)? PERIOD: (PERIOD*Divider);  //clk divider problem solution
    for(i = 0; i < (period_i); i = i + 1) begin
        @(negedge CLK_I);
        // request to clear the interrupt
        if(i == (period_i - 1)) begin
            if(Interrupt_Clear)  begin
                if(TIMER_CONFIG_TYPE[0]) begin // if ext clk (cdc) need more time for synchronizers latency
                    #100; //more waiting until the interrupt flag rises before the reading operation
                    @(negedge CLK_I);
                    READ(0);
                    end
                    else begin
                        @(negedge CLK_I);
                        READ(0);
                    end
                    WRITE(0, (DAT_O_DUT & ~(1 << 5))); //Interrupt clear
                    //delay for sync at two clock domains condition 
                    @(negedge CLK_I);
                    @(negedge CLK_I);
                    @(negedge CLK_I);
                end
            end
        end
    end
endtask

//pwm mode task
task PWM_MODE_CONFG(input [63:0] PERIOD, input [63:0] DC, input [7:0] PWM_CONFIG_TYPE, input [15:0] Divider);
begin
    //write on the control registers for 4 channels
    WRITE(4,  PERIOD[15:0]);    // address of period reg 1
    WRITE(14, PERIOD[31:16]);   // address of period reg 2  
    WRITE(16, PERIOD[47:32]);   // address of period reg 3
    WRITE(18, PERIOD[63:48]);   // address of period reg 4
    WRITE(2,  Divider);         // address of divisor reg 
    WRITE(6,  DC[15:0]);        // address of dc reg 1
    WRITE(8,  DC[31:16]);       // address of dc reg 2
    WRITE(10, DC[47:32]);       // address of dc reg 3
    WRITE(12, DC[63:48]);       // address of dc reg 4
    WRITE(0, PWM_CONFIG_TYPE);  // should be the last one to start the main counter at the suitable time
    @(negedge CLK_I);           // writing delay
end
endtask

endmodule