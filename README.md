# FPGA-TETRIS
A hardware implementation of a Tetris-style game developed on the DE10-Lite FPGA using Verilog HDL.

## Features
VGA video output at 640×480 resolution
Real-time game rendering
Line clearing and score tracking
LFSR-based pseudo-random piece generation
PLL-generated clocks for game timing and video synchronization

# Hardware
Intel/Altera DE10-Lite FPGA
VGA monitor
On-board buttons and switches for user input
Design Highlights
VGA Controller

Generates horizontal and vertical synchronization signals and renders the game board, active piece, and UI elements directly in hardware.

## Clock Management

Uses a PLL to derive lower-frequency clocks from the system clock, allowing independent timing for VGA output and game updates.

## Random Piece Generator

Implements a Linear Feedback Shift Register (LFSR) to generate pseudo-random tetromino sequences without requiring external memory or software support.

## Game Engine

Handles:
- Piece movement
- Rotation
- Collision detection
- Line completion
- Board state management
