# 2. Equivalent circuits: the models behind the numbers

Plasma power can be measured without any model ([page 1](01-what-we-measure.md#plasma-power-the-area-of-the-loop)). Everything else needs a model of the reactor.

An **equivalent circuit** replaces the real reactor by a few capacitors and a "plasma" element that only conducts while the discharge burns. Applying the basic laws of circuits (Kirchhoff's laws) to it gives formulas that turn the measured $V(t)$ and $Q(t)$ into internal quantities such as the gas voltage or the plasma current.

Several models exist. Each fixes a shortcoming of the previous one, and none was derived for packed beds. This page describes them from simple to complex, then says which one the code uses for which output.

Notation: $V$ is the applied voltage, $Q$ the measured charge, $f$ the frequency, $V_0$ the voltage amplitude, $C_\text{diel}$ the dielectric capacitance, $C_\text{gap}$ the gap capacitance, $C_\text{cell}$ the cell capacitance (no plasma), and $\zeta_\text{diel}$ the slope while the plasma is on.

---

## 2.1 The simplest equivalent circuit (Manley; Pipa; Peeters & Butterworth)

```
   V ──┤ C_diel ├──┬──┤ C_gap ├──┬── ground (via monitor capacitor)
                   │             │
                   └──[ plasma ]─┘   conducts only while the discharge burns
```

**Assumes:**
- The dielectric and the gas gap are two capacitors in series.
- The plasma is a switch-like element across the gap.
- The whole electrode area discharges, and the gap voltage stays constant while it does.

**Gives** (Peeters & Butterworth 2019, eqs. 2–4; Brandenburg 2017, eqs. 3–6):

$$
\frac{1}{C_\text{cell}} = \frac{1}{C_\text{diel}} + \frac{1}{C_\text{gap}}
$$

$$
i_\text{plasma}(t) = \frac{1}{1 - C_\text{cell}/C_\text{diel}} \left( \frac{dQ}{dt} - C_\text{cell}\frac{dV}{dt} \right)
\qquad
U_\text{gap}(t) = V(t) - \frac{Q(t)}{C_\text{diel}}
$$

**In words:**
- To get the current through the plasma, take the measured current and remove the part that only charges the capacitors, $C_\text{cell}\,dV/dt$.
- Then scale the result up by $1/(1-C_\text{cell}/C_\text{diel})$. This factor accounts for the energy stored in the gap before ignition, which drains through the plasma once it ignites.
- Peeters & Butterworth (2019, §2.2) stress that leaving out this factor is a common error. It underestimates the plasma current and overestimates the "displacement current".

**Shortcoming:** it predicts a slope of exactly $C_\text{diel}$ while the plasma is on. Real reactors often show a lower, voltage-dependent slope.

## 2.2 Partial surface discharging (Peeters & van de Sanden 2015)

```
   fraction α (not discharging):  ┤ αC_diel ├──┤ αC_gap ├
   fraction β (discharging):      ┤ βC_diel ├──┤ βC_gap ├ ∥ [plasma]
                                    α + β = 1
```

**Assumes:** only a fraction $\beta$ of the electrode area discharges. The rest ($\alpha$) stays a plain capacitor.

**Gives** (P15, eqs. 6–8, 13, 16, 3):

$$
\zeta_\text{diel} = \alpha C_\text{cell} + \beta C_\text{diel}
\quad\Rightarrow\quad
\alpha = \frac{C_\text{diel} - \zeta_\text{diel}}{C_\text{diel} - C_\text{cell}},\qquad
\beta = \frac{\zeta_\text{diel} - C_\text{cell}}{C_\text{diel} - C_\text{cell}}
$$

$$
U_b = \frac{1 - C_\text{cell}/C_\text{diel}}{1 - C_\text{cell}/\zeta_\text{diel}}\,\Delta U
\qquad
\Delta Q_\text{dis} = \frac{Q_0}{1 - C_\text{cell}/C_\text{diel}}
$$

$$
U_\text{gap}(t) = \left(1 + \frac{\alpha C_\text{cell}}{\beta C_\text{diel}}\right)V(t) - \frac{Q(t)}{\beta C_\text{diel}}
$$

Here $\Delta U$ is half the distance between the two points where the Q–V loop crosses $Q = 0$, and $Q_0$ is the vertical distance between the two plasma-off lines at $V = 0$.

**In words:**
- A plasma-on slope below $C_\text{diel}$ means part of the electrode never sees plasma.
- Correcting for this changes the burning voltage and the transferred charge. Without the correction the burning voltage is underestimated and the transferred charge overestimated.
- The plasma current formula does not change (P15, appendix A.1).

**Shortcoming:**
- It needs the true $C_\text{diel}$, which is usually calculated from geometry.
- It assumes a uniform gap and a parallelogram-shaped figure.

## 2.3 Parasitic (stray) capacitance (Brandenburg et al. 2023; Falkenstein & Coogan 1997)

```
   [ circuit of 2.2 ]  in parallel with  ┤ C_s ├   (cables, holder, edges, packing)
```

**Assumes:** an extra capacitance $C_s$ in parallel with the reactor that never discharges.

**Effect:**
- Both measured slopes become larger by $C_s$: you measure $C_\text{cell} + C_s$ and $\zeta_\text{diel} + C_s$.
- The power is not affected.
- The gap voltage and the transferred charge are (Brandenburg et al. 2023, eqs. 7–10):

$$
U_D = V_\text{min}\left(1 - \frac{C_\text{cell}}{C_\text{diel}}\right) = \frac{\Delta U}{1 + (\alpha C_\text{cell} + C_s)/(\beta C_\text{diel})}
$$

$V_\text{min}$ is the smallest voltage amplitude that sustains the discharge. On the Q–V figure it is half the voltage span from the voltage maximum to the ignition point (Brandenburg et al. 2023, Fig. 3).

**In words:** stray capacitance makes the reactor look bigger than it is. It must be subtracted before the slopes are interpreted. It can be found by measuring the empty reactor without plasma and comparing with the geometric $C_\text{cell}$ (De Meyer et al. 2025, §4.1).

## 2.4 Maximum measured dielectric capacitance (De Meyer et al. 2025)

**Situation:**
- The plasma spreads beyond the electrode edge, or the charge spreads over a conductive layer on the dielectric.
- The measured $\zeta_\text{diel}$ then *exceeds* the geometric $C_\text{diel}$, and $\beta$ becomes larger than 1, which is unphysical.

**Fix:**
- Use the largest $\zeta_\text{diel}$ measured for that configuration, $C^\text{max}_\text{diel}$, instead of the geometric value.
- Keep the geometric $C_\text{cell}$.
- Subtract $C_\text{par}$ first (De Meyer et al. 2025, eqs. 6, 9–11).

Relevant for metal-loaded catalysts, which can make the packing surface conductive (De Meyer et al. 2024).

## 2.5 Packed beds (Butterworth & Allen 2017; Peeters & Butterworth 2019 §3.2)

No complete equivalent circuit for packed beds exists yet (Butterworth & Allen 2017, §2.5; De Meyer et al. 2024, §2.3). Researchers apply the partial-discharging model of §2.2 with these caveats:

- **What $\alpha$ means changes.** In a packed bed, $\alpha$ mixes two effects that cannot be separated electrically: electrode area that does not discharge, and charge that stays trapped on the beads instead of crossing the gap ("polar" or point-to-point discharges).
- **The "series parallel-plate" model is inconsistent.** Writing $1/C_\text{cell} = 1/C_\text{diel} + 1/C_\text{gas} + 1/C_\text{packing}$ gives contradictions once $\zeta_\text{diel}$ depends on voltage (Butterworth & Allen 2017, §2.5).
- **Almond-shaped figures.**
  - The plasma ignites first where the beads touch, where the field is strongest. It then spreads outwards as the voltage rises, so the slope grows during the half-period.
  - The burning voltage is therefore **not constant** (Butterworth & Allen 2017, §3.6). A single $U_b$, and an average reduced field $E/N$ derived from it, is then not a valid description.
  - Peeters & Butterworth (2019, §3.2) recommend taking $C_\text{diel}$ from the steepest slope ($\zeta_\text{max}$) at the highest voltage.

## 2.6 Elliptical figures and parasitic resistance (Peeters & Butterworth 2019 §3.3; Brandenburg 2017)

A Q–V figure without straight segments is not a parallelogram, and the models above do not apply. At atmospheric pressure, true elliptical behaviour (a plasma that conducts during the whole period) is not expected (PB19 §3.3). More likely causes:
- an unstable discharge averaged over many periods;
- a measurement error: stray capacitance or inductance, or a delay between the voltage and charge probes;
- a weak residual plasma that slightly raises the plasma-off slope;
- a **parasitic resistance** $R_\text{par}$: a lossy element such as a heated, slightly conductive dielectric. It rounds the corners at the end of the discharge and can turn the figure into an ellipse. The enclosed area then includes losses that are not plasma (Brandenburg 2017, section "Electrical behavior and characterization").

A no-plasma measurement (voltage below ignition) separates measurement artefacts from physics. A reactor without plasma should give a straight line through the origin.

---

## Which model does this code use where?

| Output | Model | Notes |
|---|---|---|
| `power_plasma_W`, `power_plasma_UIprod_W` | none | Area of the loop and mean of $V\cdot I$. Model-free. |
| `C_cell_*`, `C_diel_eff_*`, `C_diel_eff_max_*` | slopes, with a fit that also includes a lag term (see below) | Measured values; they include stray capacitance. |
| `alpha_*`, `beta_*`, `U_burning_*` | Partial discharging (§2.2) | Assume a parallelogram and a constant burning voltage. |
| `U_breakdown_*` ($U_D$) | Brandenburg et al. 2023 eq. 9 with $C_s = 0$ | Uses only $C_\text{cell}$ and the ignition point. More robust than $U_b$ for almond figures. |
| `Q_delta_dis_*` | P15 eq. 16 | Depends on $C_\text{diel}$ and on how $Q_0$ is defined (see limitations). |
| `current_plasma_A`, pulse metrics | Simplest circuit (§2.1, with prefactor) | Same in §2.1 and §2.2. |
| `voltage_gap_V` (profile) | Partial discharging (§2.2) | Assumes a constant $U_b$; not well defined for almond figures. |
| `C_diel_F` (input) | Geometric value | Not the maximum measured slope of §2.4. |

### Where the models are mixed

1. **Lag term in the plasma-off fit.**
   - To get a window-independent $C_\text{cell}$, the code fits the plasma-off branch as $Q = C_\text{cell}V + b\,dV/dt + c$.
   - The extra term $b\,dV/dt$ behaves like a parallel resistance (§2.6).
   - All later formulas use the circuits above, which have no such element.
2. **Capacitance sources.** The measured slopes include stray capacitance and the packing, while $C_\text{diel}$ is geometric (§2.3, §2.4).
3. **Plane-parallel model on a packed bed.** The partial-discharging model was derived for a uniform gap (§2.5).

[Known limitations](05-known-limitations.md) quantifies each of these on real data.
