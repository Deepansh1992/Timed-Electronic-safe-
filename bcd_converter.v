// Converts 9-bit input value into a binary coded decimal format. value is
// treated as an unsinged number.
module bcd_converter (input [8:0] value, output reg [3:0] hund, tens, ones);
	reg [8:0] binary;
	integer i;

	always @ (value) begin
		hund = 0;
		tens = 0;
		ones = 0;
		binary = value;
		for( i = 0; i < 9; i = i + 1 ) begin
			if( hund > 4 )
				hund = hund + 3;
			if( tens > 4 )
				tens = tens + 4'd3;
			if( ones > 4 )
				ones = ones + 4'd3;

			// Shift over collection of bits by one
			{hund,tens,ones,binary} = {hund[2:0],tens,ones,binary,1'b0};
		end
	end
endmodule
