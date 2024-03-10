#Run analyses to test if the LPP mediates the effect of emotion on memory
#
#Author: Eric Fields
#Version Date: 10 March 2024

library(stringr)
library(readr)
library(tibble)
library(lme4)
library(mediation)


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
wdata <- read_csv("EmCon_WordAveraged_long.csv")
wdata$valence <- factor(wdata$valence, levels=c("NEU", "NEG", "animal"))
contrasts(wdata$valence) <- contr.simple(nlevels(wdata$valence))
wdata$delay <- factor(wdata$delay, levels=c("immediate", "delayed"))
contrasts(wdata$delay) <- contr.simple(nlevels(wdata$delay))

#Subject averaged data
sdata <- read_csv("EmCon_SubAveraged_long.csv")
sdata$valence <- factor(sdata$valence, levels=c("NEU", "NEG", "animal"))
contrasts(sdata$valence) <- contr.simple(nlevels(sdata$valence))
sdata$delay <- factor(sdata$delay, levels=c("immediate", "delayed"))
contrasts(sdata$delay) <- contr.simple(nlevels(sdata$delay))

#Single trial data
tdata <- read_csv("EmCon_SingleTrial.csv")
tdata$valence <- factor(tdata$valence, levels=c("NEU", "NEG", "animal"))
contrasts(tdata$valence) <- contr.simple(nlevels(tdata$valence))
tdata$delay <- factor(tdata$delay, levels=c("immediate", "delayed"))
contrasts(tdata$delay) <- contr.simple(nlevels(tdata$delay))


########################## WORD AVERAGED MEDIATION ANALYSIS ##########################

#Mediation separately in immediate and delayed conditions
for (dly in c("immediate", "delayed")) {
  
  #Get delay subset and ignore animal trials
  data_subset <- wdata[(wdata$valence != "animal") & (wdata$delay == dly), ]
  data_subset$valence <- factor(data_subset$valence, levels=c("NEU", "NEG"))
  contrasts(data_subset$valence) <- contr.simple(nlevels(data_subset$valence))
  
  #Calculate mediation
  med.fit <- lm(LPP ~ 1 + valence, data=data_subset)
  out.fit <- lm(old_resp ~ 1 + LPP + valence, data=data_subset)
  med.out <- mediate(med.fit, out.fit, treat = "valence", mediator = "LPP", 
                     robustSE = TRUE, sims = 10000)
  
  #Produce output in console and plots
  cat(sprintf("\n\n%s WORD AVERAGED\n", str_to_upper(dly)))
  print(summary(med.out))
  plot(med.out)
  title(sprintf("%s WORD AVERAGED", str_to_upper(dly)))
  
  #Output results to file
  #TO DO

}


################### SUBJECT AVERAGED MEDIATION ANALYSIS ###################

for (dly in c("immediate", "delayed")) {
  
  #Get delay subset and ignore animal trials
  data_subset <- sdata[(sdata$valence != "animal") & (sdata$delay == dly), ]
  data_subset$valence <- factor(data_subset$valence, levels=c("NEU", "NEG"))
  contrasts(data_subset$valence) <- contr.simple(nlevels(data_subset$valence))
  
  #Calculate mediation
  med.fit <- lmer(LPP ~ 1 + valence + (1|sub_id),
                  data=data_subset)
  out.fit <- lmer(old_resp ~ 1 + valence + LPP + (1|sub_id),
                  data=data_subset)
  med.out <- mediate(med.fit, out.fit, treat = "valence", mediator = "LPP", 
                     robustSE = TRUE, sims = 10000)
  
  #Produce output in console and plots
  cat(sprintf("\n\n%s SUBJECT AVERAGED\n", str_to_upper(dly)))
  print(summary(med.out))
  plot(med.out)
  title(sprintf("%s SUBJECT AVERAGED", str_to_upper(dly)))
  
  #Output results to file
  #TO DO
  
}

stop("Code after this point does not work.")


################### SINGLE TRIAL MEDIATION ANALYSIS ###################

for (dly in c("immediate", "delayed")) {
  
  #Get delay subset and ignore animal trials
  data_subset <- tdata[(tdata$valence != "animal") & (tdata$delay == dly), ]
  data_subset$valence <- factor(data_subset$valence, levels=c("NEU", "NEG"))
  contrasts(data_subset$valence) <- contr.simple(nlevels(data_subset$valence))
  
  #Calculate mediation
  med.fit <- lmer(LPP ~ 1 + valence + (1+valence|sub_id),
                  data=data_subset) 
  out.fit <- glmer(old_resp ~ valence + LPP + (1+valence+LPP|sub_id) + (1+valence+LPP|word),
                   family = binomial(link = "logit"), data = data_subset)
  #DOES NOT WORK AFTER THIS POINT
  #CANNOT HAVE TWO RANDOM FACTORS?
  med.out <- mediate(med.fit, out.fit, treat = "valence", mediator = "LPP", 
                     robustSE = TRUE, sims = 2)
  
}


################### WORD AVERAGED MODERATED MEDIATION ANALYSIS ###################

#Ignore animal trials
data_subset <- wdata[wdata$valence != "animal", ]
data_subset$valence <- factor(data_subset$valence, levels=c("NEU", "NEG"))
contrasts(data_subset$valence) <- contr.simple(nlevels(data_subset$valence))
data_subset[, "LPP.c"] <- data_subset$LPP - mean(data_subset$LPP)

#Calculate mediation
med.fit <- lmer(LPP.c ~ 1 + valence*delay + (1|word), 
                data=data_subset)

out.fit <- lmer(old_resp ~ 1 + valence*delay + delay*LPP.c + (1|word), 
                data=data_subset)

med.init <- mediate(med.fit, out.fit, treat = "valence", mediator = "LPP.c", sims=2)

#NOTE: DOES NOT WORK AFTER THIS POINT
#NO MOEDRATED MEDIATION FOR MIXED MODELS?
#Test moderation
test.modmed(med.init, covariates.1 = list(delay = "immediate"),
            covariates.2 = list(delay = "delay"), sims = 1000)

