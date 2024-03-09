#Analysis of behavioral memory variables for EmCon
#
#Author: Eric Fields
#Version Date: 9 March 2024

#Copyright (c) 2021, Eric Fields
#All rights reserved.
#This code is free and open source software made available under the 3-clause BSD license.

library(moments)
library(readr)
library(rstatix)
library(dplyr)
library(tidyr)
library(tidyselect)

#Load Wilcox robust functions
#Wilcox, R. R. (2016). Introduction to Robust Estimation and Hypothesis Testing (4th ed.). Waltham, MA: Elsevier.
#https://dornsife.usc.edu/labs/rwilcox/software/
if (!exists("yuen")) {
  source("C:/Users/fieldsec/OneDrive - Westminster College/Documents/ECF/Coding/R/Rallfun-v43.txt")
}

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
  
  #Get means and SDs
  desc_stats <- data %>% group_by(valence, delay) %>% get_summary_stats(all_of(DV), type = "mean_sd")
  
  #Calculate pooled standard deviation (across all four conditions)
  sp = sqrt(mean(desc_stats$sd^2))
  
  #Main effect of valence: Get means and calculate Cohen's d
  M_NEU <- mean(desc_stats[desc_stats$valence=="NEU", ]$mean)
  M_NEG <- mean(desc_stats[desc_stats$valence=="NEG", ]$mean)
  anova_table[anova_table$Effect == "valence", "d"] = (M_NEG - M_NEU) / sp
  
  #Main effect of delaye: Get means and calculate Cohen's d
  M_I <- mean(desc_stats[desc_stats$delay=="I", ]$mean)
  M_D <- mean(desc_stats[desc_stats$delay=="D", ]$mean)
  anova_table[anova_table$Effect == "delay", "d"] = (M_D - M_I) / sp
  
  #Make sure rows in the descriptives table are as expected
  if (!all(desc_stats$valence == c("NEG", "NEG", "NEU", "NEU"))) {
    stop("Row order is not as expected.")
  }
  if (!all(desc_stats$delay == c("D", "I", "D", "I"))) {
    stop("Row order is not as expected.")
  }
  
  #Calculate Cohen's d for interaction:
  #Difference in valence effect (NEG - NEU) for delayed - immediate
  int_numerator <- ((desc_stats[1, "mean"] - desc_stats[3, "mean"]) -
                      (desc_stats[2, "mean"] - desc_stats[4, "mean"]))
  anova_table[anova_table$Effect == "valence:delay", "d"] = int_numerator / sp
  
  return(anova_table)
  
}

