`include "ZueiraI.svh" 
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
			MEM_write=0;
			MEM_Addr=0;
			instruction_cicle=0;
			PCMEM_page=0;
			Stack_count=0;
			work_INT=0;
			flags=0;
			//MEM_load=1;
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
			//$display($time," foi" );
			if(instruction_cicle==0 && !Status[3]) begin
				MEM_Addr=PC[7:0];// joga a pc para o endereçamento de memoria 
				MEM_load=1;	//carrega posição de memória
				MEM_page=PCMEM_page;
				#1
				case(in_MEM[7:4])
					1:	begin		//ADD
							PC++;
							$display($time," ADD ",in_MEM[3:2],"|",in_MEM[1:0] );
							out_ALU1<=regs[in_MEM[3:2]-1];
							out_ALU2<=regs[in_MEM[1:0]-1];
							ctrl_ALU=1;
						end
					2:	begin		//SUB
							PC++;
							$display($time," SUB" );
							out_ALU1<=regs[in_MEM[3:2]-1];
							out_ALU2<=regs[in_MEM[1:0]-1];
							ctrl_ALU=2;
						end
					3:	begin		//AND
							PC++;
							$display($time," AND" );
							out_ALU1<=regs[in_MEM[3:2]-1];
							out_ALU2<=regs[in_MEM[1:0]-1];
							ctrl_ALU=3;
						end
					4:	begin		//OR
							PC++;
							$display($time," OR" );
							out_ALU1<=regs[in_MEM[3:2]-1];
							out_ALU2<=regs[in_MEM[1:0]-1];
							ctrl_ALU=4;
						end
					5:	begin		//NOT
							PC++;
							$display($time," NOT" );
							out_ALU1=regs[in_MEM[3:2]-1];
							ctrl_ALU=5;
						end
					6:	begin		//SBL
							PC++;
							$display($time," ShiftL" );
							out_ALU1=regs[in_MEM[3:2]-1];
							ctrl_ALU=6;
						end
					7:	begin		//SBR
							PC++;
							$display($time," ShiftR" );
							out_ALU1=regs[in_MEM[3:2]-1];
							ctrl_ALU=7;
						end
					8:	begin		//MOV
							if(in_MEM[1:0]!=0) begin
								PC++;
								$display($time," MOV Rd<Ro" );
								regs[in_MEM[3:2]-1]=regs[in_MEM[1:0]-1];
							end else begin
								$display($time," MOV R<L" );
								instruction_cicle=1;
								PC++;
								instruction_code=in_MEM;
							end
						end
					9: 	begin		//LD
							instruction_cicle=1;
							PC++;
							$display($time," LD" );
							instruction_code=in_MEM;
						end
					10:	begin		//ST
							instruction_cicle=1;
							PC++;
							$display($time," ST" );
							instruction_code=in_MEM;
						end
					11:	begin		//CLR
							if(in_MEM[3:2]!=0) begin
								PC++;
								regs[in_MEM[3:2]-1]=0;
								$display($time," CLR R" );
							end else begin
								instruction_cicle=1;
								PC++;
								$display($time," CLR MEM," );
								instruction_code=in_MEM;
							end
						end
					12: begin	//JMP's
							case(in_MEM[3:2])
								0:	begin						//JMP
										instruction_cicle=1;
										$display($time," JMP" );
										PC++;
										instruction_code=in_MEM;
									end
								1:	if(Status[0]==1) begin		//JMP if Z=1
										instruction_cicle=1;
										PC++;
										$display($time," JZ" );
										instruction_code=in_MEM;
									end else begin
										PC+=2;
									end
								2:	if(regs[0]!=0) begin		//JMP if X!=0
										instruction_cicle=1;
										PC++;
										$display($time," JXZ" );
										instruction_code=in_MEM;
									end else begin
										PC+=2;
									end
								3:	if(regs[0]==regs[2]) begin	//JMP if X==K
										instruction_cicle=1;
										PC++;
										$display($time," JE" );
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
										$display($time," JLT" );
										instruction_code[1:0]=in_MEM[1:0];
										instruction_code[7:4]=12;
									end else begin
										PC+=2;
									end
								1:	if(regs[0]>regs[2]) begin	//JMP if X>K
										instruction_cicle=1;
										PC++;
										$display($time," JGT" );
										instruction_code[1:0]=in_MEM[1:0];
										instruction_code[7:4]=12;
									end else begin
										PC+=2;
									end
								2:	if(Status[2]==1) begin	//JMP if Overflow
										instruction_cicle=1;
										PC++;
										$display($time," JO" );
										instruction_code[1:0]=in_MEM[1:0];
										instruction_code[7:4]=12;
									end else begin
										PC+=2;
									end
								3:	if(Status[1]==1) begin	//JMP if Underflow or minus
										instruction_cicle=1;
										PC++;
										$display($time," U" );
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
									$display($time," CALL" );
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
									$display($time," RET" );
									Stack_count--;
									PC[7:0]=Stack[Stack_count][0];
									PC[8]=0;
									PCMEM_page=Stack[Stack_count][1][5:4];
									flags=Stack[Stack_count][1][3:0];
								end
							2:	begin			//RETI
									$display($time," RETI" );
									Stack_count--;
									PC[7:0]=Stack[Stack_count][0];
									PC[8]=0;
									PCMEM_page=Stack[Stack_count][1][5:4];
									flags=Stack[Stack_count][1][3:0];
									ctrl_INTERRUPT[1]=1;
									work_INT=1;
								end
							
						endcase
				endcase
			end else if(instruction_cicle==0 && Status[3] && !work_INT)begin	// INTERRUPT START
				$display($time," INTERRUPT start c0" );
				MEM_Addr=`MEM_INT_MEM_Addr;
				MEM_page=0;
				work_INT=1;
				MEM_load=1;
				Stack[Stack_count][0]=PC[7:0];
				Stack[Stack_count][1]=Status;
				Stack_count++;
				PC[7:0]=in_MEM;
				MEM_Addr=`MEM_INT_MEM_Addr+1;
			end else if(instruction_cicle==0 && Status[3] && work_INT)begin	// INTERRUPT START				
				MEM_load=1;
				$display($time," INTERRUPT start c1" );
				PCMEM_page=in_MEM[3:0];
				ctrl_INTERRUPT[0]=1;
			end	else begin
				case(instruction_code[7:4])
					8:	begin		//mov 
							MEM_Addr=PC[7:0];// joga a pc para o endereçamento de memoria 
							MEM_page=PCMEM_page;
							MEM_load=1;
							$display($time," MOV c2" );
							instruction_cicle=0;
							PC++;
							regs[instruction_code[3:2]-1]=in_MEM;
						end
					9:	begin		//ld
							case(instruction_cicle)
								1: 	begin
										$display($time," LD C2" );
										MEM_Addr=PC[7:0];// joga a pc para o endereçamento de memoria 
										MEM_page=PCMEM_page;
										MEM_load=1;
										instruction_cicle=2;
										MEM_page=instruction_code[1:0];
										MEM_Addr=in_MEM;										
									end
								2:	begin
										MEM_load=1;
										$display($time," LD C3" );
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
										$display($time," ST c2" );
										instruction_cicle=2;
										MEM_page=instruction_code[1:0];
										MEM_Addr=in_MEM;
										out_MEM= regs[instruction_code[3:2]-1];
									end
								2:	begin
										MEM_write=1;
										instruction_cicle=0;
										PC++;
										$display($time," ST C3" );
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
										$display($time," CLR MEM C2" );
									end
								2:	begin
										MEM_write=1;
										instruction_cicle=0;
										PC++;
										$display($time," CLR MEM C3" );
									end
							endcase
						end
					12: begin
							MEM_Addr=PC[7:0];// joga a pc para o endereçamento de memoria 
							MEM_page=PCMEM_page;
							MEM_load=1;
							instruction_cicle=0;
							$display($time," JMPS C2 " ,in_MEM);
							PCMEM_page=instruction_code[1:0];
							#1 PC=in_MEM;
							$display($time," JMPS C2 " ,in_MEM);
						end
					14:	begin
							MEM_load=1;
							instruction_cicle=0;
							PCMEM_page=instruction_code[1:0];
							PC=in_MEM;
							$display($time," CALL" );
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
			ctrl_INTERRUPT=0;		
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
