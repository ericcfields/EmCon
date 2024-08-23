#Run analyses to test if the LPP mediates the effect of emotion on memory
#
#Author: Eric Fields
#Version Date: 21 August 2024

library(moments)
library(stringr)
library(readr)
library(tibble)
library(lme4)
library(lmerTest)
library(mediation)

#Load Wilcox robust functions
#Wilcox, R. R. (2016). Introduction to Robust Estimation and Hypothesis Testing (4th ed.). Waltham, MA: Elsevier.
#https://dornsife.usc.edu/labs/rwilcox/software/
if (!exists("yuen")) {
  source("C:/Users/fieldsec/OneDrive - Westminster College/Documents/ECF/Coding/R/Rallfun-v43.txt")
}


setwd("C:/Users/fieldsec/OneDrive - Westminster College/Documents/ECF/Research/EmCon/DATA/stats/erp/avg")

#Set default contrast to deviation coding
options(contrasts = rep("contr.sum", 2))

contr.simple <- function(n_levels) {
  #Create simple coding matrix for a variable with n_levels
  #See: https://stats.idre.ucla.edu/r/library/r-library-contrast-coding-systems-for-categorical-variables/
  n_predictors <- n_levels - 1
  c <- contr.treatment(n_levels) - matrix(rep(1/n_levels, n_levels*n_predictors), ncol=n_predictors)
  return(c)
}


################################### IMPORT DATA ###################################

#Word averaged data
wdata <- read_csv(file.path("data", "EmCon_WordAveraged_long.csv"))
wdata$valence <- factor(wdata$valence, levels=c("NEU", "NEG", "animal"))
contrasts(wdata$valence) <- contr.simple(nlevels(wdata$valence))
wdata$delay <- factor(wdata$delay, levels=c("immediate", "delayed"))
contrasts(wdata$delay) <- contr.simple(nlevels(wdata$delay))

#Subject averaged data
sdata <- read_csv(file.path("data", "EmCon_SubAveraged_long.csv"))
sdata$valence <- factor(sdata$valence, levels=c("NEU", "NEG", "animal"))
contrasts(sdata$valence) <- contr.simple(nlevels(sdata$valence))
sdata$delay <- factor(sdata$delay, levels=c("immediate", "delayed"))
contrasts(sdata$delay) <- contr.simple(nlevels(sdata$delay))

#Single trial data
tdata <- read_csv(file.path("data", "EmCon_SingleTrial.csv"))
tdata$valence <- factor(tdata$valence, levels=c("NEU", "NEG", "animal"))
contrasts(tdata$valence) <- contr.simple(nlevels(tdata$valence))
tdata$delay <- factor(tdata$delay, levels=c("immediate", "delayed"))
contrasts(tdata$delay) <- contr.simple(nlevels(tdata$delay))


################################### GENERAL SETTINGS ###################################

#Number of simulations to run when calculating inferential stats for mediation models
sims <- 99999

#Output results to file
sink("results/EmCon_mediation_results.txt")


################################### DESCRIPTIVES ###################################

DVs <- c("old_resp", "rk_resp", "frontal_pos", "LPP", "sub_bias", "N_trials")

#Calculate word-averaged descriptives
w_desc_table <- data.frame()
for (DV in DVs) {
  for (val in c("NEU", "NEG")) {
    for (dly in c("immediate", "delayed")) {
      dat <- wdata[wdata$valence==val & wdata$delay==dly, ][[DV]]
      rowname <- sprintf("%s: %s %s", DV, val, dly)
      w_desc_table[rowname, "M"] <- mean(dat)
      w_desc_table[rowname, "SD"] <- sd(dat)
      w_desc_table[rowname, "skew"] <- skewness(dat)
      w_desc_table[rowname, "kurtosis"] <- kurtosis(dat) - 3
      w_desc_table[rowname, "min"] <- min(dat)
      w_desc_table[rowname, "25th"] <- quantile(dat, .25)
      w_desc_table[rowname, "median"] <- median(dat)
      w_desc_table[rowname, "75th"] <- quantile(dat, .75)
      w_desc_table[rowname, "max"] <- max(dat)
      w_desc_table[rowname, "trim_mean"] <- mean(dat, trim=0.2)
      w_desc_table[rowname, "sw"] <- winsd(dat,tr=0.2)
      w_desc_table[rowname, "MAD"] <- mad(dat)
    }
  }
}
write.csv(w_desc_table, "results/EmCon_mediation_WordAveraged_descriptives.csv")

