library(lme4)
library(arrow)

CYC_2022 <- read_feather("data/CYC_2022.arrow")
dim(CYC_2022)

# "While Anna dressed the baby stopped crying."
CYC_2022 |>
  subset(Item == "Dressed")

# Convergence failure: is this a false positive?
fm <- Accuracy ~ Condition * SemanticFit * Transitivity +
  (1 | Item) +
  (1 + Condition | Subject)

mod1 <- glmer(fm, CYC_2022, binomial())
summary(mod1)

# Some slides on convergence: https://rpubs.com/palday/lme4-singular-convergence
# Also: https://stats.stackexchange.com/questions/384528/lme-and-lmer-giving-conflicting-results/

# Information of interest
mod1@optinfo$optimizer
mod1@optinfo$feval
mod1@optinfo$conv
-2 * as.numeric(logLik(mod1))

# Descriptions of optimizer options (see also `?convergence`)
lobstr::tree(glmerControl()) # Also: `lmerControl()`
unname(unstack(nloptr::nloptr.get.default.options()[, c("description", "name")]))

# Turn it off approach:
# - https://github.com/RePsychLing/SMLP2023/discussions/24

## 1) more lenient tol for gradient
mod2 <- glmer(
  fm, CYC_2022, binomial(),
  control = glmerControl(check.conv.grad = .makeCC("warning", tol = 0.005, relTol = NULL))
)
mod2@optinfo$feval
-2 * as.numeric(logLik(mod2))

## 2) turn check off
mod3 <- glmer(
  fm, CYC_2022, binomial(),
  control = glmerControl(calc.derivs = FALSE)
)
mod3@optinfo$feval
-2 * as.numeric(logLik(mod3))


# Try harder approach:

## 1) Use stricter precision: (see `?convergence`)
mod4 <- glmer(
  fm, CYC_2022, binomial(),
  control = glmerControl(
    optimizer = "Nelder_Mead",
    optCtrl = list(
      # factors of -1e3
      FtolAbs = 1e-8,
      FtolRel = 1e-18,
      XtolRel = 1e-10
    )
  )
)
mod4@optinfo$feval
mod4@optinfo$conv
-2 * as.numeric(logLik(mod4))

## 2) Switch optimizer: bobyqa (see also: `allFit()`)
mod5 <- glmer(
  fm, CYC_2022, binomial(),
  control = glmerControl(
    optimizer = "bobyqa",
    # optCtrl = list(rhobeg = 2e-1, rhoend = 2e-3) # to force failure
  )
)
mod5@optinfo$optimizer
mod5@optinfo$feval
-2 * as.numeric(logLik(mod5))

## 3) Play around with starting values back on NelderMead
mod6 <- glmer(
  fm, CYC_2022, binomial(),
  start = list(
    theta = mod5@theta,
    fixef = mod5@beta # only for glmer
  )
)
mod6@optinfo$optimizer
mod6@optinfo$feval
-2 * as.numeric(logLik(mod5))
c(mod6@beta, mod6@theta) - c(mod5@beta, mod5@theta)

# Misc: reading `verbose = TRUE` output
mod_debug <- glmer(
  fm, CYC_2022, binomial(),
  control = glmerControl(),
  verbose = TRUE # c(theta, beta)
)
mod_debug@optinfo$feval

# Julia goes brrr
library(jlme) # install.packages("jlme")
jlme_setup()
jmod <- jlmer(fm, CYC_2022, binomial())
jmod$objective
jmod$optsum

# Misc: visualize fit (lme4 equivalent of verbose, but more precise)
optsum <- jlmer(fm, CYC_2022, binomial(), thin = 1L)$optsum
# Parameter estimates plot
t(sapply(jl_get(optsum$fitlog), \(x) x[[1]])) |> 
  matplot(type = "l")
# Objective/Deviance plot
plot(sapply(jl_get(optsum$fitlog), `[[`, 2), type = "l", ylab = "-2logLik")

# Misc: contrasts
CYC_2022$Condition <- as.factor(CYC_2022$Condition)
contrasts(CYC_2022$Condition)

CYC_2022_v2 <- CYC_2022
contrasts(CYC_2022_v2$Condition) <- -contr.sum(2)
contrasts(CYC_2022_v2$Condition)
jmod_v2 <- jlmer(fm, CYC_2022_v2, binomial())

tidy(jmod_v2) |> 
  subset(term == "ConditionVerb")
tidy(jmod) |> 
  subset(term == "ConditionVerb")

jl_contrasts(CYC_2022_v2, cols = "Condition", show_code = TRUE)
MASS::ginv(contrasts(CYC_2022_v2$Condition))
