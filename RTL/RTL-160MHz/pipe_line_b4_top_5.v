/*
*
	*@Author:Yao
	*@Time :2016年3月2日11:01:36
	*@brief：FFT pipe_line_b4_top_2
*/

`resetall
`timescale 1ns/1ps
module pipe_line_b4_top_5(clk,
                        rst,
                        enable,
                        data_in,
                        omega_in,
                        data_out);
  
  parameter WORDLENGTH_IO = 16,
            WORDLENGTH_WP = 9;
  
  input clk,rst;

  input enable;
  input [(WORDLENGTH_IO<<1)-1:0] data_in;
  input [(WORDLENGTH_WP<<1)-1:0] omega_in;
  
  output[(WORDLENGTH_IO<<1)-1:0] data_out;
  reg [1:0] counter;
  
  reg [(WORDLENGTH_IO<<1)-1:0] data_out_1;
  reg [(WORDLENGTH_IO<<1)-1:0] data_out_2;
  reg [(WORDLENGTH_IO<<1)-1:0] data_out_3;
  reg [(WORDLENGTH_IO<<1)-1:0] data_out_4;
 
  always @ (posedge clk or negedge rst)
  begin
     if (!rst)
     begin
      counter <= 1;
    end
  else if(enable == 1'b1)
    begin
       counter <= counter+1;
    end
 end	 
  
  
  wire  [(WORDLENGTH_IO<<1)-1:0] data_out_00,
                                 data_out_01,
                                 data_out_02,
                                 data_out_03;

                                 
  wire  [(WORDLENGTH_WP<<1)-1:0] omega_out_00,
                                 omega_out_01,
                                 omega_out_02,
                                 omega_out_03;

                                 
  s4p1_5 #(WORDLENGTH_IO<<1) s4pd1(.clk(clk),
                                 .rst(rst),
                                 .enable(enable),
                                 .counter(counter),
                                 .data_in(data_in),
                                 .data_out0(data_out_00),
                                 .data_out1(data_out_01),
                                 .data_out2(data_out_02),
                                 .data_out3(data_out_03));
 
  s4p1_5 #(WORDLENGTH_WP<<1) s4pw1(.clk(clk),
                                 .rst(rst),
                                 .enable(enable),
											.counter(counter),
                                 .data_in(omega_in),
                                 .data_out0(omega_out_00),
                                 .data_out1(omega_out_01),
                                 .data_out2(omega_out_02),
                                 .data_out3(omega_out_03));
           
  wire [WORDLENGTH_IO-1:0] ar,ai,br,bi,cr,ci,dr,di;
  wire [WORDLENGTH_IO-1:0] er,ei,fr,fi,gr,gi,hr,hi;
  wire [WORDLENGTH_WP-1:0] w0r,w0i,w1r,w1i,w2r,w2i,w3r,w3i;

  //取四个数
  assign ar=data_out_03[(WORDLENGTH_IO<<1)-1:WORDLENGTH_IO];
  assign br=data_out_02[(WORDLENGTH_IO<<1)-1:WORDLENGTH_IO];
  assign cr=data_out_01[(WORDLENGTH_IO<<1)-1:WORDLENGTH_IO];
  assign dr=data_out_00[(WORDLENGTH_IO<<1)-1:WORDLENGTH_IO];
  assign ai=data_out_03[WORDLENGTH_IO-1:0];
  assign bi=data_out_02[WORDLENGTH_IO-1:0];
  assign ci=data_out_01[WORDLENGTH_IO-1:0];
  assign di=data_out_00[WORDLENGTH_IO-1:0];
  //取四个旋转因子
  assign w0r=omega_out_03[(WORDLENGTH_WP<<1)-1:WORDLENGTH_WP];
  assign w1r=omega_out_02[(WORDLENGTH_WP<<1)-1:WORDLENGTH_WP];
  assign w2r=omega_out_01[(WORDLENGTH_WP<<1)-1:WORDLENGTH_WP];
  assign w3r=omega_out_00[(WORDLENGTH_WP<<1)-1:WORDLENGTH_WP];
  assign w0i=omega_out_03[WORDLENGTH_WP-1:0];
  assign w1i=omega_out_02[WORDLENGTH_WP-1:0];
  assign w2i=omega_out_01[WORDLENGTH_WP-1:0];
  assign w3i=omega_out_00[WORDLENGTH_WP-1:0];
  
  b4_unit_david b4_u(.clk(clk),.ena(clk_4),
                     .rst(rst),.enable(enable),
                     .ar(ar),.ai(ai),
                     .br(br),.bi(bi),
                     .cr(cr),.ci(ci),
                     .dr(dr),.di(di),
                     .w1pr(w1r),.w1pi(w1i),
                     .w2pr(w2r),.w2pi(w2i),
                     .w3pr(w3r),.w3pi(w3i),
                     .er(er),.ei(ei),
                     .fr(fr),.fi(fi),
                     .gr(gr),.gi(gi),
                     .hr(hr),.hi(hi));
always @(posedge clk or negedge rst)
begin
   if(!rst)
	begin
      data_out_1 <= 0;
      data_out_2 <= 0;
      data_out_3 <= 0;
      data_out_4 <= 0;
	end
   else if(enable == 1)
    begin
	   if(counter==0) 
		   begin
		     data_out_1 <= {er,ei};
	        data_out_2 <= {fr,fi};
	        data_out_3 <= {gr,gi};
	        data_out_4 <= {hr,hi};
			 end
    end	 
end


assign data_out=(counter==0)?{er,ei}:
                  ((counter==1)?{data_out_2}:
                  ((counter==2)?{data_out_3}:{data_out_4}));

endmodule


