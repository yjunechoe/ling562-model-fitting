using Arrow
using Random
using Statistics
using MixedModels
using CairoMakie
using MixedModelsMakie

###############################
# A sampler of MixedModels.jl #
###############################

# Continuing from R script
CYC_2022 = Arrow.Table("CYC_2022.arrow")
Table(CYC_2022)

fm = @formula(
  Accuracy ~ Condition * SemanticFit * Transitivity +
    (1 | Item) +
    (1 + Condition | Subject)
);

#     jlmer(fm, CYC_2022, binomial())
mod = fit(MixedModel, fm, CYC_2022, Bernoulli());
mod
coeftable(mod)
mod.objective

# Plots for parameter estimates (fixed and random effects)
coefplot(mod; show_intercept=false)
caterpillar(mod)
shrinkageplot(mod; ellipse=true)

# Bootstrapped confidence intervals
mod_boot = parametricbootstrap(
  MersenneTwister(42), 100, mod;
  optsum_overrides=(;ftol_rel=1e-8)
)
ridgeplot(mod_boot; show_intercept=false)
Table(shortestcovint(mod_boot))

# Contrasts (see `jlme::jl_formul()` in R)
contrasts = Dict(
    :Condition => HypothesisCoding(
        [
            -1/2 1/2
        ];
        levels = ["Subject", "Verb"],
        labels = ["Verb"],
    ),
);
mod_v2 = fit(MixedModel, fm, CYC_2022, Bernoulli(); contrasts);
mod_v2.β
mod.β

# Maximal model
fm_max = @formula(
  Accuracy ~ Condition * SemanticFit * Transitivity
    + (1 + Condition | Item)
    + (1 + Condition * SemanticFit * Transitivity | Subject)
);
mod_max = fit(MixedModel, fm_max, CYC_2022, Bernoulli());
dof(mod_max)

# Diagnostics
issingular(mod_max)
mod_max.rePCA
mod.σρs
MixedModels.likelihoodratiotest(mod, mod_max)

##################################
# Embrace (vs. tame) uncertainty #
##################################

# Counterfactuals

## Models store the response vector 
CYC_2022.Accuracy
mod.resp.y
mean(mod.resp.y)

## New response vector can be simulated from model's existing params
mean(simulate(mod))

## Take this one step further to do a "round-tripping" experiment:
## Step 1) From model's params, derive a new param vector
simmod = deepcopy(mod);
simβ1 = copy(mod.β);
simβ1[1] = -2;
simβ1
## Step 2) From new params, simulate a response vector and refit the model
simulate!(simmod, β = simβ1)
mean(simmod.resp.y)
## Step 3) See if you can recover the inputted params
fit!(simmod);
simmod

## Scale up simulate() with parametricbootstrap()
simboot = parametricbootstrap(
  MersenneTwister(42), 100, mod;
  β = simβ1,
  optsum_overrides=(;ftol_rel=1e-8)
)
ridgeplot(simboot)
ridgeplot(mod_boot)

## Other experiments:
mod
## - Triple the contribution of random effects
ridgeplot(parametricbootstrap(
  MersenneTwister(42), 100, mod;
  θ = mod.θ .* 3,
  optsum_overrides=(;ftol_rel=1e-8)
); show_intercept=false)
## - Using half of the data
size(Table(CYC_2022), 1) ÷ 2
mod_half = fit(MixedModel, fm, Table(CYC_2022)[1:706], Bernoulli())
ridgeplot(parametricbootstrap(
  MersenneTwister(42), 100, mod_half;
  optsum_overrides=(;ftol_rel=1e-8)
); show_intercept=false)

# Power analysis is just bootstrapping on **simulated data**
## - Specify the X (dataframe minus column for response var)
##   - "A sample you're likely to see, given distribution of characteristics in the population"
## - Specify the low end of effect size (fixed effects)
##   - "I want to detect a size at least as big as..."
## - Specify expected degree of noise (random effects)
##   - "The signal to noise ratio is ..."
# For example, see: https://repsychling.github.io/MixedModelsSim.jl/stable/simulation_tutorial/
