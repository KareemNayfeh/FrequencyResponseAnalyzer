# MATLAB Frequency-Response Analyzer Using PicoScope

This repository contains a MATLAB-based frequency-response analyzer that uses a **PicoScope USB oscilloscope** to measure **transfer functions** of physical and electrical systems, including circuits, dampers, and acoustic systems.

The script performs an automated frequency sweep, captures time-domain data from the PicoScope, computes magnitude and phase response, and generates Bode-style plots.

---

## Overview

This tool was developed to experimentally measure frequency-domain behavior by:

- Driving a system with a swept sine input
- Measuring input and output signals simultaneously
- Computing amplitude and phase via Fourier-based integration
- Automatically scaling measurement ranges
- Saving processed frequency-response data for post-analysis

---

## Features

- Logarithmic frequency sweep
- Automatic signal generator configuration
- Dynamic voltage range adjustment for input and output channels
- Time-domain visualization during acquisition
- Magnitude and phase extraction
- Bode plot generation (magnitude and phase)
- Data export to `.mat` files with timestamped filenames

---

## Hardware Requirements

- **PicoScope USB oscilloscope** (PS2000 series)
- PicoScope MATLAB Instrument Driver
- Signal generator capability enabled on the device

---

## Software Requirements

- MATLAB
- PicoScope MATLAB SDK
- Required driver files:
  - `picotech_ps2000_generic.mdd`
  - `PS2000Config.m`

Ensure these files are on the MATLAB path before running the script.

---

## Output

The script generates:

- Time-domain plots of Channel A and Channel B
- Magnitude plots for individual channels
- Bode plots of the transfer function
- A `.mat` file containing:
  - Frequency vector
  - Input and output magnitudes
  - Transfer function magnitude and phase
  - Complex frequency-response data

Saved files are timestamped automatically.


