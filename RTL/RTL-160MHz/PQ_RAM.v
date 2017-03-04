//

//
// using Mentor Graphics HDL Designer(TM) 2004.1b (Build 12)
//

`resetall
`timescale 1ns/1ps
module PQ_RAM(clk,
              enable,
				  rst,
              wr,
              cen,
              addr_w,
              addr_r,
              data_in,
              data_out);
              
  parameter WORDLENGTH=32;
  parameter ADDRLENGTH=12;
  parameter ADDRWDELAY=1;
  
  input  cen,clk,wr;
  input enable;
  input rst;
  input [ADDRLENGTH-1:0] addr_w,addr_r;
  
  input [WORDLENGTH-1:0] data_in;
  output[WORDLENGTH-1:0] data_out;
  wire [ADDRLENGTH-1:0]  addr_p,addr_q;
  wire [WORDLENGTH-1:0]  data_out_p,data_out_q;
  reg  wr_delay;         //
  reg  [ADDRLENGTH-1:0]  addr_w_delay[9:0];
  
  
  
  always @ (posedge clk or negedge rst)
  
  begin 
   if(!rst)
	  begin
	   addr_w_delay[0] <= 0;          //五个周期来实现将数据延迟
      addr_w_delay[1] <= 0;
      addr_w_delay[2] <= 0;
      addr_w_delay[3] <= 0;
      addr_w_delay[4] <= 0;
      addr_w_delay[5] <= 0;
      addr_w_delay[6] <= 0;
      addr_w_delay[7] <= 0;
      addr_w_delay[8] <= 0;
      addr_w_delay[9] <= 0;
	  end
   else if(enable == 1)
   begin
      addr_w_delay[0]<=addr_w;          //五个周期来实现将数据延迟
      addr_w_delay[1]<=addr_w_delay[0];
      addr_w_delay[2]<=addr_w_delay[1];
      addr_w_delay[3]<=addr_w_delay[2];
      addr_w_delay[4]<=addr_w_delay[3];  
	 	addr_w_delay[5]<=addr_w_delay[4]; //添加两个周期的延迟,在第一个存储的时候不使用延迟判断条件是ADDRWDELAY
	 	addr_w_delay[6]<=addr_w_delay[5]; 
	 	addr_w_delay[7]<=addr_w_delay[6];
	 	addr_w_delay[8]<=addr_w_delay[7];
	 	addr_w_delay[9]<=addr_w_delay[8];
	end
  end
   //          Q,              //output data_out
   //			   CLK,            //clk
	//		      CEN,
	//		      WEN,
	//		      A,              //addr
	//		      D);             //data_in
 
  dist_mem_gen_0 P_RAM(
  .clka(clk),         // input clka
  .ena(!cen),         // input ena
  .wea(wr),           // input [0 : 0] wea
  .addra(addr_p),     // input [11 : 0] addra
  .dina(data_in),     // input [31 : 0] dina
  .douta(data_out_p)  // output [31 : 0] douta
);
  
  dist_mem_gen_0 Q_RAM(
  .clka(clk),        // input clka
  .ena(!cen),        // input ena
  .wea(!wr),         // input [0 : 0] wea
  .addra(addr_q),    // input [11 : 0] addra
  .dina(data_in),    // input [31 : 0] dina
  .douta(data_out_q) // output [31 : 0] douta
);


  always @ (posedge clk)
  begin
  if(enable == 1)
     wr_delay<=wr;     //延迟一个周期将读出来的数据标示记录
  end

  assign data_out= (wr_delay)?data_out_q:data_out_p;
  assign addr_p=(ADDRWDELAY)?((wr)?addr_w_delay[9]:addr_r):((wr)?addr_w:addr_r); 
  assign addr_q=(ADDRWDELAY)?((wr)?addr_r:addr_w_delay[9]):((wr)?addr_r:addr_w); 
endmodule
