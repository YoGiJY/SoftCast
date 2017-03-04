
`resetall
`timescale 1ns/1ps
module b4_unit_david (
                      clk,
							 rst,
							 ena,
							 enable,
                      ar,ai,
                      br,bi,
                      cr,ci,
                      dr,di,
                      w1pr,w1pi,
                      w2pr,w2pi,
                      w3pr,w3pi,
                      er,ei,
                      fr,fi,
                      gr,gi,
                      hr,hi);
  
  parameter 
  WORDLENGTH_IO = 16,
  WORDLENGTH_WP = 9; //旋转因子的长度
  
  input clk;
  input rst;
  input enable;
  input ena;
  input [WORDLENGTH_IO-1:0] 
  ar,ai,
  br,bi,
  cr,ci,
  dr,di;
  input [WORDLENGTH_WP-1:0]
  w1pr,w1pi,
  w2pr,w2pi,                       
  w3pr,w3pi; 
  
  output [WORDLENGTH_IO-1:0]   
  er,ei,
  fr,fi,
  gr,gi,            
  hr,hi;
  
  reg [WORDLENGTH_IO+WORDLENGTH_WP-1:0] 
  arw0pr,aiw0pi,
  brw1pr,biw1pi,
  crw2pr,ciw2pi,
  drw3pr,diw3pi,
  brw1pi,biw1pr,
  crw2pi,ciw2pr,
  drw3pi,diw3pr;
 
  wire [WORDLENGTH_IO-1:0] 
  ar1,ai1,
  br1,bi1,
  cr1,ci1,
  dr1,di1;
  
  wire [WORDLENGTH_WP-1:0]
  w0pr, w0pi,
  w1pr1,w1pi1,
  w2pr1,w2pi1,                       
  w3pr1,w3pi1;
  
  reg [WORDLENGTH_IO+WORDLENGTH_WP-1:0]   
  mer,mei,
  mfr,mfi,
  mgr,mgi,            
  mhr,mhi;
  
  reg [WORDLENGTH_IO+WORDLENGTH_WP-1:0]   
  mer1,mei1,
  mfr1,mfi1,
  mgr1,mgi1,            
  mhr1,mhi1;
  
  reg [WORDLENGTH_IO+WORDLENGTH_WP-1:0]   
  mer2,mei2,
  mfr2,mfi2,
  mgr2,mgi2,            
  mhr2,mhi2;
  
  reg [WORDLENGTH_IO+WORDLENGTH_WP-1:0]   
  mer3,mei3,
  mfr3,mfi3,
  mgr3,mgi3,            
  mhr3,mhi3;

  /*
  assign ar1 = $signed(ar), w0pr = 256;
  assign ai1 = $signed(ai), w0pi = 256;
  assign br1 = $signed(br), bi1 = $signed(bi);
  assign cr1 = $signed(cr), ci1 = $signed(ci);
  assign dr1 = $signed(dr), di1 = $signed(di);
  assign w1pr1 = $signed(w1pr), w1pi1 = $signed(w1pi);
  assign w2pr1 = $signed(w2pr), w2pi1 = $signed(w2pi);                       
  assign w3pr1 = $signed(w3pr), w3pi1 = $signed(w3pi); 
  
  // $signed(ar)*256
  multiply mutl12(
  .clk(clk),
  .rst(rst),
  .a(ar1),
  .b(w0pr),
  .p(arw0pr)
  );  
  // $signed(ai)*256
  multiply mutl13(
  .clk(clk),
  .rst(rst),
  .a(ai1),
  .b(w0pi),
  .p(aiw0pi)
  );  
  // brw1pr <= $signed(br)*$signed(w1pr);
  multiply mutl0(
  .clk(clk),
  .rst(rst),
  .a(br1),
  .b(w1pr1),
  .p(brw1pr)
  );
  // biw1pi <= $signed(bi)*$signed(w1pi);
  multiply mutl1(
  .clk(clk),
  .rst(rst),
  .a(bi1),
  .b(w1pi1),
  .p(biw1pi)
  );
  // crw2pr <= $signed(cr)*$signed(w2pr);
  multiply mutl2(
  .clk(clk),
  .rst(rst),
  .a(cr1),
  .b(w2pr1),
  .p(crw2pr)
  );
  // ciw2pi <= $signed(ci)*$signed(w2pi);
  multiply mutl3(
  .clk(clk),
  .rst(rst),
  .a(ci1),
  .b(w2pi1),
  .p(ciw2pi)
  );
  // drw3pr <= $signed(dr)*$signed(w3pr);
  multiply mutl4(
  .clk(clk),
  .rst(rst),
  .a(dr1),
  .b(w3pr1),
  .p(drw3pr)
  );
  //	diw3pi <= $signed(di)*$signed(w3pi);
  multiply mutl5(
  .clk(clk),
  .rst(rst),
  .a(di1),
  .b(w3pi1),
  .p(diw3pi)
  );
  //   brw1pi <= $signed(br)*$signed(w1pi);
  multiply mutl6(
  .clk(clk),
  .rst(rst),
  .a(br1),
  .b(w1pi1),
  .p(brw1pi)
  );
  //	biw1pr <= $signed(bi)*$signed(w1pr);
  multiply mutl7(
  .clk(clk),
  .rst(rst),
  .a(bi1),
  .b(w1pr1),
  .p(biw1pr)
  );     
  //  crw2pi <= $signed(cr)*$signed(w2pi);
  multiply mutl8(
  .clk(clk),
  .rst(rst),
  .a(cr1),
  .b(w2pi1),
  .p(crw2pi)
  );
  //	ciw2pr <= $signed(ci)*$signed(w2pr);
  multiply mutl9(
  .clk(clk),
  .rst(rst),
  .a(ci1),
  .b(w2pr1),
  .p(ciw2pr)
  );
  //   drw3pi <= $signed(dr)*$signed(w3pi);
  multiply mutl10(
  .clk(clk),
  .rst(rst),
  .a(dr1),
  .b(w3pi1),
  .p(drw3pi)
  );
 //   diw3pr <= $signed(di)*$signed(w3pr);
  multiply mutl11(
  .clk(clk),
  .rst(rst),
  .a(di1),
  .b(w3pr1),
  .p(diw3pr)
  );  
 */
 
 always @(posedge clk or negedge rst)
  begin
   if(!rst)
    begin
	   arw0pr <= 0;aiw0pi <= 0;
	   brw1pr <= 0;biw1pi <= 0;
      crw2pr <= 0;ciw2pi <= 0;
      drw3pr <= 0;diw3pi <= 0;
	   brw1pi <= 0;biw1pr <= 0;
      crw2pi <= 0;ciw2pr <= 0;
      drw3pi <= 0;diw3pr <= 0;
	 end
	else if(enable==1)
	 begin
	   arw0pr <= $signed(ar)*256;
		aiw0pi <= $signed(ai)*256;
	   brw1pr <= $signed(br)*$signed(w1pr);
		biw1pi <= $signed(bi)*$signed(w1pi);
      crw2pr <= $signed(cr)*$signed(w2pr);
		ciw2pi <= $signed(ci)*$signed(w2pi);
      drw3pr <= $signed(dr)*$signed(w3pr);
		diw3pi <= $signed(di)*$signed(w3pi);
	   brw1pi <= $signed(br)*$signed(w1pi);
		biw1pr <= $signed(bi)*$signed(w1pr);
      crw2pi <= $signed(cr)*$signed(w2pi);
		ciw2pr <= $signed(ci)*$signed(w2pr);
      drw3pi <= $signed(dr)*$signed(w3pi);
		diw3pr <= $signed(di)*$signed(w3pr);
	end
