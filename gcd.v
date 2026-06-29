//===============================================================
// GCD (Greatest Common Divisor) Calculator - Verilog RTL
// Architecture: Datapath + Controller (Structural Design)
// Algorithm: Euclidean Algorithm for GCD computation
//===============================================================

//===============================================================
// DATAPATH MODULE
// Instantiates all functional blocks: registers, comparator,
// subtractor, and multiplexers. Performs actual computations.
//===============================================================
module datapath(lt,gt,eq,lda,ldb,sel1,sel2,selin,clk,data_in);
  input lda,ldb,sel1,sel2,selin,clk;
  output lt,gt,eq;
  input [15:0]data_in;
  wire [15:0]bus,aout,bout,x,y,subout;

  // Register A: Loads first operand, stores intermediate results
  pipo a(aout,lda,clk,bus);
  
  // Register B: Loads second operand, stores intermediate results
  pipo b(bout,ldb,clk,bus);
  
  // Comparator: Compares A and B, generates less-than, greater-than, equal flags
  comp c(lt,gt,eq,aout,bout);
  
  // Subtractor: Computes A - B for Euclidean algorithm
  sub s(subout,x,y);
  
  // Mux1: Selects first operand (A or B) for subtractor
  mux m1(x,aout,bout,sel1);
  
  // Mux2: Selects second operand (A or B) for subtractor
  mux m2(y,aout,bout,sel2);
  
  // InputMux: Routes subtraction result or external data to bus
  mux min(bus,subout,data_in,selin);
endmodule

//===============================================================
// PIPO (Parallel-In-Parallel-Out) REGISTER MODULE
// 16-bit synchronous register with load enable control
//===============================================================
module pipo(out,ld,clk,in);
  input [15:0]in;
  input clk,ld;
  output reg[15:0]out;
  
  // Load on rising clock edge when ld signal is asserted
  always@(posedge clk)
    if(ld)
      out<=in;
endmodule

//===============================================================
// COMPARATOR MODULE
// Compares two 16-bit numbers and outputs three flags:
// l=1 if in1<in2, g=1 if in1>in2, e=1 if in1==in2
//===============================================================
module comp(l,g,e,in1,in2);
  input [15:0]in1,in2;
  output l,g,e;
  
  // Less-than comparison
  assign l=in1<in2;
  
  // Greater-than comparison
  assign g=in1>in2;
  
  // Equal comparison
  assign e=in1==in2;
endmodule

//===============================================================
// SUBTRACTOR MODULE
// Computes 16-bit difference (data1 - data2)
// Used in Euclidean algorithm to replace larger number
//===============================================================
module sub(diff,data1,data2);
  input [15:0]data1,data2;
  output [15:0]diff;
  
  // Combinational subtraction
  assign diff=data1-data2;
endmodule

//===============================================================
// 2-TO-1 MULTIPLEXER MODULE
// Selects between two 16-bit inputs based on select signal
// sel=0 selects inp0, sel=1 selects inp1
//===============================================================
module mux(data,inp0,inp1,sel);
  input [15:0]inp0,inp1;
  input sel;
  output [15:0]data;
  
  // Conditional selection
  assign data=sel?inp1:inp0;
endmodule

