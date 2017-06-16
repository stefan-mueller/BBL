## Load packages

library(tidyverse)

## Load data

# 2016/17
dta_raw_1617 <- read.csv("raw_data/bbl_2016-17.csv", 
                         header = TRUE, fileEncoding = "utf-8") %>% 
  mutate(season = "season1617") 

# 2015/16
dta_raw_1516 <- read.csv("raw_data/bbl_2015-16.csv",
                         header = TRUE, fileEncoding = "utf-8") %>% 
  mutate(season = "season1516")

# 2014/15
dta_raw_1415 <- read.csv("raw_data/bbl_2014-15.csv", header = TRUE, fileEncoding = "utf-8") %>% 
  mutate(season = "season1415")

# 2013/14
dta_raw_1314 <- read.csv("raw_data/bbl_2013-14.csv", header = TRUE, fileEncoding = "utf-8") %>% 
  mutate(season = "season1314")

# 2012/13
dta_raw_1213 <- read.csv("raw_data/bbl_2012-13.csv", header = TRUE, fileEncoding = "utf-8") %>% 
  mutate(season = "season1213")

# 2011/12
dta_raw_1112 <- read.csv("raw_data/bbl_2011-12.csv", header = TRUE, fileEncoding = "utf-8") %>% 
  mutate(season = "season1112")

## Bind datasets
dta_raw <- bind_rows(dta_raw_1617, dta_raw_1516, dta_raw_1415, dta_raw_1314, dta_raw_1213, dta_raw_1112)

## Make some changes regarding the variables (e.g. separate name and team)
dta <- dta_raw %>%
  separate(player, c("player_new", "club"), sep = "\n", remove = FALSE) %>% 
  separate(player_new, c("name", "position"), sep = "[.]", remove = FALSE) %>% 
  mutate(minutes = as.numeric(substr(minutes, 1, nchar(minutes)-6))) %>% 
  #select(season, name, club, points) %>% 
  arrange(name, season) %>% 
  select(-c(pl, player, player_new, position)) %>% 
  mutate(player_season = paste(name, season, sep = "_")) %>% 
  mutate(player_club = paste(name, club, sep = "_")) %>% 
  unique() %>% 
  select(season, player_season, name, club, games, minutes, points, ef, plusminus)

