## AudioEffectDistortion <- AudioEffect

A "distortion" effect modifies the waveform via a nonlinear mathematical function (see available ones in `Mode`), based on the amplitude of the waveform's samples. **Note:** In a nonlinear function, an input sample at *x* amplitude value, will either have its amplitude increased or decreased to a *y* value, based on the function value at *x*, which is why even at the same `drive`, the output sound will vary depending on the input's volume. To change the volume while maintaining the output waveform, use `post_gain`. In this effect, each type is a different nonlinear function. The different types available are: clip, atan, lofi (bitcrush), overdrive, and waveshape. Every distortion type available here is symmetric: negative amplitude values are affected the same way as positive ones. Although distortion will always change frequency content, usually by introducing high harmonics, different distortion types offer a range of sound qualities; from "soft" and "warm", to "crunchy" and "abrasive". For games, it can help simulate sound coming from some saturated device or speaker very efficiently. It can also help the audio stand out in a mix, by introducing higher frequencies and increasing the volume. **Note:** Although usually imperceptible, an enabled distortion effect still changes the sound even when `drive` is set to 0. This is not a bug. If this behavior is undesirable, consider disabling the effect using `AudioServer.set_bus_effect_enabled`.

**Props:**
- drive: float = 0.0
- keep_hf_hz: float = 16000.0
- mode: int (AudioEffectDistortion.Mode) = 0
- post_gain: float = 0.0
- pre_gain: float = 0.0

**Enums:**
**Mode:** MODE_CLIP=0, MODE_ATAN=1, MODE_LOFI=2, MODE_OVERDRIVE=3, MODE_WAVESHAPE=4

