//ver funcionamento INOUT
module ZueiraI_IO(
				//clk,
				PORT_A,
				PORT_B,
				PORT_C,
				DATA_A,
				DATA_B,
				DATA_C,
				DIR_A,
				DIR_B,
				DIR_C				
			);	
	//input wire clk;
	input wire [7:0] DIR_A;
	input wire [7:0] DIR_B;
	input wire [7:0] DIR_C;	
	inout wire [7:0] DATA_A;
	inout wire [7:0] DATA_B;
	inout wire [7:0] DATA_C;
	inout wire [7:0] PORT_A;
	inout wire [7:0] PORT_B;
	inout wire [7:0] PORT_C;
	
	genvar i;  
	generate  
		for (i=0; i < 8; i++)  
			begin: IO_MAP  
				assign PORT_A[i]=DIR_A[i] ? DATA_A[i]: 1'bz;
				assign PORT_B[i]=DIR_B[i] ? DATA_B[i]: 1'bz;
				assign PORT_C[i]=DIR_C[i] ? DATA_C[i]: 1'bz;
				assign DATA_A[i]=DIR_A[i] ? 1'bz: PORT_A[i];
				assign DATA_B[i]=DIR_B[i] ? 1'bz: PORT_B[i];
				assign DATA_C[i]=DIR_C[i] ? 1'bz: PORT_C[i];
			end  
	endgenerate 	
endmodule