## Rename teams that changed name
dta <- dta %>% 
  mutate(club = car::recode(club, "'Neckar RIESEN Ludwigsburg'='MHP RIESEN Ludwigsburg';'EnBW Ludwigsburg'='MHP RIESEN Ludwigsburg';
                            'New Yorker Phantoms Braunschweig'='Basketball Löwen Braunschweig';
                            'LTi GIESSEN 46ers'='GIESSEN 46ers';'Brose Baskets'='Brose Bamberg'; 'BBC Bayreuth'='medi bayreuth';
                            's.Oliver Würzburg'='s.Oliver Baskets'"))

## Recode names (some players have the same name (and first letter of first name))
# but are different players in different clubs)
dta <- dta %>% 
  mutate(name = ifelse(name == "ANDERSON K" & club == "Eisbären Bremerhaven", "ANDERSON KYLE",
                       ifelse(name == "GIBSON D" & club == "FRAPORT SKYLINERS", "GIBSON DEVIN",
                              ifelse(name == "KING A" & club == "Artland Dragons", "KING ANTHONY",
                                     ifelse(name == "SANDERS J" & club == "Telekom Baskets Bonn", "SANDERS JAMARR", name))))) %>% 
  mutate(player_season = paste(name, season, sep = "_"))

## Sort by player and seson and order descending
dta <- dta[order(dta$player_season, -abs(dta$games) ), ]
nrow(dta)

# duplicated <- dta[duplicated(dta[,2]),] %>% 
#   arrange(name)
# 
# write.csv(duplicated, "duplicated.csv", fileEncoding = "utf-8")

## Take the observation with most games
dta_unique <- dta[ !duplicated(dta$player_season), ]
nrow(dta_unique)

dta_small <- dta_unique %>% 
  select(-player_season) %>% 
  mutate(mpg = as.numeric((minutes/games))) %>% 
  unique()

## Change from long to wide format
dta_unique_wide <- dta_small %>% 
  gather(variable, value, -(c(name, season))) %>%
  unite(temp, variable, season, sep = "_") %>%
  spread(temp, value) 

## Recode whether player stayed or left
dta_stay <- dta_unique_wide %>%
  mutate(stayed_2012 = ifelse(club_season1112 != club_season1213, 0, 1)) %>% 
  mutate(stayed_2013 = ifelse(club_season1213 != club_season1314, 0, 1)) %>% 
  mutate(stayed_2014 = ifelse(club_season1314 != club_season1415, 0, 1)) %>% 
  mutate(stayed_2015 = ifelse(club_season1415 != club_season1516, 0, 1)) %>% 
  mutate(stayed_2016 = ifelse(club_season1516 != club_season1617, 0, 1)) %>% 
  mutate_each(funs(replace(., is.na(.), 0)), stayed_2012:stayed_2016) %>% 
  mutate_each(funs(as.numeric), starts_with("mpg_")) %>% 
  mutate_each(funs(as.numeric), starts_with("points_")) 



## Select only certain variables
# http://www.cookbook-r.com/Manipulating_data/Converting_data_between_wide_and_long_format/

## Transform back to long format

dta_long <- dta_stay %>% 
  tidyr::gather(season_old, club, club_season1112, club_season1213, club_season1314, club_season1415, club_season1516, club_season1617) %>% 
  mutate(season = car::recode(season_old, "'club_season1112'='2011/12';'club_season1213'='2012/13';
                              'club_season1314'='2013/14'; 'club_season1415'='2014/15';
                              'club_season1516'='2015/16'; 'club_season1617'='2016/17'")) %>% 
  filter(!is.na(club)) %>% # only select actual players
  select(-season_old)

dta_long <- dta_long %>% 
  mutate(stayed = as.numeric(ifelse(season == '2012/13', stayed_2012,
                                    ifelse(season == '2013/14', stayed_2013,
                                    ifelse(season == '2014/15', stayed_2014,
                                           ifelse(season == '2015/16', stayed_2015, stayed_2016)))))) %>% 
  mutate(points = as.numeric(ifelse(season == '2011/12', points_season1112,
                                    ifelse(season == '2012/13', points_season1213,
                         ifelse(season == '2013/14', points_season1314,
                                ifelse(season == '2014/15', points_season1415,
                                       ifelse(season == '2015/16', points_season1516, points_season1617))))))) %>% 
  mutate(games = as.numeric(ifelse(season == '2011/12', games_season1112,
                                   ifelse(season == '2012/13', games_season1213,
                         ifelse(season == '2013/14', games_season1314,
                                ifelse(season == '2014/15', games_season1415,
                                       ifelse(season == '2015/16', games_season1516, games_season1617))))))) %>% 
  mutate(ef = as.numeric(ifelse(season == '2011/12', ef_season1112,
                                ifelse(season == '2012/13', ef_season1213,
                        ifelse(season == '2013/14', ef_season1314,
                               ifelse(season == '2014/15', ef_season1415,
                                      ifelse(season == '2015/16', ef_season1516, ef_season1617))))))) %>% 
  mutate(minutes = as.numeric(ifelse(season == '2011/12', minutes_season1112,
    ifelse(season == '2012/13', minutes_season1213,
                     ifelse(season == '2013/14', minutes_season1314,
                            ifelse(season == '2014/15', minutes_season1415,
                                   ifelse(season == '2015/16', minutes_season1516, minutes_season1617))))))) %>% 
  mutate(plusminus = as.numeric(ifelse(season == '2011/12', plusminus_season1112,
    ifelse(season == '2012/13', plusminus_season1213,
                          ifelse(season == '2013/14', plusminus_season1314,
                                 ifelse(season == '2014/15', plusminus_season1415,
                                        ifelse(season == '2015/16', plusminus_season1516, plusminus_season1617)))))))

# Calculate stats per game
dta_long <- dta_long %>% 
  mutate(ppg = round(points/games, 2)) %>% 
  mutate(mpg = round(minutes/games, 2)) %>% 
  mutate(efpg = round(ef/games, 2)) %>% 
  mutate(season = as.factor(season),
         club = as.factor(club)) %>% 
  filter(season != "2011/12") %>% 
  filter(minutes > 1) # Keep only players who played during the season


## Mark teams promoted from ProA and exclud them
dta_final <- dta_long %>% 
  mutate(promoted = ifelse(season == "2016/17" & club == "RASTA Vechta", "yes",
                           ifelse(season == "2016/17" & club == "Science City Jena", "yes",
                                  ifelse(season == "2015/16" & club == "s.Oliver Baskets", "yes",
                                         ifelse(season == "2015/16" & club == "GIESSEN 46ers", "yes",
                                                ifelse(season == "2014/15" & club == "Crailsheim Merlins", "yes",
                                                       ifelse(season == "2014/15" & club == "BG Göttingen", "yes",
                                                              ifelse(season == "2013/14" & club == "RASTA Vechta", "yes",
                                                                     ifelse(season == "2012/13" & club == "Mitteldeutscher BC", "yes","no"))))))))) %>% 
  filter(promoted == "no") %>% 
  group_by(club) %>% 
  select(name, stayed, club:efpg) %>% 
  arrange(season, club) 

## Calculate stay ratio based on points and minutes
dta_final <- dta_final %>% 
  mutate(morethan15mpg = ifelse(mpg > 15, "More than 15 minutes/game", "Less than 15 minutes/game")) %>% 
  mutate(morethan5ppg = ifelse(ppg > 5, "More than 5 points/game", "Less than 5 points/game"))


## Save this dataset
write.csv(dta_final, "data/bbl_2012-2017.csv", fileEncoding = "utf-8", row.names = FALSE)

dta_stayed <- dta_final %>% 
  group_by(club, season) %>% 
  mutate(stayed_ratio = round(100 * (sum(stayed)/n()), 2)) %>% 
  select(club, season, stayed_ratio)
  
dta_stayed_minutes <- dta_final %>% 
  group_by(club, season) %>% 
  filter(morethan15mpg == "More than 15 minutes/game") %>% 
  mutate(stayed_ratio_morethan15mpg = round(100 * (sum(stayed)/n()), 2)) %>% 
  select(club, season, stayed_ratio_morethan15mpg) %>% 
  unique()

dta_stayed_points <- dta_final %>% 
  group_by(club, season) %>% 
  filter(morethan5ppg == "More than 5 points/game") %>% 
  mutate(stayed_ratio_morethan5ppg = round(100 * (sum(stayed)/n()), 2)) %>% 
  select(club, season, stayed_ratio_morethan5ppg) %>% 
  unique()

## Left join (possibly more elegant solution) and keep unique values
dta_final_summarised <- left_join(dta_stayed, dta_stayed_points)
dta_final_summarised <- left_join(dta_final_summarised, dta_stayed_minutes)
dta_final_summarised <- dta_final_summarised %>% 
  unique()


## Save this dataset (ratios per season)
write.csv(dta_final_summarised, "data/ratios_2012-2017.csv", fileEncoding = "utf-8", row.names = FALSE)


dta_final_summarised_total <- dta_final_summarised %>% 
  group_by(club) %>% 
  mutate(stayed_ratio_all = mean(stayed_ratio),
         stayed_ratio_morethan5ppg_all = mean(stayed_ratio_morethan5ppg),
         stayed_ratio_morethan15mpg_all = mean(stayed_ratio_morethan15mpg)) %>% 
  select(club, stayed_ratio_all:stayed_ratio_morethan15mpg_all) %>% 
  unique()


## Save this dataset (aggregated ratios)
write.csv(dta_final_summarised_total, "data/ratios_aggregated.csv", fileEncoding = "utf-8", row.names = FALSE)

## Make plots with ggplot2 

dta_final_summarised_long <- dta_final_summarised %>% 
  tidyr::gather(type_ratio, ratio, stayed_ratio, stayed_ratio_morethan5ppg, stayed_ratio_morethan15mpg) 
  
dta_final_summarised_long_order <- dta_final_summarised_long %>% 
  arrange(season, ratio) %>% 
  mutate(order = row_number())

dta_final_summarised_long$club <- factor(dta_final_summarised_long$club, 
                                         levels = rev(levels(dta_final_summarised_long$club)))

ggplot(dta_final_summarised_long, aes(x = club, y = ratio, order = ratio, 
                                      colour = type_ratio, shape = type_ratio)) +
  geom_point() +
  scale_y_continuous(limits = c(0, 90), breaks = c(seq(0, 90, by = 20))) +
  scale_shape_discrete(name = NULL, labels = c("Total", ">15 Minuten pro Spiel", ">5 Punkte pro Spiel")) +
  scale_color_discrete(name = NULL, labels = c("Total", ">10 Minuten pro Spiel", ">5 Punkte pro Spiel")) +
  facet_wrap(~season, scales = "free", nrow = 4) +
  coord_flip() +
  ylab(NULL) +
  xlab(NULL) +
  ggtitle("Anteil der im Kader verbliebenen eingesetzten Spieler") +
  theme_bw() +
  theme(legend.position = "bottom",
        axis.text = element_text(colour = "black"))
ggsave("output/ratio_season.jpg", height = 12, width = 12)


dta_final_summarised_long_total <- dta_final_summarised_total %>% 
  tidyr::gather(type_ratio, ratio, stayed_ratio_all, stayed_ratio_morethan5ppg_all, stayed_ratio_morethan15mpg_all) 

ggplot(dta_final_summarised_long_total, 
       aes(reorder(x = club, ratio), y = ratio,
           colour = type_ratio, shape = type_ratio)) +
  geom_point(alpha = 0.6, size = 3) +
  scale_y_continuous(limits = c(0, 90), breaks = c(seq(0, 90, by = 10))) +
  scale_shape_discrete(name = NULL, labels = c("Total", ">15 Minuten pro Spiel", ">5 Punkte pro Spiel")) +
  scale_color_discrete(name = NULL, labels = c("Total", ">15 Minuten pro Spiel", ">5 Punkte pro Spiel")) +
  coord_flip() +
  ylab("Prozent") +
  xlab(NULL) +
  ggtitle("Anteil der im Kader verbliebenen eingesetzten Spieler \n(Durchschnitt 2012/13 bis 2016/17)") +
  theme_bw() + 
  theme(legend.position = "bottom",
        axis.text = element_text(colour = "black"))
ggsave("output/ratio_total.jpg", height = 5, width = 7.5)



plot_1617 <- ggplot(filter(dta_final_summarised_long, season == "2016/17"), 
       aes(reorder(x = club, ratio), y = ratio, 
           colour = type_ratio, shape = type_ratio)) +
  geom_point(alpha = 0.6, size = 3) +
  scale_y_continuous(limits = c(0, 90), breaks = c(seq(0, 90, by = 10))) +
  scale_shape_discrete(name = NULL, labels = c("Total", ">15 Minuten pro Spiel", ">5 Punkte pro Spiel")) +
  scale_color_discrete(name = NULL, labels = c("Total", ">15 Minuten pro Spiel", ">5 Punkte pro Spiel")) +
  coord_flip() +
  ylab("Prozent") +
  xlab(NULL) +
  ggtitle("Anteil der im Kader verbliebenen eingesetzten Spieler (2016/17)") +
  theme_bw() + 
  theme(legend.position = "bottom",
        axis.text = element_text(colour = "black"))
ggsave(plot_1617, file = "output/ratio_1617.jpg", height = 5, width = 7.5)

plot_1516 <- ggplot(filter(dta_final_summarised_long, season == "2015/16"), 
                    aes(reorder(x = club, ratio), y = ratio, 
                        colour = type_ratio, shape = type_ratio)) +
  geom_point(alpha = 0.6, size = 3) +
  scale_y_continuous(limits = c(0, 90), breaks = c(seq(0, 90, by = 10))) +
  scale_shape_discrete(name = NULL, labels = c("Total", ">15 Minuten pro Spiel", ">5 Punkte pro Spiel")) +
  scale_color_discrete(name = NULL, labels = c("Total", ">15 Minuten pro Spiel", ">5 Punkte pro Spiel")) +
  coord_flip() +
  ylab("Prozent") +
  xlab(NULL) +
  ggtitle("Anteil der im Kader verbliebenen eingesetzten Spieler (2015/16)") +
  theme_bw() + 
  theme(legend.position = "bottom",
        axis.text = element_text(colour = "black"))
ggsave(plot_1516, file = "output/ratio_1516.jpg", height = 5, width = 7.5)

plot_1415 <- ggplot(filter(dta_final_summarised_long, season == "2014/15"), 
                    aes(reorder(x = club, ratio), y = ratio, 
                        colour = type_ratio, shape = type_ratio)) +
  geom_point(alpha = 0.6, size = 3) +
  scale_y_continuous(limits = c(0, 90), breaks = c(seq(0, 90, by = 10))) +
  scale_shape_discrete(name = NULL, labels = c("Total", ">15 Minuten pro Spiel", ">5 Punkte pro Spiel")) +
  scale_color_discrete(name = NULL, labels = c("Total", ">15 Minuten pro Spiel", ">5 Punkte pro Spiel")) +
  coord_flip() +
  ylab("Prozent") +
  xlab(NULL) +
  ggtitle("Anteil der im Kader verbliebenen eingesetzten Spieler (2014/15)") +
  theme_bw() + 
  theme(legend.position = "bottom",
        axis.text = element_text(colour = "black"))
ggsave(plot_1415, file = "output/ratio_1415.jpg", height = 5, width = 7.5)


plot_1314 <- ggplot(filter(dta_final_summarised_long, season == "2013/14"), 
                    aes(reorder(x = club, ratio), y = ratio, 
                        colour = type_ratio, shape = type_ratio)) +
  geom_point(alpha = 0.6, size = 3) +
  scale_y_continuous(limits = c(0, 90), breaks = c(seq(0, 90, by = 10))) +
  scale_shape_discrete(name = NULL, labels = c("Total", ">15 Minuten pro Spiel", ">5 Punkte pro Spiel")) +
  scale_color_discrete(name = NULL, labels = c("Total", ">15 Minuten pro Spiel", ">5 Punkte pro Spiel")) +
  coord_flip() +
  ylab("Prozent") +
  xlab(NULL) +
  ggtitle("Anteil der im Kader verbliebenen eingesetzten Spieler (2013/14)") +
  theme_bw() + 
  theme(legend.position = "bottom",
        axis.text = element_text(colour = "black"))
ggsave(plot_1314, file = "output/ratio_1314.jpg", height = 5, width = 7.5)


plot_1213 <- ggplot(filter(dta_final_summarised_long, season == "2012/13"), 
                    aes(reorder(x = club, ratio), y = ratio, 
                        colour = type_ratio, shape = type_ratio)) +
  geom_point(alpha = 0.6, size = 3) +
  scale_y_continuous(limits = c(0, 90), breaks = c(seq(0, 90, by = 10))) +
  scale_shape_discrete(name = NULL, labels = c("Total", ">15 Minuten pro Spiel", ">5 Punkte pro Spiel")) +
  scale_color_discrete(name = NULL, labels = c("Total", ">15 Minuten pro Spiel", ">5 Punkte pro Spiel")) +
  coord_flip() +
  ylab("Prozent") +
  xlab(NULL) +
  ggtitle("Anteil der im Kader verbliebenen eingesetzten Spieler (2012/13)") +
  theme_bw() + 
  theme(legend.position = "bottom",
        axis.text = element_text(colour = "black"))
ggsave(plot_1213, file = "output/ratio_1213.jpg",height = 5, width = 7.5)


dta_final_compare_years <- dta_final_summarised_long %>% 
  group_by(season, type_ratio) %>% 
  mutate(mean_type = mean(ratio)) %>% 
  select(season, type_ratio, mean_type) %>% 
  unique()


ggplot(dta_final_compare_years, aes(x = season, y = mean_type, 
                                    colour = type_ratio,
                                    shape = type_ratio)) +
  geom_point(size = 2, alpha = 0.8) +
  scale_y_continuous(limits = c(0, 50)) +
  scale_shape_discrete(name = NULL, labels = c("Total", ">15 Minuten pro Spiel", ">5 Punkte pro Spiel")) +
  scale_color_discrete(name = NULL, labels = c("Total", ">15 Minuten pro Spiel", ">5 Punkte pro Spiel")) +
  coord_flip() +
  geom_hline(yintercept = mean(dta_final_summarised$stayed_ratio)) +
  xlab(NULL) +
  ylab("Prozent") +
  ggtitle("Anteil der im Kader verbliebenen eingesetzten Spieler\n(vereinsübergreifend pro Saison)") +
  theme_bw() +
  theme(legend.position = "bottom")
ggsave("output/comparison_per_season.jpg", height = 5, width = 7.5)

## Load ratios reported by Baskets Bonn

dta_baskets <- read.csv("raw_data/ratios_baskets_bonn.csv",
                        fileEncoding = "utf-8") %>% 
  select(-club)

## Merge with file that contains my aggregated ratios
dta_merged <- bind_cols(dta_final_summarised_total, dta_baskets)

## Plot relationship

library(ggrepel)
ggplot(data = dta_merged, aes(x = stayed_ratio_baskets_bonn, y = stayed_ratio_all)) +
  geom_abline(slope = 1, colour = "grey20", linetype = 2) +
  geom_point(alpha = 0.8, size = 2) +
  geom_text_repel(aes(label = club), size = 4) +
  scale_x_continuous(limits = c(0, 80), breaks = c(seq(0, 80, by = 20))) +
  scale_y_continuous(limits = c(0, 80), breaks = c(seq(0, 80, by = 20))) +
  xlab("Durchschnitt (berechnet von Baskets Bonn)") +
  ylab("Durchschnitt (eigene Berechnungen)") +
  ggtitle("Vergleich der Prozentsatzes der verbliebenen Spieler\n(2012/13 bis 2016/17)") +
  theme_bw()
ggsave("output/comparison_ratios.jpg", width = 7.5, height = 7.5)

cor.test(dta_merged$stayed_ratio_all, dta_merged$stayed_ratio_baskets_bonn)
