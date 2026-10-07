# Print guide: resin printer

Tested on an **ELEGOO Saturn 4 Ultra 16K** with **ABS-like 3.0+ grey** resin, sliced in CHITUBOX (free). Other resin printers work the same way. Only the menu names change.

## Orientation

- Put the model **standing flat on the plate**, **solid** (no hollowing). A hollow plinth printed flat gets an unsupported cavity roof and is hard to drain.
- Two 100 mm dragons fit side by side on the 211 mm axis (each ~88 × 87 mm).

## CHITUBOX (free): Auto Support → Parameters Panel

**Raft section**
- Model Lift Height **0**
- Automatically Add Raft **off**

**Bottom section**
- Platform Contact Shape **None**. Otherwise "Skate" bases merge into a raft-like plate around the base.

**Top section**
- Contact Type None
- Cross-section **Cone**
- Contact Diameter **0.25 mm**
- Contact Depth **0.2 mm**

**General**
- Max Top Angle 45°
- Contact Point Spacing 2.0 mm
- Mode **+All**. The chin and hanging claws sit above the rock, and nothing from the plate reaches them.
- Add **Cross Bracing** to tall columns.

**After generating**
- Overhang Detection / Detect Island must be **0**.
- Existing rafts are separate objects. **Clear All** doesn't remove them. Delete them with the Raft tool.

## ELEGOO SatelLite equivalents

- Z Lift Height **0**
- Advanced Mode → Upper Contact Point: untick **Spherical Contact** (removes the ball tips)
- Model Penetration Depth **0.2 mm**
- Tip Width **0.3 mm**

## Printer settings

- Layer height **0.05 mm**
- Normal exposure **3.25 s**
- Bottom exposure **30 s**
- **4** bottom layers, **10** transition layers
- Tank heating on. Start only at **30 °C** vat temperature.
- Shake the resin bottle well.

## Check adhesion

Pause around layer **30–40** (~10 min) and look at the plate. Two bases on it = resume.

## Never pause a print overnight

I lost one of two dragons that way. If you must stop, cancel and restart.

## Post-processing

1. Wash.
2. Warm water soak (40–50 °C).
3. Clip the supports with flush cutters **before** the final UV cure.
4. Cure.

Mark which print is which (pencil under the base).

## Slicer says the model is ~1 mm?

Your slicer may ask whether the model is in inches. Answer **No**, then scale the model to your target height.

## Support raft merges with the base?

Check Platform Contact Shape is **None** and Automatically Add Raft is **off** (see above). Delete leftover rafts with the Raft tool, then generate the supports again.
