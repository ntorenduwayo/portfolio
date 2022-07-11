#######################################
# Installing Necessary Libraries      #
#######################################

library(readr)
library(car)
library(tidyverse)
library(corrplot)
library(rgl)
library(rglwidget)
library(scatterplot3d)
library(knitr)

#######################################
# Loading the Data                    #
#######################################

df <- read_csv("Women_Prestige_Data.csv")

########################################
# Inspecting the Data                  #
########################################

head(df)


#########################################
# Checking data type and structire:     #
#########################################

str(df)

#########################################
# Summarize the data                    #
#########################################

summary(df)


#########################################
# Data distribution:                    #
#########################################
library(purrr)
library(tidyr)
library(ggplot2)
par(mfrow= c(3, 3))
df %>%
  keep(is.numeric) %>% subset(select=-c(census))%>%
  gather() %>% 
  ggplot(aes(value)) +
  facet_wrap(~ key, scales = "free") +
  geom_histogram(aes(y = ..count..), bins=12, fill = "grey") +
  stat_function(fun = dnorm)

############################################
## Including Plots                         #
############################################

# Graphs to check data distribution:
# Create a function that helps create graphs:
histDenNorm <- function (x, main = "") {
  hist(x, prob = TRUE, main = main) # Histogram
  lines(density(x), col = "blue", lwd = 2) # Density 
  x2 <- seq(min(x), max(x), length = 40)
  f <- dnorm(x2, mean(x), sd(x))
  lines(x2, f, col = "red", lwd = 2) # Normal
  legend("topright", c("Density", "Normal"), box.lty = 3,
         lty = 3, col = c("blue", "red"), lwd = c(1, 2, 2))
}

## Create histograms:

x <- df$education
y <- df$income
z <- df$women
v <- df$prestige
par(mfrow= c(2,2))
histDenNorm(x, main = "education")
histDenNorm(y, main = "income")
histDenNorm(z, main = "women")
histDenNorm(v, main = "prestige")

########################################
# Correlation heatmap:                 #
########################################
library(psych)

df1 <- subset(df, select=-c(census, occupation_name, type))
corPlot(df1, cex = 1.2, numbers=TRUE,stars=TRUE)

########################################
# Simple Linear Regression: Predict    #
# Prestige with Education              #
########################################

model <- lm(prestige ~ education, data = df1)
summary(model)

########################################
# diagnostic plots: Model                   #
########################################

layout(matrix(c(1,2,3,4),2,2)) # optional 4 graphs/page
plot(model)


########################################
# Transform education to center the     #
# values to its mean                   #
########################################

# Center `education` on its mean
education_centered <-  scale(df1$education, center = TRUE, scale = FALSE)
model1 <- lm(prestige ~ education_centered, data = df1)
summary(model1)

################################################################
# Checking the modal fit: 1. Plotting the fitted               #
################################################################
ggplot(df1, aes(x = education_centered, y = prestige)) +
  geom_point() + 
  stat_smooth(method = "lm", col = "indianred") + 
  scale_y_continuous(breaks = seq(1000, 25000, by = 2000), minor_breaks = NULL)

################################################################
# Checking the model fit: 2. Plotting the fitted vs residuals  #
################################################################

plot(model1, which = 1, pch = 16)


########################################
# diagnostic plots: Model1                    #
########################################

layout(matrix(c(1,2,3,4),2,2)) # optional 4 graphs/page
plot(model1)


########################################
# Multiple linear regression           #
########################################

# Center all predictors on their means

education_centered  = scale(df1$education, center = TRUE, scale = FALSE)
income_centered  = scale(df1$income, center = TRUE, scale = FALSE)
women_centered  = scale(df1$women, center = TRUE, scale = FALSE)

# Bind the new variables into a dataframe

centered_predictors <- cbind(education_centered , income_centered , women_centered )
df2 <- cbind(df1, centered_predictors)
names(df2)[5:7] = c("education_centered", "income_centered", "women_centered" )
summary(df2)

# Fit a linear model and run a summary of its results

model2 <- lm(prestige ~ education_centered + income_centered + women_centered, data = df2)
summary(model2)

model3 <- lm(prestige ~ education_centered + income_centered, data = df2)
summary(model3)

################################################################
# Comparing the models using ANOVA: Not significantly different #
################################################################
anova(model2, model3, test=c("Chisq"))

###############################################################
# Comparing Models Using AIC                                  #
###############################################################

library(AICcmodavg)

model.set <- list(model1, model2, model3)
model.names <- c("model1", "model2", "model3")

aictab(model.set, modnames = model.names)

########################################
# Model Visualization                  #
########################################
library(tidyverse)
library(plotly)
library(moderndive)
# Define 3D scatterplot points --------------------------------------------
# Get coordinates of points for 3D scatterplot
x_values <- df2$education_centered
y_values <- df2$income_centered
z_values <- df2$prestige

# Define regression plane -------------------------------------------------
# Construct x and y grid elements
x_grid <- seq(from = min(x_values), to = max(x_values), length = 30)
y_grid <- seq(from = min(y_values), to = max(y_values), length = 50)

# Construct z grid by computing
# 1) fitted beta coefficients
# 2) fitted values of outer product of x_grid and y_grid
# 3) extracting z_grid (matrix needs to be of specific dimensions)
beta_hat <- df2 %>% 
  lm(prestige ~ education_centered + income_centered, data = .) %>% 
  coef()
fitted_values <- crossing(y_grid, x_grid) 

z_grid <- fitted_values %>% 
  pull(z_grid) %>%
  matrix(nrow = length(x_grid)) %>%
  t()

# Define text element for each point in plane
text_grid <- fitted_values %>% 
  pull(z_grid) %>%
  as.character() %>% 
  paste("prestige: ", ., sep = "") %>% 
  matrix(nrow = length(x_grid)) %>%
  t()

# Plot using plotly -------------------------------------------------------
plot_ly() %>%
  # 3D scatterplot:
  add_markers(
    x = x_values,
    y = y_values,
    z = z_values,
    marker = list(size = 5),
    hoverinfo = 'text',
    text = ~paste(
      "prestige: ", z_values, "<br>",
      "income_centered: ", y_values, "<br>",
      "education_centered: ", x_values 
    )
  ) %>%
  # Regression plane:
  add_surface(
    x = x_grid,
    y = y_grid,
    z = z_grid,
    hoverinfo = 'text',
    text = text_grid
  ) %>%
  # Axes labels and title:
  layout(
    title = "3D scatterplot and regression plane",
    scene = list(
      zaxis = list(title = "y: prestige"),
      yaxis = list(title = "x2: income_centered"),
      xaxis = list(title = "x1: education_centered")
    )
  )
