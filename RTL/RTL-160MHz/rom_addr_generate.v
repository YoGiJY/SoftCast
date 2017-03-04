
`resetall
`timescale 1ns/1ps
module rom_addr_generate(clk,
                         rst,
                         enable,
                         addr2,
                         addr3,
                         addr4,
                         addr5,
								 addr6);
  input clk,rst;
  input enable;
  output[3:0] addr2;
  output[5:0] addr3;
  output[7:0] addr4;
  output[9:0] addr5;
  output[11:0] addr6;
  reg[11:0] ad_reg2,ad_reg3,ad_reg4,ad_reg5,ad_reg6;
	
  always @ (posedge clk or negedge rst)
  begin
    if (!rst) begin
      ad_reg2<=-11;   //-6
      ad_reg3<=-21;  //-11
      ad_reg4<=-31;  //-16
      ad_reg5<=-41;  //-21
		ad_reg6<=-51;  //-26
    end
    else if(enable == 1'b1)
    begin
	  begin
      ad_reg2<=ad_reg2+1;
      ad_reg3<=ad_reg3+1;
      ad_reg4<=ad_reg4+1;
      ad_reg5<=ad_reg5+1;
		ad_reg6<=ad_reg6+1;
	  end
    end
  end
  
  assign addr2 = {ad_reg2[11:10],ad_reg2[1:0]};
  //assign addr2={ad_reg2[9:8],ad_reg2[1:0]}; //9:8相差2bit, [7:0]中
  assign addr3 = {ad_reg3[11:8],ad_reg3[1:0]};
  //assign addr3={ad_reg3[9:6],ad_reg3[1:0]}; //9:6相差4bit，[5:0]中相差6bit 64个点
  assign addr4={ad_reg4[11:6],ad_reg4[1:0]};
  //assign addr4={ad_reg4[9:4],ad_reg4[1:0]};
  assign addr5={ad_reg5[11:4],ad_reg5[1:0]};
  //assign addr5= ad_reg5;
  assign addr6=ad_reg6;
endmodule