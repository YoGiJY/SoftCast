//
// FFT-1024串入并出模块
//
`resetall
`timescale 1ns/1ps
module s4p1_3(clk,
            rst,
            enable,
            counter,
            data_in,
            data_out0,
            data_out1,
            data_out2,
            data_out3);
  
  parameter WORDLENGTH=16;
  input clk,rst;
  input [1:0]counter;
  input enable;
  input [WORDLENGTH-1:0] data_in;
  
  output[WORDLENGTH-1:0] data_out0,
                         data_out1,
                         data_out2,
                         data_out3;
                         
  reg   [WORDLENGTH-1:0] data_out0,
                         data_out1,
                         data_out2,
                         data_out3;
                         
  reg   [WORDLENGTH-1:0] data0,
                         data1,
                         data2,
                         data3;

  
  always @ (posedge clk or negedge rst)
  begin
    if (!rst) 
	 begin
     data0<=0;
     data1<=0;
     data2<=0;
     data3<=0;
    end
    else if (enable == 1'b1) 
	 begin
      data0<=data_in;  //这里传送过来6个数据
		data1<=data0;
      data2<=data1;
      data3<=data2;
    end
	end


 always @ (posedge clk or negedge rst)
begin
  if (!rst) begin
    data_out0<=0;
    data_out1<=0;
    data_out2<=0;
    data_out3<=0;
  end
  else if(enable == 1'b1 && counter==3) 
  begin
    data_out0<=data0;
    data_out1<=data1;
    data_out2<=data2;
    data_out3<=data3;
  end
end

endmodule


