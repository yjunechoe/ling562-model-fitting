# using MKL
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
CYC_2022 = Arrow.Table("CYC_2022.arrow");
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
## Aside: https://www.youtube.com/watch?v=y6KpCEW88gQ

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

# Overfitting diagnostics
issingular(mod_max)
mod_max.rePCA
mod.σρs
MixedModels.likelihoodratiotest(mod, mod_max)

###########################
# Performance on PNC data #
###########################

PNC_ay = Arrow.Table("PNC_ay.arrow");
PNC_ay_tbl = Table(PNC_ay)
PNC_fm_max = @formula(
  vheight ~ birthyear_z2 * allophone * gender + logdur_z2 + frequency_z2 +
                (1 + allophone + logdur_z2 + frequency_z2 | participant) +
                (1 + birthyear_z2 * gender + logdur_z2 | word)
);

# brrr
PNC_mod_max = @time fit(MixedModel, PNC_fm_max, PNC_ay);
PNC_mod_max
dof(PNC_mod_max)
issingular(PNC_mod_max)

# Inspect random effects
length(unique(PNC_ay.participant))
length(unique(PNC_ay.word))
shrinkageplot(PNC_mod_max, :participant; ellipse=true)
shrinkageplot(PNC_mod_max, :word; ellipse=true)

# Diagnose suspicious shrinkage
## Function to get the "red dots" (unconditional fits)
function uncond_raneftables(m::LinearMixedModel)
  m_uncond = deepcopy(m);
  m_uncond.θ = m.optsum.initial .* 1e4;
  updateL!(PNC_mod_max_uncond)
  raneftables(PNC_mod_max_uncond)
end ;
ranef_uncond = uncond_raneftables(PNC_mod_max);

## words
ranef_word = ranef_uncond.word
ranef_word[sortperm(ranef_word.birthyear_z2, rev=true)] # Check in R!

## participants
ranef_participant = ranef_uncond.participant
ranef_participant[sortperm(ranef_participant.logdur_z2)]
ranef_participant[sortperm(ranef_participant.var"allophone: ay0", rev=true)]

# Try with excluding outliers and simplifying formula
PNC_filtered = filter(
  row -> row.word != "RIFLES" && row.participant ∉ ["PH91-2-19", "PH80-2-08"],
  Table(PNC_ay)
);
PNC_mod_simple = @time fit(
  MixedModel,
  @formula(
    vheight ~ birthyear_z2 * allophone * gender + logdur_z2 + frequency_z2 +
                          (1 + allophone | participant) +
                  zerocorr(0 + logdur_z2 + frequency_z2 | participant) +
                  zerocorr(1 + birthyear_z2 + logdur_z2 | word)
  ),
  PNC_filtered
);
PNC_mod_simple

issingular(PNC_mod_simple)
shrinkageplot(PNC_mod_simple, :participant; ellipse=true)
shrinkageplot(PNC_mod_simple, :word; ellipse=true)
shrinkageplot(PNC_mod_simple, :word; ellipse=true, cols = ["birthyear_z2", "logdur_z2"])

###################
# Counterfactuals #
###################

mod

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

#################
# Miscellaneous #
#################

# Power analysis is just bootstrapping on **simulated data**
## - Specify the X (dataframe minus column for response var)
##   - "A sample you're likely to see, given distribution of characteristics in the population"
## - Specify the low end of effect size (fixed effects)
##   - "I want to detect a size at least as big as..."
## - Specify expected degree of noise (random effects)
##   - "The signal to noise ratio is ..."
# For example, see: https://repsychling.github.io/MixedModelsSim.jl/stable/simulation_tutorial/
