
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/26/2016 11:26:33 AM
// Design Name: 
// Module Name: FFT_1024_tb_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`resetall
`timescale 1ns/1ps
module FFT_1024_tb_tb( );
    reg rst;
	 reg rst_clk;
    reg enable;
    reg SYSCLK_P;
    reg  SYSCLK_N;
    always #2.5 SYSCLK_P = ~SYSCLK_P;
    always #2.5 SYSCLK_N = ~SYSCLK_N;

    initial 
      begin
       SYSCLK_P = 1;
       SYSCLK_N  = 0;
		 rst_clk = 0;
		 enable = 0;
        rst = 0 ;
        #100;
		  rst_clk = 1;
        #1000;
		  rst = 1;
		  #1000;
        enable = 1;
       end
       FFT_1024_tb tb(
       .rst(rst),
       .enable(enable),
		 .rst_clk(rst_clk),
       .SYSCLK_P(SYSCLK_P),
       .SYSCLK_N(SYSCLK_N)
       );
 
endmodule
