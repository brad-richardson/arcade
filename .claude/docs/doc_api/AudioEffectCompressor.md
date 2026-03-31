## AudioEffectCompressor <- AudioEffect

A "compressor" decreases the volume of sounds when it exceeds a certain volume threshold level. A compressor can have many uses in a mix: - To compress the whole volume in the Master bus (although an AudioEffectHardLimiter is probably better). - To ensure balance of voice audio clips. - To sidechain, using another bus as a trigger. This decreases the volume of the bus it is attached to, by using the volume from another audio bus for threshold detection. This technique is common in video game mixing to decrease the volume of music and SFX while voices are being heard. This effect is also known as "ducking". - To accentuate transients by using a long attack, letting sounds exceed the volume threshold level for a short period before compressing them. This can be used to make SFX more punchy.

**Props:**
- attack_us: float = 20.0
- gain: float = 0.0
- mix: float = 1.0
- ratio: float = 4.0
- release_ms: float = 250.0
- sidechain: StringName = &""
- threshold: float = 0.0