#Calculate subject-averaged descriptives
s_desc_table <- data.frame()
for (DV in DVs) {
  for (val in c("NEU", "NEG")) {
    for (dly in c("immediate", "delayed")) {
      dat <- sdata[sdata$valence==val & sdata$delay==dly, ][[DV]]
      rowname <- sprintf("%s: %s %s", DV, val, dly)
      s_desc_table[rowname, "M"] <- mean(dat)
      s_desc_table[rowname, "SD"] <- sd(dat)
      s_desc_table[rowname, "skew"] <- skewness(dat)
      s_desc_table[rowname, "kurtosis"] <- kurtosis(dat) - 3
      s_desc_table[rowname, "min"] <- min(dat)
      s_desc_table[rowname, "25th"] <- quantile(dat, .25)
      s_desc_table[rowname, "median"] <- median(dat)
      s_desc_table[rowname, "75th"] <- quantile(dat, .75)
      s_desc_table[rowname, "max"] <- max(dat)
      s_desc_table[rowname, "trim_mean"] <- mean(dat, trim=0.2)
      s_desc_table[rowname, "sw"] <- winsd(dat,tr=0.2)
      s_desc_table[rowname, "MAD"] <- mad(dat)
    }
  }
}
write.csv(s_desc_table, "results/EmCon_mediation_SubAveraged_descriptives.csv")


########################## WORD-AVERAGED MEDIATION ANALYSIS ##########################

#Mediation separately in immediate and delayed conditions
for (dly in c("immediate", "delayed")) {
  
  #Get delay subset and ignore animal trials
  data_subset <- wdata[(wdata$valence != "animal") & (wdata$delay == dly), ]
  data_subset$valence <- factor(data_subset$valence, levels=c("NEU", "NEG"))
  
  #Simple code the valence factor
  contrasts(data_subset$valence) <- contr.simple(nlevels(data_subset$valence))
  
  #Calculate regressio models and mediation
  val.fit <- lm(old_resp ~ 1 + valence, data=data_subset)
  lpp.fit <- lm(old_resp ~ 1 + LPP, data=data_subset)
  med.fit <- lm(LPP ~ 1 + valence, data=data_subset)
  out.fit <- lm(old_resp ~ 1 + LPP + valence, data=data_subset)
  med.out <- mediate(med.fit, out.fit, treat = "valence", mediator = "LPP",
                     control.value = "NEU", treat.value = "NEG",
                     sims = sims, boot = TRUE, boot.ci.type = "bca")
  
  #Produce output in console and plots
  cat(sprintf("\n\n\n####### %s WORD AVERAGED #######\n\n", str_to_upper(dly)))
  print(summary(med.fit))
  cat("\n\n")
  print(summary(lpp.fit))
  cat("\n\n")
  print(summary(val.fit))
  cat("\n\n")
  print(summary(out.fit))
  cat("\n\n")
  print(summary(med.out))
  plot(med.out)
  title(sprintf("%s WORD AVERAGED", str_to_upper(dly)))
  
  #Calculate regression and  mediation with response bias controlled
  val.fit <- lm(old_resp ~ 1 + valence + sub_bias, data=data_subset)
  lpp.fit <- lm(old_resp ~ 1 + LPP + sub_bias, data=data_subset)
  med.fit <- lm(LPP ~ 1 + valence + sub_bias, data=data_subset)
  out.fit <- lm(old_resp ~ 1 + LPP + valence + sub_bias, data=data_subset)
  med.out <- mediate(med.fit, out.fit, treat = "valence", mediator = "LPP",
                     control.value = "NEU", treat.value = "NEG",
                     sims = sims, boot = TRUE, boot.ci.type = "bca")
  
  #Produce output in console and plots
  cat(sprintf("\n\n\n####### %s WORD AVERAGED (CONTROLLING FOR BIAS) #######\n\n", str_to_upper(dly)))
  print(summary(med.fit))
  cat("\n\n")
  print(summary(lpp.fit))
  cat("\n\n")
  print(summary(val.fit))
  cat("\n\n")
  print(summary(out.fit))
  cat("\n\n")
  print(summary(med.out))
  plot(med.out)
  title(sprintf("%s WORD AVERAGED (CONTROLLING FOR BIAS)", str_to_upper(dly)))

}



