
`resetall
`timescale 1ns/1ps
module omega_generate_unit(clk,
                           rst,
                           enable,
                           omega2,
                           omega3,
                           omega4,
                           omega5,
									omega6);
  input clk,rst;
  input enable;
  output[17:0] omega2,omega3,omega4,omega5,omega6;
  
  wire[3:0] addr2;   //4bit
  wire[5:0] addr3;   //6bit
  wire[7:0] addr4;   //8bit
  wire[9:0] addr5;   //10bit
  wire[11:0] addr6;   //12bit
  
  rom_addr_generate  rom_ad_gen(.clk(clk),
                                .rst(rst),
                                .enable(enable),
                                .addr2(addr2),
                                .addr3(addr3),
                                .addr4(addr4),
                                .addr5(addr5),
										  .addr6(addr6));
                                
  ROM2_omega rm2(.ROM_data(omega2),
                 .ROM_addr(addr2),
                 .clk(clk));
  
  ROM3_omega rm3(.ROM_data(omega3),
                 .ROM_addr(addr3),
                 .clk(clk));
  
  ROM4_omega rm4(.ROM_data(omega4),
                 .ROM_addr(addr4),
                 .clk(clk));
  
  ROM5_omega rm5(.ROM_data(omega5),
                 .ROM_addr(addr5),
                 .clk(clk));
					  
  ROM6_omega rm6(.ROM_data(omega6),
                 .ROM_addr(addr6),
                 .clk(clk));
  
endmodule
