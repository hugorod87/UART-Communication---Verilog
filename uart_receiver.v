module uart_receiver
// Set Parameter CLKS_PER_BIT as follows:
// CLKS_PER_BIT = (Frequency of i_Clock)/(Frequency of UART)
// Example: 10 MHz Clock, 115200 baud UART
// (10000000)/(115200) = 87
	(
	input		 i_Clock,
	input		 i_Rx_Serial,
	output reg [7:0] o_Tx_Serial
	);
	
	// This is the state machine for all the steps of a UART Communication
	parameter s_IDLE = 3'b000;
	parameter s_RX_START_BIT = 3'b001;
	parameter s_RX_DATA_BYTE = 3'b010;
	parameter s_RX_STOP_BIT = 3'b011;
	parameter s_CLEANCACHE = 3'b100;
	parameter CLKS_PER_BIT = 87;
	
	//reg r_pointer = 1'b0;
	reg [7:0] r_Rx_Data_Cache = 0; 	// Register the receiving data
	reg [7:0] r_Clk_Count = 0; 		// Counts number of Clks
	reg [2:0] r_State_Main = 0; 	// 3 bit State Machine 
	reg [3:0] r_Bits_Count = 0;		// 4 bit count
	
		
	//Initialize
	always @(posedge i_Clock)
		begin
			case (r_State_Main)
				s_IDLE:
					begin
						r_Bits_Count <= 0;
						r_Clk_Count <= 0;
						r_Rx_Data_Cache <= 0;
						//r_pointer <= 0; // Used for more than 1 byte information.
						if (i_Rx_Serial <= 1'b0)
							r_State_Main <= s_RX_START_BIT;
						else
							r_State_Main <= s_IDLE;
					end
				s_RX_START_BIT:
					begin
						if (r_Clk_Count < (CLKS_PER_BIT-1))
							r_Clk_Count <= r_Clk_Count + 1;
						else
							begin
								r_State_Main <= s_RX_DATA_BYTE;
								r_Clk_Count <= 0;
							end
					end
				s_RX_DATA_BYTE:
					begin
						if (r_Bits_Count < 8)
							begin
								if (r_Clk_Count < (CLKS_PER_BIT-1))
									begin
										r_Clk_Count <= r_Clk_Count + 1;
										if (r_Clk_Count == (CLKS_PER_BIT / 2)) //Takes the bit sample at the middle of the bit signal
											r_Rx_Data_Cache[r_Bits_Count] <= i_Rx_Serial;
									end
								else
									begin
										r_Bits_Count <= r_Bits_Count + 1;
										r_Clk_Count <= 0;
									end
							end
						else
							begin
								r_Clk_Count <= 0;
								r_Bits_Count <= 0;
								r_State_Main <= s_RX_STOP_BIT;
							end
					end
				s_RX_STOP_BIT:
					begin
						if (i_Rx_Serial <= 1'b1)
							begin
								r_State_Main <= s_CLEANCACHE;
								o_Tx_Serial <= r_Rx_Data_Cache;
								r_Clk_Count <= 0;
							end
					end
				s_CLEANCACHE:
					begin
						r_State_Main <= s_IDLE;
						r_Rx_Data_Cache <= 0;
					end
				default:
					r_State_Main <= s_IDLE;
			endcase
		end
endmodule