# Non-convergence and overparameterization in mixed-effects models: strategies in R and Julia

Guest lecture. December 4, 2024.

## Instructions

Scripts are to be ran in the order of `01-convergence-diagnostics.R` then `02-model-fitting-interpretation.jl`.

For best experience running Julia scripts from RStudio, go to `Tools > Modify Keyboard Shortcuts` and bind the command `Send Selection to Terminal` (I use <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>Enter</kbd>).

## Files

```
.
├── data
│   ├── CYC_2022.arrow
│   └── PNC_ay.arrow
├── Project.toml
├── ...
└── scripts
    ├── 01-convergence-diagnostics.R
    └── 02-model-fitting-interpretation.jl
```

> [!IMPORTANT]  
> `PNC_ay.arrow` is a derivative of the Philadelphia Neighborhood Corpus data and must be copied into the repo separately. Instructions on this will be delivered in class.

## See also

- My prior [guest lecture](https://github.com/yjunechoe/ling5620-julia-demo) on MixedModels.jl
- MixedModels.jl [documentation website](https://juliastats.org/MixedModels.jl/stable/)
- Embrace Uncertainty [book](https://embraceuncertaintybook.com/)
