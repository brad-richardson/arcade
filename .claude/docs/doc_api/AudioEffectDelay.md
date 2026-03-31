## AudioEffectDelay <- AudioEffect

A "delay" effect plays the input audio signal back after a period of time. Each repetition is called a "delay tap" or simply "tap". Delay taps may be played back multiple times to create the sound of a repeating, decaying echo. Delay effects range from a subtle echo to a pronounced blending of previous sounds with new sounds. See also AudioEffectReverb for a blurry, continuous echo.

**Props:**
- dry: float = 1.0
- feedback_active: bool = false
- feedback_delay_ms: float = 340.0
- feedback_level_db: float = -6.0
- feedback_lowpass: float = 16000.0
- tap1_active: bool = true
- tap1_delay_ms: float = 250.0
- tap1_level_db: float = -6.0
- tap1_pan: float = 0.2
- tap2_active: bool = true
- tap2_delay_ms: float = 500.0
- tap2_level_db: float = -12.0
- tap2_pan: float = -0.4

