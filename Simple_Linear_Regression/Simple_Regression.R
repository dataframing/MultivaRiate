# Author: Danny Vilela
# Date: 2 March 2016
#   This script will serve to clean, validate, and filter the values that are
#   relevant for the simple linear regression task.
#

# Define required packages
require(ggplot2)
require(car)

###############
## SETUP I/O ##
###############

# Prepare an output file to append all of our text output
sink("results", append = TRUE, split = TRUE)

# Read in our NYC SAT dataset
df <- read.csv("SAT_Results_2012.csv", header = TRUE)

# Convert our CSV to a data frame and attach it to our session
df <- data.frame(df)

###################################
## DATA VALIDATION / CLEANING UP ##
###################################

# Clean our data to get rid of schools who did not report valid results
df <- df[!(df$Num.of.SAT.Test.Takers == 's'),]

# Clean our data to get rid of our first outlier, ``Queens Satellite High School''
# Uncomment this line if you would like to include our first outlier
df <- df[!(df$SCHOOL.NAME == 'QUEENS SATELLITE HIGH SCHOOL FOR OPPORTUNITY'),]

# Clean our data to get rid of our second outlier, ``GED PLUS s CITYWIDE''
# Uncomment this line if you would like to include our second outlier
df <- df[!(df$SCHOOL.NAME == 'GED PLUS s CITYWIDE'),]

# Our columns are read in as type character, so convert to numeric
df$SAT.Critical.Reading.Avg..Score <- as.numeric(as.character(df$SAT.Critical.Reading.Avg..Score))
df$SAT.Writing.Avg..Score <- as.numeric(as.character(df$SAT.Writing.Avg..Score))

# Establish easy references for our x and y axes
Critical_Reading_Score <- df$SAT.Critical.Reading.Avg..Score
Writing_Score <- df$SAT.Writing.Avg..Score

########################
## MAIN DATA ANALYSIS ##
########################

# Let's look at our data
read_v_write <- ggplot(df) + 
  geom_point(aes(x = Critical_Reading_Score, 
                 y = Writing_Score)) +
  labs(x = "Critical Reading Score", y = "Writing Score") +
  xlim(200, 800) + ylim(200, 800)

read_v_write

# Save our plot
ggsave(read_v_write, filename = "read_v_write_2012.png")

# Explore any outliers in our data
# Click on a point to identify it, the press `esc' to return all points clicked
#print("Press the escape key once you're done choosing points to be identified.")
#identify(Critical_Reading_Score, Writing_Score)

# Fit our linear regression model and output the summary statistics
regression <- lm(Writing_Score ~ Critical_Reading_Score)

# Output the summary of our regression object, :regression
summary(regression)

# Plot all relevant diagnostic plots for our linear regression object, :regression
plot(regression, which = c(1,2))

# Perform partial F-test for slope coefficient = 1
linearHypothesis(regression, c(0,1), rhs = 1)

# Function for fitted line plot
regplot.confbands.fun <- function(x, y, confidencelevel= .95, CImean = TRUE, 
                                  PI = TRUE, CIregline = FALSE, legend = FALSE) {
  #### Modified from a function written by Sandra McBride, Duke University
  #### For a simple linear regression line, this function
  #### will plot the line, CI for mean response, prediction intervals, 
  #### and (optionally) a simulataneous CI for the regression line.
  Critical_Reading <- x[order(x)]
  Writing <- y[order(x)]
  lm1 <- lm(Writing ~ Critical_Reading)	
  plot(Critical_Reading, Writing, ylim = c(min(Writing), (max(Writing) + .2 * max(Writing))))
  abline(lm1$coefficients)
  #### calculation of components of intervals ####
  n <- length(Writing)
  sx2 <- (var(Critical_Reading))
  shat <- summary(lm1)$sigma
  s2hat <- shat ^ 2
  SEmuhat <- shat * sqrt( (1/n) + ((Critical_Reading - mean(Critical_Reading)) ^ 2)/((n - 1) * sx2) )
  SEpred <- sqrt(s2hat + SEmuhat ^ 2)
  t.quantile <- qt(confidencelevel, lm1$df.residual)
  ####
  if (CImean == TRUE) {
    mean.up <- lm1$fitted + t.quantile*SEmuhat
    mean.down <- lm1$fitted - t.quantile*SEmuhat
    lines(Critical_Reading, mean.up, lty = 2)
    lines(Critical_Reading, mean.down, lty = 2)
  }
  if (PI == TRUE) {
    PI.up <- lm1$fitted + t.quantile*SEpred
    PI.down <- lm1$fitted - t.quantile*SEpred
    lines(Critical_Reading, PI.up, lty = 3)
    lines(Critical_Reading, PI.down, lty = 3)
  }
  if (CIregline == TRUE) {
    HW <- sqrt(2 * qf(confidencelevel, n - lm1$df.residual, lm1$df.residual)) * SEmuhat
    CIreg.up <- lm1$fitted + HW
    CIreg.down <- lm1$fitted - HW
    lines(Critical_Reading, CIreg.up, lty = 4)
    lines(Critical_Reading, CIreg.down, lty = 4)
  }	
  if (legend == TRUE) {
    choices <- c(CImean, PI, CIregline)
    line.type <- c(2,3,4)
    names.line <- c("Pointwise CI for mean resp.", 
                    "Prediction Int.", 
                    "Simultaneous conf. region for entire reg. line")
    legend(max(Critical_Reading) - (.2 * max(Critical_Reading)), max(Writing) + (.2 * max(Writing)), 
           legend = names.line[choices], lty = line.type[choices])
  }
}

# Open png graphics device to save our fitted line plot
png(filename = "fitted_line_plot_2012.png")

# Determine fitted line plot for x_axis and y_axis
regplot.confbands.fun(Critical_Reading_Score, Writing_Score)

# Close our png graphics device
dev.off()

# Confidence and prediction intervals for new observation
new_read_v_write <- data.frame(Critical_Reading_Score = c(-1.5))

# Calculate confidence and prediction interval
predict(regression, new_read_v_write, interval = c("confidence"))
predict(regression, new_read_v_write, interval = c("prediction"))

# Open png graphics device to save our fitted line plot
png(filename = "fitted_vs_residual_2012.png")

# Plot our fitted values vs residuals
plot(fitted(regression), residuals(new_read_v_write), 
     xlab = "Fitted values", ylab = "Residuals")

# Close our png graphics device
dev.off()

# Open png graphics device to save our fitted line plot
png(filename = "qq_2012.png")

# Generate normal Q-Q plot
qqnorm(residuals(regression))

# Close our png graphics device
dev.off()
