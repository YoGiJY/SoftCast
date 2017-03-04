`timescale 1ns / 1ps
/*
*
	* @Author:Yao
	* @Email:yao.jiang@tongji.edu.cn
	* @Time: 2016年12月13日10:11:47
	* @Brief:实现接收端的LLSE 
*/

/*
  * LLSE 模块实现的是
*/
module RECEIVE_LLSE_TOP(
       clk,
		 rst_n,
		 input_line_sync,    //行同步信号
       //模拟信号       
		 frame_analog_enable,
		 frame_analog_data,
       //数字信号
		 frame_digital_enable,
		 frame_digital_data0,
	    frame_digital_data1,
		 //output
		 output_line_sync,
		 enable_o,
		 data_out_dct
    );

    //input
	  input clk;
	  input rst_n;
	  input input_line_sync;
	  input frame_analog_enable;
	  input [31:0] frame_analog_data;
	  input frame_digital_enable;
	  input [31:0] frame_digital_data0;
	  input [23:0] frame_digital_data1;
	  
	  //output
	  output output_line_sync;
	  output enable_o;
	  output [63:0] data_out_dct;
    ///////////////////////////////////////////////////////////
    //数字部分的实现  //495
    //解帧数字部分数据-->(945/3个数据)-->解调-->945*4/3-->给三路turbo
    //模拟部分数据-->存储下来
   ////////////////////////////////////////////////////////////
   
	//数字部分变量定义
   reg enable;
   reg  [31:0] data0,data1,data2,data3;
   wire [15:0] input_real;
   wire [15:0] input_imag;
   wire [11:0] input_realH;
   wire [11:0] input_imagH;
   reg demodu_enable;
   wire demodu_enable_out;
//   reg [60:0] LLR0;
//   reg [60:0] LLR1;
//   reg [60:0] LLR2;
//   reg [60:0] LLR3;
   reg [15:0] OUT_LLR_0;
   reg [15:0] OUT_LLR_1;
   reg [15:0] OUT_LLR_2;
   reg [15:0] OUT_LLR_3;
	
	wire [60:0] LLR_0;
	wire [60:0] LLR_1;
	wire [60:0] LLR_2;
	wire [60:0] LLR_3;
	
   wire [63:0] data_out_llr;
   reg  [63:0] data_out_llr0;
	wire [63:0] data_in_rom;
	
	reg rst_turbo0,rst_turbo1,rst_turbo2;
	
	//这里与模拟信号同步
   reg [14:0] llse_count;   
	wire we_decode0,we_decode1,we_decode2;
	wire [7:0] addr_turbo_out0,addr_turbo_out1,addr_turbo_out2;
	reg [7:0] turbo_count,turbo_count0,turbo_count1;
	reg turbo_wr,turbo_wr0,turbo_wr1;
	reg [7:0] addr_turbo_p0,addr_turbo_p1,addr_turbo_p2;
	reg [7:0] addr_turbo_p3,addr_turbo_p4,addr_turbo_p5;
	reg [63:0] data_turbo_p0,data_turbo_p1,data_turbo_p;
	reg [63:0] data_turbo_p3,data_turbo_p4,data_turbo_p5;
	
	
	reg [3:0] sigma_count;
	wire [7:0] sigma;
	wire [17:0] ll0;
	wire [15:0] gg0;
	reg [15:0] gg1;
	reg [33:0] mutlgl0;
	reg [33:0] mutlgl;
	reg signed [49:0] mutlgl1;
	wire signed [33:0] mutlgl2;
	wire [15:0] sigma1;
	reg [53:0] divide_input2;
	reg [53:0] divide_input1;
	wire [53:0] divider_output1;
	reg [17:0] llse [0:14];
	reg [17:0] llse0 [0:14];
	reg [12:0] dc  [0:29];
	reg [12:0] dc0 [0:29];
	
	reg [63:0] data_turbo0,data_turbo1,data_turbo2;
	reg [63:0] data_turbo3,data_turbo4,data_turbo5;
	reg [63:0] data_turbo6,data_turbo7,data_turbo8;
	reg [63:0] data_turbo9,data_turbo10,data_turbo11;
	reg[215:0] digital_d0;
   reg[215:0] digital_d1;
   reg[215:0] digital_d2;

	reg [17:0] lambda0;
	reg [17:0] lambda1 [0:14];
	reg lambda2G_rst;
	
	reg [15:0] g [0:14];
   reg [17:0] select_llse0,select_llse1;
	reg [17:0] select_llse2,select_llse3;
	reg [15:0] gg;
	///////////////////////////////////////////////////////////////
	//模拟部分变量定义
   reg [31:0] analog_data;
	wire signed [15:0] data_out00,data_out01;
	reg[14:0] analog_count0;
   reg analog_wr;
   reg analog_wr1;
	reg [14:0] addr_analog_p,addr_analog_q;
	reg [31:0] data_analog_p,data_analog_q;
	wire [31:0] data_analog_out_p,data_analog_out_q;
	
	wire [31:0] data_out_analog;
	reg signed [33:0] data_out0,data_out1;
	reg signed [31:0] data_out4,data_out5;
	wire signed [37:0] data_out2,data_out3;
	wire [63:0] data_in_turbo0,data_in_turbo1,data_in_turbo2;
	wire [63:0] data_turbo_out0,data_turbo_out1,data_turbo_out2;
	
	reg we_de0,we_de1,we_de2;
	wire [23:0] lambda_data;
	wire [15:0] lambda2G_out;
	///////////////////////////////////////////////////////////////
	
	//数字部分实现
	/*
	always @(posedge clk or negedge rst_n)
	begin
	    if(rst_n == 0)
		 begin
		     enable <= 0;
		 end
		 else if(frame_digital_enable == 1)
		 begin
		     enable <= 1;
		 end
		 else if(frame_analog_enable == 0)
		 begin
		    enable <= 0;
		 end
	end
	*/
	always @(posedge clk)
	begin
	    enable <= (frame_digital_enable || frame_analog_enable);
   end
	
   //0
   always @(posedge clk or negedge rst_n)
   begin
	   if(rst_n == 0)
	   begin
		   llse_count <= 0;
	   end
		else if(enable == 1 && llse_count == 15854)  //495 + 15360
		begin
		   llse_count <= 0;
		end
	   else if(enable == 1)
	   begin
		   llse_count <= llse_count + 1;
	   end
   end
	
   //0
   always @(posedge clk or negedge rst_n)
   begin
	   if(rst_n == 0)
	   begin
		   data0 <= 0;
		   data1 <= 0;
	   end
	   else if(enable == 1)
	   begin
		   data0 <= frame_digital_data0;
		   data1 <= frame_digital_data1;
	   end
   end

   //1
   always @(posedge clk or negedge rst_n)
   begin
	   if(rst_n == 0)
	   begin
		   data2 <= 0;
		   data3 <= 0;
	   end
	   else 
	   begin 
		   data2 <= data0;
		   data3 <= data1;
	   end
   end
  
   assign input_real  =  data2[31:16];
   assign input_imag   =  data2[15:0];
   assign input_realH =  data3[23:12];
   assign input_imagH =  data3[11:0];
   
   //0
   always @(posedge clk or negedge rst_n)
   begin
	   if(rst_n == 0)
	   begin
            demodu_enable <= 0;
	   end
	   else if(llse_count >= 0 && llse_count <= 499 && enable == 1)  //这里通过计数来实现逻辑控制,494+5
	   begin
            demodu_enable <= 1;
	   end
	   else 
	   begin
            demodu_enable <= 0;
	   end
   end 
 
   wire demodu_enable_net;
   assign demodu_enable_net = demodu_enable;
   //2
   //输入之后 5CLK 之后出数据
   DEMODULATION U_demodulation(
	     .input_real(input_real),
		  .input_imag(input_imag),
		  .input_realH(input_realH),
		  .input_imagH(input_imagH),
		  .clk(clk),
		  .output_LLR_0(LLR_0),
		  .output_LLR_1(LLR_1),
		  .output_LLR_2(LLR_2),
		  .output_LLR_3(LLR_3),
		  .enable_in(demodu_enable),
		  .enable_out(demodu_enable_out)
		  );
    
    //7
    always @(posedge clk or negedge rst_n)
    begin
	    if(rst_n == 0)
	    begin
             OUT_LLR_0 <= 0;
	          OUT_LLR_1 <= 0;
		       OUT_LLR_2 <= 0;
		       OUT_LLR_3 <= 0;
	    end
	    else if(enable == 1 && llse_count>=7 && llse_count<= 495+6)
	    begin
		      OUT_LLR_0 <= -$signed({{8{LLR_0[43]}},{LLR_0[42:35]}});  //43-36 = 15
	         OUT_LLR_1 <= -$signed({{8{LLR_1[43]}},{LLR_1[42:35]}});  //43-36 = 15
		      OUT_LLR_2 <= -$signed({{8{LLR_2[43]}},{LLR_2[42:35]}});  //43-36 = 15
		      OUT_LLR_3 <= -$signed({{8{LLR_3[43]}},{LLR_3[42:35]}});  //43-36 = 15
	    end
    end


    //7
    assign data_in_rom = {OUT_LLR_0,OUT_LLR_1,OUT_LLR_2,OUT_LLR_3};  //64bit
	 
	 reg [8:0] data_in_count;
	 reg [8:0] data_in_count0;
	 wire [8:0] addr_count; 
	 reg wr;
	 wire [63:0] data_out_rom;
	 reg [63:0] data_out_rom0,data_out_rom1,data_out_rom2;
	 reg [1:0] count0;
	 reg [191:0] data_out_rom3;
	 wire [63:0] data_in_rom4,data_in_rom5,data_in_rom6,data_in_rom7;
	 reg [63:0] datav0,datav1,datav2,datav3,datav4,datav5;
	 //这里将读入的数据进行存储
	 //495 clk
	 LLSE_MEM_GEN_1 U_llse_mem_gen(
    		.clka(clk),
		   .wea(wr),
		   .addra(addr_count),
		   .dina(data_in_rom),
		   .douta(data_out_rom)
	 );
 
    assign addr_count = (wr)?data_in_count:data_in_count0;
	 
	 //494+7=501
    always @(posedge clk or negedge rst_n)
	 begin
	     if(rst_n == 0)
		  begin
		       data_in_count <= 0;
		  end
		  else if(enable == 1 && llse_count == 7)
		  begin
		      data_in_count <= 0;
		  end
		  else if(enable == 1 && data_in_count == 494+7)
		  begin
		      data_in_count <= 0;
		  end
		  else if(enable == 1)
		  begin
		     data_in_count <= data_in_count + 1;
		  end
	 end
	 
	 //7+495 = 502
	 always @(posedge clk or negedge rst_n)
	 begin
	    if(rst_n == 0)
		 begin
		     data_in_count0 <= 0;
		 end
		 else if(llse_count == 7+495)
		 begin
		     data_in_count0 <= 0;
		 end
		 else if(enable == 1 && count0!=3)
		 begin
		    data_in_count0 <= data_in_count0 + 1;
		 end
	 end
	 
	 
	 always @(posedge clk or negedge rst_n)
	 begin
	   if(rst_n == 0)
		begin
		   count0 <= 1;
		end
		else if(enable==1)
		begin
		   count0 <= count0 + 1;
		end
	 end
	 //6
	 always @(posedge clk or negedge rst_n)
	 begin
	     if(rst_n == 0)
		  begin
		     wr <= 1;
		  end
		  else if(enable == 1 && llse_count == 6)
		  begin
		     wr <= 1;
		  end
		  else if(enable == 1 && llse_count == 495+7)
		  begin
		     wr <= 0;
		  end
	 end
	 
	//将上面存储的数据，进行分解
	always @(posedge clk or negedge rst_n)
	begin
	     if(rst_n == 0)
		  begin
		    data_out_rom0 <= 0;
		    data_out_rom1 <= 0;
		    data_out_rom2 <= 0;
		  end
		  else if(enable == 1)
		  begin
		    data_out_rom0 <= data_out_rom;
			 data_out_rom1 <= data_out_rom0;
			 data_out_rom2 <= data_out_rom1;
		  end
	end
	
	always @(posedge clk or negedge rst_n)
	begin
	    if(rst_n == 0)
		 begin
		    data_out_rom3 <= 0;
		 end
		 else if(enable == 1 && count0 == 0)
		 begin
		    data_out_rom3 <= {data_out_rom2,data_out_rom1,data_out_rom0};
		 end
	end
	
	assign data_in_rom4 = {{16'b0},data_out_rom3[191:144]};
	assign data_in_rom5 = {{16'b0},data_out_rom3[143:96]};
	assign data_in_rom6 = {{16'b0},data_out_rom3[95:48]};
	assign data_in_rom7 = {{16'b0},data_out_rom3[47:0]};
	
	//这里进行尾比特计算
	always @(posedge clk or negedge rst_n)
	begin
	     if(rst_n == 0)
		  begin
		      datav0 <= 0;
				datav1 <= 0;
				datav2 <= 0;
				datav3 <= 0;
				datav4 <= 0;
				datav5 <= 0;
		  end
		  else if(enable == 1 && (llse_count == 724|| llse_count == 944 ||llse_count == 1164))
		  begin
		      datav0 <= {16'b0,{data_out_rom3[191:160]},16'b0};
				datav1 <= {16'b0,{data_out_rom3[159:128]},16'b0};
				datav2 <= {16'b0,{data_out_rom3[127:96]},16'b0};
				datav3 <= {16'b0,{data_out_rom3[95:80]},16'b0,{data_out_rom3[79:64]}};
				datav4 <= {16'b0,{data_out_rom3[63:48]},16'b0,{data_out_rom3[47:32]}};
				datav5 <= {16'b0,{data_out_rom3[31:16]},16'b0,{data_out_rom3[15:0]}};
		  end
	end
	 
	 //509 存储的数据
	 always @(posedge clk or negedge rst_n)
	 begin
	    if(rst_n == 0)
		 begin
		    data_turbo_p <= 0;
		 end
		 else if(llse_count <=724 && llse_count >=508 && enable == 1)
		 begin
		  if(count0 == 1 )
		   begin
		     data_turbo_p <= data_in_rom4;
		   end
		   else if(count0 == 2 )
		   begin
		    data_turbo_p<= data_in_rom5;
		   end
		   else if(count0 == 3)
		   begin
		     data_turbo_p <= data_in_rom6;
		   end
		   else if(count0 == 0)
		   begin
		     data_turbo_p <= data_in_rom7;
		   end
		 end
		 else if(llse_count == 725 && enable == 1)
		 begin
		     data_turbo_p <= datav0;
		 end
		 else if(llse_count == 726 && enable == 1)
		 begin
		     data_turbo_p <= datav1;
		 end
		 else if(llse_count == 727 && enable == 1)
		 begin
		     data_turbo_p <= datav2;
		 end		
		 else if(llse_count == 728 && enable == 1)
		 begin
		     data_turbo_p <= datav3;
		 end
		 else if(llse_count == 729 && enable == 1)
		 begin
		     data_turbo_p <= datav4;
		 end
		 else if(llse_count == 730 && enable == 1)
		 begin
		     data_turbo_p <= datav5;
		 end
	 end
	 
	 
	 always@(posedge clk or negedge rst_n)
	 begin
	    if(rst_n == 0)
		 begin
		     data_turbo_p0 <= 0;
		 end
		 else if(llse_count>=728 && llse_count <= 944 && enable == 1)
		 begin
		    if(count0 == 1)
		         data_turbo_p0 <= data_in_rom4;
			 else if(count0 == 2)
			      data_turbo_p0 <= data_in_rom5;
			 else if(count0 == 3)
			      data_turbo_p0 <= data_in_rom6;
			 else if(count0 == 0)
			      data_turbo_p0 <= data_in_rom7;
		 end
		 else if(llse_count == 945 && enable == 1)
		 begin
		     data_turbo_p0 <= datav0;
		 end
		 else if(llse_count == 946 && enable == 1)
		 begin
		     data_turbo_p0 <= datav1;
		 end
		 else if(llse_count == 947 && enable == 1)
		 begin
		     data_turbo_p0 <= datav2;
		 end		
		 else if(llse_count == 948 && enable == 1)
		 begin
		     data_turbo_p0 <= datav3;
		 end
		 else if(llse_count == 949 && enable == 1)
		 begin
		     data_turbo_p0 <= datav4;
		 end
		 else if(llse_count == 950 && enable == 1)
		 begin
		     data_turbo_p0 <= datav5;
		 end
	 end
	 
	 always@(posedge clk or negedge rst_n)
	 begin
	    if(rst_n == 0)
		 begin
		     data_turbo_p1 <= 0;
		 end
		 else if(llse_count>=948 && llse_count <= 1164 && enable == 1)
		 begin
		    if(count0 == 1)
		         data_turbo_p1 <= data_in_rom4;
			 else if(count0 == 2)
			      data_turbo_p1 <= data_in_rom5;
			 else if(count0 == 3)
			      data_turbo_p1 <= data_in_rom6;
			 else if(count0 == 0)
			      data_turbo_p1 <= data_in_rom7;
		 end
		 else if(llse_count == 1165 && enable == 1)
		 begin
		     data_turbo_p1 <= datav0;
		 end
		 else if(llse_count == 1166 && enable == 1)
		 begin
		     data_turbo_p1 <= datav1;
		 end
		 else if(llse_count == 1167 && enable == 1)
		 begin
		     data_turbo_p1 <= datav2;
		 end		
		 else if(llse_count == 1168 && enable == 1)
		 begin
		     data_turbo_p1 <= datav3;
		 end
		 else if(llse_count == 1169 && enable == 1)
		 begin
		     data_turbo_p1 <= datav4;
		 end
		 else if(llse_count == 1170 && enable == 1)
		 begin
		     data_turbo_p1 <= datav5;
		 end
	 end
	 
	 
   /////////////////////////////////////////////////////////////////////////
	
    //这里需要串转并的处理，turbo的输入数据的是64bit
    //将软解调的数据部分，通过存储到不同的RAM
	 //509，存储的地址
    always @(posedge clk or negedge rst_n)
    begin
        if(rst_n == 0)
	     begin
              turbo_count <= 0;
	     end
	     else if(llse_count == 508)   //这里全局llse_count进行控制 
	     begin
				  turbo_count <= 0;
	     end
		  else if(enable == 1 && llse_count == 725)
		  begin
		        turbo_count <= 216;
		  end
	     else if(enable == 1)
	     begin
               turbo_count <= turbo_count + 1;
	     end
    end
    
    //508，寄存器前面一段时间是存数据，后面一段时间就是开始读数据
    always @(posedge clk or negedge rst_n)
    begin
	    if(rst_n == 0)
	    begin
		    turbo_wr <= 1;
	    end
	    else if(enable == 1 && llse_count >=507 && llse_count <=731)
	    begin
          turbo_wr <= 1;
	    end
	    else if(enable == 1 && llse_count >= 732)
	    begin
		    turbo_wr <= 0;
	    end
    end
   
	
	
    //730
    always @(posedge clk or negedge rst_n)
    begin
	    if(rst_n == 0)
	    begin
		    turbo_wr0 <= 1;
	    end
	    else if(enable == 1 && llse_count >= 727 && llse_count <= 951)
	    begin
		    turbo_wr0 <= 1;
	    end
	    else if(enable == 1 && llse_count >= 952 )
	    begin
		    turbo_wr0 <= 0;
	    end
    end
	 
	 
	 always @(posedge clk or negedge rst_n)
	 begin
	    if(rst_n == 0)
		 begin
		     turbo_count0 <= 0;
		 end
		 else if(enable == 1 && llse_count == 728)
		 begin
		     turbo_count0 <= 0;
		 end
		 else if(enable == 1 && llse_count == 945)
		 begin
		     turbo_count0 <= 216;
		 end
		 else if(enable == 1)
		 begin
		     turbo_count0 <= turbo_count0 + 1;
		 end
	 end

    //947
    always @(posedge clk or negedge rst_n)
    begin
	    if(rst_n == 0)
	    begin
		    turbo_wr1 <= 1;
	    end
	    else if(enable == 1 && llse_count >= 947 && llse_count <= 1171)
	    begin
		    turbo_wr1 <= 1;
	    end
	    else if(enable == 1 && llse_count >= 1172)
		 begin
		    turbo_wr1 <= 0;
		 end
    end
	 
	 always @(posedge clk or negedge rst_n)
	 begin
	     if(rst_n == 0)
		  begin
		      turbo_count1 <= 0;
		  end
		  else if(enable == 1 && llse_count == 948)
		  begin
		      turbo_count1 <= 0;
		  end
		  else if(enable == 1 && llse_count == 1165)
		  begin
		     turbo_count1 <= 216;
		  end
		  else if(enable == 1)
		  begin
		     turbo_count1 <= turbo_count1 + 1;
		  end
	 end
	  
    //509
    always @(posedge clk or negedge rst_n)
    begin
	    if(rst_n == 0)
	    begin
		    addr_turbo_p3 <= 0;
		    data_turbo_p3 <= 0;
	    end
	    else if(enable == 1 && turbo_wr == 1 && llse_count >= 507 && llse_count <= 732)
	    begin
		    addr_turbo_p3 <= turbo_count;
		    data_turbo_p3 <= data_turbo_p; 
	    end
	    else if(enable == 1 && turbo_wr ==0 && llse_count >=733)
	    begin
		    addr_turbo_p3 <= addr_turbo_out0; 
	    end
    end

    //730
    always @(posedge clk or negedge rst_n)
    begin
           if(rst_n == 0)
	   begin
		   addr_turbo_p4 <= 0;
		   data_turbo_p4 <= 0;
	   end
	   else if(enable == 1 && turbo_wr0==1 && llse_count >= 727 && llse_count <= 952)
	   begin
         addr_turbo_p4 <= turbo_count0;
		   data_turbo_p4 <= data_turbo_p0; 
	   end
	   else if(enable ==1 && turbo_wr0 == 0 && llse_count >= 953)
	   begin
 		   addr_turbo_p4 <= addr_turbo_out1; 
	   end
    end

    //950
    always @(posedge clk or negedge rst_n)
    begin
	    if(rst_n == 0)
	    begin
		    addr_turbo_p5 <= 0;
		    data_turbo_p5 <= 0;
	    end
	    else if(enable == 1 && turbo_wr1 == 1 && llse_count >= 947 && llse_count <= 1172)
	    begin
		    addr_turbo_p5 <= turbo_count1;
		    data_turbo_p5 <= data_turbo_p1;
	    end
	    else if(enable == 1 && turbo_wr1 == 0 && llse_count >= 1173)
	    begin
 		   addr_turbo_p5 <= addr_turbo_out2; 
	    end
    end

    //读数据的地址产生是
    LLSE_MEM_GEN_0 U_llse_mem_gen_0(
    		.clka(clk),
		   .wea(turbo_wr),
		   .addra(addr_turbo_p3),
		   .dina(data_turbo_p3),
		   .douta(data_in_turbo0)
	);

    LLSE_MEM_GEN_0 U_llse_mem_gen_1(
    		.clka(clk),
		   .wea(turbo_wr0),
		   .addra(addr_turbo_p4),
		   .dina(data_turbo_p4),
		   .douta(data_in_turbo1)
	);

    LLSE_MEM_GEN_0 U_llse_mem_gen_2(
    		.clka(clk),
		   .wea(turbo_wr1),
		   .addra(addr_turbo_p5),
		   .dina(data_turbo_p5),
		   .douta(data_in_turbo2)
	);    

    //当上面的数字信号存储好了之后,我们可以通过计算，turbo编码计算
    //731
	 reg [63:0] turbo0_data_in,turbo1_data_in,turbo2_data_in;
	 always @(posedge clk or negedge rst_n)
	 begin
	       if(rst_n == 0)
			 begin
			    turbo0_data_in <= 0;
				 turbo1_data_in <= 0;
				 turbo2_data_in <= 0;
			 end
			 else if(enable == 1)
			 begin
			    turbo0_data_in <= data_in_turbo0;
				 turbo1_data_in <= data_in_turbo1;
				 turbo2_data_in <= data_in_turbo2;
			 end
	 end
    TURBO_TOP U_turbo0(
	    .enable(enable),
       .clk(clk),
		 .rst(rst_turbo0),
		 .data_in(turbo0_data_in),
		 .data_out(data_turbo_out0),
		 .addr_out(addr_turbo_out0),
		 .we_decode(we_decode0)
   );
	////////////////////////////////////////////////////////////////////
	//打印出llr_all
	////////////////////////////////////////////////////////////////////

   always @(posedge clk or negedge rst_n)
	begin
	    if(rst_n == 0)
       begin 
		      rst_turbo0 <= 0;
       end	
       else if(enable == 1 && llse_count == 734)
       begin
		      rst_turbo0 <= 1;
       end		 
		 else if(enable == 1 && llse_count == 0)
		 begin
		      rst_turbo0 <=  0 ;
		 end
	end
	
   //950
   TURBO_TOP U_turbo1(
   	.clk(clk),
		.enable(enable),
		.rst(rst_turbo1),
		.data_in(turbo1_data_in),
		.data_out(data_turbo_out1),
		.addr_out(addr_turbo_out1),
		.we_decode(we_decode1)
   );
	
	always @(posedge clk or negedge rst_n)
	begin
	    if(rst_n == 0)
       begin 
		      rst_turbo1 <= 0;
       end	
       else if(enable == 1 && llse_count == 954)
       begin
		      rst_turbo1 <= 1;
       end		 
		 else if(enable == 1 && llse_count == 0)
		 begin
		      rst_turbo1 <=  0 ;
		 end
	end
	
   //1170
   TURBO_TOP U_turbo2(
   	.clk(clk),
		.enable(enable),
		.rst(rst_turbo2),
		.data_in(turbo2_data_in),
		.data_out(data_turbo_out2),
		.addr_out(addr_turbo_out2),
		.we_decode(we_decode2)
   );

   always @(posedge clk or negedge rst_n)
	begin
	    if(rst_n == 0)
       begin 
		      rst_turbo2 <= 0;
       end	
       else if(enable == 1 && llse_count == 1174)
       begin
		      rst_turbo2 <= 1;
       end		 
		 else if(enable == 1 && llse_count == 0)
		 begin
		      rst_turbo2 <=  0 ;
		 end
	end
	///////////////////////////////////////////////////////
	
	//第一块数字部分

	always @(posedge clk or negedge rst_n)
	begin
	    if(rst_n == 0)
		 begin
		    we_de0 <= 0;
		 end
		 else if(enable == 1)
		 begin
		    we_de0 <= we_decode0;
		 end
	end
	
   //8873
	always @(posedge clk or negedge rst_n)
	begin
	    if(rst_n == 0)
		 begin
		      data_turbo0 <= 0;
		      data_turbo1 <= 0;
		      data_turbo2 <= 0;
				data_turbo3 <= 0;
		 end
		 else if(we_de0 == 1)
		 begin
		      data_turbo0 <= data_turbo_out0;
		      data_turbo1 <= data_turbo0;
		      data_turbo2 <= data_turbo1;
				data_turbo3 <= data_turbo2;
		 end
	end
	
	//8880
	always @(posedge clk or negedge rst_n)
	begin
	    if(rst_n == 0)
		 begin
		    digital_d0 <= 0;
		 end
		 else if(llse_count == 8880)
		 begin
		   digital_d0 <= {data_turbo3,data_turbo2,data_turbo1,data_turbo0[63:40]};
		 end
	end
	
	//第二块
   always @(posedge clk or negedge rst_n)
	begin
	    if(rst_n == 0)
		 begin
		    we_de1 <= 0;
		 end
		 else if(enable == 1)
		 begin
		    we_de1 <= we_decode1;
		 end
	end
	//9092
	always @(posedge clk or negedge rst_n)
	begin
	     if(rst_n == 0)
		  begin
		       data_turbo4 <= 0;
		       data_turbo5 <= 0;
		       data_turbo6 <= 0;
		       data_turbo7 <= 0;
		  end
		  else if(we_de1 == 1)
		  begin
		       data_turbo4 <= data_turbo_out1;
		       data_turbo5 <= data_turbo4;
		       data_turbo6 <= data_turbo5;
				 data_turbo7 <= data_turbo6;
		  end
	end
	
	//9100
   always @(posedge clk or negedge rst_n)
	begin
	   if(rst_n == 0)
		begin
		   digital_d1 <= 0;
		end
		else if(enable == 1 && llse_count == 9100)
		begin
		   digital_d1 <= {data_turbo7,data_turbo6,data_turbo5,data_turbo4[63:40]};
		end
	end
	
   //第三块
	always @(posedge clk or negedge rst_n)
	begin
	    if(rst_n == 0)
		 begin
		    we_de2 <= 0;
		 end
		 else if(enable == 1)
		 begin
		    we_de2 <= we_decode2;
		 end
	end
	
	//9312
	always @(posedge clk or negedge rst_n)
	begin
	     if(rst_n == 0)
		  begin
		       data_turbo8 <= 0;
		       data_turbo9 <= 0;
		       data_turbo10 <= 0;
		       data_turbo11 <= 0;
		  end
		  else if(we_de2 == 1)
		  begin
		       data_turbo8 <= data_turbo_out2;
		       data_turbo9 <= data_turbo8;
		       data_turbo10 <= data_turbo9;
		       data_turbo11 <= data_turbo10;
		  end
	end
	
	//9320
	always @(posedge clk or negedge rst_n)
	begin
	    if(rst_n == 0)
		 begin
		    digital_d2 <= 0;
		 end
		 else if(enable == 1 && llse_count == 9320)
		 begin
		     digital_d2 <= {data_turbo11,data_turbo10,data_turbo9,data_turbo8[63:40]};
		 end
	end
	//这里进行处理
   //[18 15 14 13 14 15 13 12 13 14 16 12 11 10 10]
   //调用求G的模块
   //8881
   always @(posedge clk or negedge rst_n)
   begin
       case(llse_count)
		   15'd8881:lambda0  <= digital_d0[215:198];     //18
		   15'd8882:lambda0  <= digital_d0[197:183];     //15
		   15'd8883:lambda0  <= digital_d0[182:169];     //14
		   15'd8884:lambda0  <= digital_d0[168:156];     //13
		   15'd8885:lambda0  <= digital_d0[155:142];     //14
		   15'd8886:lambda0  <= digital_d0[141:127];     //15
		   15'd8887:lambda0  <= digital_d0[126:114];     //13
		   15'd8888:lambda0  <= digital_d0[113:102];     //12
		   15'd8889:lambda0  <= digital_d0[101:89];      //13
		   15'd8890:lambda0  <= digital_d0[88:75];       //14
		   15'd8891:lambda0  <= digital_d0[74:59];       //16
		   15'd8892:lambda0  <= digital_d0[58:47];       //12
		   15'd8893:lambda0  <= digital_d0[46:36];       //11
		   15'd8894:lambda0  <= digital_d0[35:26];       //10
		   15'd8895:lambda0  <= digital_d0[25:16];       //10
	     endcase 
   end
	
	//8882
   always @(posedge clk or negedge rst_n)
   begin
	   case(llse_count)
		   15'd8882:lambda1[0] <= lambda0;
		   15'd8883:lambda1[1] <= lambda0;
		   15'd8884:lambda1[2] <= lambda0;
		   15'd8885:lambda1[3] <= lambda0;
		   15'd8886:lambda1[4] <= lambda0;
		   15'd8887:lambda1[5] <= lambda0;
		   15'd8888:lambda1[6] <= lambda0;
		   15'd8889:lambda1[7] <= lambda0;
		   15'd8890:lambda1[8] <= lambda0;
		   15'd8891:lambda1[9] <= lambda0;
		   15'd8892:lambda1[10]<= lambda0;
		   15'd8893:lambda1[11]<= lambda0;
		   15'd8894:lambda1[12]<= lambda0;
		   15'd8895:lambda1[13]<= lambda0;
		   15'd8896:lambda1[14]<= lambda0;
	   endcase
   end
	
	//在调用求解G的模块的时候我们需要对模块进行初始化，这样就能够很好的处理
	//8882
   always @(posedge clk or negedge rst_n)
   begin
	   if(rst_n == 0)
	   begin
		   lambda2G_rst <= 0;
	   end
	   else if(enable == 1 && llse_count>=8881 && llse_count <= 8883+94)
	   begin
         lambda2G_rst <= 1;
	   end
	   else
	   begin
		   lambda2G_rst <= 0;
	   end
   end
	
	assign lambda_data = {6'b0,lambda0};
   //8883
   LAMBDA2G U_lambda2G(
                .clk(clk),
                .rst_N(lambda2G_rst),
                .enable(1'b1),
                .data_in(lambda_data),
    //output
                .sync_o(G_enable),
                .data_out(lambda2G_out)
   );


	
   //8883+78
   always @(posedge clk or negedge rst_n)
   begin
	   if(rst_n == 0)
	   begin
		   gg <= 0;
	   end
	   else if(enable == 1)
	   begin
		   gg <= lambda2G_out;
	   end
   end
	

   //8963
   always @(posedge clk or negedge rst_n)
   begin
	   if(rst_n == 0)
		begin
		   g[0] <= 0; g[1] <= 0;
		   g[2] <= 0; g[3] <= 0;
		   g[4] <= 0; g[5] <= 0;
		   g[6] <= 0; g[7] <= 0;
		   g[8] <= 0; g[9] <= 0;
		   g[10] <= 0; g[11] <= 0;
		   g[12] <= 0; g[13] <= 0;
		   g[14] <= 0; 
		end
		else if(llse_count == 8963)
		begin
		   g[0]<= gg;
		end
	   else if(llse_count == 8964)
		begin
		   g[1]<= gg;
		end
		else if(llse_count == 8965)
		begin
		   g[2]<= gg;
		end
		else if(llse_count == 8966)
		begin
		   g[3]<= gg;
		end
		else if(llse_count == 8967)
		begin
		   g[4]<= gg;
		end
		else if(llse_count == 8968)
		begin
		   g[5]<= gg;
		end
		else if(llse_count == 8969)
		begin
		   g[6]<= gg;
		end
		else if(llse_count == 8970)
		begin
		   g[7]<= gg;
		end
		else if(llse_count == 8971)
		begin
		   g[8]<= gg;
		end
		else if(llse_count == 8972)
		begin
		   g[9]<= gg;
		end
		else if(llse_count == 8973)
		begin
		   g[10]<= gg;
		end
		else if(llse_count == 8974)
		begin
		   g[11]<= gg;
		end
		else if(llse_count == 8975)
		begin
		   g[12]<= gg;
		end
		else if(llse_count == 8976)
		begin
		   g[13]<= gg;
		end
		else if(llse_count == 8977)
		begin
		   g[14]<= gg;
		end
   end
	
	//计算获取LLSE的值
	//8964
	always @(posedge clk or negedge rst_n)
	begin
	   if(rst_n == 0)
		begin
		    sigma_count <= 0;
		end
		else if(enable == 1 && llse_count == 8964)
		begin
		    sigma_count <= 0;
		end
		else if(enable == 1 && sigma_count == 14)
		begin
		    sigma_count <= 0;
		end
		else if(enable == 1)
		begin
		    sigma_count <= sigma_count + 1;
		end
	end
	//8964
	assign gg0 = g[sigma_count];
	assign ll0 = lambda1[sigma_count];
	assign sigma = 32;
	
   //8965
	always @(posedge clk or negedge rst_n)
	begin
	    if(rst_n == 0)
		 begin
		     mutlgl <= 0;
		 end
		 else if(enable == 1)
		 begin
		    mutlgl <= gg0 * ll0;   // Q.16*Q18.0
		 end
	end
	//8965
	always @(posedge clk or negedge rst_n)
	begin
	   if(rst_n == 0)
		begin
		   gg1 <= 0;
		end
		else if(enable == 1)
		begin
		   gg1 <= gg0;
		end
	end
	//8966
	always @(posedge clk or negedge rst_n)
	begin
	   if(rst_n == 0)
		begin
		     mutlgl0 <= 0;
			  mutlgl1 <= 0;
		end
		else if(enable == 1)
		begin
		     mutlgl0 <= mutlgl;
			  mutlgl1 <= mutlgl * gg1; //这里16bit * 34bit,50 bit
		end
	end
	//8966
   assign mutlgl2 = (mutlgl1+16'h8000)>>16; //截位处理 34bit
	assign sigma1 = sigma * sigma;
	
	//8967
	always @(posedge clk or negedge rst_n)
	begin
	    if(rst_n == 0)
		 begin
		    divide_input1 <= 0;
			 divide_input2 <= 0;
		 end
		 else if(enable == 1)
		 begin
		   divide_input1 <=sigma1 + mutlgl2; //35 + 19 = 54
			divide_input2 <= {{2{mutlgl0[33]}},mutlgl0} * 262144;  //2^18;18+36=54,
		 end
	end
	//8968
    DIVIDER_TOP34 U_divider34(
	       .input1(divide_input1),
	       .input2(divide_input2),
	       .clk(clk),
	       .out(divider_output1)
      );
		
	
	//9024
	always @(posedge clk or negedge rst_n)
	begin
	     case(llse_count)
		     15'd9024:llse[0] <= divider_output1[29:12] + (divider_output1[11]?1:0);
		     15'd9025:llse[1] <= divider_output1[29:12] + (divider_output1[11]?1:0);
		     15'd9026:llse[2] <= divider_output1[29:12] + (divider_output1[11]?1:0);
		     15'd9027:llse[3] <= divider_output1[29:12] + (divider_output1[11]?1:0);
		     15'd9028:llse[4] <= divider_output1[29:12] + (divider_output1[11]?1:0);
		     15'd9029:llse[5] <= divider_output1[29:12] + (divider_output1[11]?1:0);
		     15'd9030:llse[6] <= divider_output1[29:12] + (divider_output1[11]?1:0);
		     15'd9031:llse[7] <= divider_output1[29:12] + (divider_output1[11]?1:0);
		     15'd9032:llse[8] <= divider_output1[29:12] + (divider_output1[11]?1:0);
		     15'd9033:llse[9] <= divider_output1[29:12] + (divider_output1[11]?1:0);
		     15'd9034:llse[10] <= divider_output1[29:12] + (divider_output1[11]?1:0);
		     15'd9035:llse[11] <= divider_output1[29:12] + (divider_output1[11]?1:0);
		     15'd9036:llse[12] <= divider_output1[29:12] + (divider_output1[11]?1:0);
		     15'd9037:llse[13] <= divider_output1[29:12] + (divider_output1[11]?1:0);
		     15'd9038:llse[14] <= divider_output1[29:12] + (divider_output1[11]?1:0);
		  endcase
	end
	
	//9321
	always @(posedge clk or negedge rst_n)
	begin
	    case(llse_count)
		     15'd9321:dc[0] <= digital_d1[215:203];
			  15'd9322:dc[1] <= digital_d1[202:190];
		     15'd9323:dc[2] <= digital_d1[189:177];
		     15'd9324:dc[3] <= digital_d1[176:164];
		     15'd9325:dc[4] <= digital_d1[163:151];
		     15'd9326:dc[5] <= digital_d1[150:138];
		     15'd9327:dc[6] <= digital_d1[137:125];
		     15'd9328:dc[7] <= digital_d1[124:112];
		     15'd9329:dc[8] <= digital_d1[111:99];
		     15'd9330:dc[9]  <= digital_d1[98:86];
		     15'd9331:dc[10] <= digital_d1[85:83];
		     15'd9332:dc[11] <= digital_d1[82:70];
		     15'd9333:dc[12] <= digital_d1[69:57];
		     15'd9334:dc[13] <= digital_d1[56:44];
		     15'd9335:dc[14] <= digital_d1[43:31];
		     15'd9336:dc[15] <= digital_d1[30:18];
		     15'd9337:dc[16] <= {{digital_d1[17:16]},{digital_d2[215:195]}};
		     15'd9338:dc[17] <= digital_d2[194:182];
		     15'd9339:dc[18] <= digital_d2[181:169];
		     15'd9340:dc[19] <= digital_d2[168:156];
		     15'd9341:dc[20] <= digital_d2[155:143];
		     15'd9342:dc[21] <= digital_d2[142:130];
		     15'd9343:dc[22] <= digital_d2[129:117];
		     15'd9344:dc[23] <= digital_d2[116:104];
		     15'd9345:dc[24] <= digital_d2[103:91];
		     15'd9346:dc[25] <= digital_d2[90:78];
		     15'd9347:dc[26] <= digital_d2[77:65];
		     15'd9348:dc[27] <= digital_d2[64:52];
		     15'd9349:dc[28] <= digital_d2[51:39];
		     15'd9350:dc[29] <= digital_d2[38:26];
		 endcase
	end
	
	
   always @(posedge clk or negedge rst_n)
	begin
	     if(rst_n == 0)
		  begin
		     llse0[0] <= 0;  llse0[1] <= 0; 
		     llse0[2] <= 0;  llse0[3] <= 0; 
		     llse0[4] <= 0;  llse0[5] <= 0;  
		     llse0[6] <= 0;  llse0[7] <= 0;  
		     llse0[8] <= 0;  llse0[9] <= 0;  
		     llse0[10]<= 0;  llse0[11] <= 0;  
		     llse0[12]<= 0;  llse0[13] <= 0;  
		     llse0[14]<= 0;  
		  end
		  else if(llse_count == 495)
		  begin
		     llse0[0] <= llse[0];   llse0[1] <= llse[1];
		     llse0[2] <= llse[2];   llse0[3] <= llse[3];
		     llse0[4] <= llse[4];   llse0[5] <= llse[5];
		     llse0[6] <= llse[6];   llse0[7] <= llse[7];
		     llse0[8] <= llse[8];   llse0[9] <= llse[9];
		     llse0[10] <= llse[10]; llse0[11]<= llse[11];
		     llse0[12] <= llse[12]; llse0[13]<= llse[13];
		     llse0[14] <= llse[14];
		  end
	end
  
   always @(posedge clk or negedge rst_n)
	begin
	     if(rst_n == 0)
		  begin
		     dc0[0] <= 0; dc0[1] <= 0;
		     dc0[2] <= 0; dc0[3] <= 0;
		     dc0[4] <= 0; dc0[5] <= 0;
		     dc0[6] <= 0; dc0[7] <= 0;
		     dc0[8] <= 0; dc0[9] <= 0;
		     dc0[10] <= 0;dc0[11] <= 0;
		     dc0[12] <= 0;dc0[13] <= 0;
		     dc0[12] <= 0;dc0[13] <= 0;
		     dc0[14] <= 0;dc0[15] <= 0;
		     dc0[16] <= 0;dc0[17] <= 0;
		     dc0[18] <= 0;dc0[19] <= 0;
		     dc0[20] <= 0;dc0[21] <= 0;
		     dc0[22] <= 0;dc0[23] <= 0;
		     dc0[24] <= 0;dc0[25] <= 0;
		     dc0[26] <= 0;dc0[27] <= 0;
		     dc0[28] <= 0;dc0[29] <= 0;		  
		  end
		  else if(llse_count == 495)
		  begin
		     dc0[0]  <= dc[0];   dc0[1]  <= dc[1];
		     dc0[2]  <= dc[2];   dc0[3]  <= dc[3];
		     dc0[4]  <= dc[4];   dc0[5]  <= dc[5];
		     dc0[6]  <= dc[6];   dc0[7]  <= dc[7];
		     dc0[8]  <= dc[8];   dc0[9]  <= dc[9];
		     dc0[10] <= dc[10];  dc0[11] <= dc[11];
		     dc0[12] <= dc[12];  dc0[13] <= dc[13];
		     dc0[14] <= dc[14];  dc0[15] <= dc[15];
		     dc0[16] <= dc[16];  dc0[17] <= dc[17];
		     dc0[18] <= dc[18];  dc0[19] <= dc[19];
		     dc0[20] <= dc[20];  dc0[21] <= dc[21];
		     dc0[22] <= dc[22];  dc0[23] <= dc[23];
		     dc0[24] <= dc[24];  dc0[25] <= dc[25];
		     dc0[26] <= dc[26];  dc0[27] <= dc[27];
		     dc0[28] <= dc[28];  dc0[29] <= dc[29];
		  end
	end

	//496
	wire [3:0] doutaL;
	wire [3:0] doutbL;
	wire [9:0] doutaL_addra;
	wire [9:0] doutbL_addrb;
	
	assign doutaL_addra = {analog_count0[8:0],1'b0};
	assign doutbL_addrb = {analog_count0[8:0],1'b1};
	
	DUALROMLL U_dualromll (
         .clka(clk), // input clka
         .addra(doutaL_addra), // input [9 : 0] addra
         .douta(doutaL), // output [15 : 0] douta
			.clkb(clk),
			.addrb(doutbL_addrb),
			.doutb(doutbL)
    ); 
	 
	//497
	always @(posedge clk or negedge rst_n) 
	begin
	   case(doutaL)
		     4'd0: select_llse0 <= 0;
			  4'd1: select_llse0 <= llse0[0];
			  4'd2: select_llse0 <= llse0[1];
			  4'd3: select_llse0 <= llse0[2];
			  4'd4: select_llse0 <= llse0[3];
			  4'd5: select_llse0 <= llse0[4];
			  4'd6: select_llse0 <= llse0[5];
			  4'd7: select_llse0 <= llse0[6];
			  4'd8: select_llse0 <= llse0[7];
			  4'd9: select_llse0 <= llse0[8];
			  4'd10:select_llse0 <= llse0[9];
			  4'd11:select_llse0 <= llse0[10];
			  4'd12:select_llse0 <= llse0[11];
			  4'd13:select_llse0 <= llse0[12];
			  4'd14:select_llse0 <= llse0[13];
			  4'd15:select_llse0 <= llse0[14];
   	 endcase
	end
	//497
	always @(posedge clk or negedge rst_n) 
	begin
	   case(doutbL)
		     4'd0: select_llse1  <= 0;
			  4'd1: select_llse1  <= llse0[0];
			  4'd2: select_llse1  <= llse0[1];
			  4'd3: select_llse1  <= llse0[2];
			  4'd4: select_llse1  <= llse0[3];
			  4'd5: select_llse1  <= llse0[4];
			  4'd6: select_llse1  <= llse0[5];
			  4'd7: select_llse1  <= llse0[6];
			  4'd8: select_llse1  <= llse0[7];
			  4'd9: select_llse1  <= llse0[8];
			  4'd10:select_llse1  <= llse0[9];
			  4'd11:select_llse1  <= llse0[10];
			  4'd12:select_llse1  <= llse0[11];
			  4'd13:select_llse1  <= llse0[12];
			  4'd14:select_llse1  <= llse0[13];
			  4'd15:select_llse1  <= llse0[14];
   	 endcase
	end
	//498
	always @(posedge clk or negedge rst_n)
	begin
	   if(rst_n == 0)
		begin
		     select_llse2 <= 0;
		end
		else if(enable == 1)
		begin
		     select_llse2 <= select_llse0;
		end
	end
	
	//498
	always @(posedge clk or negedge rst_n)
	begin
	   if(rst_n == 0)
		begin
		     select_llse3 <= 0;
		end
		else if(enable == 1)
		begin
		     select_llse3 <= select_llse1;
		end
	end
	
   //这里对于所求
   /////////////////////////////////
   //模拟信号的输出
   //495，这里表示的是模拟信号，开始过来进行存储
   reg analog_wr0;
	
   //495~(496+15360)
   always @(posedge clk or negedge rst_n)
   begin
	   if(rst_n == 0)
	   begin
		      analog_count0 <= 0;
	   end
	   else if(llse_count == 495)
	   begin
            analog_count0 <= 0;
	   end
	   else 
	   begin
		      analog_count0 <= analog_count0 + 1;
	   end
   end
   //这里实现乒乓存储
   //496
   always @(posedge clk or negedge rst_n)
   begin
	   if(rst_n == 0)
	   begin
		      analog_data <= 0;
	   end
	   else if(enable == 1)
	   begin
		      analog_data <= frame_analog_data;
	   end
   end
	
   //495
   always @(posedge clk or negedge rst_n)
   begin
	   if(rst_n == 0)
	   begin
             analog_wr <= 1;
	   end
	   else if(analog_count0 == 15359)
	   begin
	       	analog_wr <= ~analog_wr;
	   end
   end
	
	//496
	always @(posedge clk or negedge rst_n)
	begin
	     if(rst_n == 0)
		  begin
		      analog_wr0 <= 1;
		  end
		  else
		  begin
		     analog_wr0 <= analog_wr;
		  end
	end
   reg enable1;
   always @(posedge clk or negedge rst_n)
	begin
	    enable1 <= enable;
	end
  //497
   always @(posedge clk or negedge rst_n)
   begin
	   if(rst_n == 0)
	   begin
		   addr_analog_p <=  0;
		   data_analog_p <= 0;
	   end
	   else if(enable1 == 1 && analog_wr == 1)
	   begin
          addr_analog_p <= analog_count0;
          data_analog_p <= analog_data;
	   end
	   else if(enable1 == 1 && analog_wr == 0)
	   begin
          addr_analog_p <= analog_count0;
	   end
   end

   //497
   always @(posedge clk or negedge rst_n)
   begin
	   if(rst_n == 0)
	   begin
		      addr_analog_q <= 0;
		      data_analog_q <= 0;
	   end
	   else if(enable1 == 1 && analog_wr == 0)
	   begin
		       addr_analog_q <= analog_count0;
             data_analog_q <= analog_data;
	   end
	   else if(enable1 == 1 && analog_wr == 1)
	   begin
             addr_analog_q <= analog_count0;
	   end
   end

   //498
   DIST_LLSE_MEM U_RAM_P(
         .clka(clk),
	      .wea(analog_wr0),
	      .addra(addr_analog_p),
	      .dina(data_analog_p),
	      .douta(data_analog_out_p)
      );
    
	 DIST_LLSE_MEM U_RAM_Q(
   	   .clka(clk),
	      .wea(~analog_wr0),
	      .addra(addr_analog_q),
	      .dina(data_analog_q),
	      .douta(data_analog_out_q)
   );
	
  //498
  assign data_out_analog = (analog_wr0)?data_analog_out_q:data_analog_out_p;
  
  reg [14:0] dc_count;
  reg [14:0] dc_count0;
  reg [14:0] dc_count1;
  wire [4:0] dc_count_d;
  
  
  //497
  always @(posedge clk or negedge rst_n)
  begin
     if(rst_n == 0)
	  begin
	     dc_count <= 0;
	  end
	  else 
	  begin
	     dc_count <= analog_count0 ;
	  end
  end
  
  //498
  always @(posedge clk or negedge rst_n)
  begin
     if(rst_n == 0)
	  begin
	      dc_count0 <= 0;
	  end
	  else
	  begin
         dc_count0 <= dc_count;
	  end
  end
  
  //499
  always @(posedge clk or negedge rst_n)
  begin
     if(rst_n == 0)
	  begin
	     dc_count1 <= 0; 
	  end
	  else if(enable == 1)
	  begin 
	     dc_count1 <= dc_count0; 
	  end 
  end
//  assign dc_count = analog_count[14:9];
  
  assign data_out00 = data_out_analog[31:16];
  assign data_out01 = data_out_analog[15:0];
  //499
  always @(posedge clk or negedge rst_n)
  begin
      if(rst_n == 0)
		begin
		    data_out0 <= 0;
			 data_out1 <= 0;
		end
		else
		begin
		    data_out0 <= data_out00 * $signed(select_llse0); //16 * 18 = 34
		    data_out1 <= data_out01 * $signed(select_llse1);
		end
  end

  //500, 22-->16
  assign data_out2 = (data_out0+2'b10)>>2;
  assign data_out3 = (data_out1+2'b10)>>2;
  
  
  assign dc_count_d = dc_count1[14:0];
 
 //500
  always @(posedge clk or negedge rst_n)
  begin
     if(rst_n == 0)
	  begin
	     data_out4 <= 0;
	  end
	  else if(dc_count1[8:0] == 0)
	  begin
	     data_out4 <= {{19'b0,dc0[dc_count_d]}};
	  end
	  else 
	  begin
	    data_out4 <= data_out2;
	  end
  end
  
  //500
  always @(posedge clk or negedge rst_n)
  begin
     if(rst_n == 0)
	  begin
	    data_out5 <= 0;
	  end
	  else
	  begin
	    data_out5 <= data_out3;
	  end
  end
  
  assign data_out_dct = {data_out4,data_out5};
  
  /////////////////////////////////////////////////////////////////
  //输出控制信号、同步信号
  reg temp_sync;
  reg temp_sync0;
  reg temp_sync1;
  reg temp_sync2;
  reg [14:0] llse_count0;
  reg [14:0] llse_count1;
  always @(posedge clk or negedge rst_n)
  begin
		if(rst_n == 0)
		begin
			llse_count0 <= 0;
		end
		else if(enable == 1 &&llse_count0==15854)
		begin
		   llse_count0 <= 0;
		end
		else if(enable == 1)
		begin
		   llse_count0 <= llse_count0 + 1;
		end
  end
  always @(posedge clk or negedge rst_n)
  begin
     if(rst_n == 0)
	  begin
	       temp_sync <= 0;
	  end
	  else if(enable == 1 && llse_count0 == 498)
	  begin
	       temp_sync <= 1;
	  end
  end
  
  always @(posedge clk or negedge rst_n)
  begin
     if(rst_n == 0)
	  begin
			 temp_sync0 <= 0;
	  end
	  else if(enable == 1 && llse_count0 == 498 && temp_sync == 1)
	  begin
	       temp_sync0 <= 1;
	  end
	  else if(enable == 0)
	  begin
	       temp_sync0 <= 0;
	  end
  end
  
  assign enable_o =  temp_sync0;
  
  
  always @(posedge clk or negedge rst_n)
  begin
		if(rst_n == 0)
		begin
			llse_count1 <= 0;
		end
		else if(input_line_sync == 1)
		begin
		   llse_count1 <= 0;
		end
		else if(enable == 1 &&llse_count1==15854)
		begin
		   llse_count1 <= 0;
		end
		else if(enable == 1)
		begin
		   llse_count1 <= llse_count1 + 1;
		end
  end
  
  always @(posedge clk or negedge rst_n)
  begin
     if(rst_n == 0)
	  begin
	       temp_sync2 <= 0;
	  end
	  else if(enable == 1 && llse_count1 == 498)
	  begin
	       temp_sync2 <= 1;
	  end
  end
  
  always@(posedge clk or negedge rst_n)
  begin
     if(rst_n == 0)
	  begin
			 temp_sync1 <= 0;
	  end
	  else if(enable == 1 && llse_count1 == 498 && temp_sync2 == 1)
	  begin
	       temp_sync1 <= 1;
	  end
	  else 
	  begin
	      temp_sync1 <= 0;
	  end
  end 
  
  assign output_line_sync = temp_sync1;
  
endmodule
