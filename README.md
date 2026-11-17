# CNCmacros

A public collection of CNC G-code macros and the supporting tools used to develop and validate them.

## Contents

- `o9070.nc` - Bolt-hole circle macro.
- `BCD-REPAIR.NC` - Recover a bolt-hole circle from G54.1 P1/P2 probe offsets and call `o9070.nc` (`D` diameter, `A` hole count, optional `Q` tolerance; default `0.002`).
- `BCD-EXAMPLE.nc` - Example call for the bolt-hole circle macro.
- `O9010_TORUS_CONTOUR_V3.nc` - Torus contour macro.
- `O9010_TORUS_VALIDATOR_V3.xlsx` - Validator workbook for the torus contour macro.

## License

This project is licensed under the [MIT License](LICENSE).
