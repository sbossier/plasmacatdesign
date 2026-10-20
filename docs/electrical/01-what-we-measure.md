# 1. What we measure

This page explains the reactor, the four signals we record, and the charge–voltage figure that most of the analysis is built on. No electrical background is assumed. Terms in **bold** are explained in the [glossary](#glossary) at the end.

## The reactor

A **dielectric barrier discharge (DBD)** is a plasma made between two electrodes with an electrically insulating layer (the **dielectric**, here an alumina tube) in between. The insulator stops a continuous current, so the plasma cannot become a hot arc. It stays a cold, non-equilibrium plasma that can drive chemistry at near room temperature.

Our reactor is **coaxial**: a metal rod in the centre, an alumina tube around it, and a metal mesh around the tube.

```
        mesh electrode (high voltage)
        │  alumina tube (dielectric barrier)
        │  │   gas gap packed with beads (where the plasma forms)
        │  │   │        metal rod (grounded through the measuring circuit)
        ▼  ▼   ▼        ▼
   ─────┬──┬───────────┬──┬───────────┬──┬─────
        │██│ o o o o o │▓▓│ o o o o o │██│
   ─────┴──┴───────────┴──┴───────────┴──┴─────
```

The gap is filled with spherical beads (the **packing**, for example a catalyst). This is a **packed-bed DBD**. The beads change how and where the plasma forms (Butterworth & Allen 2017; De Meyer et al. 2024).

An alternating voltage of a few kV at a few kHz (3 kHz here) is applied. The plasma does not burn continuously. In every half-period it ignites once the voltage across the gas is high enough, and stops shortly after the applied voltage reaches its maximum. Inside the plasma, the charge is carried by many short current pulses, the **microdischarges**.

The exact dimensions of our reactor are in [Adapting to your reactor](07-adapting-to-your-reactor.md#our-setup-as-worked-example).

## The four signals

An oscilloscope records four signals at the same time, each sampled every 3.2 ns:

| Signal | What it is | Instrument | Column | Unit |
|---|---|---|---|---|
| Applied voltage $V(t)$ | Voltage on the high-voltage electrode | High-voltage probe (1000:1) | `voltage_V` | V |
| Charge $Q(t)$ | Charge that has flowed through the reactor | Voltage on a **monitor capacitor** $C_m$ in the ground line, read with a 10:1 probe; $Q = C_m V_m$ | `charge_C` | C |
| Reactor current $I(t)$ | Current through the reactor | **Rogowski coil** around the ground lead | `current_reactor_A` | A |
| Source current $I_s(t)$ | Current delivered by the amplifier | Built-in current monitor of the amplifier | `current_source_A` | A |

Charge and current describe the same thing in two ways: current is the rate at which charge flows, $I = dQ/dt$.
- The capacitor integrates the current, so it does not miss any charge. That makes it the better choice for power and capacitances.
- The Rogowski coil follows fast changes better. That makes it the better choice for seeing individual current pulses (Peeters & Butterworth 2019, §2.4).

## The charge–voltage figure (Lissajous figure)

Plotting $Q$ against $V$ for one period gives a closed loop: the **Q–V diagram**, also called the **Lissajous figure**. Its shape tells a lot about the discharge (Peeters & Butterworth 2019, §2).

In the ideal case the loop is a parallelogram:

```
   Q
   │            B ───────────────── A
   │           ╱  plasma off        ╱
   │          ╱  (slope C_cell)    ╱  plasma on
   │         ╱                    ╱   (slope ζ_diel)
   │        ╱                    ╱
   │       C ───────────────── D
   └──────────────────────────────────── V
```

- **Plasma off (A→B and C→D):** right after the voltage turns around, there is no plasma. The reactor behaves like a plain capacitor, and the slope $dQ/dV$ is the **cell capacitance** $C_\text{cell}$.
- **Plasma on (B→C and D→A):** once the gas breaks down, charge crosses the gas gap through the plasma. The slope becomes steeper: the **effective dielectric capacitance** $\zeta_\text{diel}$.
- **Point B (and D):** where the plasma ignites. The voltage there is reported as `U_ignition_*`.

Real packed-bed reactors seldom give a perfect parallelogram:
- The corners are rounded.
- The plasma-on side curves into an "almond" shape, because the plasma spreads over the beads gradually as the voltage rises (Butterworth & Allen 2017, §3.6).
- Sometimes the loop is close to an ellipse (Peeters & Butterworth 2019, §3.3).

How much the shape departs from the parallelogram decides how much the derived numbers can be trusted. See [Equivalent circuits](02-equivalent-circuits.md) and [Known limitations](05-known-limitations.md).

## Plasma power: the area of the loop

The energy delivered to the reactor in one period equals the area enclosed by the Q–V loop. Multiplying by the frequency $f$ gives the power:

$$
P = f \oint V \, dQ = \frac{1}{T}\int_0^T V(t)\, I(t)\, dt
$$

(Peeters & Butterworth 2019, eq. 9; Manley 1943.) The second form is the time average of voltage × current. It gives the same number when it is computed from the Rogowski current (De Meyer et al. 2024, SI §S4).

Two practical rules:
- The integral must run over a whole number of periods. Otherwise the capacitive energy, which flows in and back out every period, does not cancel.
- The power from the loop area is the most robust result of the whole pipeline. It does not depend on any model of what happens inside the reactor.

## What else can be derived, and at what price

Everything beyond power depends on an **equivalent circuit**: a simplified electrical model of the reactor made of capacitors and a "plasma" element. With such a model the slopes and corners of the Q–V figure can be translated into:
- how much of the electrode area is discharging (`alpha`, `beta`);
- the voltage across the gas while the plasma burns (`U_burning`) and at ignition (`U_breakdown`);
- the charge carried across the gas by the plasma (`Q_delta_dis`);
- the current carried by the plasma alone (`current_plasma_A`).

These numbers are only as good as the model. For packed beds the models are known to be approximate. [Equivalent circuits](02-equivalent-circuits.md) explains which model is used where.

## Glossary

| Term | Plain meaning |
|---|---|
| **Capacitance** $C$ | How much charge an object stores per volt applied, $C = Q/V$. Unit farad (F); here usually picofarad (pF, $10^{-12}$ F). On a Q–V plot it is the slope. |
| **Capacitor** | Two conductors separated by an insulator. The reactor itself is one: rod and mesh separated by alumina and gas. |
| **Dielectric / barrier** | The insulating layer (alumina tube). Its capacitance is $C_\text{diel}$. |
| **Gap** | The gas-filled space between dielectric and rod, here with the packing. Its capacitance is $C_\text{gap}$. |
| **Cell capacitance** $C_\text{cell}$ | Capacitance of the whole reactor when there is no plasma: dielectric and gap in series, $1/C_\text{cell} = 1/C_\text{diel} + 1/C_\text{gap}$. Always smaller than both. |
| **Effective dielectric capacitance** $\zeta_\text{diel}$ | The slope of the Q–V figure while the plasma is on. Equal to $C_\text{diel}$ only if the whole electrode area discharges. |
| **Partial discharging** | Only part of the electrode area takes part in the discharge (Peeters & van de Sanden 2015). Quantified by $\beta$ (discharging fraction) and $\alpha = 1-\beta$. |
| **Breakdown / ignition** | The moment the voltage across the gas is high enough for the gas to conduct. |
| **Burning voltage** $U_b$ | The voltage across the gas while the plasma conducts. In the ideal model it stays constant during the discharge. |
| **Breakdown (discharge) voltage** $U_D$ | The voltage across the gas at the moment of ignition (Brandenburg et al. 2023). |
| **Transferred charge** $\Delta Q_\text{dis}$ | The charge the plasma carries across the gap in one half-period. |
| **Displacement (capacitive) current** | Current that flows only because the voltage changes and capacitors charge, without charge crossing the gas. Present even without plasma. |
| **Plasma current** | The part of the current carried through the gas by the plasma. Calculated by removing the capacitive part (Peeters & Butterworth 2019, eq. 3). |
| **Microdischarge / current pulse** | A short burst of current where the plasma forms a filament across the gap. With our current probe we see pulses of 0.1–1 µs, which may contain several microdischarges (see [Known limitations](05-known-limitations.md#current-pulses-are-indicative)). |
| **Monitor capacitor** $C_m$ | A large, stable capacitor between reactor and ground. The voltage across it gives the charge. |
| **Rogowski coil** | A coil around a wire that measures the current through the wire without contact. |
| **Probe compensation** | Tuning of an oscilloscope probe so it passes fast and slow signals equally. A badly tuned probe distorts and delays the signal. |
| **Phase / time delay** | A shift in time between two signals. Even 1 µs between $V$ and $Q$ changes the measured power and capacitances noticeably. |
| **Quantisation** | The oscilloscope stores values in discrete steps (8–12 bit). The step size depends on the chosen vertical range and sets the smallest detectable change. |
| **Equivalent circuit** | A simplified electrical model of the reactor (capacitors plus a plasma element) used to interpret the measurements. |
| **Lissajous figure / Q–V diagram** | Plot of charge against voltage over one period. |
| **Packed bed** | Gap filled with beads or pellets (catalyst or support). |
