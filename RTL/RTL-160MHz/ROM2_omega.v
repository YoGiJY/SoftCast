
`resetall
`timescale 1ns/1ps
module ROM2_omega (ROM_data, ROM_addr,clk);
  
  parameter WORDLENGTH=18,ADDRLENGTH=4;

  output [WORDLENGTH-1:0] ROM_data;
  input 	[ADDRLENGTH-1:0] ROM_addr;
  
  input  clk;
  reg    [WORDLENGTH-1:0] ROM_data;


  always @ (posedge clk)
  begin
  case(ROM_addr)
    4'b0000:ROM_data<=18'b011111111000000000;
    4'b0001:ROM_data<=18'b011111111000000000;
    4'b0010:ROM_data<=18'b011111111000000000;
    4'b0011:ROM_data<=18'b011111111000000000;
    4'b0100:ROM_data<=18'b011111111000000000;
    4'b0101:ROM_data<=18'b011101011110011111;
    4'b0110:ROM_data<=18'b010110100101001100;
    4'b0111:ROM_data<=18'b001100001100010101;
    4'b1000:ROM_data<=18'b011111111000000000;
    4'b1001:ROM_data<=18'b010110100101001100;
    4'b1010:ROM_data<=18'b000000000100000001;
    4'b1011:ROM_data<=18'b101001100101001100;
    4'b1100:ROM_data<=18'b011111111000000000;
    4'b1101:ROM_data<=18'b001100001100010101;
    4'b1110:ROM_data<=18'b101001100101001100;
    4'b1111:ROM_data<=18'b100010101001100001;
         endcase
  end
endmodule