################### WORD AVERAGED: ANALYSIS OF MEMORY DELAY EFFECT ###################

#Get (weighted) average LPP and difference in memory across delay for each word
c_wdata <- data.frame()
for (word in unique(wdata$word)) {
  imm_N <- wdata[wdata$word==word & wdata$delay=="immediate", ]$N_trials
  dly_N <- wdata[wdata$word==word & wdata$delay=="delayed", ]$N_trials
  imm_LPP <- wdata[wdata$word==word & wdata$delay=="immediate", ]$LPP
  dly_LPP <- wdata[wdata$word==word & wdata$delay=="delayed", ]$LPP
  imm_ON <- wdata[wdata$word==word & wdata$delay=="immediate", ]$old_resp
  dly_ON <- wdata[wdata$word==word & wdata$delay=="delayed", ]$old_resp
  imm_RK <- wdata[wdata$word==word & wdata$delay=="immediate", ]$rk_resp
  dly_RK <- wdata[wdata$word==word & wdata$delay=="delayed", ]$rk_resp
  imm_bias <- wdata[wdata$word==word & wdata$delay=="immediate", ]$sub_bias
  dly_bias <- wdata[wdata$word==word & wdata$delay=="delayed", ]$sub_bias
  c_wdata[word, "valence"] <- unique(wdata[wdata$word==word, "valence"])
  c_wdata[word, "LPP"] <- (imm_N*imm_LPP + dly_N*dly_LPP) / (imm_N + dly_N)
  c_wdata[word, "dly_effect_ON"] <- imm_ON - dly_ON
  c_wdata[word, "dly_effect_RK"] <- imm_RK - dly_RK
  c_wdata[word, "dly_effect_bias"] <- imm_bias - dly_bias
}

#Ignore animal trials & code valence factors
data_subset <- c_wdata[c_wdata$valence != "animal", ]
data_subset$valence <- factor(data_subset$valence, levels=c("NEU", "NEG"))

#Simple code the valence factor
contrasts(data_subset$valence) <- contr.simple(nlevels(data_subset$valence))

#LPP to delay effect correlation
cor_results <- cor.test(c_wdata$LPP, c_wdata$dly_effect_ON)

#Regression models and mediation
val.fit <- lm(dly_effect_ON ~ 1 + valence, data=data_subset)
lpp.fit <- lm(dly_effect_ON ~ 1 + LPP, data=data_subset)
med.fit <- lm(LPP ~ 1 + valence, data=data_subset)
out.fit <- lm(dly_effect_ON ~ 1 + valence + LPP, data=data_subset)
med.out <- mediate(med.fit, out.fit, treat = "valence", mediator = "LPP",
                   control.value = "NEU", treat.value = "NEG",
                   sims = sims, boot = TRUE, boot.ci.type = "bca")

#Produce output in console and plots
cat("\n\n\n####### WORD AVERAGED DELAY EFFECT #######\n\n")
print(summary(med.fit))
cat("\n\n")
print(summary(lpp.fit))
cat("\n\n")
print(summary(val.fit))
cat("\n\n")
print(summary(out.fit))
cat("\n\n")
print(summary(med.out))
plot(med.out)
title("WORD AVERAGED DELAY EFFECT")

#Regression and mediation controlling for bias
val.fit <- lm(dly_effect_ON ~ 1 + valence + dly_effect_bias, data=data_subset)
lpp.fit <- lm(dly_effect_ON ~ 1 + LPP + dly_effect_bias, data=data_subset)
med.fit <- lm(LPP ~ 1 + valence + dly_effect_bias, data=data_subset)
out.fit <- lm(dly_effect_ON ~ 1 + valence + LPP + dly_effect_bias, data=data_subset)
med.out <- mediate(med.fit, out.fit, treat = "valence", mediator = "LPP",
                   control.value = "NEU", treat.value = "NEG",
                   sims = sims, boot = TRUE, boot.ci.type = "bca")

#Produce output in console and plots
cat("\n\n\n####### WORD AVERAGED DELAY EFFECT (CONTROL FOR BIAS) #######\n\n")
print(summary(med.fit))
cat("\n\n")
print(summary(lpp.fit))
cat("\n\n")
print(summary(val.fit))
cat("\n\n")
print(summary(out.fit))
cat("\n\n")
print(summary(med.out))
plot(med.out)
title("WORD AVERAGED DELAY EFFECT (CONTROL FOR BIAS)")


