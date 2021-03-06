#### BIOSTATS 2 - ASSIGNMENT 4 ####
# Katie Kosteva 
# November 2019

#Clear Environment
rm(list = ls())

# 1. [4 Points] The BayesFactor package contains a function regressionBF. Use regressionBF on the dTransform data -- use the threshold values (S, M, L, and so on) to predict RE (refractive error). Look at the Bayes Factor output, what does it seem to tell you? The help shows an example of how the BF for each model can be tested against the full model (all thresholds). Put this line in the script with a comment that notes the best model. How does this model compare to what we saw with the stepwise model selection we did in previous lectures? 
## define a function to make dTransform
dFull <- read.csv('https://raw.githubusercontent.com/hashtagcpt/biostats2/master/full_data.csv')

make_dTransform <- function(dFull) {
  # strip thresh values for data frame and log transform
  t1<-log10(dFull$thr1)           
  t2<-log10(dFull$thr2)
  t3<-log10(dFull$thr3)
  t4<-log10(dFull$thr4)
  t5<-log10(dFull$thr5)
  t6<-log10(dFull$thr6)
  
  # factor will change a numeric variable to a factor which is   useful for creating categorical variables
  dFull$subject <- factor(dFull$subject)
  # assign RE variable
  RE <- dFull$RE
  
  subject <- dFull$subject
  
  # make a data.frame
  dTransform <- data.frame(subject,RE,t1,t2,t3,t4,t5,t6)
  colnames(dTransform) <- c('subject','RE','A','L','M','Sneg','Spos','S')
  
  return(dTransform)
}
dTransform <- make_dTransform(dFull)

library(BayesFactor)
## Compute Bayes factors for all regression models
output = regressionBF(RE ~ S+L+M+A+Sneg+Spos, data = dTransform, progress=FALSE)
head(output)
# Bayes factors are greater than 1 therefore there is stronger evidence for the numerator. 

## Compute all Bayes factors against the full model, and look again at best models
head(output / output[63])
# Best Model is S+Spos which is the same combination found when using linear regression in the previous lecture. 


#2. [3 Points] A colleague is going to run an experiment where they are going to compute a correlation test. Beforehand, they ask you how many subjects they need to run. Based on previous work, they believe the r for their experiment could be between .2 and .6, their funders want a *Type II error* probability of no more than 0.4, and they will use a conventional alpha of .05. Calculate what the minimum and the maximum number of subjects they need to run for their experiment to be adequately powered, given their funder's constraints. 

# Power = 1 - (Type II Error Rate) = 1 - 0.4 = 0.6
library(pwr)
# Maximum number of patient is n = 121
pwr.r.test(r=0.2,power=0.60,sig.level=0.05,alternative="two.sided")
# Minimum number of patients is n = 13
pwr.r.test(r=0.6,power=0.60,sig.level=0.05,alternative="two.sided")


# 3. [3 Points]
# This function will help you create some simulated psychometric data... 
datasim <- function(contrasts, pcorrect, ntrials) {
  for (tmp in 1:length(contrasts)) {
    contrast <- rep(contrasts[tmp], ntrials)
    correct <- rbinom(ntrials, 1, pcorrect[tmp])
    if (tmp == 1) {
      data <- data.frame(contrast, correct)
    } else {
      data <- rbind(data, data.frame(contrast, correct))
    }
  }
  return(data)  
}

# Create some data with contrast levels for the variable "contrasts" 0.01 to 0.1 in 10 steps. Create a vector that goes from 0 to 1 for "pcorrect". Set ntrials equal to 20. Fit and plot the resulting psychometric function. What is 50% threshold level for this resulting function?
library(tidyverse)
library(psyphy)

# Create vectors 
contrast <- seq(0.01, 0.1, length.out = 10)
pcorrect <- seq(0.0, 1.0,length.out = 10)

# Create data
dat.contast <- datasim(contrast, pcorrect, ntrials=20)

# Summarize data
dc_summary <- dat.contast %>% group_by(contrast,correct) %>% tally() %>%  ungroup() %>% complete(contrast, correct, fill = list(n = 1))

dc_summary <- subset(dc_summary, correct == 1)
dc_summary$incorrect <- 20 - dc_summary$n
dc_summary$correct <- dc_summary$n

# Take the absolute value of negative contrast values
dc_summary$contrast <- abs(dc_summary$contrast)

# Fit the psychometric function
psymet_fit <- glm(formula = cbind(correct, incorrect) ~ log(contrast), family = binomial, data = dc_summary)

xseq <- seq(0.01, 0.1, len = 100) 
psymet_fit.pred <- predict(psymet_fit, newdata = data.frame(contrast = xseq), type = "response", se.fit = TRUE)  # obtain predicted values 
psymet_pred_df <- data.frame(xseq, psymet_fit.pred$fit)
colnames(psymet_pred_df) <- c('contrast','fit')

psymet_plot <- ggplot(data = dc_summary, aes(x = contrast, y = correct / 20)) + geom_point(size = 4) + geom_line(data = psymet_pred_df, aes(x = contrast, y = fit), size = 2) + ylab('proportion correct') + theme(text = element_text(size=16), axis.text.x = element_text(size = 16), axis.text.y = element_text(size=16))

psymet_plot
# The 50% threshold is around 0.050 based on observation of the graph (but this changes slightly based on the simulated data)

