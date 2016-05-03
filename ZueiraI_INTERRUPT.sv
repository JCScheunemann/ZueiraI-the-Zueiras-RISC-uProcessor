module ZueiraI_INTERRUPT(
				clk,
				rst,
				INT_IO,
				INT_CH,
				INT_TYPE_0to3,
				INT_TYPE_4to7,
				INT_ctrl,
				INT_flag
			);
	input wire clk,rst;
	input wire [7:0] INT_IO;
	input wire [7:0] INT_CH;
	//input wire [7:0] INT_Status;
	input wire [7:0] INT_TYPE_0to3;
	input wire [7:0] INT_TYPE_4to7;
	input wire [1:0] INT_ctrl;
	output reg INT_flag;
	wire [7:0]	posINT,negINT;
	
	
	initial begin
		INT_flag=0;
	end
	always@(posedge rst) INT_flag=0;
	genvar i;
	generate  
		for (i=0; i < 4; i++)  
			begin: Interrupt_assign_vector_CH_0_3  
				assign posINT[i]=INT_IO[i]  & INT_CH[i] & INT_TYPE_0to3[i<<2];
				assign posINT[i+4]=INT_IO[i+4]  & INT_CH[i+4] & INT_TYPE_4to7[i<<2];
				assign negINT[i]=INT_IO[i]  & INT_CH[i] & INT_TYPE_0to3[(i<<2)+1];
				assign negINT[i+4]=INT_IO[i+4]  & INT_CH[i+4] & INT_TYPE_4to7[(i<<2)+1];
				always@(posedge posINT[i]) INT_flag=1;
				always@(negedge negINT[i]) INT_flag=1;
				always@(posedge posINT[i+4]) INT_flag=1;
				always@(negedge negINT[i+4]) INT_flag=1;
			end   
	endgenerate 
	always@(posedge INT_ctrl[0]) INT_flag=0;
endmodule;