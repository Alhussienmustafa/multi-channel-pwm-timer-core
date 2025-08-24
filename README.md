Multi-Channel PWM/Timer Core FPGA Project
Overview
This repository contains the design and documentation for a Multi-Channel PWM/Timer Core, developed as my submission for the IEEE Helwan Digital Design Competition. 
As Chairman of the Communications Society Chapter at IEEE Helwan Student Branch, I created this 16-bit core based on the provided specs. 
The project showcases advanced FPGA design techniques, including dual clock support and runtime configurability.

Features

Supports up to 4 independent PWM/Timer channels with configurable Period and Duty Cycle.
Dual clock operation (Wishbone clock and external clock) with Clock Domain Crossing (CDC) synchronization using synchronizers.
Down clocking capability up to 1/65535 of the original frequency using a 16-bit divisor.
Wishbone B4 Slave Interface for runtime control of registers (Ctrl, Divisor, Period, DC).
Dynamic period and duty cycle adjustments during operation.

Design Details

Architecture: Implemented in Verilog with a modular structure, supporting PWM and Timer modes.
Clock Management: Handles Wishbone clock, external clock, and clock divider output, resolved with synchronizers to mitigate CDC issues.
Testbench: Directed Testbench with Tasks for Write/Read operations on all registers, validated in QuestaSim with zero warnings from QuestaLint.

Implementation Status

Synthesis: Successfully completed on Artix-7 FPGA using Vivado, achieving 5% LUTs and 3% Flip-Flops utilization.
Challenge: The Artix-7’s single dedicated clock pin couldn’t accommodate the dual clock setup, leading to Hold Time violations and preventing full Implementation.
Decision: Opted for Synthesis and simulation validation instead of Implementation due to clock constraints.

Results

Stable PWM output and Timer interrupt generation across all test cases.
Efficient resource use and no glitches observed in dual clock scenarios.
Timing analysis shows positive Worst Negative Slack (1.569 ns), with Hold Time optimization pending.

How to Use

Clone this repository: git clone https://github.com/Alhussienmustafa/multi-channel-pwm-timer-core
Open the Verilog files in Vivado for Synthesis.
Use the provided Testbench (testbench.v) in QuestaSim for simulation.
Configure registers via Wishbone interface as per the specs.

Files

PWM_TMR_CORE.v: Main Verilog design file.
testbench.v: Directed Testbench with Write/Read Tasks.
PWM_UM.pdf: Original specs document (available at Google Drive Link).
screenshots/: Waveforms and Vivado reports.

Acknowledgments

Inspired by the IEEE Helwan Digital Design Competition specs.
Tools: Vivado, QuestaSim, QuestaLint.
Feedback and collaboration are welcome!