get_int_followup <- function(data) {

  ph_table <- data.frame()
  
  #Calculate pooled standard deviation (across all four conditions)
  desc_stats <- data %>% group_by(valence, delay) %>% get_summary_stats(all_of(DV), type = "mean_sd")
  sp = sqrt(mean(desc_stats$sd^2))
  
  #Define contrasts to be calculated
  contrsts <- list("I: NEG - NEU" = c("NEG", "NEU", "I", "I"),
                   "D: NEG - NEU" = c("NEG", "NEU", "D", "D"),
                   "NEU: I - D" =   c("NEU", "NEU", "I", "D"),
                   "NEG: I - D" =   c("NEG", "NEG", "I", "D"))
  
  #Calculate statistics for all contrasts
  for (i in 1:length(contrsts)) {
    row <- names(contrsts[i])
    idx_1 <- (data$valence == contrsts[[row]][1]) & (data$delay == contrsts[[row]][3])
    idx_2 <- (data$valence == contrsts[[row]][2]) & (data$delay == contrsts[[row]][4])
    t_results <- t.test(data[idx_1, ][[DV]], data[idx_2,][[DV]], paired=TRUE)
    d <- as.numeric(t_results$estimate) / sp
    ph_table[row, "t"] <- as.numeric(t_results$statistic)
    ph_table[row, "df"] <- as.numeric(t_results$parameter)
    ph_table[row, "p"] <- as.numeric(t_results$p.value)
    ph_table[row, "mean_diff"] <- as.numeric(t_results$estimate)
    ph_table[row, "CI_L"] <- as.numeric(t_results$conf.int[1])
    ph_table[row, "CI_U"] <- as.numeric(t_results$conf.int[2])
    ph_table[row, "d"] <- d
  }
  
  return(ph_table)
  
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

#Which columns represent dependent variables for analysis
DVs <- colnames(data)[4:19]


############################# DESCRIPTIVE STATISTICS #############################

desc_table <- data.frame()
for (DV in DVs) {
  for (val in c("NEU", "NEG")) {
    for (dly in c("I", "D")) {
      dat <- data[data$valence==val & data$delay==dly, ][[DV]]
      rowname <- sprintf("%s: %s %s", DV, val, dly)
      desc_table[rowname, "M"] <- mean(dat)
      desc_table[rowname, "SD"] <- sd(dat)
      desc_table[rowname, "skew"] <- skewness(dat)
      desc_table[rowname, "kurtosis"] <- kurtosis(dat) - 3
      desc_table[rowname, "min"] <- min(dat)
      desc_table[rowname, "25th"] <- quantile(dat, .25)
      desc_table[rowname, "median"] <- median(dat)
      desc_table[rowname, "75th"] <- quantile(dat, .75)
      desc_table[rowname, "max"] <- max(dat)
      desc_table[rowname, "trim_mean"] <- mean(dat, trim=0.2)
      desc_table[rowname, "sw"] <- winsd(dat,tr=0.2)
      desc_table[rowname, "MAD"] <- mad(dat)
    }
  }
}

write.csv(desc_table, "results/EmCon_memory_descriptives.csv")


############################# VALENCE X DELAY ANOVA #############################

all_results <- data.frame()
for (DV in DVs) {
  
  #Calculate ANOVA
  anova_result <- anova_test(data, dv=all_of(DV), wid=sub_id, within=c(valence, delay))
  anova_table <- get_anova_table(anova_result)
  anova_table <- add_cohens_d(data, ANOVA_table)
  write.csv(anova_table, sprintf("results/full/EmCon_%s_ANOVA.csv", DV), row.names=FALSE)
  
  #Calculate interaction follow-ups
  ph_table <- get_int_followup(data)
  write.csv(ph_table, sprintf("results/full/EmCon_%s_int_posthoc.csv", DV))
  
  #Add results to full results table
  all_results[DV, "val_d"] <- anova_table[anova_table$Effect=="valence", "d"]
  all_results[DV, "val_p"] <- anova_table[anova_table$Effect=="valence", "p"]
  all_results[DV, "delay_d"] <- anova_table[anova_table$Effect=="delay", "d"]
  all_results[DV, "delay_p"] <- anova_table[anova_table$Effect=="delay", "p"]
  all_results[DV, "int_d"] <- anova_table[anova_table$Effect=="valence:delay", "d"]
  all_results[DV, "int_p"] <- anova_table[anova_table$Effect=="valence:delay", "p"]
  all_results[DV, "Imm_NEG-NEU_d"] <- ph_table["I: NEG - NEU", "d"]
  all_results[DV, "Imm_NEG-NEU_p"] <- ph_table["I: NEG - NEU", "p"]
  all_results[DV, "Del_NEG-NEU_d"] <- ph_table["D: NEG - NEU", "d"]
  all_results[DV, "Del_NEG-NEU_p"] <- ph_table["D: NEG - NEU", "p"]
  all_results[DV, "NEU_I-D_d"] <- ph_table["NEU: I - D", "d"]
  all_results[DV, "NEU_I-D_p"] <- ph_table["NEU: I - D", "p"]
  all_results[DV, "NEG_I-D_d"] <- ph_table["NEG: I - D", "d"]
  all_results[DV, "NEG_I-D_p"] <- ph_table["NEG: I - D", "p"]
  
}

write.csv(all_results, "results/EmCon_memory_ANOVA_results.csv")
