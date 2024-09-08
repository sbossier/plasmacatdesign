library(tidyverse)
library(propagate)
library(ggrepel)
library(ggthemes)
dataCO2 <- read.csv("conversion-fit.csv")

##################################################################################
# fitting CO2 conversion to first-order reaction rate model                      #
# obtaining equilibrium concentration and reaction rate constant with SD and RSD #
##################################################################################

totalWeight <- sum(dataCO2$convCO2SD^-2)
dataCO2FitW <- nls(convCO2 ~ C-(C-1)*exp(-k*resTime), data = dataCO2, start = list(C=20,k=.05), weights = (convCO2SD^-2/totalWeight))
summary(dataCO2FitW)$coef
C <- summary(dataCO2FitW)$coef[1]
k <- summary(dataCO2FitW)$coef[2]

CSD <- summary(dataCO2FitW)$coef[3]
kSD <- summary(dataCO2FitW)$coef[4]

CRSD <- CSD/C
kRSD <- kSD/k

#######################################################
# constructing the 95% prediction interval of the fit #
#######################################################

# dataCO2FitPred <- data.frame(resTime = seq(0, 100, 2))
# predValues <- predictNLS(dataCO2Fit, newdata = dataCO2FitPred, interval = "prediction", alpha = .05)

# dataCO2FitPred$mean <- predValues$summary[,2]
# dataCO2FitPred$lcl <- predValues$summary[,5]
# dataCO2FitPred$ucl <- predValues$summary[,6]

#######################################################
# constructing the 95% confidence interval of the fit #
#######################################################

dataCO2FitWConf <- data.frame(resTime = seq(0, 100, 4))
confValues <- predictNLS(dataCO2FitW, newdata = dataCO2FitWConf, interval = "confidence", alpha = .05)

dataCO2FitWConf$mean <- confValues$summary[,2]
dataCO2FitWConf$lcl <- confValues$summary[,5]
dataCO2FitWConf$ucl <- confValues$summary[,6]

#####################
# plotting the data #
#####################

dataCO2 %>%
  ggplot(aes(resTime,convCO2)) +
  geom_line(data = dataCO2FitWConf, aes(x = resTime, y = mean), color= "grey", size = 1.5) +
  geom_ribbon(data = dataCO2FitWConf, 
              aes(x = resTime, y = mean, ymin = lcl, ymax = ucl), 
              color= "grey", alpha = .25, size = 1.25) +
  #geom_ribbon(data = dataCO2FitPred, aes(x = resTime, y = mean, ymin = lcl, ymax = ucl), color= "blue", alpha = .25) +
  #geom_line(size = 1) +
  geom_point(size = 2) +
  geom_errorbar(aes(ymin=convCO2 - qt(.975, 11)*convCO2SD, ymax=convCO2 + qt(.975, 11)*convCO2SD), width=1, position=position_dodge(0.05), size = 1) +
  scale_x_continuous(limits = c(0,100),expand = expansion(mult = c(0.01, .01))) + 
  scale_y_continuous(limits = c(0,30),expand = expansion(mult = c(0.01, 0.01))) +
  ggtitle("CO2 conversion vs. residence time") +
  xlab("Residence time (s)") +
  ylab("CO2 conversion (%)") +
  theme_solarized()