module SSD_converter (input [3:0]SSD_in, output reg[6:0]SSD_out);
	always@(SSD_in) begin
		case(SSD_in)
			4'h0 : SSD_out = 7'b1000000;			//0
			4'h1 : SSD_out = 7'b1111001;			//1
			4'h2 : SSD_out = 7'b0100100;			//2
			4'h3 : SSD_out = 7'b0110000;			//3
			4'h4 : SSD_out = 7'b0011001;			//4
			4'h5 : SSD_out = 7'b0010010;			//5
			4'h6 : SSD_out = 7'b0000010;			//6
			4'h7 : SSD_out = 7'b1111000;			//7
			4'h8 : SSD_out = 7'b0000000;			//8
			4'h9 : SSD_out = 7'b0010000;			//9
			4'hA : SSD_out = 7'b0001000;			//A
			4'hB : SSD_out = 7'b0000011;			//B
			4'hC : SSD_out = 7'b1000110;			//C
			4'hD : SSD_out = 7'b0100001;			//D
			4'hE : SSD_out = 7'b0000110;			//E
			4'hF : SSD_out = 7'b0001110;			//F
		endcase
	end
endmodule
