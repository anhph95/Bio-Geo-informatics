# My script for my term project
# Clean up stuff
rm(list=ls())

# Load libraries
library(sf)
library(leaflet)
library(dplyr)
library(ggplot2)


# Load data
df <- read.csv(file.choose())
View(df)

##################################################
## Data cleaning
# Why do we need cleaning?
# Run the following code, notice anything unusual?
table(df$squirrelpresent)
# Another way to check it
unique(df$squirrelpresent)

# Now run both of these code, see the difference?
df$squirrelpresent[df$squirrelpresent=="no "] <- "no"
table(df$squirrelpresent)

# Above is just one simple example, you might need to inspect more columns base on your need
# Date - check for date out of this semester
mydate <- strptime(paste(df$date, df$time), format="%m/%d/%Y %I:%M:%S %p")
start_date <- strptime("08/01/2023",format="%m/%d/%Y")
end_date <- strptime("12/31/2023",format="%m/%d/%Y")
odds <- df[mydate < start_date | mydate > end_date,]
View(odds)
# Fix
df[388,"date"] <- "09/06/2023"
df[673,"date"] <- "10/18/2023"
df[757,"date"] <- "10/24/2023"

# GPS
# Out of Georgia
odds <- df[!(between(df$latitude,30.357,35.000)&between(df$longitude,-85.605,-80.840)),]
View(odds)
# Fix
df$longitude[df$longitude>0] <- -df$longitude[df$longitude>0]

# Out of Atlanta
odds <- df[!(between(df$latitude,33.647,33.886)&between(df$longitude,-84.552,-84.289)),]
View(odds)
# Better plot and fix manually

# Behaviors - no behavior noted down although squirrel presented
behavior_col <- sprintf("behavior%02d", 1:16)
behavior_only <- df[df$squirrelpresent=="yes",][behavior_col]
rows_all_na  <- rowSums(is.na(behavior_only)) == ncol(behavior_only)
odds <- df[df$squirrelpresent=="yes",][rows_all_na,]
View(odds)

## Formating 
# Get date time in R format
df$datetime <- strptime(paste(df$date, df$time), format="%m/%d/%Y %I:%M:%S %p")

# Get hour 
df$hour <- as.numeric(format(df$datetime, format="%H"))

##################################################
### Masking - usefull for t-test and ANOVA
# Get time category
df <- df %>%
  mutate(hour = as.integer(format(datetime, "%H")),
         time_category = case_when(
           hour >= 20 | hour < 4 ~ "Night",
           hour >= 4 & hour < 12 ~ "Morning",
           hour >= 12 & hour < 17 ~ "Afternoon",
           hour >= 17 & hour < 20 ~ "Evening"
         ))

# GT vs non GT
df$GT <- ifelse(between(df$latitude,33.768,33.783) & between(df$longitude,-84.407,-84.391),'yes','no')
?ifelse # Check what the code does

# Weekend vs weekday
df$Weekendvsweekday <- ifelse(df$weekday %in% c('Saturday','Sunday'),'weekend','weekday')

##################################################
### Subsetting - only recommended for t-test
# Subsetting examples for GT vs non-GT
df_allGt <- df[between(df$latitude,33.768,33.783) & between(df$longitude,-84.407,-84.391),] # Give all data in the Lat and Long range
df_notGt <- df[!(between(df$latitude,33.768,33.783) & between(df$longitude,-84.407,-84.391)),] # Give all data NOT in the Lat and Long range
?between # Check what the code does

# AM vs PM
df_am <- df[between(df$hour,0,11),]
df_pm <- df[between(df$hour,12,23),]

# subsetting examples for Clough vs Kendeda building
df_CULC <- df[grepl('culc|clough',df$sitedescription,ignore.case=T),] # Give any data that mention Clough or CULC in the description
df_Kendeda <- df[grepl('kendeda',df$sitedescription,ignore.case=T),] # Give any data that mention Kendeda in the description
?grepl # Check what the code does

# Random sampling by factor
df_sample <- df %>% group_by(cloudcover) %>% sample_n(30)
table(df_sample$cloudcover)

##################################################
### Squirrel present or not
# Count groups, similar to count() in demographic lab
table(df$squirrelpresent)
?table # Check what the code does, look for Cross tabulation and table creation

# Count by 2 independent variables
tbl <- table(df$cloudcover,df$squirrelpresent)
tbl

# Count to percentage
tbl_percent <- prop.table(tbl,1) # 1 for by row, 2 for by column
tbl_percent
?prop.table # Check what the code does

# Wide vs long data format
tbl_wide <- as.data.frame.matrix(tbl)
tbl_long <- as.data.frame(tbl)

# Only look at data where squirrel present
df_squirrel <- df[df$squirrelpresent=='yes',]

## Number of squirrel vs cloud cover
df_squirrel_count <- as.data.frame(table(df_squirrel$cloudcover,df_squirrel$week))
# ANOVA
anova <- aov(Freq~Var1,data=df_squirrel_count) # Check what is Var1 and Freq in this case
summary(anova)
TukeyHSD(anova)
?aov
# Boxplot
ggplot(df_squirrel_count, aes(x = Var1, y = Freq)) +
  geom_boxplot()

## Number of squirrel vs number of human
df_human <- as.data.frame(table(df_squirrel$humanwithin30ft))
df_human$Var1 <- as.numeric(df_human$Var1)

