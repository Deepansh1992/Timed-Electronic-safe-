module lab5_tb();

	// I/O for DUT
	reg clk, rst_n, action_n;
	reg [17:0] SW;
	wire [6:0] state_7s [1:0];
	wire [6:0] code_7s [1:0];
	wire [6:0] count_7s [2:0];
	wire [3:0] leds;

	// Signals for testbench
	reg [5:0] combo [1:3];
	reg [2:0] expected_combo;
	reg [5:0] current_attempt;
	reg [8:0] wrong_attempts;
	reg [13:0] bcd_data_2digit [0:255];
	reg [20:0] bcd_data_3digit [0:511];
	integer error_count;
	integer timeout;

	localparam MAX_ENTRY_TIME = 750;

	lab5 dut0(.clk(clk), .rst_n(rst_n), .SW(SW), .action_n(action_n), .HEX7(state_7s[1]), .HEX6(state_7s[0]), .HEX5(code_7s[1]), .HEX4(code_7s[0]), .HEX2(count_7s[2]), .HEX1(count_7s[1]), .HEX0(count_7s[0]), .LEDG(leds));

	initial begin
		// Initialize variables
		clk = 0;
		rst_n = 0; // Start in reset
		action_n = 1;
		SW = 0;
		{combo[1],combo[2],combo[3]} = $random;
		expected_combo = 0;
		current_attempt = 0;
		wrong_attempts = 0;
		$readmemh("lab5_data_2digit.dat", bcd_data_2digit);
		$readmemh("lab5_data_3digit.dat", bcd_data_3digit);
		error_count = 0;
		timeout = 0;
		
		$display("INFO: Starting simulation.");
		
		// Start with a reset
		reset_dut();
		
		// Change the input combinations
		repeat(5) begin
			set_switches($random);
		end

		$display("INFO: Starting standard (Lab 4) tests.");

		// Set the combination
		set_combination({combo[1], combo[2], combo[3]});

		// Try an invalid combination
		current_attempt = $random;
		while( current_attempt == combo[expected_combo] ) current_attempt = $random;
		try_combination(current_attempt);

		// Try a valid combination
		try_combination(combo[1]);

		// Reset the device
		reset_dut();
		
		// Set a new combination
		{combo[1],combo[2],combo[3]} = $random;
		set_combination({combo[1], combo[2], combo[3]});
		
		// Try a valid combination
		try_combination(combo[1]);

		// Try several invalid combinations
		repeat(10) begin
			current_attempt = $random;
			while( current_attempt == combo[expected_combo] ) current_attempt = $random;
			try_combination(current_attempt);
		end

		// Second valid combination
		try_combination(combo[2]);

		// Third valid combination
		try_combination(combo[3]);

		// Restart system
		press_button();

		// Run through a third valid combination
		{combo[1],combo[2],combo[3]} = $random;
		set_combination({combo[1], combo[2], combo[3]});
		try_combination(combo[1]);
		try_combination(combo[2]);
		try_combination(combo[3]);
		press_button();

		$display("INFO: Starting timed tests.");

		// Ensure counter starts at combo input
		reset_dut();
		{combo[1],combo[2],combo[3]} = $random;
		repeat (MAX_ENTRY_TIME/2) @ (negedge clk);
		set_combination({combo[1], combo[2], combo[3]});
		try_combination(combo[1]);
		repeat (MAX_ENTRY_TIME/2+10) @ (negedge clk);
		verify_outputs();
		
		// See if a timeout occurs while in entry mode
		reset_dut();
		repeat (MAX_ENTRY_TIME+1) @ (negedge clk);
		verify_outputs();

		// See if a timeout occurs while waiting for combo 1
		reset_dut();
		{combo[1],combo[2],combo[3]} = $random;
		set_combination({combo[1], combo[2], combo[3]});
		repeat (MAX_ENTRY_TIME+1) @ (negedge clk);
		verify_outputs();

		// See if a timeout occurs while waiting for combo 2
		reset_dut();
		{combo[1],combo[2],combo[3]} = $random;
		set_combination({combo[1], combo[2], combo[3]});
		try_combination(combo[1]);
		repeat (MAX_ENTRY_TIME+1) @ (negedge clk);
		verify_outputs();
		
		// See if a timeout occurs while waiting for combo 3
		reset_dut();
		{combo[1],combo[2],combo[3]} = $random;
		set_combination({combo[1], combo[2], combo[3]});
		try_combination(combo[1]);
		try_combination(combo[2]);
		repeat (MAX_ENTRY_TIME+1) @ (negedge clk);
		verify_outputs();

		// See if a timeout occurs while unlocked
		reset_dut();
		{combo[1],combo[2],combo[3]} = $random;
		set_combination({combo[1], combo[2], combo[3]});
		try_combination(combo[1]);
		try_combination(combo[2]);
		try_combination(combo[3]);
		repeat (MAX_ENTRY_TIME+1) @ (negedge clk);
		verify_outputs();

		// See if a combination can be entered correctly after a timeout
		reset_dut();
		{combo[1],combo[2],combo[3]} = $random;
		set_combination({combo[1], combo[2], combo[3]});
		try_combination(combo[1]);
		repeat (MAX_ENTRY_TIME+1) @ (negedge clk);
		verify_outputs();
		try_combination(combo[1]);
		try_combination(combo[2]);
		try_combination(combo[3]);
		verify_outputs();

		repeat (5) @ (negedge clk);
		$display("INFO: Simulation complete.");
		$stop;
	end
	
	// Clock generation
	always @ (clk)
		#5 clk <= ~clk;

	// Timeout logic
	always @ (posedge clk) begin
		if( (expected_combo == 3'd2) || (expected_combo == 3'd3) ) begin
			timeout = timeout + 1;
			if( timeout == MAX_ENTRY_TIME ) begin
				expected_combo = 3'd1;
			end
		end
		else begin
			timeout = 0;
		end
	end

	/*
	 * Support functions and tasks
	 */
	task reset_dut;
	begin
		@ (negedge clk);
		rst_n = 0;
		repeat(2) @ (negedge clk);
		rst_n = 1;
		expected_combo = 0;
		wrong_attempts = 0;
		verify_outputs();
	end
	endtask

	task press_button;
	begin
		@ (negedge clk);
		action_n = 0;
		@ (negedge clk);
		action_n = 1;
		if( expected_combo == 4 ) begin
			expected_combo = 0;
			wrong_attempts = 0;
		end
		else if( expected_combo == 0 )
			expected_combo = 1;
		else if( SW[5:0] == combo[expected_combo] )
			expected_combo = expected_combo + 1;
		else
			wrong_attempts = wrong_attempts + 1;
		verify_outputs();
	end
	endtask

	task set_switches(input [17:0] val);
	begin
		@ (negedge clk);
		SW = val;
		verify_outputs();
	end
	endtask

	task set_combination(input [17:0] val);
	begin
		set_switches(val);
		press_button();
	end
	endtask

	task try_combination(input [5:0] comb);
	begin
		set_switches({SW[17:6], comb});
		press_button();
	end
	endtask

	task verify_outputs;
	begin
		// Wait a few clock cycles to let the system prodce an output
		repeat(3) @ (negedge clk);

		case( expected_combo )
			// No combination set
			3'd0: begin
				if( {state_7s[1],state_7s[0]} !== to_bcd_2digit(SW[17:12]) ) begin
					$display("ERROR at %0t ps: combo 1 expected %b and received %b", $time, to_bcd_2digit(SW[17:12]), {state_7s[1],state_7s[0]});
					error_count = error_count + 1;
				end
				if( {code_7s[1],code_7s[0]} !== to_bcd_2digit(SW[11:6]) ) begin
					$display("ERROR at %0t ps: combo 2 expected %b and received %b", $time, to_bcd_2digit(SW[11:6]), {code_7s[1],code_7s[0]});
					error_count = error_count + 1;
				end
				if( {count_7s[2],count_7s[1],count_7s[0]} !== to_bcd_3digit({3'b000,SW[5:0]}) ) begin
					$display("ERROR at %0t ps: combo 3 expected %b and received %b", $time, to_bcd_3digit({3'b000,SW[5:0]}), {count_7s[2],count_7s[1],count_7s[0]});
					error_count = error_count + 1;
				end
				if( leds !== 4'h0 ) begin
					$display("ERROR at %0t ps: LEDs present the wrong state, expected %b and received %b", $time, 4'h0, leds);
					error_count = error_count + 1;
				end
			end

			// Entering combinations
			3'd1, 3'd2, 3'd3: begin
				if( {state_7s[1],state_7s[0]} !== to_bcd_2digit("L") ) begin
					$display("ERROR at %0t ps: Locked state expected %b and received %b", $time, to_bcd_2digit("L"), {state_7s[1],state_7s[0]});
					error_count = error_count + 1;
				end
				if( {code_7s[1],code_7s[0]} !== to_bcd_2digit(SW[5:0]) ) begin
					$display("ERROR at %0t ps: Current input combination expected %b and received %b", $time, to_bcd_2digit(SW[5:0]), {code_7s[1],code_7s[0]});
					error_count = error_count + 1;
				end
				if( {count_7s[2],count_7s[1],count_7s[0]} !== to_bcd_3digit(wrong_attempts) ) begin
					$display("ERROR at %0t ps: Count of wrong attempts incorrect, expected %b and received %b", $time, to_bcd_3digit(wrong_attempts), {count_7s[2],count_7s[1],count_7s[0]});
					error_count = error_count + 1;
				end
				if( leds !== (2**expected_combo-1) ) begin
					$display("ERROR at %0t ps: LEDs present the wrong state, expected %b and received %b", $time, (4'd2**expected_combo-4'd1), leds);
					error_count = error_count + 1;
				end
			end

			// Unlocked
			3'd4: begin
				if( {state_7s[1],state_7s[0]} !== to_bcd_2digit("U") ) begin
					$display("ERROR at %0t ps: Unlocked state expected %b and received %b", $time, to_bcd_2digit("U"), {state_7s[1],state_7s[0]});
					error_count = error_count + 1;
				end
				// Doesn't matter what is diplayed on the middle/combo2 display
				if( {count_7s[2],count_7s[1],count_7s[0]} !== to_bcd_3digit(wrong_attempts) ) begin
					$display("ERROR at %0t ps: Count of wrong attempts incorrect, expected %b and received %b", $time, to_bcd_3digit(wrong_attempts), {count_7s[2],count_7s[1],count_7s[0]});
					error_count = error_count + 1;
				end
				if( leds !== 4'hF ) begin
					$display("ERROR at %0t ps: LEDs present the wrong state, expected %b and received %b", $time, 4'hF, leds);
					error_count = error_count + 1;
				end
			end

			// Error
			default: begin
				$display("ERROR at %0t ps: expected_combo had the unexpected value %d", $time, expected_combo);
			end
		endcase
	end
	endtask

	// Functions for converting binary numbers to BCD on 7-segment displays
	function [13:0] to_bcd_2digit(input [7:0] val);
	begin
		to_bcd_2digit = bcd_data_2digit[val];
	end
	endfunction
	function [20:0] to_bcd_3digit(input [8:0] val);
	begin
		to_bcd_3digit = bcd_data_3digit[val];
	end
	endfunction














/*






	// Input capture block
	 
	always begin
		@ (negedge action_n) begin
			// Collect the correct combination
			if( leds == 4'h0 ) begin
				combination = SW;
				wrong_attempts = 0;
			end
			// Collect the current guess
			else begin
				current_attempt = SW[5:0];
				if( leds[2] ) begin
					if( SW[5:0] !== combination[17:12] ) begin
						wrong_attempts = wrong_attempts + 1;
					end
				end
				else if ( leds[1] ) begin
					if( SW[5:0] !== combination[11:6] ) begin
						wrong_attempts = wrong_attempts + 1;
					end
				end
				else begin
					if( SW[5:0] !== combination[5:0] ) begin
						wrong_attempts = wrong_attempts + 1;
					end
				end
			end
		end
	end

	// Output compare blocks

	// Left display for combo 1 and safe state
	always begin
		@ ( state_7s[1], state_7s[0] ) begin
			#1 // Let the leds stabilize
			
			// Skip if in reset
			if( rst_n ) begin
				// Initially display the input combo 1
				if( leds == 4'h0 ) begin
					if( {state_7s[1],state_7s[0]} !== to_bcd_2digit(SW[17:12]) ) begin
						$display("ERROR at %0t: combo 1 expected %b and received %b", $time, to_bcd_2digit(SW[17:12]), {state_7s[1],state_7s[0]});
					end
				end
				// Display the Locked indicator
				else if( ~leds[3] ) begin
					if( {state_7s[1],state_7s[0]} !== to_bcd_2digit("L") ) begin
						$display("ERROR at %0t: Locked state expected %b and received %b", $time, to_bcd_2digit("L"), {state_7s[1],state_7s[0]});
					end
				end
				// Display the Unlocked indicator
				else begin
					if( {state_7s[1],state_7s[0]} !== to_bcd_2digit("U") ) begin
						$display("ERROR at %0t: Unlocked state expected %b and received %b", $time, to_bcd_2digit("U"), {state_7s[1],state_7s[0]});
					end
				end
			end
		end
	end
	
	// Center display for combo 2 and guess
	always begin
		@( code_7s[1], code_7s[0] ) begin
			#1 // Let the leds stabilize
			
			// Skip if in reset
			if( rst_n ) begin
				// Initially display the input combo 2
				if( leds == 4'h0 ) begin
					if( {code_7s[1],code_7s[0]} !== to_bcd_2digit(SW[11:6]) ) begin
						$display("ERROR at %0t: combo 2 expected %b and received %b", $time, to_bcd_2digit(SW[11:6]), {code_7s[1],code_7s[0]});
					end
				end
				// Display the current guess otherwise
				else begin
					if( {code_7s[1],code_7s[0]} !== to_bcd_2digit(SW[5:0]) ) begin
						$display("ERROR at %0t: Current combination expected %b and received %b", $time, to_bcd_2digit(SW[5:0]), {code_7s[1],code_7s[0]});
					end
				end
			end
		end
	end

	// Right display for combo 3 and count of wrong attempts
	always begin
		@( cnt_7s[3], cnt_7s[2], cnt_7s[1], cnt_7s[0] ) begin
			#1 // Let the leds stabilize

			// Skip if in reset
			if( rst_n ) begin
				// Initially display input combo 3
				if( leds == 4'h0 ) begin
					if( {cnt_7s[3],cnt_7s[2],cnt_7s[1],cnt_7s[0]} !== to_bcd_4digit({3'b000,SW[5:0]}) ) begin
						$display("ERROR at %0t: combo 3 expected %b and received %b", $time, to_bcd_4digit({3'b000,SW[5:0]}), {cnt_7s[3],cnt_7s[2],cnt_7s[1],cnt_7s[0]});
					end
				end
				// Display the count of wrong attempts
				else begin
					if( {cnt_7s[3],cnt_7s[2],cnt_7s[1],cnt_7s[0]} !== to_bcd_4digit(wrong_attempts) ) begin
						$display("ERROR at %0t: Count of wrong attempts incorrect, expected %b and received %b", $time, to_bcd_4digit(wrong_attempts), {cnt_7s[3],cnt_7s[2],cnt_7s[1],cnt_7s[0]});
					end
				end
			end
		end
	end

	// LEDs for state progress
	always begin
		@( leds ) begin
			// Skip if in reset
			if( rst_n ) begin
				if( leds[3] ) begin
					if( current_attempt !== combination[17:12] ) begin
						$display("ERROR at %0t: combo 3 accepted in error, correct=%b and received=%b", $time, combination[17:12], current_attempt);
					end
				end
				else if( leds[2] ) begin
					if( current_attempt !== combination[11:6] ) begin
						$display("ERROR at %0t: combo 2 accepted in error, correct=%b and received=%b", $time, combination[11:6], current_attempt);
					end
				end
				else if( leds[1] ) begin
					if( current_attempt !== combination[5:0] ) begin
						$display("ERROR at %0t: combo 1 accepted in error, correct=%b and received=%b", $time, combination[5:0], current_attempt);
					end
				end
			end
		end
	end

	// Block to ensure an input causes an output change, which in/out?
	
	// Support functions and tasks
	 
	// Functions for converting binary numbers to BCD on 7-segment displays
	function [13:0] to_bcd_2digit(input [7:0] val);
	begin
		to_bcd_2digit = bcd_data_2digit[val];
	end
	endfunction
	function [27:0] to_bcd_4digit(input [8:0] val);
	begin
		to_bcd_4digit = bcd_data_4digit[val];
	end
	endfunction
	
	// Task to simulat a button press
	task press_button;
	begin
		@(negedge clk);
		action_n = 0;
		@(negedge clk);
		action_n = 1;
	end
	endtask
	
	// Task that enters a combination and presses the button
	task try_combination(input [5:0] combo);
	begin
		@ (negedge clk);
		SW[5:0] = combo;
		press_button();
	end
	endtask
*/
endmodule
