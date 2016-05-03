`include "ZueiraI.svh"

module ZueiraI(
			rst,
			clk,
			IO_PORTA,
			IO_PORTB,
			IO_PORTC
			);
	input wire rst;
	input wire clk;
	inout wire [7:0] IO_PORTA;
	inout wire [7:0] IO_PORTB;
	inout wire [7:0] IO_PORTC;
	//memory connectios and bus
	reg [7:0] Memory[0:255];
	reg [7:0]	MEM_CPU_IN;
	wire [7:0]	MEM_CPU_OUT;
	wire [11:0] MEM_CPU_CTRL_BUS;
	
	//wire connections declaration
	wire [2:0][7:0] ALU_DATA_BUS;
	wire [1:0][2:0] ALU_CTRL_BUS;
	
	wire [2:0][7:0] IO_DATA_BUS;
	wire [2:0][7:0] IO_CTRL_BUS;
	
	wire [2:0]	INTERRUPT_CTRL_BUS;
	wire [2:0][7:0] INTERRUPT_DATA_BUS;
	
	ZueiraI_core CPU(
					.rst(rst),
					.clk(clk),
					.out_ALU1(ALU_DATA_BUS[0]),
					.out_ALU2(ALU_DATA_BUS[1]),
					.in_ALU(ALU_DATA_BUS[2]),
					.flags_ALU(ALU_CTRL_BUS[0]),
					.ctrl_ALU(ALU_CTRL_BUS[1]),
					.flags_INTERRUPT(INTERRUPT_CTRL_BUS[2]),
					.ctrl_INTERRUPT(INTERRUPT_CTRL_BUS[1:0]),
					.ctrl_MEM(MEM_CPU_CTRL_BUS),
					.out_MEM(MEM_CPU_OUT),
					.in_MEM	(MEM_CPU_IN)
				);
	ZueiraI_INTERRUPT INTERRUPT(
					.clk(clk),
					.rst(rst),
					.INT_IO(IO_DATA_BUS[0]),
					.INT_CH(INTERRUPT_DATA_BUS[0]),
					.INT_TYPE_0to3(INTERRUPT_DATA_BUS[1]),
					.INT_TYPE_4to7(INTERRUPT_DATA_BUS[2]),
					.INT_ctrl(INTERRUPT_CTRL_BUS[1:0]),
					.INT_flag(INTERRUPT_CTRL_BUS[2])
				);
	
	ZueiraI_ALU ALU(
					.in1(ALU_DATA_BUS[0]),
					.in2(ALU_DATA_BUS[1]),
					.out(ALU_DATA_BUS[2]),
					.flags(ALU_CTRL_BUS[0]),	//flags[2:0]--[O ,U, Z]
					.ctrl(ALU_CTRL_BUS[1]),
					.rst(rst)
				);
	/*Zueira_IO IO(
					.PORT_A(IO_PORTA),
					.PORT_B(IO_PORTB),
					.PORT_C(IO_PORTC),
					.DATA_A(IO_DATA_BUS[0]),
					.DATA_B(IO_DATA_BUS[1]),
					.DATA_C(IO_DATA_BUS[2]),
					.DIR_A(IO_CTRL_BUS[0]),
					.DIR_B(IO_CTRL_BUS[1]),
					.DIR_C(IO_CTRL_BUS[2])	
				);*/
	initial begin
		$readmemh("MEM.list",Memory);
	end
	always@(posedge MEM_CPU_CTRL_BUS[10]) begin
			MEM_CPU_IN=Memory[MEM_CPU_CTRL_BUS[7:0]];
		end
	always@(posedge MEM_CPU_CTRL_BUS[11]) begin
			Memory[MEM_CPU_CTRL_BUS[7:0]]=MEM_CPU_OUT;
		end
	assign INTERRUPT_DATA_BUS[0]=Memory[`MEM_INT_CH];
	assign INTERRUPT_DATA_BUS[0]=Memory[`MEM_INT_TYPE_0to3];
	assign INTERRUPT_DATA_BUS[0]=Memory[`MEM_INT_TYPE_4to7];
	assign IO_CTRL_BUS[0]=Memory[`MEM_IO_DIR_A];
	assign IO_CTRL_BUS[1]=Memory[`MEM_IO_DIR_B];
	assign IO_CTRL_BUS[2]=Memory[`MEM_IO_DIR_C];
endmodule;










