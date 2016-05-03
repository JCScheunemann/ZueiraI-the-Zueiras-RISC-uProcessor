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