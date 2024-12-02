# Non-convergence and overparameterization in mixed-effects models: strategies in R and Julia

LING 5620 "Quantitative Study of Linguistic Variation" guest lecture. December 4, 2024. University of Pennsylvania.

## Instructions

Scripts are to be ran in the order of `01-convergence-diagnostics.R` then `02-model-fitting-interpretation.jl`.

For best experience running Julia scripts from RStudio, go to `Tools > Modify Keyboard Shortcuts` and bind the command `Send Selection to Terminal` (I use <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>Enter</kbd>).

## Files

```
.
├── data
│   ├── CYC_2022.arrow
│   └── PNC_ay.arrow
├── scripts
│   ├── 01-convergence-diagnostics.R
│   └── 02-model-fitting-interpretation.jl
├── Project.toml
└── ...
```

> [!IMPORTANT]  
> `PNC_ay.arrow` is a derivative of the Philadelphia Neighborhood Corpus data (not distributable by me) and must be copied into the repo separately. Instructions on this will be delivered in class.

## See also

- My prior [workshop](https://colab.research.google.com/drive/1eT-cb3_TAczLvs29_XpRH49oaySM4zW0?usp=sharing) and [guest lecture](https://github.com/yjunechoe/ling5620-julia-demo) on MixedModels.jl
- MixedModels.jl [documentation website](https://juliastats.org/MixedModels.jl/stable/) (see also [MixedModelsExtras.jl](https://palday.github.io/MixedModelsExtras.jl/stable/), [MixedModelsMakie.jl](https://palday.github.io/MixedModelsMakie.jl/stable/), [MixedModelsSim.jl](https://repsychling.github.io/MixedModelsSim.jl/stable/), [Effects.jl](https://beacon-biosignals.github.io/Effects.jl/stable/), etc.)
- Embrace Uncertainty [book](https://embraceuncertaintybook.com/)
- SMLP [workshop](https://repsychling.github.io/SMLP2024/) (I attended the [2023](https://repsychling.github.io/SMLP2023/) iteration)
