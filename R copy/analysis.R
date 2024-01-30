### analysis

# productivity

productivity_clean |> group_by(destSiteID, treatment, plot_nr) |> summarise(sum = sum(productivity)) |> group_by(destSiteID, treatment) |> summarise(mean(sum), sd(sum)/sqrt(n()))

dd <- productivity_clean |> 
  group_by(destSiteID, date_out, treatment, plot_nr) |> 
  summarise(sum = sum(productivity))
fit <- lm(sum ~ destSiteID, dd |> filter(treatment == "Cage"))
fit <- lm(sum ~ destSiteID, dd |> filter(treatment == "Control"))
summary(fit)

fit <- lm(sum ~ destSiteID*treatment, dd)
summary(fit)

dd |> 
  mutate(destSiteID = factor(destSiteID, levels = c("Vikesland", "Joasete", "Liahovden"))) |> 
  group_by(destSiteID, treatment, date_out) |> 
  summarise(mean = mean(sum),
            se = sd(sum)/sqrt(n())) |> 
  ggplot(aes(x = date_out, y = mean, colour = treatment,
             ymin = mean - se, ymax = mean + se)) +
  geom_point() +
  geom_errorbar() +
  labs(x = "", y = bquote(Productivity~(g~cm^-2~y^-1))) +
  facet_wrap(~ destSiteID) +
  theme_bw()

# roots
roots_clean |> 
  mutate(days = as.numeric(as.character(days_buried))) |> 
  group_by(year) |> 
  summarise(mean = mean(days),
            se = sd(days)/sqrt(n()))

# soil
soil_character |> 
  group_by(variable, destSiteID) |> 
  summarise(mean = mean(value),
            se = sd(value)/sqrt(n()),
            min = min(value),
            max = max(value))

cn_clean |> 
  group_by(variable, destSiteID) |> 
  summarise(mean = mean(value),
            se = sd(value)/sqrt(n()),
            min = min(value),
            max = max(value)) |> 
  print(n = Inf)

dd <- cn_clean |> 
  filter(variable == "soil_organic_matter",
         year == 2021) |> 
  mutate(destSiteID = factor(destSiteID, levels = c("Vikesland", "Joasete", "Liahovden")))
fit <- lm(value ~ destSiteID, dd)
summary(fit)


# decomposition
tbi_index |> 
  group_by(timing) |> 
  summarise(ming = min(fraction_remaining_green, na.rm = TRUE), maxg = max(fraction_remaining_green, na.rm = TRUE),
            minr = min(fraction_remaining_red, na.rm = TRUE), maxr = max(fraction_remaining_red, na.rm = TRUE),
            meank = mean(k, na.rm = TRUE), mink = min(k, na.rm = TRUE), maxk = max(k, na.rm = TRUE),
            meanS = mean(S, na.rm = TRUE), minS = min(S, na.rm = TRUE), maxS = max(S, na.rm = TRUE))


fit <- lm(k ~ origSiteID*timing, tbi_index)
summary(fit)
fit <- lm(S ~ origSiteID*timing, tbi_index)
summary(fit)
