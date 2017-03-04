`resetall
`timescale 1ns/1ps

module FFT_1024_tb(
       rst,
		 rst_clk,
       enable,
       SYSCLK_P,
       SYSCLK_N
);
  
  input         rst;            //rst 0有效
  input         enable;    //enable 1有 效
  input         SYSCLK_P;
  input         SYSCLK_N;
  input         rst_clk;
 
  reg            cen;
  (* KEEP = "true"*)  wire[31:0]  data_out;
  wire[31:0]          data_out_out;
  (* KEEP = "true"*)   wire[31:0]  data_in;
  (* KEEP = "true"*)   reg[11:0]      addr_p;
  wire[11:0]  addr;
  (* KEEP = "true"*)   wire      sync_o;
 
 wire          clk;
 
////////////////////////////////////////////////////

/////////////////////////////////////////////////// 
	//对时钟进行分频

  FractionalFreq Fraction(
	    .CLK_IN1_P(SYSCLK_P),    // Clock in ports
       .CLK_IN1_N(SYSCLK_N),    // Clock out ports
       .CLK_OUT1(clk),
       .RESET(!rst_clk)
	);


	   FFT_1024_top fft(
          .clk(clk),
          .rst(rst),
          .enable(enable),
          .data_in(data_in),
          .sync_o(sync_o),
          .data_out(data_out)
    );
	 
	 dist_mem_gen_1 realdata (
	 .clka(clk),          // input clka
	 .ena(cen),           // input ena
	 .wea(1'b0),          // input [0 : 0] wea
	 .addra(addr),        // input [9 : 0] addra
	 .dina(data_out_out), // input [31 : 0] dina
	 .douta(data_in)      // output [31 : 0] douta
);
    
	 /*
    dist_mem_gen_1 realdata(
              .clk(clk),
              .i_ce(cen),
              .we(1'b0),
              .a(addr),
              .d(data_out_out),
              .spo(data_in));
     */
    assign addr = addr_p;
    
    always @(posedge clk or negedge rst)
    begin
       if(!rst)
         cen<=0;
       else
         cen<=1;
    end
    
    always @(posedge clk or negedge rst)
    begin
        if(!rst)
           addr_p <= 0;
        else if(enable == 1'b1)
           addr_p <= addr_p+1;
    end
	 
  endmodule