# Linear regression
linear <- lm(Var1~Freq,data=df_human) # Check what is Var1 and Freq in this case
summary(linear)
?lm
# Scatter plot
ggplot(df_human, aes(x=Var1,y=Freq))+
  geom_point(color='black')+
  geom_smooth(method = "lm")+
  xlab('# human within 30ft')+ylab('# squirrel')

# Polynomial regression
poly <- lm(Var1~poly(Freq,2),data=df_human)
summary(poly)
# Scatter plot
ggplot(df_human, aes(x=Var1,y=Freq))+
  geom_point(color='black')+
  geom_smooth(method = "lm",formula=y~poly(x,2))+
  xlab('# human within 30ft')+ylab('# squirrel')

## Squirrel presence vs wind conditions
df_wind <- table(df$windconditions,df$squirrelpresent)
# Test for independence
chisq.test(df_wind)
RVAideMemoire::G.test(df_wind)
?chisq.test
?RVAideMemoire::G.test
# Bar plot
df_wind_plot <- as.data.frame(df_wind)
ggplot(df_wind_plot,aes(x=Var1,y=Freq,fill=Var2))+
  geom_bar(stat="identity", color="black", position=position_dodge())

##################################################
### Squirrel behavior
# Only look at data where squirrel presented
df_squirrel <- df[df$squirrelpresent=='yes',]
# Run below codes as a chunk, compare your df with df_combine, what do you think the code does
behaviors <- c('Vigilance','Foraging','Alert Feeding','Social','Other') # list of all behavior
behavior_col <- sprintf("behavior%02d", 1:16) # list of column names to extract data
# Function to get percentage of each behavior and the most common behavior
behavior_count <- function(x) {
  x <- factor(x,levels=behaviors,order=T) # Add factor and order
  tbl <- table(x) # Count each behavior
  percent_tbl <- round(prop.table(tbl)*100,2) # Compute percentage
  # Find most common one
  common <- setNames(paste(names(tbl[tbl == max(tbl)]), collapse = ', '),'most_common')
  # # Run these two lines if your data has NAs
  # if(all(is.na(percent_tbl))){common<-setNames(NA,'most_common')} # If no squirrel, return NA
  # else{common <- setNames(paste(names(tbl[tbl == max(tbl)]), collapse = ', '),'most_common')} # Some case might have evenly common behaviors, record all of them
  return(c(percent_tbl,common))
}
percent <- as.data.frame(t(apply(df_squirrel[,behavior_col],1,behavior_count))) # Apply above function to each row of column behavior01 to behavior16
percent[behaviors] <- lapply(percent[behaviors], as.numeric) # Change to numeric
df_combine <-cbind(df_squirrel,percent) # Attach result to original table
# What question can you ask with the df_combine

##################################################
## Example questions
# Box plots
ggplot(df_combine, aes(x = cloudcover, y = Foraging)) +
  geom_boxplot() +
  coord_flip() # Rotate to make it horizontal

# Scatter plot
ggplot(df_combine, aes(x=Vigilance,y=humanwithin30ft))+
  geom_point()+
  geom_smooth(method = "lm", se = T)

# Common behavior by week
df_common <- as.data.frame(table(df_combine$week,df_combine$most_common))
ggplot(df_common, aes(x = Var1, y = Freq, fill = Var2)) +
  geom_bar(stat = "identity", position=position_dodge()) +
  theme_minimal() +
  ylab("# squirrel") +
  xlab("Week") +
  coord_flip()

# Behavior percentage by week
# Wide to long
library(tidyr)
behaviors <- c('Vigilance','Foraging','Alert Feeding','Social','Other')
df_long <- df_combine %>% pivot_longer(cols = all_of(behaviors), names_to = "Behavior", values_to = "count")
df_long$week <- as.character(df_long$week)
# Plot
ggplot(df_long, aes(x = cloudcover, y = count, fill = Behavior)) +
  geom_boxplot() +
  theme_minimal() +
  ylab("Behavior percentage") +
  xlab("Week")

##################################################
## GIS
# Time category masking
df <- df %>%
  mutate(hour = as.integer(format(datetime, "%H")),
         time_category = case_when(
           hour >= 20 | hour < 4 ~ "Night",
           hour >= 4 & hour < 12 ~ "Morning",
           hour >= 12 & hour < 17 ~ "Afternoon",
           hour >= 17 & hour < 20 ~ "Evening"
         ))

# Plot map
df_popup <- df[df$squirrelpresent=='yes',] %>% st_as_sf(coords=c("longitude", "latitude"), crs=4326) %>% 
  mutate(popup_html = paste0("<i>", geometry, "</i><br/>", 
                             "<i>", weekday, "</i><br/>",
                             "<i>", datetime, "</i><br/>", 
                             "<i>", sitedescription, "</i><br/>")
  )

pal <- colorFactor(c("purple","orange","red","black"), domain = c('Night','Morning','Afternoon','Evening'))
leaflet() %>% 
  addProviderTiles("Esri.WorldStreetMap") %>% 
  addCircleMarkers(data = df_popup,
                   popup = ~popup_html,
                   color = ~pal(time_category),
                   stroke = T,
                   radius = 2,
                   opacity = 1)
# Try to color by other factor instead of time