end

always @(posedge clk or negedge rst)
begin
  if(!rst)
  begin
   	  mer1 <= 0; mer2 <= 0;
		  mei1 <= 0; mei2 <= 0;
        mfr1 <= 0; mfr2 <= 0;
		  mfi1 <= 0; mfi2 <= 0;
        mgr1 <= 0; mgr2 <= 0;
        mgi1 <= 0; mgi2 <= 0;
		  mhr1 <= 0; mhr2 <= 0;
        mhi1 <= 0; mhi2 <= 0;	  

  end
  else if(enable==1)
  begin

       mer1 <= $signed(arw0pr)+$signed(brw1pr);
		 mer3 <= -$signed(biw1pi)+$signed(crw2pr);
		 mer2 <= -$signed(ciw2pi)+$signed(drw3pr)-$signed(diw3pi);
		 
       mei1 <= $signed(aiw0pi)+$signed(brw1pi);
		 mei3 <= $signed(biw1pr)+$signed(crw2pi);
		 mei2 <= $signed(ciw2pr)+$signed(drw3pi)+$signed(diw3pr);
		 
	    mfr1 <= $signed(arw0pr)+$signed(brw1pi);
		 mfr3 <= $signed(biw1pr)-$signed(crw2pr);
		 mfr2 <= $signed(ciw2pi)-$signed(drw3pi)-$signed(diw3pr); //原+crw2pr+ciw2pi
		 
       mfi1 <= $signed(aiw0pi)-$signed(brw1pr);
		 mfi3 <= $signed(biw1pi)-$signed(crw2pi);
		 mfi2 <= -$signed(ciw2pr)+$signed(drw3pr)-$signed(diw3pi);
	    
		 mgr1 <= $signed(arw0pr)-$signed(brw1pr);
		 mgr3 <= $signed(biw1pi)+$signed(crw2pr);
		 mgr2 <= -$signed(ciw2pi)-$signed(drw3pr)+$signed(diw3pi);
     
    	 mgi1 <= $signed(aiw0pi)-$signed(brw1pi);
		 mgi3 <= -$signed(biw1pr)+$signed(crw2pi);
		 mgi2 <= $signed(ciw2pr)-$signed(drw3pi)-$signed(diw3pr);
	    
		 mhr1 <= $signed(arw0pr)-$signed(brw1pi);
		 mhr3 <= -$signed(biw1pr)-$signed(crw2pr);
		 mhr2 <= $signed(ciw2pi)+$signed(drw3pi)+$signed(diw3pr); //原+crw2pr+ciw2pi
       
		 mhi1 <= $signed(aiw0pi)+$signed(brw1pr);
		 mhi3 <= -$signed(biw1pi)-$signed(crw2pi);
		 mhi2 <= -$signed(ciw2pr)-$signed(drw3pr)+$signed(diw3pi);
  end
