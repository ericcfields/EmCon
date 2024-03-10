#Run analyses to test if the LPP mediates the effect of emotion on memory
#
#Author: Eric Fields
#Version Date: 10 March 2024

library(stringr)
library(readr)
library(tibble)

library(lme4)
library(car)
library(afex)
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

data <- read_csv("EmCon_WordAveraged_long.csv")

data$valence <- factor(data$valence, levels=c("NEU", "NEG", "animal"))
contrasts(data$valence) <- contr.simple(nlevels(data$valence))
data$delay <- factor(data$delay, levels=c("immediate", "delayed"))
contrasts(data$delay) <- contr.simple(nlevels(data$delay))


############################### MEDIATION ANALYSIS ###############################

#Mediation separately in immediate and dealyed conditions
for (dly in c("immediate", "delayed")) {

  data_subset <- data[(data$valence != "animal") & (data$delay == dly), ]
  data_subset$valence <- factor(data_subset$valence, levels=c("NEU", "NEG"))
  contrasts(data_subset$valence) <- contr.simple(nlevels(data_subset$valence))
  
  #Calculate mediation for immediate
  med.fit <- lm(LPP ~ 1 + valence, data=data_subset)
  out.fit <- lm(old_resp ~ 1 + LPP + valence, data=data_subset)
  med.out <- mediate(med.fit, out.fit, treat = "valence", mediator = "LPP", robustSE = TRUE, sims = 10000)
  cat(sprintf("\n\n%s\n", str_to_upper(dly)))
  print(summary(med.out))
  plot(med.out)
  title(str_to_upper(dly))

}
