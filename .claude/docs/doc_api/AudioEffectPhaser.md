## AudioEffectPhaser <- AudioEffect

A "phaser" effect creates a copy of the original audio that phase-rotates differently across the entire frequency spectrum, with the use of a series of all-pass filter stages (6 in this effect). This copy modulates with a low-frequency oscillator and combines with the original audio, resulting in peaks and troughs that sweep across the spectrum. This effect can be used to create a "glassy" or "bubbly" sound.

**Props:**
- depth: float = 1.0
- feedback: float = 0.7
- range_max_hz: float = 1600.0
- range_min_hz: float = 440.0
- rate_hz: float = 0.5

