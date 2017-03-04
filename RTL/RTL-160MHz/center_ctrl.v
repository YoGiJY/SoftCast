
`resetall
`timescale 1ns/1ps
module center_ctrl(clk,
                   rst,
                   enable,
                   wr0,
                   wr1,
                   wr2,
                   wr3,
                   wr4,
                   wr5,
						 wr6,
                   addri,
                   addr0,
                   addr1,
                   addr2,
                   addr3,
                   addr4,
                   addr5,
						 addr6);
						 
  parameter ADDRLENGTH = 12;
  input clk,rst;
  input enable;
  output wr0,wr1,wr2,wr3,wr4,wr5,wr6;
  output[ADDRLENGTH-1:0] addri,addr0,addr1,addr2,addr3,addr4,addr5,addr6;
  
  reg [ADDRLENGTH-1:0] clk_4_reg;
  reg wr0,wr1,wr2,wr3,wr4,wr5,wr6;
 
  always @ (posedge clk or negedge rst)
  begin
    if (!rst) begin
      clk_4_reg<=0;
      wr0<=0;
      wr1<=0;
      wr2<=0;
      wr3<=0;
      wr4<=0;
      wr5<=0;
		wr6<=0;
    end
    else if(enable == 1'b1)
    begin	 
		clk_4_reg<=clk_4_reg+1;
      if (clk_4_reg==0)  wr0<=~wr0;   //0
      if (clk_4_reg==10)  wr1<=~wr1;   //5
      if (clk_4_reg==20) wr2<=~wr2;   //10
      if (clk_4_reg==30) wr3<=~wr3;   //15
      if (clk_4_reg==40) wr4<=~wr4;   //20
      if (clk_4_reg==50) wr5<=~wr5;   //25
		if (clk_4_reg==60) wr6<=~wr6;   //30
    end
  end
  
  addr_accumulator addr_accu(.clk(clk),
                             .rst(rst),
                             .enable(enable),
                             .out_addri(addri),
                             .out_addr0(addr0),
                             .out_addr1(addr1),
                             .out_addr2(addr2),
                             .out_addr3(addr3),
                             .out_addr4(addr4),
                             .out_addr5(addr5),
									  .out_addr6(addr6));
endmodule
