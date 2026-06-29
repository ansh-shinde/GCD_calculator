# GCD Calculator - Verilog RTL Implementation

A hardware implementation of the **Greatest Common Divisor (GCD)** calculator using **Verilog**, designed with a **structural architecture** combining a datapath and finite state machine (FSM) controller.

## 📋 Overview

This project implements the **Euclidean Algorithm** for computing the GCD of two 16-bit numbers. The design follows a classic **datapath + controller** architecture commonly used in digital system design.

**Algorithm:** Euclidean Algorithm
- Repeatedly computes: `GCD(a, b) = GCD(b, a mod b)` until one number becomes zero
- The remaining non-zero number is the GCD

## 🏗️ Architecture

### High-Level Components

```
┌─────────────────────────────────────────┐
│         GCD Calculator System           │
├─────────────────────────────────────────┤
│         CONTROLLER (FSM)                │
│  ┌─────────────────────────────────┐   │
│  │ States: s0→s1→s2→s3/s4→s5      │   │
│  │ Generates control signals       │   │
│  └─────────────────────────────────┘   │
├─────────────────────────────────────────┤
│          DATAPATH                       │
│  ┌──────────────┐  ┌──────────────┐   │
│  │ Register A   │  │ Register B   │   │
│  └──────────────┘  └──────────────┘   │
│  ┌──────────────────────────────────┐  │
│  │ Comparator (lt, gt, eq)         │  │
│  │ Subtractor (A - B)              │  │
│  │ Multiplexers (sel1, sel2, selin)│  │
│  └──────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### Module Description

#### **Controller (FSM)**
Finite State Machine that orchestrates the GCD computation:

| State | Name | Function |
|-------|------|----------|
| `s0` | IDLE | Waits for `start` signal |
| `s1` | LOAD | Loads second operand (data_in → Register B) |
| `s2` | COMPARE & ROUTE | Initial comparison and subtraction setup |
| `s3` | LOOP PATH1 | Continues when A < B (computes B - A) |
| `s4` | LOOP PATH2 | Continues when A > B (computes A - B) |
| `s5` | DONE | Computation complete, GCD available in Register A |

**State Transitions:**
- `s0` → `s1` (on `start=1`)
- `s1` → `s2` (always)
- `s2` → `s3` (if A < B) / `s4` (if A > B) / `s5` (if A == B)
- `s3/s4` → `s5` (when A == B) or loop back based on comparison
- `s5` → `s5` (remains in done state)

#### **Datapath**
Performs the actual computation:

- **PIPO Register (16-bit):** Parallel-In-Parallel-Out synchronous registers for storing A and B values
- **Comparator:** Generates flags: `lt` (A<B), `gt` (A>B), `eq` (A==B)
- **Subtractor:** Computes 16-bit difference (A - B)
- **Multiplexers:** Route data between registers, subtractor, and input

## 📁 Files

| File | Description |
|------|-------------|
| `gcd.v` | Main design module containing all structural components (datapath, controller, and submodules) |
| `gcd_test.v` | Testbench for simulation and verification |
| `gcd.vcd` | VCD (Value Change Dump) file generated during simulation for waveform analysis |

## 🔧 Module Details

### Datapath Components

```verilog
module datapath(lt, gt, eq, lda, ldb, sel1, sel2, selin, clk, data_in)
```

**Inputs:**
- `lda, ldb` - Load enables for registers A and B
- `sel1, sel2` - Select signals for subtractor inputs
- `selin` - Select signal for input multiplexer
- `clk` - Clock signal
- `data_in[15:0]` - External 16-bit data input

**Outputs:**
- `lt, gt, eq` - Comparison flags

### Controller Signals

```verilog
module controller(sel1, sel2, selin, done, lda, ldb, lt, gt, eq, start, clk)
```

**Inputs:**
- `lt, gt, eq` - Comparison flags from datapath
- `start` - Start signal to initiate GCD computation
- `clk` - Clock signal

**Outputs:**
- `sel1, sel2, selin` - Multiplexer select signals
- `lda, ldb` - Register load enables
- `done` - Asserted when GCD computation is complete

## 📊 Simulation

### Test Vectors (from `gcd_test.v`)

```verilog
#12 data_in = 143;  // First operand
#10 data_in = 78;   // Second operand
```

**Expected Result:** GCD(143, 78) = **13**

### Running Simulation

Use a Verilog simulator (e.g., ModelSim, Vivado, or Icarus Verilog):

```bash
iverilog -o gcd gcd.v gcd_test.v
vvp gcd
```

View waveforms in the generated `gcd.vcd` file using GTKWave or similar tool:

```bash
gtkwave gcd.vcd
```

## 🎯 Key Features

✅ **Structural Design** - Clear separation of datapath and controller
✅ **FSM-Based Control** - Well-defined state machine with proper synchronization
✅ **16-bit Precision** - Handles numbers up to 65,535
✅ **Euclidean Algorithm** - Efficient GCD computation
✅ **Synchronous Design** - All state transitions synchronized with clock
✅ **Comprehensive Documentation** - Inline comments explaining each module

## 📈 Computation Flow

1. **Load Phase:**
   - `start=1` triggers state s0→s1
   - First operand loaded into Register A (s0)
   - Second operand loaded into Register B (s1)

2. **Comparison Phase:**
   - Compare A and B using the comparator
   - Generate flags: lt, gt, eq

3. **Iteration Phase:**
   - If A < B: Compute B - A, store in B
   - If A > B: Compute A - B, store in A
   - If A == B: GCD found, transition to done state

4. **Output:**
   - GCD value remains in Register A
   - `done` flag asserted, indicating completion

## 🔍 Important Design Notes

- **FSM Separation:** Separate states (s0, s1) for loading vs. looping to prevent pipelining issues
- **Combinational Outputs:** Control signals generated combinationally based on current state
- **Sequential Transitions:** State updates occur synchronously on clock edges
- **Multi-line Case Blocks:** All multi-statement case branches use `begin-end` blocks

## 💡 Applications

- **Digital Signal Processing (DSP)** systems
- **Cryptography** algorithms (RSA, ECC)
- **Rational Number Reduction** in fixed-point arithmetic
- **Hardware Accelerators** for mathematical operations

## 📚 References

- **Euclidean Algorithm:** [Wikipedia](https://en.wikipedia.org/wiki/Euclidean_algorithm)
- **Verilog HDL:** IEEE 1364 Standard

## 📝 License

Open source - Free to use and modify

---

**Author:** Ansh Shinde  
**Last Updated:** 2026
