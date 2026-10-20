# 6. Experimental guide: recording better electrical data

Most of the uncertainty in [Known limitations](05-known-limitations.md) comes from the measurement, not from the calculation. This checklist removes most of it. It is based on Peeters & Butterworth 2019 (PB19), Brandenburg 2017, Brandenburg et al. 2023 and De Meyer et al. 2024/2025, plus our own experience.

## 1. Probes

- [ ] **Tune (compensate) every passive probe** before each measurement day.
  - Connect the probe to the oscilloscope's calibration output (a square wave) and turn the trimmer until the square wave has flat tops: no overshoot, no rounding.
  - A badly tuned charge probe adds a time delay of several µs between $V$ and $Q$. That changes the measured power and every slope ([limitations](05-known-limitations.md#day-to-day-differences-in-probe-tuning)).
- [ ] **Check the timing between channels (deskew).**
  - Feed the same signal to the voltage, charge and current channels and compare.
  - Note the delays, or correct them in the scope.
  - One metre of coaxial cable adds only 3–4 ns (PB19 §3.3), but probe tuning can add microseconds.
- [ ] **Use the right high-voltage probe range** and connect it as close to the reactor electrode as possible (PB19 §2). An amplifier's built-in voltage monitor can have a phase error.
- [ ] **Keep ground connections short.**
  - Do not use the long crocodile-clip ground lead of a probe on the monitor capacitor.
  - Wrap a short wire directly around the probe's ground barrel instead (PB19 §3.4).
  - Long ground loops pick up noise from the discharge.

## 2. Monitor capacitor

- [ ] **Use a class 1 ceramic capacitor (C0G / NP0)** (PB19 §2.4). Its value hardly changes with voltage, temperature or frequency. Example: Kemet C330C103F1G5TA, 10 nF, 100 V, C0G, 1%.
- [ ] **Choose the value** so that $C_m / C_\text{cell}$ is between 100 and 10 000 (PB19 §2.4).
  - Too small: the voltage across $C_m$ overloads the scope input.
  - Too large: the signal drowns in noise.
  - The expected signal without plasma is $V_m = V\,C_\text{cell}/C_m$ (PB19 eq. 10).
- [ ] **Measure $C_m$ with an LCR meter.** Manufacturer values and the stray capacitance of the measuring circuit can differ from the nominal value (PB19 §2.4; DM24 SI §S4).
- [ ] **Use one cable without adapters** from capacitor to scope. Every connector adds inductance that causes ringing after each discharge pulse (PB19 §3.4).
- [ ] Optionally, add an **RC low-pass filter** across $C_m$ (e.g. 100 Ω + 200 pF, about 50 MHz) if ringing overloads the input (PB19 §3.4). Note that this reduces the bandwidth.

## 3. Oscilloscope settings

- [ ] **Fill the vertical range.**
  - The scope stores values in discrete steps (8–12 bit). These steps set the noise floor of the current: in our data the noise was 2.5–3 steps.
  - A range that is too wide makes small pulses disappear in the steps.
- [ ] **Record the vertical range of every channel** for every capture. It decides the noise floor and so the smallest detectable pulse.
- [ ] **Sample fast enough** for the current probe (Pearson 4100: 10 ns rise time; we sample every 3.2 ns). Turn off bandwidth limiters on the current channel.
- [ ] **Record a whole number of periods**, ideally ≥ 5. The code uses whole periods only.
- [ ] **Take several captures per condition** (we take ~12). Cycles and captures are not independent repeats: the reactor run is the unit of replication. See [Calculation steps C2](03-calculation-steps.md#c2-average-per-capture).

## 4. Reference measurements

These measurements turn uncertain results into well-founded ones. Record each at the same probe settings as the plasma measurements, with the voltage *below* ignition (no plasma) unless stated otherwise.

| Measurement | When | What it gives | Why |
|---|---|---|---|
| **Empty reactor, no plasma** | Once per reactor and setup | Stray capacitance $C_s$ = measured slope − geometric $C_\text{cell}$ | $C_s$ enters $U_D$, $U_b$ and $\Delta Q_\text{dis}$ (Brandenburg et al. 2023; De Meyer et al. 2025) |
| **Packed reactor, cold, no plasma** | Every measurement day, before the plasma | The true $C_\text{cell}$ of the packed bed. The time delay of the charge probe (Q–V should be a straight line through the origin; a loop means a delay or a loss). | The plasma-off slope during operation reads ~20% high ([limitations](05-known-limitations.md#cell-capacitance-reads-too-high-during-plasma)); the delay is needed for the time-shift correction |
| **Packed reactor, hot, no plasma** | Immediately after switching off the plasma, lowering the voltage below ignition | Whether the lag/loss term remains when the reactor is hot | Separates heating losses in the dielectric or packing from plasma ([limitations](05-known-limitations.md#the-lag-term-in-the-plasma-off-fit)) |
| **Voltage-amplitude series with plasma** | Once per material | $\zeta_\text{diel}$ against amplitude: where it saturates estimates the true $C_\text{diel}$ (PB19 §3.1). The slope of $Q_0$ against $V_0$ also gives $C_\text{diel}$ (Brandenburg 2017). | Replaces the geometric $C_\text{diel}$ and its 5–10% uncertainty |

With a no-plasma recording:
- $Q$ against $V$ should be a straight line.
- Its slope is $C_\text{cell}$ (+ $C_s$).
- Any enclosed area means power where none should be. Check the phase and connections (PB19 §3.3).

## 5. Metadata to record

For every run:
- date;
- reactor ID and geometry;
- packing (material, size, mass, packing efficiency);
- gas and flow;
- frequency and voltage amplitude;
- the scope's vertical range per channel and sample interval;
- $C_m$ (measured);
- probe models and attenuation;
- whether the probes were tuned that day;
- the file names of the reference measurements.

## 6. Analysis choices to consider

- **Spectral pulse metric.** Instead of counting peaks, the spectral content of the plasma current in a frequency band can be summed (De Meyer et al. 2024). The code reports this as `pulse_band_rms_A`. Choose the band from your own spectra ([Adapting](07-adapting-to-your-reactor.md#spectral-pulse-band)).
- **Faster current measurement.** To count single microdischarges you need a measurement chain with ns resolution (PB19 §4). A 10 ns Rogowski coil gives indicative pulse groups only.
- **Plasma current with the correct factor.** Always use $i_\text{plasma} = (I - C_\text{cell}\,dV/dt)/(1 - C_\text{cell}/C_\text{diel})$ (PB19 eq. 3), not just $I - C_\text{cell}\,dV/dt$.
