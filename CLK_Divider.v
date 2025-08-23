module CLK_Division(
input  wire         ref_clk ,
input  wire         rst , 
input  wire         clk_En ,
input  wire  [15:0] Div_rat ,
output wire         Div_Clk
);
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
wire [6:0] half_period ;
wire [6:0] full_period ;
wire       clk_En_in ;
wire       odd ;
reg        flag ;
reg  [6:0] Counter ;
reg        Div_Clk_O ;


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
assign half_period = ((Div_rat >> 1) - 1 );
assign full_period = (Div_rat >> 1) ;
assign odd = Div_rat[0] ;
assign Div_Clk = !clk_En ? ref_clk : Div_Clk_O ; //output logic
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

always@(posedge ref_clk or posedge rst) begin
	if (rst)begin 
        Div_Clk_O <= 1'b0 ;
        Counter <= 7'b0 ;
		flag <= 1'b0 ;
    end
	else if (clk_En) begin
		if (!odd && (Counter == half_period)) begin
			Counter <= 0 ; 
			Div_Clk_O <= ~Div_Clk_O ;
		end
		else if ((odd && (Counter == half_period) && flag) || (odd && (Counter == full_period) && !flag)) begin
			Counter <= 0 ; 
			Div_Clk_O <= ~Div_Clk_O ;
			flag <= ~flag ; 
		end
		else begin
			Counter <= Counter + 1'b1 ;
		end
	end
end

endmodule