################### SUBJECT AVERAGED MEDIATION ANALYSIS ###################

for (dly in c("immediate", "delayed")) {
  
  #Get delay subset and ignore animal trials
  data_subset <- sdata[(sdata$valence != "animal") & (sdata$delay == dly), ]
  data_subset$valence <- factor(data_subset$valence, levels=c("NEU", "NEG"))
  
  #Simple code the valence factor
  contrasts(data_subset$valence) <- contr.simple(nlevels(data_subset$valence))
  
  #Calculate regression and mediation
  val.fit <- lme4::lmer(old_resp ~ 1 + valence + (1|sub_id), data=data_subset)
  lpp.fit <- lme4::lmer(old_resp ~ 1 + LPP + (1|sub_id), data=data_subset)
  med.fit <- lme4::lmer(LPP ~ 1 + valence + (1|sub_id),
                  data=data_subset)
  out.fit <- lme4::lmer(old_resp ~ 1 + valence + LPP + (1|sub_id),
                  data=data_subset)
  med.out <- mediate(med.fit, out.fit, treat = "valence", mediator = "LPP",
                     control.value = "NEU", treat.value = "NEG",
                     sims = sims)
  
  #Produce output in console and plots
  cat(sprintf("\n\n\n####### %s SUBJECT AVERAGED #######\n\n", str_to_upper(dly)))
  print(summary(as_lmerModLmerTest(med.fit)))
  cat("\n\n")
  print(summary(as_lmerModLmerTest(lpp.fit)))
  cat("\n\n")
  print(summary(as_lmerModLmerTest(val.fit)))
  cat("\n\n")
  print(summary(as_lmerModLmerTest(out.fit)))
  cat("\n\n")
  print(summary(med.out))
  plot(med.out)
  title(sprintf("%s SUBJECT AVERAGED", str_to_upper(dly)))
  
  #Calculate mediation with response bias controlled
  val.fit <- lme4::lmer(old_resp ~ 1 + valence + sub_bias + (1|sub_id), data=data_subset)
  lpp.fit <- lme4::lmer(old_resp ~ 1 + LPP + sub_bias + (1|sub_id), data=data_subset)
  med.fit <- lme4::lmer(LPP ~ 1 + valence + sub_bias + (1|sub_id),
                  data=data_subset)
  out.fit <- lme4::lmer(old_resp ~ 1 + valence + LPP + sub_bias + (1|sub_id),
                  data=data_subset)
  med.out <- mediate(med.fit, out.fit, treat = "valence", mediator = "LPP",
                     control.value = "NEU", treat.value = "NEG",
                     sims = sims)
  
  #Produce output in console and plots
  cat(sprintf("\n\n\n####### %s SUBJECT AVERAGED (CONTROLLING FOR BIAS) #######\n\n", str_to_upper(dly)))
  print(summary(as_lmerModLmerTest(med.fit)))
  cat("\n\n")
  print(summary(as_lmerModLmerTest(lpp.fit)))
  cat("\n\n")
  print(summary(as_lmerModLmerTest(val.fit)))
  cat("\n\n")
  print(summary(as_lmerModLmerTest(out.fit)))
  cat("\n\n")
  print(summary(med.out))
  plot(med.out)
  title(sprintf("%s SUBJECT AVERAGED (CONTROLLING FOR BIAS)", str_to_upper(dly)))
  
}


################### SUBJECT AVERAGED: ANALYSIS OF MEMORY DELAY EFFECT ###################

