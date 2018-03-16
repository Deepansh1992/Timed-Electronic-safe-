module action_counter(input action_n, clk, rst,output reg action_counter);
reg enable;

always@(posedge clk) begin 

	if (rst == 1'b0) begin
		action_counter <= 0;
	end
	else begin 		
		if (action_n == 1'b0 && enable == 1'b1) begin
		 action_counter <= 1'b1;
		end 
		else begin 
		action_counter <= 1'b0;
		end
		enable <= action_n;
	end 	
end 

endmodule
	
