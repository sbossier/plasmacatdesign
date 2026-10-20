# To do

## Before or shortly after the first public release
- [ ] Confirm the licence holder with the University of Antwerp (now: the author).
- [ ] Add ORCID, version and DOI to `CITATION.cff` (e.g. via a Zenodo release).
- [ ] After the upcoming publication: add example data (now gitignored in `example-data/`), e.g. on Zenodo with a DOI, ideally including the raw `.psdata` files and the no-plasma reference measurements. Decide the data licence (CC BY 4.0 planned).

## Code
- [ ] Make the folder layout that `parse_file_path` expects configurable, so others can use their own layout. Not a priority now.
- [ ] Convert the still-relevant notebooks in `ipynb/` to marimo notebooks with PEP 723 headers, and document them.
- [ ] Clean up the old environments (`requirements.txt`, `renv/`, `renv.lock`, `.venv`).
- [ ] Document the R scripts in `r/`.

## Physics and measurements (see docs/electrical/05-known-limitations.md)
- [ ] Decide how to treat the quadrature term of the plasma-off fit in Q0 and ΔQ_dis (now included). This needs a hot post-plasma no-plasma measurement.
- [ ] Measure the parasitic capacitance C_s (empty reactor, no plasma) and include it in the equations.
- [ ] Record a voltage-amplitude series to check where ζ_diel saturates (estimate of the true C_diel).
