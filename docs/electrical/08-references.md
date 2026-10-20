# 8. References

The selected literature focuses on the electrical diagnostics of DBDs and, where available, of packed-bed and coaxial reactors. The PDFs are not redistributed with this repository; follow the DOIs.

## Core references

| Short | Reference | Used for |
|---|---|---|
| **P15** | F. J. J. Peeters, M. C. M. van de Sanden, *The influence of partial surface discharging on the electrical characterization of DBDs*, Plasma Sources Sci. Technol. **24**, 015016 (2015). [doi:10.1088/0963-0252/24/1/015016](https://doi.org/10.1088/0963-0252/24/1/015016) | Partial-discharging circuit: $\alpha$, $\beta$, $U_b$, $\Delta Q_\text{dis}$, gap voltage, plasma charge; zero-mean charge |
| **PB19** | F. Peeters, T. Butterworth, *Electrical Diagnostics of Dielectric Barrier Discharges*, in: Atmospheric Pressure Plasma – from Diagnostics to Applications, IntechOpen (2019). [doi:10.5772/intechopen.80433](https://doi.org/10.5772/intechopen.80433) | Q–V basics, power from the loop area, plasma current with the correct prefactor, monitor capacitor choice, noise and ringing, almond and elliptical figures, $\zeta_\text{max}$ |
| **B&A17** | T. Butterworth, R. W. K. Allen, *Plasma-catalyst interaction studied in a single pellet DBD reactor: dielectric constant effect on plasma dynamics*, Plasma Sources Sci. Technol. **26**, 065008 (2017). [doi:10.1088/1361-6595/aa6c35](https://doi.org/10.1088/1361-6595/aa6c35) | Packed beds: meaning of $\alpha$, charge trapping, almond shapes, variable burning voltage, limits of the packed-bed circuit |
| **B17** | R. Brandenburg, *Dielectric barrier discharges: progress on plasma sources and on the understanding of regimes and single filaments*, Plasma Sources Sci. Technol. **26**, 053001 (2017). [doi:10.1088/1361-6595/aa6426](https://doi.org/10.1088/1361-6595/aa6426). Corrigendum: Plasma Sources Sci. Technol. **27**, 079501 (2018), which corrects the gap voltage equation (5) to $U_g = V - Q/C_d$. | Review: the simplest circuit, parasitic resistance and stray capacitance, rounded corners, determining $C_d$ from $Q_0$ vs $V_0$ |
| **B23** | R. Brandenburg, M. Schiorlin, M. Schmidt, H. Höft, A. V. Pipa, V. Brüser, *Plane Parallel Barrier Discharges for Carbon Dioxide Splitting: Influence of Discharge Arrangement on Carbon Monoxide Formation*, Plasma **6**, 162–180 (2023). [doi:10.3390/plasma6010013](https://doi.org/10.3390/plasma6010013) | Breakdown voltage $U_D$ from $V_\text{min}$, stray capacitance in the circuit, generalised Manley power |
| **DM24** | R. De Meyer, Y. Gorbanev, R.-G. Ciocarlan, P. Cool, S. Bals, A. Bogaerts, *Importance of plasma discharge characteristics in plasma catalysis: Dry reforming of methane vs. ammonia synthesis*, Chem. Eng. J. **488**, 150838 (2024), incl. supporting information. [doi:10.1016/j.cej.2024.150838](https://doi.org/10.1016/j.cej.2024.150838) | Coaxial packed-bed reactor of the same type, $C_\text{diel}$ of a tube, spectral ("FFT") microdischarge quantity, why the Pearson 4100 cannot count single microdischarges, power methods compared |
| **DM25** | R. De Meyer, P. Cimento, R. Brandenburg, J. Verbeeck, S. Coulombe, A. Bogaerts, *Electrical characterization of an atmospheric pressure Townsend discharge exposed to a conductive layer: an update of the equivalent circuit*, Plasma Sources Sci. Technol. **34**, 105005 (2025). [doi:10.1088/1361-6595/ae0af6](https://doi.org/10.1088/1361-6595/ae0af6) | Parasitic capacitance correction, $C^\text{max}_\text{diel}$, plasma-off reference measurements, $V_\text{min}$ and $U_D$ |

## Background

| Reference | Note |
|---|---|
| J. Yao et al., *A study on the equivalent electric circuit simulation model of DBD streamer and glow alternate discharge*, J. Phys.: Conf. Ser. **418**, 012023 (2013). [doi:10.1088/1742-6596/418/1/012023](https://doi.org/10.1088/1742-6596/418/1/012023) | Circuit *simulation* of a pin-to-plane DBD with streamer and glow modes in alternate half-periods. Not used in the calculations. It illustrates why the two half-periods (`_neg`, `_pos`) can differ. |

## Cited through the references above (not checked against the original)

- T. C. Manley, *The electric characteristics of the ozonator discharge*, Trans. Electrochem. Soc. **84**, 83 (1943). Origin of Q–V analysis and the power equation.
- A. V. Pipa, J. Koskulics, R. Brandenburg, T. Hoder, *The simplest equivalent circuit of a pulsed dielectric barrier discharge and the determination of the gas gap charge transfer*, Rev. Sci. Instrum. **83**, 115112 (2012).
- A. V. Pipa, R. Brandenburg, *The equivalent circuit approach for the electrical diagnostics of dielectric barrier discharges: the classical theory and recent developments*, Atoms **7**, 14 (2019).
- Z. Falkenstein, J. J. Coogan, *Microdischarge behaviour in the silent discharge of nitrogen–oxygen and water–air mixtures*, J. Phys. D: Appl. Phys. **30**, 817 (1997). Parasitic capacitance.
- Uytdenhouwen et al.: reactor design and the packing-efficiency algorithm. TODO: add the full references.
