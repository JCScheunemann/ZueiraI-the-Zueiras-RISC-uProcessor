`include "ZueiraI.svh"
module ZueiraI_ALU(	
			in1,
			in2,
			out,
			flags,	//flags[2:0]--[O ,U, Z]
			ctrl,
			rst
		);
	input wire 	rst;			// reset signal
	input wire	[7:0] in1;		//Data in 1
	input wire	[7:0] in2;		//Data in 2
	input wire	[2:0] ctrl;		//Control BUS
	output reg	[2:0] flags;	//return flags(Overflow, Underflow or minus,Zero)
	output reg	[7:0] out;		//Data out
	reg [8:0] tmp;				//tmp var
	always@(rst)
		begin
			flags=0;
			out=0;
			tmp=0;
		end
	always @ (*) 
		case (ctrl) 
			1:	if(in1!=0 && in2!=0) begin
					tmp= in1+in2;
					out[7:0]=tmp[7:0];
					flags=tmp[8]<<2;
				end else begin
					out=0;
					flags=1;
				end
				
			2:	if(in2>in1)begin
					out=0;
					flags=1<<1;
				end else if(in1==in2) begin
					out=0;
					flags=1;
				end else begin
					out=in1-in2;
					flags=3'b001;
				end
			3:	out=in1&in2;
			4:	out=in1|in2;
			5:	out=~in1;
			6:	begin
					out=in1<<1;
					flags=in1[7]<<2;
				end
			7:	begin
					out=in1>>1;
					flags=in1[0]<<1;
				end
			default:begin
						out=0;
						flags=0;
					end
		endcase 		
endmodule;

module ZueiraI_core(
			rst,
			clk,
			out_ALU1,
			out_ALU2,
			in_ALU,
			flags_ALU,
			ctrl_ALU,
			flags_INTERRUPT,
			ctrl_INTERRUPT,
			ctrl_MEM,
			out_MEM,
			in_MEM			
		);

//======================Input/Output signals=========================
	input wire rst; //reset signal
	input wire clk;
	//ALU connections
	output reg [7:0] out_ALU1;
	output reg [7:0] out_ALU2;
	input wire [7:0] in_ALU;
	input wire [2:0] flags_ALU;
	output reg [2:0] ctrl_ALU;
	//Interrupt connections
	input wire flags_INTERRUPT;
	output reg [1:0] ctrl_INTERRUPT;
	// MEM connections
	input wire [7:0] in_MEM;
	output reg [7:0] out_MEM;
	output wire [11:0] ctrl_MEM;
//================Internal Data vars and state flags=================
	reg [8:0] PC;
	wire [7:0] Status;
	reg [1:0][7:0] Stack [8];
	reg	[2:0] Stack_count;
	reg [7:0] MEM_Addr;
	reg [7:0] regs[3];//X, Y, K registradores de uso geral
	reg [1:0] MEM_page;
	reg [1:0] PCMEM_page;
	reg MEM_load;
	reg MEM_write;
	reg [1:0] instruction_cicle;
	reg [7:0] instruction_code;
	reg	[3:0] flags;
	reg work_INT;
	//-----------------------Reset tree---------------------
	always @(rst)
		begin
			PC=0;
			out_ALU1=0;
			out_ALU2=0;
			ctrl_ALU=0;
			ctrl_INTERRUPT=0;
			out_MEM=0;
			MEM_load=0;
			MEM_write=0;
			MEM_Addr=0;
			instruction_cicle=0;
			PCMEM_page=0;
			Stack_count=0;
		end
	//-----------assing flags position to Status [I,O,U,Z]-----------
	assign Status[3:0]=flags;
	assign Status[5:4]=MEM_page;
	//-----------Assign MEM BUS values---------------------
	assign ctrl_MEM[7:0]=MEM_Addr;	
	assign ctrl_MEM[9:8]=MEM_page;
	assign ctrl_MEM[10]= MEM_load;
	assign ctrl_MEM[11]= MEM_write;
	
	//----------------process running tree-----------------
	always@(posedge clk) 
		begin
			if(instruction_cicle==0 && !Status[3]) begin
				MEM_Addr=PC[7:0];// joga a pc para o endereçamento de memoria 
				MEM_page=PCMEM_page;
				MEM_load=1;	//carrega posição de memória
				case(in_MEM[7:4])
					1:	begin		//ADD
							PC++;
							out_ALU1=regs[in_MEM[3:2]-1];
							out_ALU2=regs[in_MEM[1:0]-1];
							ctrl_ALU=1;
						end
					2:	begin		//SUB
							PC++;
							out_ALU1=regs[in_MEM[3:2]-1];
							out_ALU2=regs[in_MEM[1:0]-1];
							ctrl_ALU=2;
						end
					3:	begin		//AND
							PC++;
							out_ALU1=regs[in_MEM[3:2]-1];
							out_ALU2=regs[in_MEM[1:0]-1];
							ctrl_ALU=3;
						end
					4:	begin		//OR
							PC++;
							out_ALU1=regs[in_MEM[3:2]-1];
							out_ALU2=regs[in_MEM[1:0]-1];
							ctrl_ALU=4;
						end
					5:	begin		//NOT
							PC++;
							out_ALU1=regs[in_MEM[3:2]-1];
							ctrl_ALU=5;
						end
					6:	begin		//SBL
							PC++;
							out_ALU1=regs[in_MEM[3:2]-1];
							ctrl_ALU=6;
						end
					7:	begin		//SBR
							PC++;
							out_ALU1=regs[in_MEM[3:2]-1];
							ctrl_ALU=7;
						end
					8:	begin		//MOV
							if(in_MEM[1:0]!=0) begin
								PC++;
								regs[in_MEM[3:2]-1]=regs[in_MEM[1:0]-1];
							end else begin
								instruction_cicle=1;
								PC++;
								instruction_code=in_MEM;
							end
						end
					9: 	begin		//LD
							instruction_cicle=1;
							PC++;
							instruction_code=in_MEM;
						end
					10:	begin		//ST
							instruction_cicle=1;
							PC++;
							instruction_code=in_MEM;
						end
					11:	begin		//CLR
							if(in_MEM[3:2]!=0) begin
								PC++;
								regs[in_MEM[3:2]-1]=0;
							end else begin
								instruction_cicle=1;
								PC++;
								instruction_code=in_MEM;
							end
						end
					12: begin	//JMP's
							case(in_MEM[3:2])
								0:	begin						//JMP
										instruction_cicle=1;
										PC++;
										instruction_code=in_MEM;
									end
								1:	if(Status[0]==1) begin		//JMP if Z=1
										instruction_cicle=1;
										PC++;
										instruction_code=in_MEM;
									end else begin
										PC+=2;
									end
								2:	if(regs[0]!=0) begin		//JMP if X!=0
										instruction_cicle=1;
										PC++;
										instruction_code=in_MEM;
									end else begin
										PC+=2;
									end
								3:	if(regs[0]==regs[2]) begin	//JMP if X==K
										instruction_cicle=1;
										PC++;
										instruction_code=in_MEM;
									end else begin
										PC+=2;
									end
							endcase
						end
					13:	begin	// more JMP's
							case(in_MEM[3:2])
								0:	if(regs[0]<regs[2]) begin	//JMP if X<K
										instruction_cicle=1;
										PC++;
										instruction_code[1:0]=in_MEM[1:0];
										instruction_code[7:4]=12;
									end else begin
										PC+=2;
									end
								1:	if(regs[0]>regs[2]) begin	//JMP if X>K
										instruction_cicle=1;
										PC++;
										instruction_code[1:0]=in_MEM[1:0];
										instruction_code[7:4]=12;
									end else begin
										PC+=2;
									end
								2:	if(Status[2]==1) begin	//JMP if Overflow
										instruction_cicle=1;
										PC++;
										instruction_code[1:0]=in_MEM[1:0];
										instruction_code[7:4]=12;
									end else begin
										PC+=2;
									end
								3:	if(Status[1]==1) begin	//JMP if Underflow or minus
										instruction_cicle=1;
										PC++;
										instruction_code[1:0]=in_MEM[1:0];
										instruction_code[7:4]=12;
									end else begin
										PC+=2;
									end
							endcase
						end
					14: case(in_MEM[3:2])
							0:	begin			//CALL
									instruction_cicle=1;
									MEM_Addr=PC;
									MEM_page=PCMEM_page;
									PC+=2;
									Stack[Stack_count][0]=PC[7:0];
									Stack[Stack_count][1]=Status;
									if(PC[8]==1 && Stack[Stack_count][1][5:4]<3)begin
										Stack[Stack_count][1][5:4]++;
									end
									Stack_count++;
									instruction_code=in_MEM;									
								end
							1:	begin			//RET
									Stack_count--;
									PC[7:0]=Stack[Stack_count][0];
									PC[8]=0;
									PCMEM_page=Stack[Stack_count][1][5:4];
									flags=Stack[Stack_count][1][3:0];
								end
							2:	begin			//RETI
									Stack_count--;
									PC[7:0]=Stack[Stack_count][0];
									PC[8]=0;
									PCMEM_page=Stack[Stack_count][1][5:4];
									flags=Stack[Stack_count][1][3:0];
									ctrl_INTERRUPT[0]=1;
								end
							
						endcase
				endcase
			end else begin
				case(instruction_code[7:4])
					8:	begin		//mov 
							MEM_Addr=PC[7:0];// joga a pc para o endereçamento de memoria 
							MEM_page=PCMEM_page;
							MEM_load=1;
							instruction_cicle=0;
							PC++;
							regs[instruction_code[3:2]-1]=in_MEM;
						end
					9:	begin		//ld
							case(instruction_cicle)
								1: 	begin
										MEM_Addr=PC[7:0];// joga a pc para o endereçamento de memoria 
										MEM_page=PCMEM_page;
										MEM_load=1;
										instruction_cicle=2;
										MEM_page=instruction_code[1:0];
										MEM_Addr=in_MEM;										
									end
								2:	begin
										MEM_load=1;
										instruction_cicle=0;
										PC++;
										regs[instruction_code[3:2]-1]=in_MEM;
									end
							endcase
						end
					10:	begin		//ST
							case(instruction_cicle)
								1: 	begin
										MEM_Addr=PC[7:0];// joga a pc para o endereçamento de memoria 
										MEM_page=PCMEM_page;
										MEM_load=1;
										instruction_cicle=2;
										MEM_page=instruction_code[1:0];
										MEM_Addr=in_MEM;
										out_MEM= regs[instruction_code[3:2]-1];
									end
								2:	begin
										MEM_write=1;
										instruction_cicle=0;
										PC++;
									end
							endcase
						end
					11:	begin
							case(instruction_cicle)
								1: 	begin
										MEM_Addr=PC[7:0];// joga a pc para o endereçamento de memoria 
										MEM_page=PCMEM_page;
										MEM_load=1;
										instruction_cicle=2;
										MEM_page=instruction_code[1:0];
										MEM_Addr=in_MEM;
										out_MEM= 0;
									end
								2:	begin
										MEM_write=1;
										instruction_cicle=0;
										PC++;
									end
							endcase
						end
					12: begin
							MEM_Addr=PC[7:0];// joga a pc para o endereçamento de memoria 
							MEM_page=PCMEM_page;
							MEM_load=1;
							instruction_cicle=0;
							PCMEM_page=instruction_code[1:0];
							PC=in_MEM;
						end
					14:	begin
							MEM_load=1;
							instruction_cicle=0;
							PCMEM_page=instruction_code[1:0];
							PC=in_MEM;
						end
				endcase
			end 
		
			if(PC[8]==1 && PCMEM_page<3) begin
				PC[8]=0;
				PCMEM_page++;
			end;
		end
		
	always@(negedge clk) 
		begin
			MEM_load=0;
			MEM_write=0;
			ctrl_INTERRUPT[0]=0;
			if(in_MEM[7:4]!=14)	begin
				flags[2:0]=flags_ALU;
				flags[3]=flags_INTERRUPT;
			end
			
			if(instruction_cicle==0) begin
				case(in_MEM[7:4])
					1:	regs[2]=in_ALU;
					2:	regs[2]=in_ALU;
					3:	regs[2]=in_ALU;
					4:	regs[2]=in_ALU;
					5:	regs[in_MEM[1:0]-1]=in_ALU;
					6:	regs[in_MEM[1:0]-1]=in_ALU;
					7:	regs[in_MEM[1:0]-1]=in_ALU;
				endcase
			end
		end	
endmodule;

module ZueiraI_IO(
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








