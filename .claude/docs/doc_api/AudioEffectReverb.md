## AudioEffectReverb <- AudioEffect

A "reverb" effect plays the input audio back continuously, decaying over a period of time. It simulates sounds in different kinds of spaces, ranging from small rooms, to big caverns. See also AudioEffectDelay for a non-blurry type of echo.

**Props:**
- damping: float = 0.5
- dry: float = 1.0
- hipass: float = 0.0
- predelay_feedback: float = 0.4
- predelay_msec: float = 150.0
- room_size: float = 0.8
- spread: float = 1.0
- wet: float = 0.5

