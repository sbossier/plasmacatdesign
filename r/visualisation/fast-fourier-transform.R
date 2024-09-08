# Load necessary packages
library(tidyverse)
library(ggrepel)
library(ggthemes)
library(Rttf2pt1)
library(extrafontdb)
library(extrafont)

# Load in fonts
loadfonts(device = "win")

# Clear workspace
rm(list=ls())

# Read in starting data
setwd("H:/data/co2-splitting/empty-reactor/res-time-70s-2")
filename <- "20201029-0007.csv"
data     <- read_csv(filename, na = c("NA", "N/A", "N A", "Na", "na", "n a", "N a"))
data     <- select(data, c("Time", "Channel C"))[-1,]
colnames(data) <- c("time_ms", "plasma_current_A")
data <- data %>%
  mutate(plasma_current_mA = as.numeric(plasma_current_A)*1000,
         time_ms = as.numeric(time_ms))

trend <- lm(plasma_current_mA ~ time_ms, data)
data <- data %>%
  mutate(plasma_current_mA_residual = trend$residuals)

f.data <- GeneCycle::periodogram(data$plasma_current_mA_residual)
acq.freq <- 3.125e+8
harmonics <- 1:(acq.freq/2)

plot(x = (f.data$freq[500:550]*acq.freq)/1000,
     y = f.data$spec[500:550]/sum(f.data$spec),
     xlab="Harmonics (kHz)",
     ylab="Amplitute Density",
     ylim = c(0, 0.0035),
     type="h")


plot(x = data$time_ms,
       y = data$plasma_current_mA,
       xlab = "Time (ms)",
       ylab = "Plasma Current (A)",
       type = "h")
abline(trend, col="red")


#####################
# fft result #
#####################
data %>% filter(pwr_sei == "Power Const." & grepl("Al", support_type)) %>%
  ggplot(aes(x = sei,
             y = U_min_pos_kV_avg,
             color = material)) +
  geom_point(size = 2) +
  geom_line(alpha = 1) +
  geom_errorbar(aes(ymin  = U_min_pos_kV_avg + qt(.975, df_calc) * U_min_pos_kV_sd / sqrt(df_calc + 1),
                    ymax  = U_min_pos_kV_avg - qt(.975, df_calc) * U_min_pos_kV_sd / sqrt(df_calc + 1)),
                width = 15,
                size  = 0.85,
                alpha = 0.25,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 7000),
                     expand = expansion(mult = c(0.0, 0.0))) + 
  scale_y_continuous(limits = c(4, 9),
                     expand = expansion(mult = c(0.0, 0.0))) +
  labs(x     = "SEI (kJ/mol)",
       y     = "Minimum Positive Voltage (kV)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = F, ncol = 1, bycol = T))




#################################################
fft_result <-  fft(data2$plasma_current_A)
plot.frequency.spectrum(fft_result, xlimits=c(0,50))


plot.frequency.spectrum <- function(X.k, xlimits=c(0,length(X.k))) {
  plot.data  <- cbind(0:(length(X.k)-1), Mod(X.k))
  
  # TODO: why this scaling is necessary?
  plot.data[2:length(X.k),2] <- 2*plot.data[2:length(X.k),2] 
  
  plot(plot.data, t="h", lwd=2, main="", 
       xlab="Frequency (Hz)", ylab="Strength", 
       xlim=xlimits,
       ylim=c(0,max(Mod(plot.data[,2]))))
}

plot.frequency.spectrum(fft_result)

# Plot the i-th harmonic
# Xk: the frequencies computed by the FFt
#  i: which harmonic
# ts: the sampling time points
# acq.freq: the acquisition rate
plot.harmonic <- function(Xk, i, ts, acq.freq, color="red") {
  Xk.h <- rep(0,length(Xk))
  Xk.h[i+1] <- Xk[i+1] # i-th harmonic
  harmonic.trajectory <- get.trajectory(Xk.h, ts, acq.freq=acq.freq)
  points(ts, harmonic.trajectory, type="l", col=color)
}