# 16x8 Asynchronous FIFO (CDC & Gray Code Architecture)

**Description:**
RTL implementation of a dual-clock 16-depth by 8-bit width Asynchronous FIFO written in Verilog. Designed for safe Clock Domain Crossing (CDC) between independent write (`wr_clk`) and read (`rd_clk`) clock domains without metastability corruption.

**Key Architectural Features:**
* **5-Bit Binary-to-Gray Code Pointers:** Converts 5-bit binary read/write pointers (`[3:0]` address + `[4]` wrap bit) into unit-distance Gray code (`G = B ^ (B >> 1)`) so only 1 bit changes per clock transition.
* **Dual 2-Flop CDC Synchronizers:** Passes `wr_ptr_gray` into the read clock domain and `rd_ptr_gray` into the write clock domain via 2-stage D-Flip-Flop synchronizer chains to eliminate metastability.
* **Gray-Code Full & Empty Flag Generation:** Evaluates `empty` in the read domain and `full` in the write domain using MSB wrap-bit comparison.

**Verification (`async_fifo_tb.v`):**
Simulated in Icarus Verilog across asynchronous clock domains (`100 MHz` write clock vs. `71.4 MHz` read clock).

**Waveform Simulation:**

<img width="1920" height="1080" alt="Screenshot 2026-10-21 170631" src="https://github.com/user-attachments/assets/98f9b564-8767-481b-8567-184228539038" />