end

 always @(posedge clk or negedge rst)
 begin
   if(!rst)
	begin
	   mer <= 0; mei <= 0;
	   mfr <= 0; mfi <= 0;
	   mgr <= 0; mgi <= 0;
	   mhr <= 0; mhi <= 0; 
	end
	else if(enable == 1)
	 begin
	    mer <= $signed(mer1)+$signed(mer2)+$signed(mer3);
	    mei <= $signed(mei1)+$signed(mei2)+$signed(mei3);
	    mfr <= $signed(mfr1)+$signed(mfr2)+$signed(mfr3);
	    mfi <= $signed(mfi1)+$signed(mfi2)+$signed(mfi3);
	    mgr <= $signed(mgr1)+$signed(mgr2)+$signed(mgr3);
	    mgi <= $signed(mgi1)+$signed(mgi2)+$signed(mgi3);
	    mhr <= $signed(mhr1)+$signed(mhr2)+$signed(mhr3);
	    mhi <= $signed(mhi1)+$signed(mhi2)+$signed(mhi3); 
	 end
 end
 

  //这是四舍五入
  	 assign er = (mer[WORDLENGTH_WP-1])?{1'b0,(mer>>WORDLENGTH_WP)+1}:{1'b0,(mer>>WORDLENGTH_WP)};
    assign ei = (mei[WORDLENGTH_WP-1])?{1'b0,(mei>>WORDLENGTH_WP)+1}:{1'b0,(mei>>WORDLENGTH_WP)};
	 assign fr = (mfr[WORDLENGTH_WP-1])?{1'b0,(mfr>>WORDLENGTH_WP)+1}:{1'b0,(mfr>>WORDLENGTH_WP)};
	 assign fi = (mfi[WORDLENGTH_WP-1])?{1'b0,(mfi>>WORDLENGTH_WP)+1}:{1'b0,(mfi>>WORDLENGTH_WP)};
	 assign gr = (mgr[WORDLENGTH_WP-1])?{1'b0,(mgr>>WORDLENGTH_WP)+1}:{1'b0,(mgr>>WORDLENGTH_WP)};
	 assign gi = (mgi[WORDLENGTH_WP-1])?{1'b0,(mgi>>WORDLENGTH_WP)+1}:{1'b0,(mgi>>WORDLENGTH_WP)};
	 assign hr = (mhr[WORDLENGTH_WP-1])?{1'b0,(mhr>>WORDLENGTH_WP)+1}:{1'b0,(mhr>>WORDLENGTH_WP)};
	 assign hi = (mhi[WORDLENGTH_WP-1])?{1'b0,(mhi>>WORDLENGTH_WP)+1}:{1'b0,(mhi>>WORDLENGTH_WP)}; 
  
endmodule
 
