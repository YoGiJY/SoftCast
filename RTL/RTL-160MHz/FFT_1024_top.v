
/*
 * @Author:Yao
 * @Time :2016年2月22日20:41:52
 * @Brief:FFT_1024_top(clk, rst, enable, data_in, sync_o, data_out)
 *                     时钟,重置,有效信号,输入数据,输出信号,输出数据
 */
`resetall
`timescale 1ns/1ps
module FFT_1024_top(clk,
                    rst,
                    enable,
                    data_in,
                    sync_o,
                    data_out);
                    
  parameter WORDLENGTH=32;
  parameter ADDRLENGTH=12;
  input clk;
  input enable;
  input [WORDLENGTH-1:0] data_in;
  
  input rst; //这个rst
  
  output sync_o;
  output[WORDLENGTH-1:0] data_out;
  
 (* KEEP = "true" *) wire sync_o;
 (* KEEP = "true" *) wire wr0,wr1,wr2,wr3,wr4,wr5,wr6;
 (* KEEP = "true" *) wire [ADDRLENGTH-1:0] addri,addr0,addr1,addr2,addr3,addr4,addr5,addr6;

 (* KEEP = "true" *) wire [WORDLENGTH-1:0] rom_out_L0,rom_out_L1,rom_out_L2,rom_out_L3,rom_out_L4,rom_out_L5,rom_out_L6,
                        FFT_out_L1,FFT_out_L2,FFT_out_L3,FFT_out_L4,FFT_out_L5,FFT_out_L6;
  
 (* KEEP = "true" *) wire [17:0] omega2,omega3,omega4,omega5,omega6;

  reg cen;
  reg ou;
  reg t;
  reg [ADDRLENGTH-1:0] bug;
  reg [ADDRLENGTH-1:0] count;
  
  //将存储器初始化
  always @(posedge clk or negedge rst)
  begin
    if(rst == 1'b0)
      cen <= 1;
    else if(enable == 1)
      cen <= 0;
  end
  
  //实现判断输出数据的标志
  always @(posedge clk or negedge rst)
  begin
    if(rst == 1'b0)
      count <= 963+1024*3;  
    else if(enable == 1'b1)
      count <= count +1;
   end
  
  always @(posedge clk or negedge rst)
  begin
    if(rst == 1'b0)
      begin
        bug <=0;
        t <= 0;
      end
    else if(count == 4095)
      bug <= bug+1;
    else if(bug >6 )
      t <=1; 
   end
  
  
  always @(posedge clk or negedge rst)
  begin
    if(!rst)
      ou<=0;
    else if(t ==1 && count == 4095)
     ou<=1;
    else 
      ou<=0;
	end
  
  assign sync_o = ou;
  
  //中央控制信息
 
  center_ctrl cent_ctrl(.clk(clk),
                        .rst(rst),
                        .enable(enable),
                        .wr0(wr0),
                        .wr1(wr1),
                        .wr2(wr2),
                        .wr3(wr3),
                        .wr4(wr4),
                        .wr5(wr5),
								.wr6(wr6),
                        .addri(addri),
                        .addr0(addr0),
                        .addr1(addr1),
                        .addr2(addr2),
                        .addr3(addr3),
                        .addr4(addr4),
                        .addr5(addr5),
								.addr6(addr6));

 
   omega_generate_unit omega(.clk(clk),
                            .rst(rst),
                            .enable(enable),
                            .omega2(omega2),
                            .omega3(omega3),
                            .omega4(omega4),
                            .omega5(omega5),
									 .omega6(omega6));
  
  //
  //always @
  //LEVEL ZERO RAM
  
  PQ_RAM  #(32,12,0)  L0_RAM(.clk(clk),
                             .enable(enable),
									  .rst(rst),
                             .wr(wr0),
							        .cen(cen),
                             .addr_w(addri),
                             .addr_r(addr0),
                             .data_in(data_in),
                             .data_out(rom_out_L0));

  //LEVEL ONE FFT
  //clk_reg[1:0] == 0
  pipe_line_b4_top_2  #(16,9) L1_PPL_FFT(.clk(clk),   //2
                                         .rst(rst),
                                         .enable(enable),
                                         .data_in(rom_out_L0),
                                         .omega_in(18'b0_1111_1111_0_0000_0000),
                                         .data_out(FFT_out_L1));
 

  //LEVEL ONE RAM
  
  PQ_RAM   L1_RAM(.clk(clk),
                 .enable(enable),
					  .rst(rst),
                 .wr(wr1),
				     .cen(cen),
                 .addr_w(addr0),
                 .addr_r(addr1),
                 .data_in(FFT_out_L1),
                 .data_out(rom_out_L1));

  //LEVEL TWO FFT
  //clk_reg[1:0] == 1
  pipe_line_b4_top_3  #(16,9) L2_PPL_FFT(.clk(clk),   //1
                                         .rst(rst),
                                         .enable(enable),
                                         .data_in(rom_out_L1),
                                         .omega_in(omega2),
                                         .data_out(FFT_out_L2));

  
  //LEVEL TWO RAM
  
  PQ_RAM  L2_RAM(.clk(clk),
                 .wr(wr2),
					  .enable(enable),
					  .rst(rst),
				     .cen(cen),
                 .addr_w(addr1),
                 .addr_r(addr2),
                 .data_in(FFT_out_L2),
                 .data_out(rom_out_L2));
  

  //LEVEL THREE FFT
  //clk_reg[1:0] == 2
  pipe_line_b4_top_4  #(16,9) L3_PPL_FFT(.clk(clk),    //0
                                         .rst(rst),
                                         .enable(enable),
                                         .data_in(rom_out_L2),
                                         .omega_in(omega3),
                                         .data_out(FFT_out_L3));
  
  //LEVEL THREE RAM
  
  PQ_RAM  L3_RAM(.clk(clk),
                 .wr(wr3),
					  .rst(rst),
					  .enable(enable),
				     .cen(cen),
                 .addr_w(addr2),
                 .addr_r(addr3),
                 .data_in(FFT_out_L3),
                 .data_out(rom_out_L3));
 
  //LEVEL FOUR FFT
  //clk_reg[1:0] == 3
  pipe_line_b4_top_1  #(16,9) L4_PPL_FFT(.clk(clk),             //3
                                         .rst(rst),
                                         .enable(enable),
                                         .data_in(rom_out_L3),
                                         .omega_in(omega4),
                                         .data_out(FFT_out_L4));

  
  //LEVEL FOUR RAM
  
  PQ_RAM  L4_RAM(.clk(clk),
                 .wr(wr4),
					  .rst(rst),
					  .enable(enable),
				     .cen(cen),
                 .addr_w(addr3),
                 .addr_r(addr4),
                 .data_in(FFT_out_L4),
                 .data_out(rom_out_L4));

  //LEVEL FIVE FFT
  //clk_reg[1:0] == 0
  pipe_line_b4_top_5  #(16,9) L5_PPL_FFT(.clk(clk),              //2
                                         .rst(rst),
                                         .enable(enable),
                                         .data_in(rom_out_L4),
                                         .omega_in(omega5),
                                         .data_out(FFT_out_L5));
 
  //LEVEL FIVE RAM
  
  PQ_RAM  L5_RAM(.clk(clk),
                 .wr(wr5),
					  .rst(rst),
					  .enable(enable),
				     .cen(cen),
                 .addr_w(addr4),
                 .addr_r(addr5),
                 .data_in(FFT_out_L5),
                 .data_out(rom_out_L5));  
	
	
  //LEVEL SIX FFT
  //clk_reg[1:0] == 0
  pipe_line_b4_top_6  #(16,9) L6_PPL_FFT(.clk(clk),             //1
                                         .rst(rst),
                                         .enable(enable),
                                         .data_in(rom_out_L5),
                                         .omega_in(omega6),
                                         .data_out(FFT_out_L6));
 
  //LEVEL FIVE RAM
  
  PQ_RAM  L6_RAM(.clk(clk),
                 .wr(wr6),
					  .rst(rst),
					  .enable(enable),
				     .cen(cen),
                 .addr_w(addr5),
                 .addr_r(addr6),
                 .data_in(FFT_out_L6),
                 .data_out(data_out));  
					  
					  
endmodule
