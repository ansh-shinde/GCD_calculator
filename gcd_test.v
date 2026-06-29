module gcd_test;
reg clk,start;
reg [15:0]data_in;
wire done;

datapath dp(lt,gt,eq,lda,ldb,sel1,sel2,selin,clk,data_in);
controller cnt(sel1,sel2,selin,done,lda,ldb,lt,gt,eq,start,clk);
 
initial
begin
clk=0;
#3 start=1;
#1000 $finish;
end

always #5 clk=~clk;

initial 
begin
#12 data_in=143;
#10 data_in=78;
end

initial 
begin 
$dumpfile("gcd.vcd");
$dumpvars(0,gcd_test);
$monitor("time=%d  ans=%d  done=%b",$time,dp.aout,done);
end

endmodule