#Get (weighted) average LPP and difference in memory across delay for each sub_id & valence
c_sdata <- data.frame()
row <- 0
for (sub_id in unique(sdata$sub_id)) {
  for (val in c("NEU", "NEG")) {
    
    imm_N <- sdata[sdata$sub_id==sub_id & sdata$valence==val & sdata$delay=="immediate", ]$N_trials
    dly_N <- sdata[sdata$sub_id==sub_id & sdata$valence==val & sdata$delay=="delayed", ]$N_trials
    imm_LPP <- sdata[sdata$sub_id==sub_id & sdata$valence==val & sdata$delay=="immediate", ]$LPP
    dly_LPP <- sdata[sdata$sub_id==sub_id & sdata$valence==val & sdata$delay=="delayed", ]$LPP
    imm_ON <- sdata[sdata$sub_id==sub_id & sdata$valence==val & sdata$delay=="immediate", ]$old_resp
    dly_ON <- sdata[sdata$sub_id==sub_id & sdata$valence==val & sdata$delay=="delayed", ]$old_resp
    imm_RK <- sdata[sdata$sub_id==sub_id & sdata$valence==val & sdata$delay=="immediate", ]$rk_resp
    dly_RK <- sdata[sdata$sub_id==sub_id & sdata$valence==val & sdata$delay=="delayed", ]$rk_resp
    imm_bias <- sdata[sdata$sub_id==sub_id & sdata$valence==val & sdata$delay=="immediate", ]$sub_bias
    dly_bias <- sdata[sdata$sub_id==sub_id & sdata$valence==val & sdata$delay=="delayed", ]$sub_bias
    
    row = row + 1
    c_sdata[row, "sub_id"] <- sub_id
    c_sdata[row, "valence"] <- val
    c_sdata[row, "LPP"] <- (imm_N*imm_LPP + dly_N*dly_LPP) / (imm_N + dly_N)
    c_sdata[row, "dly_effect_ON"] <- imm_ON - dly_ON
    c_sdata[row, "dly_effect_RK"] <- imm_RK - dly_RK
    c_sdata[row, "dly_effect_bias"] <- imm_bias - dly_bias
    
  }
}

#Code valence factor
data_subset <- c_sdata
data_subset$valence <- factor(data_subset$valence, levels=c("NEU", "NEG"))

#Calculate regression and mediation
val.fit <- lme4::lmer(dly_effect_ON ~ 1 + valence + (1|sub_id), data=data_subset)
lpp.fit <- lme4::lmer(dly_effect_ON ~ 1 + LPP + (1|sub_id), data=data_subset)
med.fit <- lme4::lmer(LPP ~ 1 + valence + (1|sub_id),
                      data=data_subset)
out.fit <- lme4::lmer(dly_effect_ON ~ 1 + valence + LPP + (1|sub_id),
                      data=data_subset)
med.out <- mediate(med.fit, out.fit, treat = "valence", mediator = "LPP",
                   control.value = "NEU", treat.value = "NEG",
                   sims = sims)

#Produce output in console and plots
cat("\n\n\n####### SUBJECT AVERAGED DELAY EFFECT #######\n\n")
print(summary(as_lmerModLmerTest(med.fit)))
cat("\n\n")
print(summary(as_lmerModLmerTest(lpp.fit)))
cat("\n\n")
print(summary(as_lmerModLmerTest(val.fit)))
cat("\n\n")
print(summary(as_lmerModLmerTest(out.fit)))
cat("\n\n")
print(summary(med.out))
plot(med.out)
title("WORD AVERAGED DELAY EFFECT")

#Calculate mediation with response bias controlled
val.fit <- lme4::lmer(dly_effect_ON ~ 1 + valence + dly_effect_bias + (1|sub_id), data=data_subset)
lpp.fit <- lme4::lmer(dly_effect_ON ~ 1 + LPP + dly_effect_bias + (1|sub_id), data=data_subset)
med.fit <- lme4::lmer(LPP ~ 1 + valence + dly_effect_bias + (1|sub_id),
                      data=data_subset)
out.fit <- lme4::lmer(dly_effect_ON ~ 1 + valence + LPP + dly_effect_bias + (1|sub_id),
                      data=data_subset)
med.out <- mediate(med.fit, out.fit, treat = "valence", mediator = "LPP",
                   control.value = "NEU", treat.value = "NEG",
                   sims = sims)

#Produce output in console and plots
cat("\n\n\n####### SUBJECT AVERAGED DELAY EFFECT (CONTROL FOR BIAS) #######\n\n")
print(summary(as_lmerModLmerTest(med.fit)))
cat("\n\n")
print(summary(as_lmerModLmerTest(lpp.fit)))
cat("\n\n")
print(summary(as_lmerModLmerTest(val.fit)))
cat("\n\n")
print(summary(as_lmerModLmerTest(out.fit)))
cat("\n\n")
print(summary(med.out))
plot(med.out)
title("WORD AVERAGED DELAY EFFECT (CONTROL FOR BIAS)")



sink()
