#Analysis of behavioral memory variables for EmCon
#
#Author: Eric Fields
#Version Date: 9 March 2024

#Copyright (c) 2021, Eric Fields
#All rights reserved.
#This code is free and open source software made available under the 3-clause BSD license.


library(readr)
library(rstatix)
library(dplyr)
library(tidyr)
library(tidyselect)

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

add_cohens_d <- function(data, anova_results) {

  desc_stats <- data %>% group_by(valence, delay) %>% get_summary_stats(all_of(DV), type = "mean_sd")
  sp = sqrt(mean(desc_stats$sd^2))
  
  M_NEU <- mean(desc_stats[desc_stats$valence=="NEU", ]$mean)
  M_NEG <- mean(desc_stats[desc_stats$valence=="NEG", ]$mean)
  anova_table[anova_table$Effect == "valence", "d"] = (M_NEG - M_NEU) / sp
  
  M_I <- mean(desc_stats[desc_stats$delay=="I", ]$mean)
  M_D <- mean(desc_stats[desc_stats$delay=="D", ]$mean)
  anova_table[anova_table$Effect == "delay", "d"] = (M_D - M_I) / sp
  
  if (!all(desc_stats$valence == c("NEG", "NEG", "NEU", "NEU"))) {
    stop("Column order is not as expected.")
  }
  if (!all(desc_stats$delay == c("D", "I", "D", "I"))) {
    stop("Column order is not as expected.")
  }
  
  int_numerator <- ((desc_stats[1, "mean"] - desc_stats[3, "mean"]) -
                      (desc_stats[2, "mean"] - desc_stats[4, "mean"]))
  anova_table[anova_table$Effect == "valence:delay", "d"] = int_numerator / sp
  
  return(anova_table)
  
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


################################### Valence x Delay Models ###################################

DVs <- colnames(data)[4:14]

all_results <- data.frame()
for (DV in DVs) {
  
  anova_result <- anova_test(data, dv=all_of(DV), wid=sub_id, within=c(valence, delay))
  anova_table <- get_anova_table(anova_result)
  anova_table <- add_cohens_d(data, ANOVA_table)
  
  all_results[DV, "val_d"] <- anova_table[anova_table$Effect=="valence", "d"]
  all_results[DV, "val_p"] <- anova_table[anova_table$Effect=="valence", "p"]
  
  all_results[DV, "delay_d"] <- anova_table[anova_table$Effect=="delay", "d"]
  all_results[DV, "delay_p"] <- anova_table[anova_table$Effect=="delay", "p"]
  
  all_results[DV, "int_d"] <- anova_table[anova_table$Effect=="valence:delay", "d"]
  all_results[DV, "int_p"] <- anova_table[anova_table$Effect=="valence:delay", "p"]
  
}

write.csv(all_results, "EmCon_memory_results.csv")
