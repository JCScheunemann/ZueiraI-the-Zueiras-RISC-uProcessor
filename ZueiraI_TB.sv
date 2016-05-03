`timescale 1 ns / 1 ns
module ZueiraI_tb;

reg clk, rst;
wire [2:0][7:0] IO;
initial begin
  clk=0;
  rst=1;
   rst= #10 0;
  repeat(200) 
	begin
		#10  clk =  ! clk;
	end
  //#1  $stop;
end


ZueiraI z1(
			.rst(rst),
			.clk(clk),
			.IO_PORTA(IO[0]),
			.IO_PORTB(IO[1]),
			.IO_PORTC(IO[2])
			);
endmodule