//===============================================================
// CONTROLLER (FSM) MODULE
// Finite State Machine that controls the GCD computation flow
// States: s0(idle), s1(load), s2-s4(compute loop), s5(done)
// IMP: FSM transitions happen in sequential block, outputs in combinational
//===============================================================
module controller(sel1,sel2,selin,done,lda,ldb,lt,gt,eq,start,clk);
  input lt,gt,eq,start,clk;
  output reg lda,ldb,sel1,sel2,selin,done;
  reg [2:0]state;
  
  // IMP: Separate states for loading (s0,s1) and looping (s2,s3,s4)
  //      prevents looping from being skipped due to pipelining
  parameter s0=3'b000, s1=3'b001, s2=3'b010, s3=3'b011, s4=3'b100, s5=3'b110;

  //---------------------------------------------------------------
  // SEQUENTIAL BLOCK: State Transitions on Clock Edges
  // IMP: All state updates must occur here to ensure proper synchronization
  //---------------------------------------------------------------
  always@(posedge clk)
    case(state)
      // s0: IDLE - Wait for start signal
      s0:if(start)
           begin
             state<=s1;
           end
      
      // s1: LOAD - Load second operand, prepare for computation
      s1:begin 
           state<=s2;
         end
      
      // s2: COMPUTE LOOP (Entry) - Check if numbers are equal
      s2:begin 
           if(eq)
             state<=s5;           // Equal: go to done
           else if(lt)
             state<=s3;           // A<B: keep A, compute B-A
           else if(gt)
             state<=s4;           // A>B: keep B, compute A-B
         end
      
      // s3: COMPUTE LOOP (Path1) - When A was less than B
      s3:begin 
           if(eq)
             state<=s5;
           else if(lt)
             state<=s3;           // Stay in this path
           else if(gt)
             state<=s4;           // Switch to other path
         end
      
      // s4: COMPUTE LOOP (Path2) - When A was greater than B
      s4:begin
           if(eq)
             state<=s5;
           else if(gt)
             state<=s4;           // Stay in this path
           else if(lt)
             state<=s3;           // Switch to other path
         end
      
      // s5: DONE - Hold when computation complete
      s5:begin 
           state<=s5;             // Remain in done state
         end
      
      // Default: Reset to idle on unexpected state
      default:state<=s0;
    endcase

  //---------------------------------------------------------------
  // COMBINATIONAL BLOCK: Control Signal Generation
  // IMP: Multi-line case branches must use begin-end blocks
  //      Controls register loads, mux selections, and done flag
  //---------------------------------------------------------------
  always@(*)
    case(state)
      // s0: IDLE - Load first operand from input
      s0:begin 
           sel1=0;               // Mux1 selects A
           sel2=0;               // Mux2 selects A
           selin=1;              // Bus receives external data_in
           lda=1;                // Load register A
           ldb=0;                // Hold register B
           done=0;               // Computation ongoing
         end
      
      // s1: LOAD - Load second operand from input
      s1:begin 
           done=0;
           sel1=0;
           sel2=0;
           selin=1;              // Bus receives external data_in
           lda=0;
           ldb=1;                // Load register B
         end
      
      // s2: COMPARE & ROUTE - Initial comparison and subtraction setup
      s2:begin
           if(eq)
             begin
               done=1;           // GCD found
               lda=0;
               ldb=0;
             end
           else if(lt)           // If A<B, compute B-A (B becomes new value)
             begin
               sel1=1;           // Mux1 selects B
               sel2=0;           // Mux2 selects A
               selin=0;          // Bus receives subtraction result (B-A)
               ldb=1;            // Load computed value into B
               lda=0;
             end
           else if(gt)           // If A>B, compute A-B (A becomes new value)
             begin
               selin=0;          // Bus receives subtraction result (A-B)
               sel1=0;           // Mux1 selects A
               sel2=1;           // Mux2 selects B
               done=0;
               ldb=0;
               lda=1;            // Load computed value into A
             end
         end
      
      // s3: LOOP PATH1 - Continue when A was smaller
      s3:begin
           if(eq) 
             begin
               done=1;           // GCD found
               lda=0;
               ldb=0;
             end
           else if(lt)           // Still A<B, compute B-A
             begin
               sel1=1;           // Mux1 selects B
               sel2=0;           // Mux2 selects A
               selin=0;          // Bus receives B-A
               ldb=1;            // Load into B
               lda=0;
             end
           else if(gt)           // Now A>B, compute A-B
             begin
               selin=0;          // Bus receives A-B
               sel1=0;           // Mux1 selects A
               sel2=1;           // Mux2 selects B
               done=0;
               ldb=0;
               lda=1;            // Load into A
             end
         end
      
      // s4: LOOP PATH2 - Continue when A was greater
      s4:begin
           if(eq)
             begin
               done=1;           // GCD found
               lda=0;
               ldb=0; 
             end
           else if(lt)           // Now A<B, compute B-A
             begin
               sel1=1;           // Mux1 selects B
               sel2=0;           // Mux2 selects A
               selin=0;          // Bus receives B-A
               ldb=1;            // Load into B
               lda=0;
             end
           else if(gt)           // Still A>B, compute A-B
             begin
               selin=0;          // Bus receives A-B
               sel1=0;           // Mux1 selects A
               sel2=1;           // Mux2 selects B
               done=0;
               ldb=0;
               lda=1;            // Load into A
             end
         end
      
      // s5: DONE - Hold all outputs, GCD is in register A
      s5:begin
           done=1;               // Assert done flag
           lda=0;
           ldb=0;
           sel1=0;
           sel2=0;
           selin=0;              // Bus unchanged
         end
      
      // Default: Initialize all outputs
      default:state=s0;
    endcase
endmodule
