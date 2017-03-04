`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:07:28 11/20/2016 
// Design Name: 
// Module Name:    SEND_SOFTCAST_TOP 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: SEND_SOFTCAST_TOP模块中 第一步：先计算lamda
//                                     第二步：lamda和dc系数参加CRC校验然后经过turbo编码，lamda计算g
//                                     第三步：(I,Q)的形式输出数字部分数据和模拟部分数据
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module SEND_SOFTCAST_TOP(
    clk,                       //时钟信号
    rst_N,                     //重置信号
    enable,                    //有效信号                  
    data_in,                   //输入DCT数据
    input_line_sync,          //行同步输入
	 
    sync_digital,              //同步输出信号
    data_out_digital_real,     //经过turbo编码和modu之后数字数据
    data_out_digital_image,
    output_line_sync_digital,
	 
    sync_analog,               //同步输出信号
    data_out_analog_real,      //功率分配之后的模拟信号数据
    data_out_analog_image,
    output_line_sync_analog
    );
	 
    ////////////////////////////////////////////////
    input clk;                           //时钟信号
    input rst_N;                         //重置信号
    input enable;
    input signed [15:0]data_in;                 //输入数据    //(s,16,0)
	 input input_line_sync;              //同步时钟信号
    output sync_digital;                 //数字部分输出同步信号
    output [15:0]data_out_digital_real;            //数字部分输出信号0
    output [15:0]data_out_digital_image;            //数字部分输出信号1
	 output output_line_sync_digital;	  //输出数字部分同步帧信号

    output sync_analog;                  //模拟部分输出同步信号
    output [15:0]data_out_analog_real;   //模拟部分输出数据real   //（s,16,9）
    output [15:0]data_out_analog_image;  //模拟部分输出数据image
	 output output_line_sync_analog;     //模拟部分输出同步帧信号
	 ///////////////////////////////////////////////////////
	 
	 
	 ///////////////数据实现P、Q存储////////////////////////
	 reg signed [15:0] data0;
	 reg signed [15:0] data1;
	 
	 wire[13:0] addr_r;               //读数据信号
	 reg [13:0] addr_q_0,addr_q_1;    //地址信号
	 reg [13:0] addr_p_0,addr_p_1;
	 
	 wire[15:0] addr_q_w0,addr_q_w1;
    wire[15:0] addr_p_w0,addr_p_w1;
	 
	 reg [15:0] data_in_p_0,data_in_p_1;
	 reg [15:0] data_in_q_0,data_in_q_1;
	 
	 wire [15:0] data_out_p_0,data_out_p_1;
	 wire [15:0] data_out_q_0,data_out_q_1;
	 
	 wire [15:0] dataout1;    // 取模拟数据0
	 wire [15:0] dataout2;    // 取模拟数据1
	 
	 reg wr;
	 reg [14:0] count;        //存数据计数
	 reg [14:0] count_N;  

    //我们在写数据的时候，也需要的就是读数据
	 //当轮到P存储器读数据的时候，wr==0 and 读数据
	 reg[13:0] count_analog; //开始输出数据
	 reg [4:0] count_dc;
	 wire [14:0] count_dc_NM;
	 wire [15:0] dc_data0;    
	 /////////////////////////////////////////////////////////
	 	 reg signed [39:0] lambda[0:14];
    reg [23:0] lambda0[0:14];           //(u,24,0)	 
	 reg[11:0] lambdaAftercordic;       //(u,12,0) 
	 reg[21:0] sumOflambdaAftercordic;  //(u,22,0) 
	 reg[10:0] sumOfcordic;             //(u,11,0)
	 reg[5:0]  lambdaMutilcordic;	    //(u,6,0)
	 reg[15:0] g[0:14]; //(u,16,16)
	 
	 
	 reg signed [31:0] mulambda;
	 //reg [39:0] exlambda[14:0];                   //(u,40,0)
	 reg [59:0] exlambda[14:0];
	 wire [9:0] Lcount;
	 wire [3:0] doutL;
	 //计数的方式读取ROM中的数据来判断Lambda位置，这里使用的是L型的数据形式
	 	 reg [5:0]shift_bits_2;
	 //第二次开根号之后，剩下的数据只有6bit计算
	 reg [16:0]g_1;
    reg [16:0]g_2;
	 
	 reg [31:0]g0_0;
    reg [31:0]g0_1;
    reg [31:0]g0_2;
    reg [31:0]g0_3;
    reg [31:0]g0_4;
	 reg [31:0]g0_5;
    reg [31:0]g0_6;
    reg [31:0]g0_7;
    reg [31:0]g0_8;
    reg [31:0]g0_9;
	 reg [31:0]g0_10;
    reg [31:0]g0_11;
    reg [31:0]g0_12;
    reg [31:0]g0_13;
    reg [31:0]g0_14;
	 
	 reg [16:0] temp_g1_0[14:0];
	 reg [15:0] g1_00[14:0];
    
	 reg [31:0]divide_input1;
    reg [31:0]divide_input2;
	 reg [3:0] divider_count;
	 wire [16:0] temp_divider;
	 
	 wire [31:0]divide_output1;
	 reg [5:0] shifr_bit_2;
	 reg [5:0] temp_shift_sum_bit;
	 reg [23:0] temp_sqrt;
	 /////////////////////////////////////////////////////
	 reg enable_digital;
	 reg temp_frame_digital0;
	 reg temp_frame_digital1;
	 reg [14:0] count_frame_digital0;
	 //
	 reg temp_digital0;
	 reg temp_digital1;
	  reg enable_tst;
	  reg [1:0] beforemedu0,beforemedu1,beforemedu2;
	  reg [1:0] beforemedu3,beforemedu4,beforemedu5;
	  reg [2:0] beforemedu7,beforemedu8,beforemedu9;
	  reg [2:0] beforemedu6;
	  	 reg [63:0] turbo_input0;
	 reg  sync_turbo;
	 wire digit_encode_0;
	 wire digit_encode_1;
	 wire digit_encode_2;
	 	  reg [15:0] dc_data1;
	  reg [12:0] dc_data2;
     reg [12:0] dc_data3;

    reg [7:0] crc_count;
    reg [215:0] crc_data;		 
	 reg crc_sync;
	 reg crc_enable;
	 wire crc_datain;
	 wire [15:0] crc_dataout;
	 reg [215:0] digital_turbo0;
    reg [215:0] digital_turbo1;
    reg [215:0] digital_turbo2;
	 
	 reg [199:0] digital_d0;
	 reg [199:0] digital_d1;
	 reg [199:0] digital_d2;
	 
	 reg [199:0] input_crc_d0;
	 
	 reg [23:0] temp_d0;
	 reg [4:0] temp_lambda0_d0;
	 reg [17:0] temp_lambda0_d1;
	 wire [18:0] temp_lambda0_d2;
	 wire [18:0] temp_lambda0_d3;
	 //同步输出
	  reg sync_analog_temp0;
	  reg [14:0]sync_analog_temp1;
	  reg sync_analog_temp2;
	  reg sync_analog_temp3;
	  //////////////////////////////////////////
	 
	 //1
	 always @(posedge clk or negedge rst_N)
	 begin
		if(rst_N == 1'b0)
		begin
		   wr <= 1'b1;              //存储器的读写信号不重要
		end
		else if(enable == 1'b1 && count == 30719)
		begin
			wr <= ~wr;
		end 
	 end
	 
	 always@(posedge clk or negedge rst_N)
	 begin
		  if(rst_N == 1'b0)
		  begin
			 count <= -3;
		  end
		  else if(enable == 1'b1 && count == 30719)
		  begin
			 count <= 0;
		  end
		  else if(enable == 1'b1)
		  begin
		    count <= count + 1;
		  end
	 end
	 
	 
	 //2
	 always @(posedge clk or negedge rst_N)
	 begin
		if(rst_N == 1'b0)
		begin
			data0 <= 16'h0000;
			data1 <= 16'h0000;
		end
		else if(enable == 1'b1)
		begin
		   data0 <= data_in;
			data1 <= data0;
		end
	 end
	 ////////////////////////////////////////////////////////
	 
    //72
    always @(posedge clk or negedge rst_N)
    begin
	     if(rst_N == 0)
		  begin
		    count_analog <= 0;
		  end
		  else if(enable == 1 && count_N[14:10]==0 && count_N[9:0]==1+929)
		  begin
		    count_analog <= 0;
		  end
		  else if(enable == 1 && count_analog == 15359)
		  begin
		    count_analog <= 0;
		  end
		  else if(enable == 1)
		  begin
		    count_analog <= count_analog + 1;
		  end
    end	 
	 
	 //提取dc系数的
	 
	 //1
	 always @(posedge clk or negedge rst_N)
    begin
	    if(rst_N == 0)
		 begin
		   count_dc <= 0;
		 end
		 else if(enable == 1 && count_N[14:10]==0 && count_N[9:0]==0)
		 begin
		   count_dc <= 0;
		 end
		 else if(enable == 1 && count_dc==29)
		 begin
		   count_dc <= 0;
		 end
		 else if(enable == 1)
		 begin
		   count_dc <= count_dc + 1;
		 end
	 end	 
	 
	 //这里存在的就是DC系数，都存在第一个RAM中，0,512,1024，...
	 assign count_dc_NM = count_dc<<10; 
	 
	 ////////////////////////////////////////////////////////
    //存储设备有一个特点就是，数据写的时候，另外的一个PQ存储读数据，暂时不读
	 //3
	  always @(posedge clk or negedge rst_N)
	  begin
		 if(rst_N == 1'b0)
		 begin
			addr_p_0 <= 0;
			addr_p_1 <= 0;
		 end
		 else if(enable == 1'b1 && wr == 1)
		 begin
	       if(count[0]==0)
			 begin
			    addr_p_0 <= count[14:1];
				 data_in_p_0 <= data1;
			 end
			 else if(count[0]==1)
			 begin
				addr_p_1 <= count[14:1];
				data_in_p_1 <= data1;
			 end
		 end
		 //2
		 else if(enable == 1 && wr == 0 && count_N>=1 && count_N <=30)//第二个周期开始读取DC
		 begin
		    addr_p_0 <= count_dc_NM[14:1];
		 end
		 //73
		 else if(enable == 1 && wr == 0 && count_N>=31)
		 begin
		    addr_p_0 <= count_analog;
			 addr_p_1 <= count_analog;
		 end
	  end
	  
	  
	  
	  always @(posedge clk or negedge rst_N)
	  begin
		 if(rst_N == 1'b0)
		 begin
			addr_q_0 <= 0;
			addr_q_1 <= 0;
		 end
		 else if(enable == 1'b1 && wr == 0)
		 begin
	       if(count[0]==0)
			 begin
			    addr_q_0 <= count[14:1];
				 data_in_q_0 <= data1;
			 end
			 else if(count[0]==1)
			 begin
				addr_q_1 <= count[14:1];
				data_in_q_1 <= data1;
			 end
		 end
		 //2
		 else if(enable == 1 && wr == 1 && count_N>=1 && count_N <= 30)
		 begin
		    addr_q_0 <= count_dc_NM[14:1];
		 end
		 //73
		 else if(enable == 1 && wr == 1  && count_N>=31)
		 begin
		    addr_q_0 <= count_analog;
			 addr_q_1 <= count_analog;
		 end
	  end
	  
	   assign addr_q_w0 = addr_q_0;
      assign addr_q_w1 = addr_q_1;
      assign addr_p_w0 = addr_p_0;
      assign addr_p_w1 = addr_p_1;
		
	   //3
		assign dc_data0 = (wr)?data_out_q_0:data_out_p_0;
	  
	  //74
	  //获取数据
	  assign dataout1 = (wr)?data_out_q_0:data_out_p_0;
	  assign dataout2 = (wr)?data_out_q_1:data_out_p_1;
	  
	  
	 //////////////////////////////////////////////////////
	 //4
	 DIST_SOFTCAST_MEM U_RAM_P_0(
			.clka(clk),
			.wea(wr),
			.addra(addr_p_w0),
			.dina(data_in_p_0),
			.douta(data_out_p_0)
		);
		
	 DIST_SOFTCAST_MEM U_RAM_P_1(
			.clka(clk),
			.wea(wr),
			.addra(addr_p_w1),
			.dina(data_in_p_1),
			.douta(data_out_p_1)
			);
			
	 /////////////////////////////////////////////////////
	  DIST_SOFTCAST_MEM U_RAM_Q_0(
			.clka(clk),
			.wea(~wr),
			.addra(addr_q_w0),
			.dina(data_in_q_0),
			.douta(data_out_q_0)
			);
			
		DIST_SOFTCAST_MEM U_RAM_Q_1(
			.clka(clk),
			.wea(~wr),
			.addra(addr_q_w1),
			.dina(data_in_q_1),
			.douta(data_out_q_1)
			);
	 
	 
	 
	 //////////////////////////////////////////////////////
	 /////////////////实现求解lambda////////////////////////
	 //0
	 assign Lcount = count[9:0];
	 
	 //1
	 ROMLL U_romLL(
	              .clka(clk), // input clka
                 .addra(Lcount), // input [9 : 0] addra
                 .douta(doutL) // output [15 : 0] douta
					  );
	
	 //count == 0 对应 data1
	 
    //1
	 always@(posedge clk or negedge rst_N)
	 begin
	    if(rst_N==0)
		 begin
		   count_N <= 0;
			mulambda <= 0;
		 end
		 else if(enable == 1)
		 begin
		   count_N <= count;
		   mulambda <= data1 * data1;
		 end
	 end
	 
	 //2
	 always @(posedge clk or negedge rst_N)
	 begin
	    if(rst_N == 0)
		 begin
		    exlambda[0] <= 0;
		 end
		 else if(doutL == 1)
		 begin
		    exlambda[0] <= exlambda[0] + mulambda;
		 end
		 else if(count_N[9:0]==32*3-1)
		 begin
		    exlambda[0] <= exlambda[0]*65536;  //第一个chunk块是存在 8 round()
		 end
		 else if(enable == 1 && count_N[9:0]==32*3+1)
		 begin 
		    exlambda[0] <= 0;
		 end
	 end
	 reg temp;
	 //lambda[0]求出之后,将lambda[0]进行累加
	 always @(posedge clk or negedge rst_N)
	 begin
			if(rst_N == 0)
			begin
			  	 lambda[0] <= 0;
			end
			else if(count_N[9:0]==32*3)
			begin
				lambda[0] <= lambda[0] + (exlambda[0]>>19)+((exlambda[0]&60'h000000000040000)?1:0);
			end
			else if(count_N[14:10]==29 && count_N[9:0]==32*3+3)
		   begin
		      lambda[0]  <= 0;
		   end
	 end
	 
	
	 
	 //lambda[1]
	 always @(posedge clk or negedge rst_N)
	 begin
	   if(rst_N==1'b0)
		begin
			exlambda[1] <= 0;
	   end
		else if(doutL == 2)
		begin
			   exlambda[1] <= exlambda[1] + mulambda;
		end
		else if(count_N[9:0]==32*5-1)
		begin
			   exlambda[1] <= (exlambda[1]*32768);   //16
		end
		else if(count_N[9:0] == 32*5+1)
		begin
		      exlambda[1] <= 0;
		end
	end
	 
	 
	 always @(posedge clk or negedge rst_N)
	 begin
	     if(rst_N==0)
		  begin
		     lambda[1] <= 0;
		  end
		  else if(enable == 1 && count_N[9:0]==32*5)
		  begin
		    lambda[1] <= lambda[1] + (exlambda[1]>>19) + ((exlambda[1]&60'h0000000000040000)?1:0);
		  end // 4
		  else if(count_N[14:10]==29 && count_N[9:0]==32*5+3)
		  begin
		    lambda[1] <= 0;
		  end
	 end
	 
	 
	 //lambda[2]
	 always @(posedge clk or negedge rst_N)
	 begin
	   if(rst_N==1'b0)
		begin
			exlambda[2] <= 0;
	   end
		else if(doutL==3)		
		begin
			   exlambda[2] <= exlambda[2] + mulambda;
		end
		else if(count_N[9:0]==32*7-1)
		begin
			   exlambda[2] <= (exlambda[2]*21845);    //24  21845 = (2^19/24)
		end
		else if(enable == 1 && count_N[9:0]==32*7+1)
		begin
				exlambda[2] <= 0;
		end
	 end
	 
	 always @(posedge clk or negedge rst_N)
	 begin
		  if(rst_N == 0)
		  begin
		    	lambda[2] <= 0;
		  end
		  else if(enable == 1 && count_N[9:0]==32*7)
		  begin
			  	lambda[2] <= lambda[2] + (exlambda[2]>>19) + ((exlambda[2]&60'h0000000000040000)?1:0);
		  end
		  else if(count_N[14:10]==29 && count_N[9:0]==32*7+3)
		  begin
		     lambda[2]  <= 0;
		  end
	 end
	 
	 //lambda[3]
	 always @(posedge clk or negedge rst_N)
	 begin
	   if(rst_N==1'b0)
		begin
			exlambda[3] <= 0;
	   end
		if(doutL == 4)
		begin
			exlambda[3] <= exlambda[3] + mulambda;
		end
		else if(count_N[9:0]==32*9-1)
		begin
			exlambda[3] <= exlambda[3]*16384;    //32
      end	
      else if(count_N[9:0]==32*9+1)
		begin
			exlambda[3] <= 0;
		end		
	  end
	 
	 always @(posedge clk or negedge rst_N)
	 begin
			if(rst_N == 0)
			begin
			   lambda[3] <= 0;
			end
			else if(enable == 1 && count_N[9:0]==32*9)
			begin
			   lambda[3] <= lambda[3] + (exlambda[3]>>19) + ((exlambda[3]&60'h0000000000040000)?1:0);
			end
			else if(count_N[14:10]==29 && count_N[9:0]==32*9+3)
		   begin
		      lambda[3]  <= 0;
		  end
	 end
	 
	 //lambda[4]
	 always @(posedge clk or negedge rst_N)
	 begin
	   if(rst_N==1'b0)
		begin
			exlambda[4] <= 0;
	   end
		else if(doutL==5)
	   begin
			exlambda[4] <= exlambda[4] + mulambda;
		end
		else if(count_N[9:0]==32*11-1)
		begin
			exlambda[4] <= (exlambda[4]*13107);    //40   13107 = round(2^19/40)  
      end
		else if(count_N[9:0]==32*11+1)
		begin
			exlambda[4] <= 0;
		end
	 end
	 
	 
    always @(posedge clk or negedge rst_N)
	 begin
			if(rst_N == 0)
			begin
			   lambda[4] <= 0;
			end
			else if(enable == 1 && count_N[9:0]==32*11)
			begin
			   lambda[4] <= lambda[4] + (exlambda[4]>>19) + ((exlambda[4]&60'h0000000000040000)?1:0);
			end
		   else if(count_N[14:10]==29 && count_N[9:0]==32*11+3)
		   begin
		     lambda[4]  <= 0;
		   end
	 end
	 

	 
	 //lambda[5]
	 always @(posedge clk or negedge rst_N)
	 begin
	   if(rst_N==1'b0)
		begin
			exlambda[5] <= 0;
	   end
		else if(doutL ==  6)
		begin
			exlambda[5] <= exlambda[5] + mulambda;
		end
		else if(count_N[9:0]==32*13-1)
		begin
			exlambda[5] <= (exlambda[5]*10923);    //48  round(2^19/48)
		end
	   else if(count_N[9:0]==32*13+1)
		begin
		   exlambda[5] <= 0;
		end
	 end
	 
	 
	 always @(posedge clk or negedge rst_N)
	 begin
			if(rst_N == 0)
			begin
			   lambda[5] <= 0;
			end
			else if(enable == 1 && count_N[9:0]==32*13)
			begin
			   lambda[5] <= lambda[5] + (exlambda[5]>>19) + ((exlambda[5]&60'h0000000000040000)?1:0);
			end
			else if(count_N[14:10]==29 && count_N[9:0]==32*13+3)
		   begin
		      lambda[5]  <= 0;
		   end
	 end
	
	 
	//lambda[6]
	 always @(posedge clk or negedge rst_N)
	 begin
	   if(rst_N==1'b0)
		begin
			exlambda[6] <= 0;
	   end
		else if(doutL == 7)
		begin
		exlambda[6] <= exlambda[6] + mulambda;
		end
		else if(count_N[9:0]==32*15-1)
		begin
			exlambda[6] <= (exlambda[6]*9362);    //56 round(2^19/56)
		end
		else if(enable == 1 && count_N[9:0]==32*15+1)
		begin
		   exlambda[6] <= 0;
		end
	 end 
	 
	 
	 always @(posedge clk or negedge rst_N)
	 begin
			if(rst_N == 0)
			begin
			   lambda[6] <= 0;
			end
			else if(enable == 1 && count_N[9:0]==32*15)
			begin
			   lambda[6] <= lambda[6] + (exlambda[6]>>19) + ((exlambda[6]&60'h0000000000040000)?1:0); 
			end
			else if(count_N[14:10]==29 && count_N[9:0]==32*15+3)
		   begin
		      lambda[6]  <= 0;
		   end
	 end
	 
	 //lambda[7]
	 always @(posedge clk or negedge rst_N)
	 begin
	   if(rst_N==1'b0)
		begin
			exlambda[7] <= 0;
	   end
		else if(doutL == 8)
		begin
			exlambda[7] <= exlambda[7] + mulambda;
		end
		else if(count_N[9:0]==32*17-1)
		begin
			exlambda[7] <= (exlambda[7]*8192);    //64
		end
		else if(enable == 1 && count_N[9:0]==32*17+1)
		begin
			exlambda[7] <= 0;
		end
	 end
	 
	 
	 always @(posedge clk or negedge rst_N)
	 begin
			if(rst_N == 0)
			begin
			   lambda[7] <= 0;
			end
			else if(enable == 1 && count_N[9:0]==32*17)
			begin
			   lambda[7] <= lambda[7] + (exlambda[7]>>19) + ((exlambda[7]&60'h0000000000040000)?1:0); 
			end
			else if(count_N[14:10]==29 && count_N[9:0]==32*17+3)
		   begin
		      lambda[7]  <= 0;
		   end
	 end
	 
	 
	 //lambda[8]
	 always @(posedge clk or negedge rst_N)
	 begin
	   if(rst_N==1'b0)
		begin
			exlambda[8] <= 0;
	   end
		else if(doutL == 9)
		begin
			exlambda[8] <= exlambda[8] + mulambda;
		end
		else if(count_N[9:0]==32*19-1)
		begin
			exlambda[8] <= (exlambda[8]*7282);    //72   round(2^19/72)
		end
		else if(enable == 1 && count_N[9:0]==32*19+1)
		begin
			exlambda[8] <= 0;
		end
	 end
	 
	 always @(posedge clk or negedge rst_N)
	 begin
			if(rst_N == 0)
			begin
			   lambda[8] <= 0;
			end
			else if(enable == 1 && count_N[9:0]==32*19)
			begin
			   lambda[8] <= lambda[8] + (exlambda[8]>>19) + ((exlambda[8]&60'h0000000000040000)?1:0);
			end
			else if(count_N[14:10]==29 && count_N[9:0]==32*19+3)
		   begin
		      lambda[8]  <= 0;
		   end
	 end
	 
	 //lambda[9]
	 always @(posedge clk or negedge rst_N)
	 begin
	   if(rst_N==1'b0)
		begin
			exlambda[9] <= 0;
	   end
		else if(doutL == 10)
		begin
			   exlambda[9] <= exlambda[9] + mulambda;
		end
		else if(count_N[9:0]==32*21-1)
		begin
			   exlambda[9] <= (exlambda[9]*6554);    //80  round(2^19/80)
		end
		else if(enable == 1 && count_N[9:0]==32*21+1)
		begin
				exlambda[9] <= 0;
		end
	 end
	 
	 always @(posedge clk or negedge rst_N)
	 begin
			if(rst_N == 0)
			begin
			   lambda[9] <= 0;
			end
			else if(enable == 1 && count_N[9:0]==32*21)
			begin
			   lambda[9] <= lambda[9] + (exlambda[9]>>19) + ((exlambda[9]&60'h0000000000040000)?1:0);
			end
			else if(count_N[14:10]==29 && count_N[9:0]==32*21+3)
		   begin
		      lambda[9]  <= 0;
		   end
	 end
	 

    //lambda[10]
	 always @(posedge clk or negedge rst_N)
	 begin
	   if(rst_N==1'b0)
		begin
			 exlambda[10] <= 0;
	   end
		else if(doutL == 11)
		begin
			   exlambda[10] <= exlambda[10] + mulambda;
		end
		else if(count_N[9:0]==32*23-1)
		begin
			   exlambda[10] <= (exlambda[10]*5958);    //88  round(2^19/88)
		end
		else if(enable == 1 && count_N[9:0]==32*23+1)
		begin
				exlambda[10] <= 0;
		end
	 end
	 
	 always @(posedge clk or negedge rst_N)
	 begin
			if(rst_N == 0)
			begin
			   lambda[10] <= 0;
			end
			else if(enable == 1 && count_N[9:0]==32*23)
			begin
			   lambda[10] <= lambda[10] + (exlambda[10]>>19) + ((exlambda[10]&60'h0000000000040000)?1:0);
			end
			else if(count_N[14:10]==29 && count_N[9:0]==32*23+3)
		   begin
		      lambda[10]  <= 0;
		   end
	 end


	 //lambda[11]
	 always @(posedge clk or negedge rst_N)
	 begin
	   if(rst_N==1'b0)
		begin
			lambda[11] <= 0;
			exlambda[11] <= 0;
	   end
		else if(doutL == 12)
		begin
			exlambda[11] <= exlambda[11] + mulambda;
		end
		else if(count_N[9:0]==32*25-1)
		begin
			exlambda[11] <= (exlambda[11]*5461);    //96   round(2^19/96)
		end
		else if(enable == 1 && count_N[9:0]==32*25+1)
		begin
		   exlambda[11] <= 0;
		end
	 end
	 
	 always @(posedge clk or negedge rst_N)
	 begin
			if(rst_N == 0)
			begin
			   lambda[11] <= 0;
			end
			else if(enable == 1 && count_N[9:0]==32*25)
			begin
			   lambda[11] <= lambda[11] + (exlambda[11]>>19) + ((exlambda[11]&60'h0000000000040000)?1:0); 
			end
			else if(count_N[14:10]==29 && count_N[9:0]==32*25+3)
		   begin
		      lambda[11]  <= 0;
		   end
	 end
	 
	 
	 //lambda[12]
	 always @(posedge clk or negedge rst_N)
	 begin
	   if(rst_N==1'b0)
		begin
			exlambda[12] <= 0;
	   end
		else if(doutL == 13)
		begin
			exlambda[12] <= exlambda[12] + mulambda;
		end
		else if(count_N[9:0]==32*27-1)
		begin
			exlambda[12] <= exlambda[12]*5041;    //104   round(2^19/104)
		end
		else if(enable == 1 && count_N[9:0]==32*27+1)
		begin
			exlambda[12] <= 0;
		end
	 end
	 
	 always @(posedge clk or negedge rst_N)
	 begin
			if(rst_N == 0)
			begin
			   lambda[12] <= 0;
			end
			else if(enable == 1 && count_N[9:0]==32*27)
			begin
			   lambda[12] <= lambda[12] + (exlambda[12]>>19) + ((exlambda[12]&60'h0000000000040000)?1:0);
			end
			else if(count_N[14:10]==29 && count_N[9:0]==32*27+3)
		   begin
		      lambda[12]  <= 0;
		   end
	 end
	 
	 //lambda[13]
	 always @(posedge clk or negedge rst_N)
	 begin
	   if(rst_N==1'b0)
		begin
			exlambda[13] <= 0;
	   end
		else if(doutL == 14)
		begin
			exlambda[13] <= exlambda[13] + mulambda;
		end
		else if(count_N[9:0]==32*29-1)
		begin
			   exlambda[13] <= (exlambda[13]*4681);    //112   round(2^19/112)
		end
		else if(count_N[9:0]==32*29+1)
		begin
				exlambda[13] <= 0;
		end
	 end
	 
	 always @(posedge clk or negedge rst_N)
	 begin
			if(rst_N == 0)
			begin
			   lambda[13] <= 0;
			end
			else if(enable == 1 && count_N[9:0]==32*29)
			begin
			   lambda[13] <= lambda[13] + (exlambda[13]>>19) + ((exlambda[13]&60'h0000000000040000)?1:0); 
			end
			else if(count_N[14:10]==29 && count_N[9:0]==32*29+3)
		   begin
		      lambda[13]  <= 0;
		   end
	 end
	 
	 //lambda[14]
	 always @(posedge clk or negedge rst_N)
	 begin
	   if(rst_N==1'b0)
	   begin
			exlambda[14] <= 0;
	   end
		else if(doutL == 15)
		begin
			exlambda[14] <= exlambda[14] + mulambda;
		end
		else if(count_N[9:0]== 0)
		begin
			exlambda[14] <= (exlambda[14]*2865);    //183   round(2^19/183)
		end
	   else if(enable == 1 && count_N[9:0]==2)
		begin
			exlambda[14] <= 0;
		end
	 end
	 
	 always @(posedge clk or negedge rst_N)
	 begin
			if(rst_N == 0)
			begin
			   lambda[14] <= 0;
			end
			else if(enable == 1 && count_N[9:0]==1)
			begin
			   lambda[14] <= lambda[14] + ((exlambda[14])>>19) + ((exlambda[14]&60'h0000000000040000)?1:0);
			end
			else if(count_N[14:10]==0 && count_N[9:0]==1+3)
		   begin
		      lambda[14] <= 0;
		   end
	 end
	 
	 
	 
	 //求lambda的值,总的平均值,这里出现的问题是乘法器
	 
	 wire [59:0] data_temp;
	 reg  [39:0] data_lambda;
	 reg  [23:0] data_temp_mutl;
	 
	 reg  flag_lambda0;
	 reg  flag_sqrtlambda0;
	 reg  flag_sumsqrtlambda0;
	 
	 //3
	 /*
	 always @(posedge clk or negedge rst_N)
	 begin 
	     case(count_N)
		    15'd29794:data_lambda <= lambda[0];
		    15'd29858:data_lambda <= lambda[1];
		    15'd29922:data_lambda <= lambda[2];
		    15'd29986:data_lambda <= lambda[3];
		    15'd30050:data_lambda <= lambda[4];
		    15'd30114:data_lambda <= lambda[5];
		    15'd30178:data_lambda <= lambda[6];
		    15'd30242:data_lambda <= lambda[7];
		    15'd30306:data_lambda <= lambda[8];
		    15'd30370:data_lambda <= lambda[9];
		    15'd30434:data_lambda <= lambda[10];
		    15'd30498:data_lambda <= lambda[11];
		    15'd30562:data_lambda <= lambda[12];
		    15'd30626:data_lambda <= lambda[13];
		    15'd3    :data_lambda <= lambda[14];
		  endcase
	 end
	 */
	 
     //3
     always @(posedge clk or negedge rst_N)
     begin
	      if(rst_N == 0)
			begin
			     data_lambda <= 0;
			end
	      else if(count_N == 29794)
			begin
			     data_lambda <= lambda[0];
			end
			else if(count_N == 29858)
			begin
			     data_lambda <= lambda[1];
			end
			else if(count_N == 29922)
			begin
			     data_lambda <= lambda[2];
			end
			else if(count_N == 29986)
			begin
			     data_lambda <= lambda[3];
			end
			else if(count_N == 30050)
			begin
			     data_lambda <= lambda[4];
			end
			else if(count_N == 30114)
			begin
			     data_lambda <= lambda[5];
			end
			else if(count_N == 30178)
			begin
			     data_lambda <= lambda[6];
			end
			else if(count_N == 30242)
			begin
			     data_lambda <= lambda[7];
			end
			else if(count_N == 30306)
			begin
			     data_lambda <= lambda[8];
			end
			else if(count_N == 30370)
			begin
			     data_lambda <= lambda[9];
			end
			else if(count_N == 30434)
			begin
			     data_lambda <= lambda[10];
			end
			else if(count_N == 30498)
			begin
			     data_lambda <= lambda[11];
			end
			else if(count_N == 30562)
			begin
			     data_lambda <= lambda[12];
			end
			else if(count_N == 30626)
			begin
			     data_lambda <= lambda[13];
			end
			else if(count_N == 3)
			begin
			     data_lambda <= lambda[14];
			end
     end	  
	  
	  
	 assign data_temp = (data_lambda*17476);   // round(2^19/30)
	 
	 //4
	 //进行饱和处理
	 always @(posedge clk or negedge rst_N)
	 begin
	    if(rst_N==0)
		 begin
		    data_temp_mutl <= 0;
		 end
		 else if(enable == 1)
		 begin
			 data_temp_mutl <= (data_temp>>19) +((data_temp&60'h0000000000040000)?1:0); //这里将40bit中的数据赋值给data_temp_mutl
		 end
	 end
	 
	 //5
	 always @(posedge clk or negedge rst_N)
	 begin
	    if(rst_N == 0)
		 begin
		   lambda0[0] <= 0;
		 end
		 else if(enable== 1 && count_N[14:10]==29 && count_N[9:0]==32*3+4)
		 begin
		   lambda0[0] <= data_temp_mutl;
		 end
	 end
	 
	 //5
	 always @(posedge clk or negedge rst_N)
	 begin
	     if(rst_N == 0)
		  begin
		    lambda0[1] <= 0;
		  end
		  else if(enable == 1 && count_N[14:10]==29 && count_N[9:0]==32*5+4)
                  begin
		    lambda0[1] <= data_temp_mutl;
        end		  
	 end
	 
	 //5
	 always @(posedge clk or negedge rst_N)
	 begin
	     if(rst_N == 0)
		  begin
		    lambda0[2] <= 0;
		  end
		  else if(enable == 1 && count_N[14:10]==29 && count_N[9:0]==32*7+4)
        begin
		    lambda0[2] <= data_temp_mutl;
        end		  
	 end
	 
	 //5
	 always @(posedge clk or negedge rst_N)
	 begin
	     if(rst_N == 0)
		  begin
		    lambda0[3] <= 0;
		  end
		  else if(enable == 1 && count_N[14:10]==29 && count_N[9:0]==32*9+4)
        begin
		    lambda0[3] <= data_temp_mutl;
        end		  
	 end
	 
	 //5
	 always @(posedge clk or negedge rst_N)
	 begin
	     if(rst_N == 0)
		  begin
		    lambda0[4] <= 0;
		  end
		  else if(enable == 1 && count_N[14:10]==29 && count_N[9:0]==32*11+4)
        begin
		    lambda0[4] <= data_temp_mutl;
        end		  
	 end
	 //5
	 always @(posedge clk or negedge rst_N)
	 begin
	     if(rst_N == 0)
		  begin
		    lambda0[5] <= 0;
		  end
		  else if(enable == 1 && count_N[14:10]==29 && count_N[9:0]==32*13+4)
        begin
		    lambda0[5] <= data_temp_mutl;
        end		  
	 end
	 
	 //5
	 always @(posedge clk or negedge rst_N)
	 begin
	     if(rst_N == 0)
		  begin
		    lambda0[6] <= 0;
		  end
		  else if(enable == 1 && count_N[14:10]==29 && count_N[9:0]==32*15+4)
        begin
		    lambda0[6] <= data_temp_mutl;
        end		  
	 end
	 
	 //5
	 always @(posedge clk or negedge rst_N)
	 begin
	     if(rst_N == 0)
		  begin
		    lambda0[7] <= 0;
		  end
		  else if(enable == 1 && count_N[14:10]==29 && count_N[9:0]==32*17+4)
        begin
		    lambda0[7] <= data_temp_mutl;
        end		  
	 end
	 
	 //5
	 always @(posedge clk or negedge rst_N)
	 begin
	     if(rst_N == 0)
		  begin
		    lambda0[8] <= 0;
		  end
		  else if(enable == 1 && count_N[14:10]==29 && count_N[9:0]==32*19+4)
        begin
		    lambda0[8] <= data_temp_mutl;
        end		  
	 end
	 
	 //5
	 always @(posedge clk or negedge rst_N)
	 begin
	     if(rst_N == 0)
		  begin
		    lambda0[9] <= 0;
		  end
		  else if(enable == 1 && count_N[14:10]==29 && count_N[9:0]==32*21+4)
        begin
		    lambda0[9] <= data_temp_mutl;
        end		  
	 end
	 
	 //5
	 always @(posedge clk or negedge rst_N)
	 begin
	     if(rst_N == 0)
		  begin
		    lambda0[10] <= 0;
		  end
		  else if(enable == 1 && count_N[14:10]==29 && count_N[9:0]==32*23+4)
        begin
		    lambda0[10] <= data_temp_mutl;
        end		  
	 end
	 //5
	 always @(posedge clk or negedge rst_N)
	 begin
	     if(rst_N == 0)
		  begin
		    lambda0[11] <= 0;
		  end
		  else if(enable == 1 && count_N[14:10]==29 && count_N[9:0]==32*25+4)
        begin
		    lambda0[11] <= data_temp_mutl;
        end		  
	 end
	 
	 //5
	 always @(posedge clk or negedge rst_N)
	 begin
	     if(rst_N == 0)
		  begin
		    lambda0[12] <= 0;
		  end
		  else if(enable == 1 && count_N[14:10]==29 && count_N[9:0]==32*27+4)
        begin
		    lambda0[12] <= data_temp_mutl;
        end		  
	 end
	 
	 //5
	 always @(posedge clk or negedge rst_N)
	 begin
	     if(rst_N == 0)
		  begin
		    lambda0[13] <= 0;
		  end
		  else if(enable == 1 && count_N[14:10]==29 && count_N[9:0]==32*29+4)
        begin
		    lambda0[13] <= data_temp_mutl;
        end		  
	 end
	 
	 //5
	 
	 always @(posedge clk or negedge rst_N)
	 begin
	     if(rst_N == 0)
		  begin
		    lambda0[14] <= 0;
		  end
		  else if(enable == 1 && count_N[14:10]==0 && count_N[9:0]==1+4)
        begin
		    lambda0[14] <= data_temp_mutl;
        end		  
	 end

	 /////////////////////////////////////////////////////
	 //求sqrt(lambda)
	 //上面可以得出 第30块，出现第一个lambda
	 reg [23:0]lambda0_op;
    reg [3:0]expo0; 
	 reg rst_cordic;
	 
    reg [23:0]  xlambda0_x;
    reg [23:0]  ylambda0_y;
	 
    wire [23:0] sqrt_lambda0_n;
	 reg [23:0] sqrt_lambda0_m; 
	 reg [23:0] sqrt_lambda0_m0;
	 reg [21:0] sum_sqrt;   //我们计算得到的数据是经过移位处理的数据
	                        //12+10 = 22
	 reg [23:0] sum_sqrt_lambda0_op;
    reg [5:0]  expo_sum_sqrt_lambda0;
	 reg [23:0] sum_sqrt_lambda0_m;
	 
	 wire [23:0] y_out;
	 wire [23:0] z_out;
	 
	 reg [5:0]shift_bits;
	 reg flag0_cordic;
	 reg flag1_cordic;
	 reg flag2_cordic;
	 
	 //5 ,在执行cordic之前初始化cordic
	 always @(posedge clk or negedge rst_N)
	 begin
	    if(rst_N == 0)
		 begin
			 rst_cordic <= 0;
		 end
		 else if(enable == 1)
		 begin
		    rst_cordic <= 1;
		 end
	 end 

	 //5
	 always@(posedge clk or negedge rst_N)
	 begin
	   if(rst_N ==0)
		begin
		   expo0<=0;
			lambda0_op<=0;
		end
		else if(enable == 1)
		begin
		if(data_temp_mutl[23:20]>=1&&data_temp_mutl[23:20]<=7)
			begin
			  expo0<=10;
			  lambda0_op<=data_temp_mutl;
			end
		else if(data_temp_mutl[21:18]>=1&&data_temp_mutl[21:18]<=7)
			begin
			  expo0<=9;
			  lambda0_op<={data_temp_mutl[21:0],2'b00};
			end
		else if(data_temp_mutl[19:16]>=1&&data_temp_mutl[19:16]<=7)
			begin
			  expo0<=8;
			  lambda0_op<={data_temp_mutl[19:0],4'b0000};
			end
		else if(data_temp_mutl[17:14]>=1&&data_temp_mutl[17:14]<=7)
			begin
			  expo0<=7;
			  lambda0_op<={data_temp_mutl[17:0],6'b000000};
			end
		else if(data_temp_mutl[15:12]>=1&&data_temp_mutl[15:12]<=7)
			begin
			  expo0<=6;
			  lambda0_op<={data_temp_mutl[15:0],8'b0000_0000};
			end
		else if(data_temp_mutl[13:10]>=1&&data_temp_mutl[13:10]<=7)
			begin
			  expo0<=5;
			  lambda0_op<={data_temp_mutl[13:0],10'b0000000000};
			end
		else if(data_temp_mutl[11:8]>=1&&data_temp_mutl[11:8]<=7)
			begin
			  expo0 <= 4; 
			  lambda0_op <= {data_temp_mutl[11:0],12'b0000_0000_0000};
			end
	   else if(data_temp_mutl[9:6]>=1&&data_temp_mutl[9:6]<=7)
	   begin
		     expo0 <= 3;
			  lambda0_op <= {data_temp_mutl[9:0],14'b00000000000000};
	   end
		else if(data_temp_mutl[7:4]>=1 && data_temp_mutl[7:4]<=7)
		begin
		     expo0 <= 2;
			  lambda0_op <= {data_temp_mutl[7:0],16'b0000000000000000};
		end
		else if(data_temp_mutl[5:2]>=1 && data_temp_mutl[5:2]<=7)
		begin
		     expo0 <= 1;
			  lambda0_op <= {data_temp_mutl[5:0],18'b000000000000000000};
		end
		else if(data_temp_mutl[3:0]>=1 && data_temp_mutl[3:0]<=7)
		begin
		     expo0 <= 0;
			  lambda0_op <= {data_temp_mutl[3:0],20'b00000000000000000000};
		end
		else
		begin
		     expo0 <= 0;
			  lambda0_op <= 24'b0;
		end
		end
	 end

	 //6
	 always @(posedge clk or negedge rst_N)
	 begin
		    case(count_N)
			    15'd29797:flag0_cordic <= 1;
			    15'd29861:flag0_cordic <= 1;
			    15'd29925:flag0_cordic <= 1;
			    15'd29989:flag0_cordic <= 1;
			    15'd30053:flag0_cordic <= 1;
			    15'd30117:flag0_cordic <= 1;
			    15'd30181:flag0_cordic <= 1;
			    15'd30245:flag0_cordic <= 1;
			    15'd30309:flag0_cordic <= 1;
			    15'd30373:flag0_cordic <= 1;
			    15'd30437:flag0_cordic <= 1;
			    15'd30501:flag0_cordic <= 1;
			    15'd30565:flag0_cordic <= 1;
			    15'd30629:flag0_cordic <= 1;
			    15'd6:    flag0_cordic <= 1;
				 default:  flag0_cordic<= 0;
			 endcase
	 end
	 
	 //22
	 always @(posedge clk or negedge rst_N)
	 begin
	    if(rst_N==0)
		 begin
		   flag1_cordic <= 0 ;
		 end
		 else if(enable == 1 && count_N[14:10]==0 && count_N[9:0]== 1+21)
		 begin
		   flag1_cordic <= 1;
		 end
		 else if(enable== 1 && count_N[14:10] == 0 && count_N[9:0]== 1+22)
		 begin
		   flag1_cordic <= 0;
		 end
	 end
	 
	 //19 
	 always @(posedge clk or negedge rst_N)
	 begin
		    case(count_N)
			  15'd29810:flag2_cordic <= 1;
			  15'd29874:flag2_cordic <= 1;
			  15'd29938:flag2_cordic <= 1;
			  15'd30002:flag2_cordic <= 1;
			  15'd30066:flag2_cordic <= 1;
			  15'd30130:flag2_cordic <= 1;
			  15'd30194:flag2_cordic <= 1;
			  15'd30258:flag2_cordic <= 1;
			  15'd30322:flag2_cordic <= 1;
			  15'd30386:flag2_cordic <= 1;
			  15'd30450:flag2_cordic <= 1;
			  15'd30514:flag2_cordic <= 1;
			  15'd30578:flag2_cordic <= 1;
			  15'd30642:flag2_cordic <= 1;
			  15'd19:   flag2_cordic <= 1;
           default :flag2_cordic <= 0;
			endcase
     end		 
	 //6
	 always @(posedge clk or negedge rst_N)
	 begin
	     if(rst_N == 0)
		  begin
		    xlambda0_x <= 0;
			 ylambda0_y <= 0;
		  end
		  else if(enable == 1'b1 && flag0_cordic == 1)
		  begin
		    xlambda0_x <= lambda0_op + 24'h100000;
			 ylambda0_y <= lambda0_op - 24'h100000;
		  end
		  //22
		  else if(enable == 1'b1 && flag1_cordic == 1)
		  begin
		    xlambda0_x <= sum_sqrt_lambda0_op + 24'h100000;
			 ylambda0_y <= sum_sqrt_lambda0_op - 24'h100000;
		  end
		  //19
		  else if(enable == 1'b1 && flag2_cordic == 1)
		  begin
		    xlambda0_x <= sqrt_lambda0_n + 24'h100000;
			 ylambda0_y <= sqrt_lambda0_n - 24'h100000;
		  end
	 end
	 
	 //7 + 12 = 19
	 //22+ 12 = 34
	 //20+ 12 = 32
	 CORDIC U_cordic(
                 .clk(clk),
					  .rst(rst_cordic),
					  .x(xlambda0_x),
					  .y(ylambda0_y),
					  .z(24'd0),
					  .mode(2'b01),
					  .x_out(sqrt_lambda0_n),
					  .y_out(y_out),
					  .z_out(z_out)
					  );
	 
    //19
	 //35
    always @(posedge clk or negedge rst_N)
    begin
	     if(rst_N == 0)
		  begin
		     sqrt_lambda0_m <= 0;
			 // sqrt_lambda0_m0 <= 0;
			 // temp <= 0;
		  end
		  else if(enable == 1'b1)
		  begin
		     sqrt_lambda0_m <= sqrt_lambda0_n;
			  //sqrt_lambda0_m0 <= sqrt_lambda0_n >> shift_bits;
			  //temp <= sqrt_lambda0_n[shift_bits-1]?1:0;
		  end
    end
	 
	 //lambda开更号之后是，4位整数20位小数，我需要保留的是12bit
	 //这里我的理解就是,4位整数不动，我们计算完毕之后需要增加20bit（因为输出之后也是24bit）
	 //我们移位之后缩小了expo bit，所以最后 4+8=12 ，shift_bits = 20-8-expo0
	 //6
	 always @(posedge clk or negedge rst_N)
	 begin
	    if(rst_N == 0)
		 begin
		    shift_bits <= 0;
		 end
		 else if(enable == 1'b1)
		 begin
		    shift_bits <= 20-(expo0); //12-expo0
		 end
	 end
	 
	 //sqrt_sum的大小是22bit
	 //20
	 always @(posedge clk or negedge rst_N)
	 begin
	    if(rst_N == 0)
		 begin
		    sum_sqrt <= 0 ;
		 end
		 else if(enable == 1'b1 && count_N[14:10]==29 && count_N[9:0] == 32*3+18)
		 begin
		   sum_sqrt <= 0;
		 end
		 else if(enable == 1)
		 //count_N[9:0] ==32*3 + 19
		    case(count_N)
			   15'd29811:sum_sqrt <= sum_sqrt + 8*((sqrt_lambda0_m>>shift_bits) + (sqrt_lambda0_m[shift_bits-1]?1:0));
				15'd29875:sum_sqrt <= sum_sqrt + 16*((sqrt_lambda0_m>>shift_bits) + (sqrt_lambda0_m[shift_bits-1]?1:0)); 
				15'd29939:sum_sqrt <= sum_sqrt + 24*((sqrt_lambda0_m>>shift_bits) + (sqrt_lambda0_m[shift_bits-1]?1:0)); 
				15'd30003:sum_sqrt <= sum_sqrt + 32*((sqrt_lambda0_m>>shift_bits) + (sqrt_lambda0_m[shift_bits-1]?1:0)); 
				15'd30067:sum_sqrt <= sum_sqrt + 40*((sqrt_lambda0_m>>shift_bits) + (sqrt_lambda0_m[shift_bits-1]?1:0)); 
				15'd30131:sum_sqrt <= sum_sqrt + 48*((sqrt_lambda0_m>>shift_bits) + (sqrt_lambda0_m[shift_bits-1]?1:0)); 
				15'd30195:sum_sqrt <= sum_sqrt + 56*((sqrt_lambda0_m>>shift_bits) + (sqrt_lambda0_m[shift_bits-1]?1:0)); 
				15'd30259:sum_sqrt <= sum_sqrt + 64*((sqrt_lambda0_m>>shift_bits) + (sqrt_lambda0_m[shift_bits-1]?1:0)); 
				15'd30323:sum_sqrt <= sum_sqrt + 72*((sqrt_lambda0_m>>shift_bits) + (sqrt_lambda0_m[shift_bits-1]?1:0)); 
				15'd30387:sum_sqrt <= sum_sqrt + 80*((sqrt_lambda0_m>>shift_bits) + (sqrt_lambda0_m[shift_bits-1]?1:0)); 
				15'd30451:sum_sqrt <= sum_sqrt + 88*((sqrt_lambda0_m>>shift_bits) + (sqrt_lambda0_m[shift_bits-1]?1:0)); 
				15'd30515:sum_sqrt <= sum_sqrt + 96*((sqrt_lambda0_m>>shift_bits) + (sqrt_lambda0_m[shift_bits-1]?1:0)); 
				15'd30579:sum_sqrt <= sum_sqrt + 104*((sqrt_lambda0_m>>shift_bits) + (sqrt_lambda0_m[shift_bits-1]?1:0)); 
				15'd30643:sum_sqrt <= sum_sqrt + 112*((sqrt_lambda0_m>>shift_bits) + (sqrt_lambda0_m[shift_bits-1]?1:0));
            15'd20   :sum_sqrt <= sum_sqrt + 183*((sqrt_lambda0_m>>shift_bits) + (sqrt_lambda0_m[shift_bits-1]?1:0));				
			 endcase
	 end
	 
	 // 求和之后这里需要的就是计算求和之后的sqrt(sum)
	 
	 //21
	 always @(posedge clk or negedge rst_N)
	 begin
	   if(rst_N == 0)
		begin
	      sum_sqrt_lambda0_op <= 0;
         expo_sum_sqrt_lambda0 <= 0;			
		end
		else if(enable == 1)
		begin
		  if(sum_sqrt[21:18]>=1&&sum_sqrt[21:18]<=7)
					begin
					  expo_sum_sqrt_lambda0<=9;
					  sum_sqrt_lambda0_op<={sum_sqrt,2'b0};
					end
				else if(sum_sqrt[19:16]>=1&&sum_sqrt[19:16]<=7)
					begin
					  expo_sum_sqrt_lambda0<=8;
					  sum_sqrt_lambda0_op<={sum_sqrt[19:0],4'b0};
					end
				else if(sum_sqrt[17:14]>=1&&sum_sqrt[17:14]<=7)
					begin
					  expo_sum_sqrt_lambda0<=7;
					  sum_sqrt_lambda0_op<={sum_sqrt[17:0],6'b0};
					end
				else if(sum_sqrt[15:12]>=1&&sum_sqrt[15:12]<=7)
					begin
					  expo_sum_sqrt_lambda0<=6;
					  sum_sqrt_lambda0_op<={sum_sqrt[15:0],8'b0};
					end
				else if(sum_sqrt[13:10]>=1&&sum_sqrt[13:10]<=7)
					begin
					  expo_sum_sqrt_lambda0<=5;
					  sum_sqrt_lambda0_op<={sum_sqrt[13:0],10'b0};
					end 
				else if(sum_sqrt[11:8]>=1&&sum_sqrt[11:8]<=7)
					begin
					  expo_sum_sqrt_lambda0<=4;
					  sum_sqrt_lambda0_op<={sum_sqrt[11:0],12'b0};
					end
				else if(sum_sqrt[9:6]>=1&&sum_sqrt[9:6]<=7)
					begin
					  expo_sum_sqrt_lambda0<=3;
					  sum_sqrt_lambda0_op<={sum_sqrt[9:0],14'b0};
					end
				else if(sum_sqrt[7:4]>=1&&sum_sqrt[7:4]<=7)
					begin
					  expo_sum_sqrt_lambda0<=2;
					  sum_sqrt_lambda0_op<={sum_sqrt[7:0],16'b0};
					end
				else if(sum_sqrt[5:2]>=1&&sum_sqrt[5:2]<=7)
					begin
					  expo_sum_sqrt_lambda0<=1;
					  sum_sqrt_lambda0_op<={sum_sqrt[5:0],18'b0};
					end
				else if(sum_sqrt[3:0]>=1&&sum_sqrt[3:0]<=7)
					begin
					  expo_sum_sqrt_lambda0<=0;
					  sum_sqrt_lambda0_op<={sum_sqrt[3:0],20'b0};
					end
				else 
					begin
					   expo_sum_sqrt_lambda0 <= 0;
                 	sum_sqrt_lambda0_op<= 0;				  
					end
		end
	 end
	 
	 ////////////////////////////////////////////////////////
	 
	 always@(posedge clk or negedge rst_N)
	 begin
	    if(rst_N == 0)
		 begin
		   shifr_bit_2 <= 0;
		 end
		 else if(enable == 1)
		 begin
		   shift_bits_2<=20-(expo0>>1);
		 end
	 end

   //36，输出的结果是sqrt(sqrt(lambda))
   always@(posedge clk or negedge rst_N)
	begin
	   if(rst_N == 0)
		begin
		  g_1 <= 0;
        g_2	<= 0;
		end
		else if(enable == 1)
		begin
		  g_1<=((sqrt_lambda0_m>>shift_bits_2) + (sqrt_lambda0_m[shift_bits_2-1]?1:0))*181;//sqrt(2) = 181/128
	  	  g_2<=(sqrt_lambda0_m>>shift_bits_2) + (sqrt_lambda0_m[shift_bits_2-1]?1:0);
		end
	end
	
   //37
   always@(posedge clk or negedge rst_N)
	begin
		   case(count_N)
			 //32*3 + 36
			 15'b111010010000100:g0_0<=expo0[0]?((g_1>>7)+((g_1[6])?1:0)):g_2;
			 15'b111010011000100:g0_1<=expo0[0]?((g_1>>7)+((g_1[6])?1:0)):g_2;
			 15'b111010100000100:g0_2<=expo0[0]?((g_1>>7)+((g_1[6])?1:0)):g_2;
			 15'b111010101000100:g0_3<=expo0[0]?((g_1>>7)+((g_1[6])?1:0)):g_2;
			 15'b111010110000100:g0_4<=expo0[0]?((g_1>>7)+((g_1[6])?1:0)):g_2;
			 15'b111010111000100:g0_5<=expo0[0]?((g_1>>7)+((g_1[6])?1:0)):g_2;
			 15'b111011000000100:g0_6<=expo0[0]?((g_1>>7)+((g_1[6])?1:0)):g_2;
			 15'b111011001000100:g0_7<=expo0[0]?((g_1>>7)+((g_1[6])?1:0)):g_2;
			 15'b111011010000100:g0_8<=expo0[0]?((g_1>>7)+((g_1[6])?1:0)):g_2;
			 15'b111011011000100:g0_9<=expo0[0]?((g_1>>7)+((g_1[6])?1:0)):g_2;
			 15'b111011100000100:g0_10<=expo0[0]?((g_1>>7)+((g_1[6])?1:0)):g_2;
			 15'b111011101000100:g0_11<=expo0[0]?((g_1>>7)+((g_1[6])?1:0)):g_2;
			 15'b111011110000100:g0_12<=expo0[0]?((g_1>>7)+((g_1[6])?1:0)):g_2;
			 15'b111011111000100:g0_13<=expo0[0]?((g_1>>7)+((g_1[6])?1:0)):g_2;
			 //36
			 15'd36:g0_14<=expo0[0]?((g_1>>7)+((g_1[6])?1:0)):g_2;
			endcase
	  end
	  
	 //
	 always @(posedge clk or negedge rst_N)
	 begin
	      if(rst_N == 0)
			begin
			     temp_shift_sum_bit <= 0;
			end
			else if(enable == 1)
			begin
			     temp_shift_sum_bit <= 20-expo_sum_sqrt_lambda0;
			end
	 end
	 
	 always @(posedge clk or negedge rst_N)
	 begin
	      if(rst_N == 0)
			begin
			   temp_sqrt <= 0;
			end
			else if(enable == 1)
			begin
			  temp_sqrt <= (sqrt_lambda0_n>>temp_shift_sum_bit) + (sqrt_lambda0_n[temp_shift_sum_bit-1]?1:0);
			end
	 end
	 
	 //37
	 always @(posedge clk or negedge rst_N)
	 begin
	    if(rst_N == 0)
		 begin
		    temp_g1_0[0] <= 0;
		 end
		 else if(enable == 1 && count_N[14:10] == 0 && count_N[9:0] == 1+37)
		 begin
		    temp_g1_0[0]  <= g0_0*temp_sqrt;
		 end
	 end
	 
	 //37
	 always @(posedge clk or negedge rst_N)
	 begin
	    if(rst_N == 0)
		 begin
		   temp_g1_0[1] <= 0;
		 end
		 else if(enable == 1 && count_N[14:10] == 0 && count_N[9:0] == 1+37)
		 begin
		    temp_g1_0[1]  <= g0_1*temp_sqrt;
		 end
	 end
	 
	 //37
	 always @(posedge clk or negedge rst_N)
	 begin
	    if(rst_N == 0)
		 begin
		   temp_g1_0[2] <= 0;
		 end
		 else if(enable == 1 && count_N[14:10] == 0 && count_N[9:0] == 1+37)
		 begin
		    temp_g1_0[2]  <= g0_2*temp_sqrt;
		 end
	 end
	 
	 //37
	 always @(posedge clk or negedge rst_N)
	 begin
	    if(rst_N == 0)
		 begin
		   temp_g1_0[3] <= 0;
		 end
		 else if(enable == 1 && count_N[14:10] == 0 && count_N[9:0] == 1+37)
		 begin
		    temp_g1_0[3]  <= g0_3*temp_sqrt;
		 end
	 end
	 
	 //37
	 always @(posedge clk or negedge rst_N)
	 begin
	    if(rst_N == 0)
		 begin
		   temp_g1_0[4] <= 0;
		 end
		 else if(enable == 1 && count_N[14:10] == 0 && count_N[9:0] == 1+37)
		 begin
		    temp_g1_0[4]  <= g0_4*temp_sqrt;
		 end
	 end
	
	 //37
	 always @(posedge clk or negedge rst_N)
	 begin
	    if(rst_N == 0)
		 begin
		   temp_g1_0[5] <= 0;
		 end
		 else if(enable == 1 && count_N[14:10] == 0 && count_N[9:0] == 1+37)
		 begin
		    temp_g1_0[5]  <= g0_5*temp_sqrt;
		 end
	 end
	 
	 //37
	 always @(posedge clk or negedge rst_N)
	 begin
	    if(rst_N == 0)
		 begin
		   temp_g1_0[6] <= 0;
		 end
		 else if(enable == 1 && count_N[14:10] == 0 && count_N[9:0] == 1+37)
		 begin
		    temp_g1_0[6]  <= g0_6*temp_sqrt;
		 end
	 end
	 
	 //37
	 always @(posedge clk or negedge rst_N)
	 begin
	    if(rst_N == 0)
		 begin
		   temp_g1_0[7] <= 0;
		 end
		 else if(enable == 1 && count_N[14:10] == 0 && count_N[9:0] == 1+37)
		 begin
		    temp_g1_0[7]  <= g0_7*temp_sqrt;
		 end
	 end
	 
	 //37
	 always @(posedge clk or negedge rst_N)
	 begin
	    if(rst_N == 0)
		 begin
		   temp_g1_0[8] <= 0;
		 end
		 else if(enable == 1 && count_N[14:10] == 0 && count_N[9:0] == 1+37)
		 begin
		    temp_g1_0[8]  <= g0_8*temp_sqrt;
		 end
	 end
	 
	 	 //37
	 always @(posedge clk or negedge rst_N)
	 begin
	    if(rst_N == 0)
		 begin
		   temp_g1_0[9] <= 0;
		 end
		 else if(enable == 1 && count_N[14:10] == 0 && count_N[9:0] == 1+37)
		 begin
		    temp_g1_0[9]  <= g0_9*temp_sqrt;
		 end
	 end
	 
	 	 //37
	 always @(posedge clk or negedge rst_N)
	 begin
	    if(rst_N == 0)
		 begin
		   temp_g1_0[10] <= 0;
		 end
		 else if(enable == 1 && count_N[14:10] == 0 && count_N[9:0] == 1+37)
		 begin
		    temp_g1_0[10]  <= g0_10*temp_sqrt;
		 end
	 end
	 
	 	 //37
	 always @(posedge clk or negedge rst_N)
	 begin
	    if(rst_N == 0)
		 begin
		   temp_g1_0[11] <= 0;
		 end
		 else if(enable == 1 && count_N[14:10] == 0 && count_N[9:0] == 1+37)
		 begin
		    temp_g1_0[11]  <= g0_11*temp_sqrt;
		 end
	 end
	 
	 
	 	 //37
	 always @(posedge clk or negedge rst_N)
	 begin
	    if(rst_N == 0)
		 begin
		   temp_g1_0[12] <= 0;
		 end
		 else if(enable == 1 && count_N[14:10] == 0 && count_N[9:0] == 1+37)
		 begin
		    temp_g1_0[12]  <= g0_12*temp_sqrt;
		 end
	 end
	 
	 
	 	 //37
	 always @(posedge clk or negedge rst_N)
	 begin
	    if(rst_N == 0)
		 begin
		   temp_g1_0[13] <= 0;
		 end
		 else if(enable == 1 && count_N[14:10] == 0 && count_N[9:0] == 1+37)
		 begin
		    temp_g1_0[13]  <= g0_13*temp_sqrt;
		 end
	 end
	 
	 	 //37
	 always @(posedge clk or negedge rst_N)
	 begin
	    if(rst_N == 0)
		 begin
		   temp_g1_0[14] <= 0;
		 end
		 else if(enable == 1 && count_N[14:10] == 0 && count_N[9:0] == 1+37)
		 begin
		    temp_g1_0[14]  <= g0_14*temp_sqrt;
		 end
	 end
	 
	  
	//上面得到的sumsqrt
	 
	 //37
	 always @(posedge clk or negedge rst_N)
	 begin
	   if(rst_N == 0)
		 begin
		   divider_count <= 0;
		 end
		 else if((count_N[14:10]==0 && enable == 1 && count_N[9:0] == 1+37) || divider_count ==14)
		 begin
		   divider_count <= 0;
		 end
		 else if(enable==1)
		 begin
		   divider_count <= divider_count + 1;
		 end
	 end
	 
	 assign temp_divider = temp_g1_0[divider_count];
	 
	 //38
	 always @(posedge clk or negedge rst_N)
	 begin
	     if(rst_N == 0)
		  begin
		     divide_input1 <= 0;
			  divide_input2 <= 0;
		  end
		  else if(enable == 1 && count_N[14:10] == 0)
		  begin
		     divide_input2 <= 2097152;//32*2^16; divide_input 保留的是10bit小数,(u,21,16)
			  divide_input1 <= {{15{temp_divider[16]}},temp_divider};  //temp_divider[16:0]
		  end
	 end
	 
	 //39
	 DIVIDER_TOP U_divider_top(
						.input1(divide_input1),
						.input2(divide_input2),
						.clk(clk),
						.out(divide_output1)
	 );
	 
	 //73
	 always @(posedge clk or negedge rst_N)
	 begin
	    if(rst_N==0)
		 begin
		    g1_00[0] <= 0;
		    g1_00[1] <= 0;
		    g1_00[2] <= 0;
		    g1_00[3] <= 0;
		    g1_00[4] <= 0;
		    g1_00[5] <= 0;
		    g1_00[6] <= 0;
		    g1_00[7] <= 0;
		    g1_00[8] <= 0;
		    g1_00[9] <= 0;
		    g1_00[10] <= 0;
		    g1_00[11] <= 0;
		    g1_00[12] <= 0;
		    g1_00[13] <= 0;
		    g1_00[14] <= 0;
		 end
		 else if(enable == 1 && count_N[14:10]==0)
		 begin
		   //73
			case(count_N[9:0])
			   //73
			   10'd74:g1_00[0] <= divide_output1[15:0];
				10'd75:g1_00[1] <= divide_output1[15:0];
				10'd76:g1_00[2] <= divide_output1[15:0];
				10'd77:g1_00[3] <= divide_output1[15:0];
				10'd78:g1_00[4] <= divide_output1[15:0];
				10'd79:g1_00[5] <= divide_output1[15:0];
				10'd80:g1_00[6] <= divide_output1[15:0];
				10'd81:g1_00[7] <= divide_output1[15:0];
				10'd82:g1_00[8] <= divide_output1[15:0];
				10'd83:g1_00[9] <= divide_output1[15:0];
				10'd84:g1_00[10] <= divide_output1[15:0];
				10'd85:g1_00[11] <= divide_output1[15:0];
				10'd86:g1_00[12] <= divide_output1[15:0];
				10'd87:g1_00[13] <= divide_output1[15:0];
				10'd88:g1_00[14] <= divide_output1[15:0];
			endcase
		end
	 end
	 
	 //////////////////////////////////////////////////////
	 //上述在lambda求出之后经过86个周期得到数据，g将其保存在g1_00中，下面是进行输出处理，
	 //第73个周期获取到数据准备乘以g输出
	 
	 reg [13:0] count_MN0;
	 reg [13:0] count_MN1;
	 wire [14:0] count_MN2;
	 wire [14:0] count_MN3;
	 
	 always @(posedge clk or negedge rst_N)
	 begin
	    if(rst_N==0)
		 begin
		    count_MN0 <= 0;
			// count_MN1 <= 0;
  		 end
		 else if(enable == 1 && count_N >= 1+298)
		 begin
		    //71
		    count_MN0 <= count_analog;
			 //count_MN1 <= count_MN0;
		 end
	 end
	 //72
	  assign count_MN2 =  {count_MN0,1'b0};
	  assign count_MN3 =  {count_MN0,1'b1};
	  
	 
     reg signed [15:0] data_analog_temp0;
     reg signed [15:0] data_analog_temp1;
	  reg signed [31:0] data_analog_temp2;
	  reg signed [31:0] data_analog_temp3;
	  
	  reg  [15:0] select_g00;
	  reg  [15:0] select_g01;
	  
	  wire [3:0] doutaL;
	  wire [3:0] doutbL;
	  
	  //74
	  always @(posedge clk or negedge rst_N)
	  begin
	    if(rst_N == 0)
		 begin
		     data_analog_temp0 <= 0;
			  data_analog_temp1 <= 0;
		 end
		 else if(enable == 1)
		 begin
		    data_analog_temp0 <= dataout1;
			 data_analog_temp1 <= dataout2;
		 end
	  end
	 
	  //73
     DUALROMLL U_dualromll (
                .clka(clk), // input clka
                .addra(count_MN2[9:0]), // input [9 : 0] addra
                .douta(doutaL), // output [15 : 0] douta
                .clkb(clk), // input clkb
                .addrb(count_MN3[9:0]), // input [9 : 0] addrb
                .doutb(doutbL) // output [15 : 0] doutb
              );
	  
	  
	 //74
	 always @(posedge clk or negedge rst_N)
	  begin
	    if(rst_N == 0)
		 begin
		     select_g00 <= 0;
		 end
		 else if(enable==1)
		 begin
		  case(doutaL)
		     4'd1:select_g00 <= g1_00[0];
			  4'd2:select_g00 <= g1_00[1];
			  4'd3:select_g00 <= g1_00[2];
			  4'd4:select_g00 <= g1_00[3];
			  4'd5:select_g00 <= g1_00[4];
			  4'd6:select_g00 <= g1_00[5];
			  4'd7:select_g00 <= g1_00[6];
			  4'd8:select_g00 <= g1_00[7];
			  4'd9:select_g00 <= g1_00[8];
			  4'd10:select_g00 <= g1_00[9];
			  4'd11:select_g00 <= g1_00[10];
			  4'd12:select_g00 <= g1_00[11];
			  4'd13:select_g00 <= g1_00[12];
			  4'd14:select_g00 <= g1_00[13];
			  4'd15:select_g00 <= g1_00[14];
			  4'd0 :select_g00 <= 0;
		  endcase
		 end
	  end
	  
	  //74
	  always @(posedge clk or negedge rst_N)
	  begin
	    if(rst_N == 0)
		 begin
		     select_g01 <= 0;
		 end
		 else if(enable==1)
		 begin
		 case(doutbL)
		     4'd1:select_g01 <= g1_00[0];
			  4'd2:select_g01 <= g1_00[1];
			  4'd3:select_g01 <= g1_00[2];
			  4'd4:select_g01 <= g1_00[3];
			  4'd5:select_g01 <= g1_00[4];
			  4'd6:select_g01 <= g1_00[5];
			  4'd7:select_g01 <= g1_00[6];
			  4'd8:select_g01 <= g1_00[7];
			  4'd9:select_g01 <= g1_00[8];
			  4'd10:select_g01 <= g1_00[9];
			  4'd11:select_g01 <= g1_00[10];
			  4'd12:select_g01 <= g1_00[11];
			  4'd13:select_g01 <= g1_00[12];
			  4'd14:select_g01 <= g1_00[13];
			  4'd15:select_g01 <= g1_00[14];
			  4'd0 :select_g01 <= 0;
		  endcase
		 end
	  end
	  
	  
	  //75
	  always @(posedge clk or negedge rst_N)
	  begin
	     if(rst_N == 0)
		  begin
		     data_analog_temp2 <= 0;
           data_analog_temp3 <= 0;  
		  end
		  else if(enable == 1)
		  begin
		     data_analog_temp2 <= $signed(select_g00) * $signed(data_analog_temp0);
           data_analog_temp3 <= $signed(select_g01) * $signed(data_analog_temp1);			  
		  end
	  end
	  
	  //这里进行截位处理
	  //(u,16,16) * (s,16,0) = (s,16,9)
	  //这里需要进行截位处理，数据的饱和处理
	  
	  assign data_out_analog_real  = ({data_analog_temp2[31:6]}+1)>>1;   //经过turbo编码和modu之后数字数据
     assign data_out_analog_image = ({data_analog_temp3[31:6]}+1)>>1;
     //assign data_out_analog_image = (data_analog_temp3>>7) + (data_analog_temp3[6]?1:0);
	 
	 /////////////////////////////////////////////////////////////

	  //1
	  always @(posedge clk or negedge rst_N)
	  begin
	     if(rst_N == 0)
		  begin
		     sync_analog_temp1 <= 0;
		  end
		  else if(enable == 1 && sync_analog_temp1 == 30719)
		  begin
		     sync_analog_temp1 <= 0;
		  end
		  else if(enable == 1)
		  begin
		    sync_analog_temp1 <= sync_analog_temp1+1;
		  end
	  end
	  
	  
	  //表示开始运行之后，sync_analog_temp2 == 1
	  always @(posedge clk or negedge rst_N)
	  begin
	     if(rst_N == 0)
		  begin
		    sync_analog_temp2 <= 0;
		  end
		  else if(enable == 1 && sync_analog_temp1==938+15360) //
		  begin
		    sync_analog_temp2 <= 1;
		  end
	  end
	  
	  always @(posedge clk or negedge rst_N)
	  begin
	     if(rst_N == 0)
		  begin
		    sync_analog_temp3 <= 0;
		  end
		  else if(enable == 1 && sync_analog_temp2 == 1 && sync_analog_temp1 >= 937 && sync_analog_temp1 <937+15360) //79
		  begin
		     sync_analog_temp3 <= 1;
		  end
		  else 
		  begin
		    sync_analog_temp3 <= 0;
		  end
	  end
	  
	  assign sync_analog = sync_analog_temp3;
	  
	  
	  ////////////////////////////////////////////////////////////
	  
	  //帧同步
	  reg temp_frame;
	  reg [14:0] count_frame1;
	  reg temp_frame2;
	  reg temp_frame3;
	  reg analog_temp_frame0;
	  
	  //-2 
	  always @(posedge clk or negedge rst_N)
	  begin
	     if(rst_N == 0)
		  begin 
		     count_frame1 <= 0;
		  end
		  else if(enable == 1 && input_line_sync == 1)
		  begin
		    count_frame1 <= 0;
		  end
		  else if(enable == 1 && count_frame1 == 30719)
		  begin
		    count_frame1 <= 0;
		  end
		  else if(enable == 1)
		  begin
		    count_frame1 <= count_frame1 + 1;
		  end
	  end
	  
	  //上述通过计数来实现
	  always @(posedge clk or negedge rst_N)
	  begin
	    if(rst_N == 0)
		 begin
		   temp_frame2 <= 0;
		 end
		 else if(enable == 1 && count_frame1 == 938) //78
		 begin
		   temp_frame2 <= 1;
		 end
	  end
	  
	  always @(posedge clk or negedge rst_N)
	  begin
	     if(rst_N == 0)
		  begin
		     temp_frame3 <= 0;
		  end
		  else if(enable == 1 && temp_frame2 == 1 && count_frame1 == 936)//78
		  begin
		     temp_frame3 <= 1;
		  end
		  else 
		  begin
		    temp_frame3 <= 0;
		  end
	  end
	  
	  assign output_line_sync_analog = temp_frame3;
	  
	  
	 ///////////////////////////////////////////////////////////////////////
	 //Dc系数和lambda作为数字部分输出，lambda求出之后，经过第五个周期将数据保存在lambda0[]寄存器中
	 
	 //对不同的lambda0进行饱和处理
	 //lambda的位宽 [18 15 14 13 14 15 13 12 13 14 16 12 11 10 10]
	 
	 
	 //6
	 always @(posedge clk or negedge rst_N)
	 begin
	    if(rst_N == 0)
		 begin
		    temp_d0 <=0 ;
			 temp_lambda0_d0 <= 0;
		 end
		 else if(enable == 1 && count_N[14:10] ==29)
		 begin
		     if(count_N[9:0]==32*3 +5)
			  begin
			      temp_d0 <= lambda0[0];
					temp_lambda0_d0 <= 18;
			  end
			  else if(count_N[9:0]==32*5 + 5)
			  begin
			      temp_d0 <= lambda0[1];
				   temp_lambda0_d0 <= 15;
			  end
			  else if(count_N[9:0]==32*7 + 5)
			  begin
			      temp_d0 <= lambda0[2];
				   temp_lambda0_d0 <= 14;
			  end
			  else if(count_N[9:0]==32*9 + 5)
			  begin
			      temp_d0 <= lambda0[3];
				   temp_lambda0_d0 <= 13;
			  end
			  else if(count_N[9:0]==32*11 + 5)
			  begin
			      temp_d0 <= lambda0[4];
				   temp_lambda0_d0 <= 14;
			  end
			  else if(count_N[9:0]==32*13 + 5)
			  begin
			      temp_d0 <= lambda0[5];
					temp_lambda0_d0 <= 15;
			  end
			  else if(count_N[9:0]==32*15 + 5)
			  begin
			     temp_d0 <= lambda0[6];	  
				  temp_lambda0_d0 <= 13;
			  end
			  else if(count_N[9:0]==32*17 + 5)
			  begin
			     temp_d0 <= lambda0[7];
				  temp_lambda0_d0 <= 12;
			  end
			  else if(count_N[9:0]==32*19 + 5)
			  begin
			     temp_d0 <= lambda0[8];
				  temp_lambda0_d0 <= 13;
			  end
			  else if(count_N[9:0]==32*21 + 5)
			  begin
			     temp_d0 <= lambda0[9];
				  temp_lambda0_d0 <= 14;
			  end
			  else if(count_N[9:0]==32*23 + 5)
			  begin
			     temp_d0 <= lambda0[10];
				  temp_lambda0_d0 <= 16;
			  end
			  else if(count_N[9:0]==32*25 + 5)
			  begin
			     temp_d0 <= lambda0[11];
				  temp_lambda0_d0 <= 12;
			  end
			  else if(count_N[9:0]==32*27 + 5)
			  begin
			     temp_d0 <= lambda0[12];
				  temp_lambda0_d0 <= 11;
			  end
			  else if(count_N[9:0]==32*29 + 5)
			  begin
			     temp_d0 <= lambda0[13];
				  temp_lambda0_d0 <= 10;
			  end
		 end
		 else if(count_N[14:10]==0 && count_N[9:0] ==1+5)
		 begin
		       temp_d0 <= lambda0[14];
				 temp_lambda0_d0 <= 10;
		 end
	 end
	 
	 assign temp_lambda0_d2 = 1<<temp_lambda0_d0 -1;
	 assign temp_lambda0_d3 = -(1<<temp_lambda0_d0);
	
	 //7
	 always @(posedge clk or negedge rst_N)
	 begin
	    if(rst_N == 0)
		 begin
		    temp_lambda0_d1 <= 0;
		 end
		 /*
		 else if(enable == 1 && temp_d0 >= temp_lambda0_d2)
		 begin
          temp_lambda0_d1 <= temp_lambda0_d2; 
		 end
		 else if(enable == 1 && temp_d0 <= temp_lambda0_d3)
		 begin
          temp_lambda0_d1 <= temp_lambda0_d3;
		 end
		 */
		 else 
		 begin
		    temp_lambda0_d1 <= temp_d0[17:0];
		 end
	 end

	 //8
	 always @(posedge clk or negedge rst_N)
	 begin
	      if(rst_N==0)
			begin
			   digital_d0 <= 200'b0;
			end
			else if(enable == 1 && count_N[14:10]==29)
			begin
			   if(count_N[9:0] == 32*3 + 7)
				 begin
				    digital_d0[199:182] <=  temp_lambda0_d1[17:0];  //18
				 end
				 else if(count_N[9:0] == 32*5 + 7)
				 begin
				    digital_d0[181:167] <=  temp_lambda0_d1[14:0]; //15
				 end
				 else if(count_N[9:0] == 32*7 + 7)
				 begin
				    digital_d0[166:153] <=  temp_lambda0_d1[13:0]; //14
				 end
				 else if(count_N[9:0] == 32*9 + 7)
				 begin
				    digital_d0[152:140] <=  temp_lambda0_d1[12:0];  //13
				 end
				 else if(count_N[9:0] == 32*11 + 7)
				 begin
				    digital_d0[139:126] <=  temp_lambda0_d1[13:0];  //14
				 end
				 else if(count_N[9:0] == 32*13 + 7)
				 begin
				    digital_d0[125:111] <=  temp_lambda0_d1[14:0];  //15
				 end
				 else if(count_N[9:0] == 32*15 + 7)
				 begin
				    digital_d0[110:98] <=  temp_lambda0_d1[12:0];   //13
				 end
				 else if(count_N[9:0] == 32*17 + 7)
				 begin
				    digital_d0[97:86] <=  temp_lambda0_d1[11:0];    //12
				 end
				 else if(count_N[9:0] == 32*19 + 7)
				 begin
				    digital_d0[85:73] <=  temp_lambda0_d1[12:0];    //13
				 end
				 else if(count_N[9:0] == 32*21 + 7)
				 begin
				    digital_d0[72:59] <=  temp_lambda0_d1[13:0];    //14
				 end
				 else if(count_N[9:0] == 32*23 + 7)
				 begin
				    digital_d0[58:43] <=  temp_lambda0_d1[15:0];    //16
				 end
				 else if(count_N[9:0] == 32*25 + 7)
				 begin
				    digital_d0[42:31] <=  temp_lambda0_d1[11:0];    //12
				 end
				 else if(count_N[9:0] == 32*27 + 7)
				 begin
				    digital_d0[30:20] <=  temp_lambda0_d1[10:0];    //11
				 end
				 else if(count_N[9:0] == 32*29 + 7)
				 begin
				    digital_d0[19:10] <=  temp_lambda0_d1[9:0];     //10
				 end
			end
			else if(enable==1 && count_N[14:10]==0 && count_N == 1+7)  //10  
			begin
			      digital_d0[9:0] <= temp_lambda0_d1[9:0];
			end
	 end
	 
    
	 /////////////////////////////////////////////////////////////////
	 //10
	 always @(posedge clk or negedge rst_N)
	 begin
	     if(rst_N == 0)
		  begin
		     crc_count <= 0;
		  end
		  else if(enable == 1 && count_N == 10)
		  begin
		    crc_count <= 216;
		  end
		  else if(enable == 1 && count_N == 229) //201
		  begin
		    crc_count <= 216;
		  end
		  else if(enable == 1 && count_N == 447)
		  begin
		    crc_count <= 216;
		  end
		  else if(enable == 1)
		  begin
		    crc_count <= crc_count - 1;
		  end
	 end
	 
	 //9
	 always @(posedge clk or negedge rst_N)
	 begin
	      if(rst_N == 0)
			begin
			  crc_data <= 0;
			end
			else if(enable == 1 && count_N == 9)
			begin
			  crc_data <= {digital_d0,16'b0};
			end
			else if(enable == 1 && count_N == 228)
			begin
			  crc_data <= {digital_d1,16'b0};
			end
			else if(enable == 1 && count_N == 446)
			begin
			  crc_data <= {digital_d2,16'b0};
			end
	 end
	 
	 
	 //6
	 always @(posedge clk or negedge rst_N)
	 begin
	     if(rst_N == 0)
		  begin
		     crc_sync <= 0; 
		  end
		  else if(enable == 1 && count_N == 10)
		  begin
		    crc_sync <= 0;
		  end
		  else if(enable == 1 && count_N == 229) //210
		  begin
		    crc_sync <= 0;
		  end
		  else if(enable == 1 && count_N == 447)
		  begin
		    crc_sync <= 0;
		  end
		  else if(enable == 1 && count_N == 665)
		  begin
		    crc_sync <= 0;
		  end
		  else 
		  begin
		    crc_sync <= 1;
		  end
	 end
	 
	 //10
	 always @(posedge clk or negedge rst_N)
	 begin
	   if(rst_N == 0)
		begin
		  crc_enable <= 0;
		end
		else if(enable == 1 && count_N == 10)
		begin
		  crc_enable <= 1;
		end
	 end
	 
	 assign crc_datain = crc_data[crc_count];
	 
	 CRC16 U_crc16(         
	      .data_in(crc_datain),  //数据
			.clk(clk),             
			.en(crc_enable),       //1有效
			.rst_N(rst_N),         //0
			.syn(crc_sync),        //块同步，200
			.data_out(crc_dataout)
			);
	
    //226	
	 always @(posedge clk or negedge rst_N)
	 begin
	      if(rst_N == 0)
			begin
			   digital_turbo0 <= 0;
			end
			else if(enable == 1 && count_N == 228)
			begin
			  digital_turbo0 <= {digital_d0,crc_dataout};
			end
	 end
	 
	 //444
	 always @(posedge clk or negedge rst_N)
	 begin
	    if(rst_N == 0)
		 begin
		    digital_turbo1 <= 0;
		 end
		 else if(enable == 1 && count_N == 447)
		 begin
		    digital_turbo1 <= {digital_d1,crc_dataout};
		 end
	 end
	 
	 //662
	 always @(posedge clk or negedge rst_N)
	 begin
	   if(rst_N == 0)
		begin
		  digital_turbo2 <= 0;
		end
		else if(enable == 1 && count_N == 665)
		begin
		  digital_turbo2 <= {digital_d2,crc_dataout};
		end
	 end
	////////////////////////////////////////////////////////////////
	
	
	 //////////////////////////////////////////////////////////////////
	 //这里因为在计算g的时候，我这里可以有30个周期都数据，读取dc数据然后保存
	 //获取存储好的DC系数
	 
	  
	 //4
	 always @(posedge clk or negedge rst_N)
	 begin
	    if(rst_N == 0)
		 begin
		    dc_data1 <= 0;
		 end
		 else if(enable == 1)
		 begin
		   dc_data1 <= dc_data0;
		 end
	 end
	 
	 //5
	 always @(posedge clk or negedge rst_N)
	 begin
	    if(rst_N==0)
		 begin
		    dc_data2 <= 0;
			 dc_data3 <= 0;
		 end
		 
		 /*else if(enable == 1 && dc_data1 >= 2^13-1)
		 begin
		    dc_data2 <=  2^13-1;
		 end
		 else if(enable == 1 && dc_data1 <= -2^13)
		 begin
		   dc_data2 <=  -2^13;
		 end
		 */
		 
		 else if(enable == 1)
		 begin
		   dc_data2 <=  dc_data1[12:0];
			dc_data3 <= dc_data2;
		 end
	 end
	 
	 //6
	 always @(posedge clk or negedge rst_N)
	 begin
	   if(rst_N == 0)
		begin
		   digital_d1 <= 0;
		end
		else if(enable == 1 && count_N[14:10]==0 && count_N[9:0]==1+5) 
		begin
		   digital_d1[199:187] <= dc_data3;
		end
		else if(enable == 1 && count_N[14:10]==0 && count_N[9:0]==1+6)
		begin
         digital_d1[186:174] <= dc_data3;
 		end
		else if(enable == 1 && count_N[14:10]==0 && count_N[9:0]==1+7)
		begin
		   digital_d1[173:161] <= dc_data3;
		end
		else if(enable == 1 && count_N[14:10]==0 && count_N[9:0]==1+8)
		begin
		   digital_d1[160:148] <= dc_data3;
		end
		else if(enable == 1 && count_N[14:10]==0 && count_N[9:0]==1+9)
		begin
		   digital_d1[147:135] <= dc_data3;
		end
		else if(enable == 1 && count_N[14:10]==0 && count_N[9:0]==1+10)
		begin
		  digital_d1[134:122] <= dc_data3;
		end
		else if(enable == 1 && count_N[14:10]==0 && count_N[9:0]==1+11)
		begin
		  digital_d1[121:109] <= dc_data3;
		end
		else if(enable == 1 && count_N[14:10]==0 && count_N[9:0]==1+12)
		begin
		  digital_d1[108:96] <= dc_data3;
		end
		else if(enable == 1 && count_N[14:10]==0 && count_N[9:0]==1+13)
		begin
		  digital_d1[95:83] <= dc_data3;
		end
		else if(enable == 1 && count_N[14:10]==0 && count_N[9:0]==1+14)
		begin
		  digital_d1[82:70] <= dc_data3;
		end
		else if(enable == 1 && count_N[14:10]==0 && count_N[9:0]==1+15)
		begin
		  digital_d1[69:57] <= dc_data3;
		end
		else if(enable == 1 && count_N[14:10]==0 && count_N[9:0]==1+16)
		begin
		  digital_d1[56:44] <= dc_data3;
		end
		else if(enable == 1 && count_N[14:10]==0 && count_N[9:0]==1+17)
		begin
		  digital_d1[43:31] <= dc_data3;
		end
		else if(enable == 1 && count_N[14:10]==0 && count_N[9:0]==1+18)
		begin
		  digital_d1[30:18] <= dc_data3;
		end
		else if(enable == 1 && count_N[14:10]==0 && count_N[9:0]==1+19)
		begin
		  digital_d1[17:5] <= dc_data3;
		end
		//20
		else if(enable == 1 && count_N[14:10]==0 && count_N[9:0]==1+20)
		begin
		  digital_d1[4:0] <= dc_data3[12:8];
		  digital_d2[199:192] <= dc_data3[7:0];
		end
		else if(enable == 1 && count_N[14:10]==0 && count_N[9:0]==1+21)
		begin
		  digital_d2[191:179] <= dc_data3;
		end
		else if(enable == 1 && count_N[14:10]==0 && count_N[9:0]==1+22)
		begin
		  digital_d2[178:166] <= dc_data3;
		end
		else if(enable ==1 && count_N[14:10]==0 && count_N[9:0]==1+23)
		begin
		  digital_d2[165:153] <= dc_data3;
		end
		else if(enable ==1 && count_N[14:10]==0 && count_N[9:0]==1+24)
		begin
		  digital_d2[152:140] <= dc_data3;
		end
		else if(enable ==1 && count_N[14:10]==0 && count_N[9:0]==1+25)
		begin
		  digital_d2[139:127] <= dc_data3;
		end
		else if(enable ==1 && count_N[14:10]==0 && count_N[9:0]==1+26)
		begin
		  digital_d2[126:114] <= dc_data3;
		end
		else if(enable ==1 && count_N[14:10]==0 && count_N[9:0]==1+27)
		begin
		  digital_d2[113:101] <= dc_data3;
		end
		else if(enable ==1 && count_N[14:10]==0 && count_N[9:0]==1+28)
		begin
		  digital_d2[100:88] <= dc_data3;
		end
		else if(enable ==1 && count_N[14:10]==0 && count_N[9:0]==1+29)
		begin
		  digital_d2[87:75] <= dc_data3;
		end
		else if(enable ==1 && count_N[14:10]==0 && count_N[9:0]==1+30)
		begin
		  digital_d2[74:62] <= dc_data3;
		end
		else if(enable ==1 && count_N[14:10]==0 && count_N[9:0]==1+31)
		begin
		  digital_d2[61:49] <= dc_data3;
		end
		else if(enable ==1 && count_N[14:10]==0 && count_N[9:0]==1+32)
		begin
		  digital_d2[48:36] <= dc_data3;
		end
		else if(enable ==1 && count_N[14:10]==0 && count_N[9:0]==1+33)
		begin
		  digital_d2[35:23] <= dc_data3;
		end
		else if(enable ==1 && count_N[14:10]==0 && count_N[9:0]==1+34)
		begin
		  digital_d2[22:10] <= dc_data3;
		end
		else if(enable ==1 && count_N[14:10]==0 && count_N[9:0]==1+35)
		begin
		  digital_d2[9:0] <= 10'b0;
		end
	 end
	 
	 //上面处理的是高位给lambda0然后lambda1，最后一个lambda14是放在最低位
	 //////////////////////////////////////////////////////////////////
	 

	 //227,212
	 always @(posedge clk or negedge rst_N)
	 begin
	    case(count_N)
		   15'd231:turbo_input0 <= digital_turbo0[63:0];
			15'd232:turbo_input0 <= digital_turbo0[127:64];
			15'd233:turbo_input0 <= digital_turbo0[191:128];
			15'd234:turbo_input0 <= {digital_turbo0[215:192],40'b0};
			
			15'd462:turbo_input0 <= digital_turbo1[63:0];
			15'd463:turbo_input0 <= digital_turbo1[127:64];
			15'd464:turbo_input0 <= digital_turbo1[191:128];
			15'd465:turbo_input0 <= {digital_turbo1[215:192],40'b0};
			
			15'd693:turbo_input0 <= digital_turbo2[63:0];
			15'd694:turbo_input0 <= digital_turbo2[127:64];
			15'd695:turbo_input0 <= digital_turbo2[191:128];
			15'd696:turbo_input0 <= {digital_turbo2[215:192],40'b0};
		 endcase
	 end
	 
	 //226
	 always @(posedge clk or negedge rst_N)
	 begin
	   if(rst_N == 0)
		begin
		   sync_turbo <= 0;
		end
		else if(enable == 1 && count_N == 229)
		begin
		   sync_turbo <= 0;
		end
		else if(enable == 1 && count_N == 460)
		begin
		   sync_turbo <= 0;
		end
		else if(enable == 1 && count_N == 691)
		begin
		   sync_turbo <= 0;
		end
		else 
		begin
		   sync_turbo <= 1;
		end
	 end
	 
	 //228
	 TURBO_ENCODE U_turbo_encode(	
	                       .clk(clk),
                          .rst(sync_turbo),
	                       .bitblock(turbo_input0),
	                       .sys(digit_encode_0),
	                       .parity1(digit_encode_1),
	                       .parity2(digit_encode_2)
								  );
	 
	  //435,第一块结束,219开始
	  //661,第二块结束,445开始
	  //888,第三块结束,672开始
	  
	  reg [2:0]modu_input;
	  wire modu_enableout;
	  reg modu_enable;
     wire[31:0]output_mod;
	  reg modu_rst;
	  reg signed [15:0] data_out_digital0;
	  reg signed [15:0] data_out_digital1;
	  reg signed [15:0] data_out_digital2;
	  reg signed [15:0] data_out_digital3;
	  reg digital_temp_sync;
	  reg [1:0] temp_modu_input0;
	  reg [2:0] temp_modu_input1;
	  reg temp_modu_input2;
	  reg [2:0] modu_input3;
	  
	  /*
	  always @(posedge clk or negedge rst_N)
	  begin
	     if(rst_N == 0)
		  begin
		     temp_modu_input0 <= 0;
			  temp_modu_input1 <= 0;
			  temp_modu_input2 <= 0;
		  end
		  else if(enable == 1 && count_N == 451)
		  begin
		    temp_modu_input0 <= {digit_encode_0,digit_encode_1};
		  end
		  else if(enable == 1 && count_N == 452)
		  begin
		    temp_modu_input1 <= {temp_modu_input0,digit_encode_0};
			 temp_modu_input2 <= digit_encode_1;
		  end
		  else if(enable == 1 && count_N == 453)
		  begin
		    temp_modu_input1 <= {temp_modu_input2,digit_encode_0,digit_encode_1};
		  end
		  
		  else if(enable == 1 && count_N == 454)
		  begin
		     temp_modu_input0 <= {digit_encode_0,digit_encode_1};
		  end
		  else if(enable == 1 && count_N == 455)
		  begin
		     temp_modu_input1 <= {temp_modu_input0,digit_encode_0};
			  temp_modu_input2 <= digit_encode_1;
		  end
		  else if(enable == 1 && count_N == 456)
		  begin
		     temp_modu_input1 <= {temp_modu_input2,digit_encode_0,digit_encode_1};
		  end
	  end
	   */
	 //218
	 always @(posedge clk or negedge rst_N)
	 begin
	    if(rst_N == 0)
		 begin
		     modu_input  <= 3'b0;
		 end 
		 //第一块
		 else if(enable == 1 && count_N ==461)
		 begin
		    modu_input <= beforemedu6;
		 end
		 else if(enable == 1 && count_N == 462)
		 begin
		   modu_input <= beforemedu7;
		 end
		 else if(enable == 1 && count_N == 463)
		 begin
		   modu_input <= beforemedu8;
		 end
		 else if(enable == 1 && count_N == 464)
		 begin
		   modu_input <= beforemedu9;
		 end
		 //第二块
		 else if(enable == 1 && count_N ==692)
		 begin
		    modu_input <= beforemedu6;
		 end
		 else if(enable == 1 && count_N == 693)
		 begin
		   modu_input <= beforemedu7;
		 end
		 else if(enable == 1 && count_N == 694)
		 begin
		   modu_input <= beforemedu8;
		 end
		 else if(enable == 1 && count_N == 695)
		 begin
		   modu_input <= beforemedu9;
		 end
		 //第三块
		 else if(enable == 1 && count_N ==923)
		 begin
		    modu_input <= beforemedu6;
		 end
		 else if(enable == 1 && count_N == 924)
		 begin
		   modu_input <= beforemedu7;
		 end
		 else if(enable == 1 && count_N == 925)
		 begin
		   modu_input <= beforemedu8;
		 end
		 else if(enable == 1 && count_N == 926)
		 begin
		   modu_input <= beforemedu9;
		 end
		 //
		 else if(enable == 1)
		 begin
		     modu_input <= {digit_encode_2,digit_encode_1,digit_encode_0};
		 end
	 end
	 
	  //这里先将最后6个clk数据分成存下来然后再进行，输出给调制
	 
	  always @(posedge clk or negedge rst_N)
	  begin
	      if(rst_N == 0)
			begin
			   beforemedu0 <= 0;
				beforemedu1 <= 0;
				beforemedu2 <= 0;
			end
			//第一块
			else if(enable == 1 && count_N >= 454 && count_N <= 456)
			begin
			   beforemedu0 <= {digit_encode_1,digit_encode_0};
				beforemedu1 <= beforemedu0;
				beforemedu2 <= beforemedu1; 
			end
			else if(enable == 1 && count_N >= 457 && count_N<=459)
			begin
			   beforemedu3 <= {digit_encode_2,digit_encode_0};
				beforemedu4 <= beforemedu3;
				beforemedu5 <= beforemedu4; 
			end
			//第二块
			else if(enable == 1 && count_N >= 685 && count_N <= 687)
			begin
			   beforemedu0 <= {digit_encode_1,digit_encode_0};
				beforemedu1 <= beforemedu0;
				beforemedu2 <= beforemedu1; 
			end
			else if(enable == 1 && count_N >= 688 && count_N<=690)
			begin
			  	beforemedu3 <= {digit_encode_2,digit_encode_0};
				beforemedu4 <= beforemedu3;
				beforemedu5 <= beforemedu4;
			end
			//第三块
		   else if(enable == 1 && count_N >= 916 && count_N <= 918)
			begin
			   beforemedu0 <= {digit_encode_1,digit_encode_0};
				beforemedu1 <= beforemedu0;
				beforemedu2 <= beforemedu1; 
			end
			else if(enable == 1 && count_N >= 919 && count_N<=921)
			begin
			  	beforemedu3 <= {digit_encode_2,digit_encode_0}; //3
				beforemedu4 <= beforemedu3;                     //2
				beforemedu5 <= beforemedu4;                     //1
			end
	  end
	  
	  
	  //454 //457
	  always @(posedge clk or negedge rst_N)
	  begin
	      if(rst_N == 0)
			begin
			  beforemedu6 <= 0;
			  beforemedu7 <= 0;
			  beforemedu8 <= 0;
			  beforemedu9 <= 0;
			end
			//第一块
			else if(enable == 1 && count_N == 460)
			begin
			  beforemedu6 <= {beforemedu1[0],beforemedu2};
			  beforemedu7 <= {beforemedu0,beforemedu1[1]};
			  beforemedu8 <= {beforemedu4[0],beforemedu5};
			  beforemedu9 <= {beforemedu3,beforemedu4[1]};
			end
			//第二块
			else if(enable == 1 && count_N == 691)
			begin
			  beforemedu6 <= {beforemedu1[0],beforemedu2};
			  beforemedu7 <= {beforemedu0,beforemedu1[1]};
			  beforemedu8 <= {beforemedu4[0],beforemedu5};
			  beforemedu9 <= {beforemedu3,beforemedu4[1]};
			end
			//第三块
			else if(enable == 1 && count_N == 922)
			begin
			  beforemedu6 <= {beforemedu1[0],beforemedu2};
			  beforemedu7 <= {beforemedu0,beforemedu1[1]};
			  beforemedu8 <= {beforemedu4[0],beforemedu5};
			  beforemedu9 <= {beforemedu3,beforemedu4[1]};
			end
	 end
	  
	  
	 // MODULATION有效信号
	 always @(posedge clk or negedge rst_N)
	 begin
	   if(rst_N == 0)
		begin
		   modu_enable <= 0;
		end
		//第一块
		else if(enable == 1 && count_N>=237 && count_N <=452+3)
		begin
		   modu_enable <= 1;
		end
		else if(enable == 1 && count_N >= 460 && count_N <= 463+3)
		begin
		   modu_enable <= 1;
		end
		//第二块
		else if(enable == 1 && count_N >=468 && count_N <= 686)
		begin
		   modu_enable <= 1;
		end
		else if(enable == 1 && count_N >= 691 && count_N <= 694+3)
		begin
		  modu_enable <= 1;
		end
	   //第三块
		else if(enable == 1 && count_N >=699 && count_N <= 914+3)
		begin
		   modu_enable <= 1;
		end
		else if(enable == 1 && count_N >= 922 && count_N <= 925+3)
		begin
		  modu_enable <= 1;
		end
		else
		begin
		   modu_enable <= 0;
		end
	 end
	 
	 //238
	
	 always@(posedge clk)
	 begin
	     enable_tst <= modu_enable;
	 end
	 reg rst_mod;
	 always@(posedge clk)
	 begin
	     if(modu_enable == 0)
		  begin
		      rst_mod <= 0;
		  end
		  else
		  begin
		      rst_mod <= 1;
		  end
	 end
	 MODULATION U_modulation(
	           .input_bits_1(modu_input),
		        .enable_in(enable_tst),
		        .clk(clk),
		        .output_mod(output_mod),
		        .enable_out(modu_enableout),
		        .rst(rst_mod)
              );
//	  assign data_out_digital_real = output_mod[31:16];
//   assign data_out_digital_image = output_mod[15:0];

	  
	 //239
	 //接受调制之后的数字部分数据
	 always @(posedge clk or negedge rst_N)
	 begin
	      if(rst_N == 0)
			begin
			    	data_out_digital0 <= 0;
			      data_out_digital1 <= 0;
			end
			else if(enable == 1)
			begin
	     	     data_out_digital0 <= output_mod[15:0];
			     data_out_digital1 <= output_mod[31:16];
			end
	 end
	 
	 always @(posedge clk or negedge rst_N)
    begin
	   if(rst_N == 0)
		begin

			data_out_digital2 <= 0;
			data_out_digital3 <= 0;
		end
		else if(enable == 1)
		begin
			data_out_digital2 <= data_out_digital0+1;
			data_out_digital3 <= data_out_digital1+1;
		end
    end
	 
    always @(posedge clk or negedge rst_N)
    begin
	    if(rst_N == 0)
		 begin
		    digital_temp_sync <= 0;
		 end
		 else if(enable == 1)
		 begin
		   digital_temp_sync <= modu_enableout;
		 end
    end	
	 
    assign sync_digital = temp_frame_digital0?digital_temp_sync:0;
	 
    assign data_out_digital_real = {data_out_digital2[15],data_out_digital2[15:1]};
    assign data_out_digital_image ={data_out_digital3[15],data_out_digital3[15:1]};
	 
	 //224开始输出数据
	 
	 ////////////////////////////////////////////////////////////////
	 
	 //数字信号的帧同步
    
	 
	 //0
	 always @(posedge clk or negedge rst_N)
	 begin
	     if(rst_N == 0)
		  begin
		     count_frame_digital0 <= 0;
		  end
		  else if(input_line_sync == 1 )
		  begin
		     count_frame_digital0 <= 0;
		  end
		  else if(count_frame_digital0 == 30719 && enable == 1)
		  begin
		     count_frame_digital0 <= 0;
		  end
		  else if(enable == 1)
		  begin
		     count_frame_digital0 <= count_frame_digital0 + 1;
		  end
	 end
	 
	 
	 always @(posedge clk or negedge rst_N)
	 begin
	    if(rst_N == 0)
		 begin
		    temp_frame_digital0 <= 0;
		 end
		 else if(enable == 1 &&count_frame_digital0==30719)
		 begin
		    temp_frame_digital0 <= 1;
		 end
	 end
	 
	 always @(posedge clk or negedge rst_N)
	 begin
	    if(rst_N == 0)
		 begin
		    temp_frame_digital1 <= 0;
		 end
		 else if(enable == 1 && temp_frame_digital0 ==1 && count_frame_digital0 == 244)
		 begin
		    temp_frame_digital1 <= 1;
		 end
		 else
		 begin
		    temp_frame_digital1 <= 0;
		 end
	 end
	 
	 assign output_line_sync_digital = temp_frame_digital1;
	 
endmodule
