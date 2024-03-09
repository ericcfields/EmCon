#Analysis of behavioral memory variables for EmCon
#
#Author: Eric Fields
#Version Date: 8 March 2024

#Copyright (c) 2021, Eric Fields
#All rights reserved.
#This code is free and open source software made available under the 3-clause BSD license.

library(stringr)
library(readr)
library(tibble)
library(tidyr)
library(dplyr)
library(lme4)
library(afex)
library(car)
library(emmeans)
library(performance)
library(ggplot2)

setwd("C:/Users/fieldsec/OneDrive - Westminster College/Documents/ECF/Research/EmCon/DATA/stats/behavioral")

#Set default contrast to deviation coding
options(contrasts = rep("contr.sum", 2))


contr.simple <- function(n_levels) {
  #Create simple coding matrix for a variable with n_levels
  #See: https://stats.idre.ucla.edu/r/library/r-library-contrast-coding-systems-for-categorical-variables/
  n_predictors <- n_levels - 1
  c <- contr.treatment(n_levels) - matrix(rep(1/n_levels, n_levels*n_predictors), ncol=n_predictors)
  return(c)
}

make_lmer_table <- function(m, ci_method="Wald", alpha=0.05) {
  #Create more readable table of lmer results
  
  #Get relevant stats
  coeff_table <- summary(m)$coefficients
  ci_table <- confint.merMod(m, method=ci_method, level=1-alpha)
  
  #Create results table from these stats
  res_table <- data.frame()
  res_table["intercept", colnames(coeff_table)] <- coeff_table["(Intercept)",]
  res_table["intercept", colnames(ci_table)] <- ci_table["(Intercept)",]
  for (pred_name in rownames(coeff_table)[-1]) {
    res_table[pred_name, colnames(coeff_table)] <- coeff_table[pred_name,]
    res_table[pred_name, colnames(ci_table)] <- ci_table[pred_name,]
  }
  
  #More usable column names
  colnames(res_table) <- c("estimate", "se", "df", "t", "pvalue", "CI_L", "CI_U")
  
  return(res_table)
  
}


################################### IMPORT DATA ###################################

#Import data
data <- read_csv("EmCon_memory_long.csv")

#Get only neutral and negative conditions
data <- data[data$valence!="animal", ]

#Set factors and contrast schemes
data$valence <- factor(data$valence)
contrasts(data$valence) <- contr.simple(nlevels(data$valence))
data$delay <- factor(data$delay)
contrasts(data$delay) <- contr.simple(nlevels(data$delay))


################################### SET-UP ###################################

DVs <- colnames(data)[4:14]

anova_test_method <- "F"
ci_method <- "profile"

################################### Valence x Delay Models ###################################

all_results <- data.frame()
for (DV in DVs) {
  
  #Model formula
  f <- as.formula(sprintf("%s ~ 1 + valence*delay + (1 + valence + delay | sub_id)", DV))
  
  #Estimate lmer model
  cat(sprintf("\nEstimating model for %s\n", DV))
  m <- lmer_alt(f, data=data,
                expand_re=TRUE, 
                REML=TRUE,
                type=3,
                method="KR",
                check_contrasts=FALSE,
                test_intercept=TRUE,
                all_fit=TRUE)
  
  res_table <- make_lmer_table(m, ci_method=ci_method)
  
  #Add Cohen's d
  s <- sqrt(sum(as.data.frame(VarCorr(m))$vcov))
  for (row in rownames(res_table)[-1]) {
    res_table[row, "d"] <- res_table[row, "estimate"] / s
  }
  
  #Update all results table
  all_results[DV, "intercept"] <- res_table["intercept", "estimate"]
  all_results[DV, "val_b"] <- res_table["valence2", "estimate"]
  all_results[DV, "val_d"] <- res_table["valence2", "d"]
  all_results[DV, "val_p"] <- res_table["valence2", "pvalue"]
  all_results[DV, "delay_b"] <- res_table["delay2", "estimate"]
  all_results[DV, "delay_d"] <- res_table["delay2", "d"]
  all_results[DV, "delay_p"] <- res_table["delay2", "pvalue"]
  all_results[DV, "interaction_b"] <- res_table["valence2:delay2", "estimate"]
  all_results[DV, "interaction_d"] <- res_table["valence2:delay2", "d"]
  all_results[DV, "interaction_p"] <- res_table["valence2:delay2", "pvalue"]
  
}

write.csv(all_results, "EmCon_memory_results.csv")
