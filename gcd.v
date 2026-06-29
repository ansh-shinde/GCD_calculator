
//multi line case branch always always use begin end blocks
//fsm variable(state) should always be update in sequential block
//always use seperate states for loading(s0,s1) and looping(s2,s3,s4) else looping might get skipped

module datapath(lt,gt,eq,lda,ldb,sel1,sel2,selin,clk,data_in);
input lda,ldb,sel1,sel2,selin,clk;
output lt,gt,eq;
input [15:0]data_in;
wire [15:0]bus,aout,bout,x,y,subout;

pipo a(aout,lda,clk,bus);
pipo b(bout,ldb,clk,bus);
comp c(lt,gt,eq,aout,bout);
sub s(subout,x,y);
mux m1(x,aout,bout,sel1);
mux m2(y,aout,bout,sel2);
mux min(bus,subout,data_in,selin);
endmodule

module pipo(out,ld,clk,in);
input [15:0]in;
input clk,ld;
output reg[15:0]out;
always@(posedge clk)
if(ld)
out<=in;
endmodule

module comp(l,g,e,in1,in2);
input [15:0]in1,in2;
output l,g,e;
assign l=in1<in2;
assign g=in1>in2;
assign e=in1==in2;
endmodule

module sub(diff,data1,data2);
input [15:0]data1,data2;
output [15:0]diff;
assign diff=data1-data2;
endmodule

module mux(data,inp0,inp1,sel);
input [15:0]inp0,inp1;
input sel;
output [15:0]data;
assign data=sel?inp1:inp0;
endmodule

module controller(sel1,sel2,selin,done,lda,ldb,lt,gt,eq,start,clk);
input lt,gt,eq,start,clk;
output reg lda,ldb,sel1,sel2,selin,done;
reg [2:0]state;
parameter s0=3'b000, s1=3'b001, s2=3'b010, s3=3'b011, s4=3'b100,s5=3'b110;
always@(posedge clk)
case(state)
s0:if(start)
   begin
   state<=s1;
   end
s1:begin 
   state<=s2;
   end
s2:begin 
   if(eq)
   state<=s5;
   else if(lt)
   state<=s3;
   else if(gt)
   state<=s4;
   end
s3:begin 
   if(eq)
   state<=s5;
   else if(lt)
   state<=s3;
   else if(gt)
   state<=s4;
   end
s4:begin
   if(eq)
   state<=s5;
   else if(gt)
   state<=s4;
   else if(lt)
   state<=s3;
   end
s5:begin 
   state<=s5;
   end
default:state<=s0;
endcase

always@(*)
case(state)
s0:begin 
   sel1=0;
   sel2=0;
   selin=1;
   lda=1;
   ldb=0;
   done=0;
   end
s1:begin 
   done=0;
   sel1=0;
   sel2=0;
   selin=1;
   lda=0; ldb=1;
   end
s2:begin
      if(eq)
      begin
       done=1;
       lda=0;
       ldb=0;
      end
      else if(lt)
           begin
           sel1=1;
           sel2=0;
           selin=0;
           ldb=1; lda=0;
           end
      else if(gt)
           begin
           selin=0;
           sel1=0;
           sel2=1;
           done=0;
           ldb=0; lda=1;
           end
   end
s3:  begin
       if(eq) 
       begin
       done=1;
       lda=0;
       ldb=0;
       end
      else if(lt)
           begin
           sel1=1;
           sel2=0;
           selin=0;
           ldb=1; lda=0;
           end
      else if(gt)
           begin
           selin=0;
           sel1=0;
           sel2=1;
           done=0;
           ldb=0; lda=1;
           end
        end
s4: begin
       if(eq)
       begin
       done=1;
       lda=0;
       ldb=0; 
       end
      else if(lt)
           begin
           sel1=1;
           sel2=0;
           selin=0;
           ldb=1; lda=0;
           end
      else if(gt)
           begin
           selin=0;
           sel1=0;
           sel2=1;
           done=0;
           ldb=0; lda=1;
           end
     end
s5:begin
   done=1;
   lda=0;
   ldb=0;
   sel1=0;
   sel2=0;
   selin=0;  
   end
default:state=s0;
endcase
endmodule

