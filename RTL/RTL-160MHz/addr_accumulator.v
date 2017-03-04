
`resetall
`timescale 1ns/1ps
module addr_accumulator(clk,
                        rst,
                        enable,
                        out_addri,
                        out_addr0,
                        out_addr1,
                        out_addr2,
                        out_addr3,
                        out_addr4,
                        out_addr5,
								out_addr6);
  
  parameter ADDRLENGTH = 12;
  input clk,rst;
  input enable;
  reg [ADDRLENGTH-1:0] clk_4_reg;
  output[ADDRLENGTH-1:0] 
              out_addri,
              out_addr0,
              out_addr1,
              out_addr2,
              out_addr3,
              out_addr4,
              out_addr5,
				  out_addr6;
 
  reg [ADDRLENGTH-1:0] addri,addr0,addr1,addr2,addr3,addr4,addr5,addr6;
   
  always@(posedge clk or negedge rst)
  begin
    if(!rst) begin
	   clk_4_reg <= 0;
      addri<=-1;  //-1
      addr0<=-1;  //-1      //一个周期后开始
      addr1<=-11;  //-6      //四个周期后开始
      addr2<=-21; //-11
      addr3<=-31; //-16
      addr4<=-41; //-21
      addr5<=-51; //-26
		addr6<=-61; //-31
    end
    else if(enable == 1'b1)
    begin
	    clk_4_reg <= clk_4_reg+1;
       addri<=addri+1;
       addr0<=addr0+1;
		 addr1<=addr1+1;
		 addr2<=addr2+1;
       addr3<=addr3+1;
       addr4<=addr4+1;
       addr5<=addr5+1;
		 addr6<=addr6+1;
	 end
	end
  
  assign out_addri= addri;
  assign out_addr0={addr0[1:0],addr0[11:2]};
  //assign out_addr0={addr0[1:0],addr0[9:2]};             //256  //1024
  assign out_addr1={addr1[11:10],addr1[1:0],addr1[9:2]};
  //assign out_addr1={addr1[9:8],addr1[1:0],addr1[7:2]};  //64   //256
  assign out_addr2={addr2[11:8],addr2[1:0],addr2[7:2]};
  //assign out_addr2={addr2[9:6],addr2[1:0],addr2[5:2]};  //16   //64
  assign out_addr3={addr3[11:6],addr3[1:0],addr3[5:2]};
  //assign out_addr3={addr3[9:4],addr3[1:0],addr3[3:2]};  //4    //16
  assign out_addr4={addr4[11:4],addr4[1:0],addr4[3:2]};
  //assign out_addr4= addr4;                              //0    //4
  assign out_addr5=addr5;
  //assign out_addr5={addr5[1:0],addr5[3:2],addr5[5:4],addr5[7:6],addr5[9:8]};//变址 //0
  //变址
  assign out_addr6={addr6[1:0],addr6[3:2],addr6[5:4],addr6[7:6],addr6[9:8],addr6[11:10]};
endmodule
