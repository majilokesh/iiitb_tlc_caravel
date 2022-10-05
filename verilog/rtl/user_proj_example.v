`default_nettype none

module user_proj_example #(
    parameter BITS = 32
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq
);
    //Inputsw
    wire clk;
    wire rst_n;
    wire [2:0] light_highway;
    wire [2:0] light_farm;
    wire C;

    wire [`MPRJ_IO_PADS-1:0] io_in;
    wire [`MPRJ_IO_PADS-1:0] io_out;
    wire [`MPRJ_IO_PADS-1:0] io_oeb;
    
    iiitb_tlc dut(light_highway, light_farm, C, clk, rst_n);
    
endmodule

   module iiitb_tlc(light_highway, light_farm, C, clk, rst_n);

	parameter HGRE_FRED = 2'b00, // Highway green and farm red
		  HYEL_FRED = 2'b01,// Highway yellow and farm red
		  HRED_FGRE = 2'b10,// Highway red and farm green
		  HRED_FYEL = 2'b11;// Highway red and farm yellow
	input C, // sensor
   	clk, // clock = 50 MHz
   	rst_n; // reset active low

	output reg[2:0] light_highway, light_farm; // output of lights
	reg[1:0]  RED_count_en, YELLOW_count_en1, YELLOW_count_en2;
	reg[1:0] state, next_state;
	integer i;
// next state
	always @(posedge clk or negedge rst_n)
		begin
			if(~rst_n)
			begin
			RED_count_en<=0;YELLOW_count_en1<=0;YELLOW_count_en2<=0;
			 state <= 2'b00;
			end
			else 
			 state <= next_state; 
		end
// FSM
	always @(*)
		begin
			case(state)
				HGRE_FRED: 
					begin // Green on highway and red on farm way

					 RED_count_en <= 2'b01;
					 YELLOW_count_en1 <= 2'b00;
					 YELLOW_count_en2 <= 2'b00;
					 light_highway <= 3'b001;
					 light_farm <= 3'b100;
					 if(C) next_state <= HYEL_FRED; 
					 // if sensor detects vehicles on farm road, 

					 else next_state <= HGRE_FRED;
					end
				HYEL_FRED: 
					begin// yellow on highway and red on farm way

					RED_count_en <= 2'b00;
					YELLOW_count_en1 <= 2'b01;
					YELLOW_count_en2 <= 2'b00;					  
					light_highway <= 3'b010;
					light_farm <= 3'b100;
					next_state <= HRED_FGRE;

					end
				HRED_FGRE: 
					begin// red on highway and green on farm way
					
					RED_count_en <= 2'b01;
					YELLOW_count_en1 <= 2'b00;
					YELLOW_count_en2 <= 2'b00;					 
					light_highway <= 3'b100;
					light_farm <= 3'b001; 
					next_state <= HRED_FYEL;

					end
				HRED_FYEL:
					begin// red on highway and yellow on farm way

					RED_count_en <= 2'b00;
					YELLOW_count_en1 <= 2'b00;
					YELLOW_count_en2 <= 2'b01;					 
					light_highway <= 3'b100;
					light_farm <= 3'b010; 
					next_state <= HGRE_FRED;

					end
				default: next_state <= HGRE_FRED;
			endcase
		end

endmodule
`default_nettype wire
