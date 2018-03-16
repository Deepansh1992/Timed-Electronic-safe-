

//Please Do not modify the definition of the top level module except to change an output type (reg/wire).
module timed_electronic_safe(input clk, rst_n, input [17:0] SW, input action_n, output reg[6:0] HEX7, HEX6, HEX5, HEX4, HEX2, HEX1, HEX0, output reg [3:0] LEDG);

	//Time
	localparam tmax = 10'd750;
	localparam BITS_timer = 10;

	// States
	localparam S_ENTRY  = 3'd0;
	localparam S_TRY_1  = 3'd1;
	localparam S_TRY_2  = 3'd2;
	localparam S_TRY_3  = 3'd3;
	localparam S_UNLOCK = 3'd4;

	// State register
	reg [2:0] state;
	
	//timer 
	reg [BITS_timer-1:0] t;
 
	wire action_counter;
	reg [5:0] code_1,code_2,code_3;
	reg [5:0] try_1,try_2,try_3, try_1_sig;
	
	wire [6:0] disp_0,disp_1,disp_2,disp_4,disp_5,disp_6,disp_7, error_ssd0, error_ssd1, error_ssd2;
	
	reg [8:0] error_count;
	wire [3:0] error_0,error_1,error_2;
	
	wire [3:0] disp_0_sig, disp_1_sig, disp_2_sig, disp_4_sig, disp_5_sig, disp_6_sig, disp_7_sig;
	
	action_counter action_counter1(.action_n(action_n), .clk(clk), .rst(rst_n), .action_counter(action_counter));


	
	bcd_converter display0(.value(error_count),.hund(error_2), .tens(error_1), .ones(error_0));
	SSD_converter ssd_converter_E2(.SSD_in(error_2), .SSD_out(error_ssd2));
	SSD_converter ssd_converter_E1(.SSD_in(error_1), .SSD_out(error_ssd1));
	SSD_converter ssd_converter_E0(.SSD_in(error_0), .SSD_out(error_ssd0));
		
	bcd_converter display3(.value({3'd0,SW[17:12]}),.tens(disp_7_sig), .ones(disp_6_sig));
	bcd_converter display2(.value({3'd0,SW[11:6]}), .tens(disp_5_sig), .ones(disp_4_sig));
	bcd_converter display1(.value({3'd0,SW[5:0]}),  .tens(disp_1_sig), .ones(disp_0_sig));

	SSD_converter ssd_converter_5(.SSD_in(disp_7_sig), .SSD_out(disp_7));
	SSD_converter ssd_converter_4(.SSD_in(disp_6_sig), .SSD_out(disp_6));
	SSD_converter ssd_converter_3(.SSD_in(disp_5_sig), .SSD_out(disp_5));
	SSD_converter ssd_converter_2(.SSD_in(disp_4_sig), .SSD_out(disp_4));
	SSD_converter ssd_converter_1(.SSD_in(disp_1_sig), .SSD_out(disp_1));
	SSD_converter ssd_converter_0(.SSD_in(disp_0_sig), .SSD_out(disp_0));


	// State machine always block, including both next state logic and state register
	always @ (posedge clk, negedge rst_n) begin
		if( rst_n == 1'b0) begin
			state <= S_ENTRY;
			t <= 5'd0;
		end
		else begin
		t <= t+1;
			case( state )
				S_ENTRY: begin
					code_1 <= SW[5:0];
					code_2 <= SW[11:6];
					code_3 <= SW[17:12];
					error_count <= 9'd0;
						if(action_counter == 1) begin 
							state <= S_TRY_1;	
							error_count <= 0;
							t<= 0;
						end 
				end
				
				S_TRY_1: begin
				// t <= t+1;
					try_1 <= SW[5:0];		
					if (action_counter && t<tmax) begin	 
						if( code_3 == try_1 )
							state <= S_TRY_2;
						else  begin
							state <= S_TRY_1;
							error_count = error_count +9'd1;
						end
					end
					else if(t>tmax) begin
						state <= S_TRY_1;
						t <= 0; 
					end 
				end
					
				S_TRY_2: begin
					try_2 <= SW[5:0];
					if (action_counter && t<tmax) begin
						if( code_2 == try_2)
							state <= S_TRY_3;
						else begin
							state <= S_TRY_2;
							error_count = error_count +9'd1;
						end
					end
					else if(t>tmax) begin 
						state <= S_TRY_1;
						t <= 0;
					end 
				end
					
				S_TRY_3: begin
					try_3 <= SW[5:0];
					if (action_counter && t<tmax) begin 
						if( code_1 == try_3)
							state <= S_UNLOCK;
						else begin
							state <= S_TRY_3;
							error_count = error_count +9'd1;
						end
					end
					else if(t>tmax) begin 
						state <= S_TRY_1;
						t <= 0;
					end
				end

				S_UNLOCK: begin
					if(action_counter) begin 
						state <= S_ENTRY;
						error_count <= 9'd0;
						t <= 0;
					end
				end

				default: begin
					state <= S_ENTRY;
				end
			endcase
		end
	end

	// Output logic always block
	always @ (*) begin
		case( state )
			S_ENTRY: begin
				HEX7 <= disp_7; HEX6 <= disp_6; 
				HEX5 <= disp_5; HEX4 <= disp_4; HEX2 <= 7'b1000000; HEX1 <= disp_1; HEX0 <= disp_0;   LEDG<= 4'b0000;
			end
			
			S_TRY_1: begin
				HEX7 <= 7'b1111111; HEX6 <= 7'b1000111;  
				HEX5 <= disp_1 ; HEX4 <= disp_0; HEX2 <= error_ssd2; HEX1 <= error_ssd1;  HEX0 <= error_ssd0;  LEDG<= 4'b0001;
			end
			
			S_TRY_2: begin
				HEX7 <= 7'b1111111; HEX6 <= 7'b1000111;  
				HEX5 <= disp_1 ; HEX4 <= disp_0; HEX2 <= error_ssd2; HEX1 <= error_ssd1; HEX0 <= error_ssd0;  LEDG<= 4'b0011;
			end
			
			S_TRY_3: begin
				HEX7 <= 7'b1111111; HEX6 <= 7'b1000111;  
				HEX5 <= disp_1 ; HEX4 <= disp_0; HEX2 <= error_ssd2; HEX1 <= error_ssd1; HEX0 <= error_ssd0;  LEDG<= 4'b0111;
			end
			
			S_UNLOCK: begin
				HEX7 <= 7'b1111111; HEX6 <= 7'b1000001;  
				HEX5 <= 7'b1000000 ; HEX4 <= 7'b1000000; HEX2 <= error_ssd2; HEX1 <= error_ssd1; HEX0 <= error_ssd0;  LEDG<= 4'b1111;
			end
			default: begin
				HEX7 <= disp_7; HEX6 <= disp_6; HEX5 <= disp_5; HEX4 <= disp_4; HEX2 <= 7'b1000000; HEX1 <= disp_1; HEX0 <= disp_0; LEDG<= 4'b0000;
			end
		endcase
	end
endmodule

/*
 * Do not modify the modules below. They are setup to provide a clock divider
 * for your main module and allow the testbench to run at that slower clock
 * rate.
 */
module timed_electronic_safe_top(input clk_in, rst_n, input [17:0] SW, input action_n, output [6:0] HEX7, HEX6, HEX5, HEX4, HEX2, HEX1, HEX0, output [3:0] LEDG);
	wire clk;
	clk_divider c0 (.clk_in(clk_in), .rst_n(rst_n), .clk_out(clk));
	timed_electronic_safe device(clk, rst_n, SW, action_n, HEX7, HEX6, HEX5, HEX4, HEX2, HEX1, HEX0, LEDG);
endmodule

module clk_divider(input clk_in, rst_n, output clk_out);
	localparam BITS = 21;
	reg [BITS-1:0] cnt;
	
	always @ (posedge clk_in) begin
		if( ~rst_n ) begin
			cnt <= 0;
		end
		else begin
			cnt <= cnt + 1;
		end
	end
	
	assign clk_out = cnt[BITS-1];
endmodule

