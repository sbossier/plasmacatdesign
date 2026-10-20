# plasmacatdesign

Analysis code for **packed-bed coaxial dielectric barrier discharge (DBD) plasma reactors**, used for plasma-catalytic CO₂ splitting and dry reforming of methane at the University of Antwerp.

This repository is being prepared for public use. The **electrical analysis pipeline** is documented and ready to use. The rest of the repository is work in progress (see [Repository status](#repository-status)).

## Who this is for

This is for researchers who record voltage, charge and current of a DBD reactor with an oscilloscope and want to turn those signals into numbers they can report. Examples are plasma power, the capacitances of the reactor, how much of the packed bed is discharging, the voltage across the gas, and an indicator of discharge pulses.

The documentation is written for **chemists**. It explains every quantity in plain language, says what it does and does not tell you, and gives the literature it comes from. No background in electrical engineering is assumed.

## What the electrical pipeline does

```
PicoScope .psdata captures          (one folder per reactor run)
        │  py/electrical/psdata_conversion_and_consolidation.py
        ▼
lissajous_data.parquet              (time, charge, voltage, currents + run metadata)
        │  py/electrical/lissajous_calculations.py
        ▼
lissajous_calculations.parquet               one row per AC cycle (all results)
lissajous_calculations_no_outliers.parquet   same, gross failures removed
lissajous_calculations_no_outliers_avg.csv   mean per oscilloscope capture
lissajous_figure.png                         average Q–V figure + capacitance check
profile_data.parquet                         down-sampled time traces incl. plasma current and gap voltage
```

## Quick start

1. Install [uv](https://docs.astral.sh/uv/getting-started/installation/). Each notebook declares its own dependencies in its header (PEP 723), so no virtual environment has to be set up by hand.
2. Open a notebook in the browser:
   ```
   uvx marimo edit --sandbox py/electrical/lissajous_calculations.py
   ```
   `--sandbox` is required, otherwise the dependencies in the header are ignored.
3. Set `top_folder` in the configuration cell to the folder with your data (default: `example-data/` in the repository root), and press **Run calculations**. The results are written next to each input file.
4. To run without the browser:
   ```
   uv run py/electrical/lissajous_calculations.py
   ```

Converting your own `.psdata` files needs PicoScope 6 (Windows). See [Adapting to your reactor](docs/electrical/07-adapting-to-your-reactor.md).

## Documentation

| | |
|---|---|
| [1. What we measure](docs/electrical/01-what-we-measure.md) | The reactor, the four signals, the Q–V (Lissajous) figure, glossary |
| [2. Equivalent circuits](docs/electrical/02-equivalent-circuits.md) | The electrical models behind the numbers, and where each one falls short |
| [3. Calculation steps](docs/electrical/03-calculation-steps.md) | Every step of the notebook: what, why, formula, reference |
| [4. Output columns](docs/electrical/04-output-columns.md) | Every output column: unit, meaning, how much to trust it |
| [5. Known limitations](docs/electrical/05-known-limitations.md) | What is uncertain in the results, with numbers |
| [6. Experimental guide](docs/electrical/06-experimental-guide.md) | How to record better data: probes, monitor capacitor, reference measurements |
| [7. Adapting to your reactor](docs/electrical/07-adapting-to-your-reactor.md) | Which settings to change for another reactor, frequency or oscilloscope |
| [8. References](docs/electrical/08-references.md) | Literature, with what each source is used for |

## Required folder layout

The conversion notebook reads the experiment description from the folder names, so the layout is fixed:

```
<parent folder>/<project>/<reaction>/<supplier>/<material>/<power mode>/lissajous/<residence time>s-<run number>-<plasma state>/<YYYYMMDD-NNNN>.psdata
example-data/   plasmacatdesign/co2-splitting/uhasselt/SiO2+TMAH-220-03H/pwr-const/lissajous/10.0s-01-plasma-01/
```

The details are in [Adapting to your reactor](docs/electrical/07-adapting-to-your-reactor.md#folder-layout). A more flexible layout is on the [to-do list](to-do.md).

## Repository status

| Path | Status |
|---|---|
| `py/electrical/` | Documented marimo notebooks (this README) |
| `example-data/` | Not yet included: example data will be published together with an upcoming paper |
| `ipynb/` | Older Jupyter notebooks (GC analysis, conversion fitting, other electrical analyses). **Undocumented.** They will be converted to marimo and documented over time. `ipynb/electrical/lissajous_calculations.ipynb` is the *previous* calculation method, kept for reference. |
| `r/` | R scripts for fitting and visualisation. **Undocumented.** |
| `requirements.txt`, `renv/`, `renv.lock` | Environments of the older notebooks. To be cleaned up. |

See [to-do.md](to-do.md).

## Licence and citation

- Code: [MIT](LICENSE).
- Documentation (`docs/`): [CC BY 4.0](LICENSE-docs.md).
- If you use this code, please cite it as described in [CITATION.cff](CITATION.cff).

The literature PDFs used to build this pipeline are not redistributed. See the [references](docs/electrical/08-references.md) for DOIs.
