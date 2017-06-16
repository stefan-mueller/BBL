# Load packages

library(tidyverse)

# Load data

dta_raw_1617 <- read.csv("raw_data/beko_bbl_2016-17.csv", 
                         header = TRUE, fileEncoding = "utf-8") %>% 
  mutate(season = "season1617") 

#names(dta_raw_1617)[2] <- c("E","F")
dta_raw_1516 <- read.csv("raw_data/beko_bbl_2015-16.csv",
                         header = TRUE, fileEncoding = "utf-8") %>% 
  mutate(season = "season1516")

dta_raw_1415 <- read.csv("raw_data/beko_bbl_2014-15.csv", header = TRUE, fileEncoding = "utf-8") %>% 
  mutate(season = "season1415")

dta_raw_1314 <- read.csv("raw_data/beko_bbl_2013-14.csv", header = TRUE, fileEncoding = "utf-8") %>% 
  mutate(season = "season1314")

dta_raw_1213 <- read.csv("raw_data/beko_bbl_2012-13.csv", header = TRUE, fileEncoding = "utf-8") %>% 
  mutate(season = "season1213")

dta_raw_1112 <- read.csv("raw_data/beko_bbl_2011-12.csv", header = TRUE, fileEncoding = "utf-8") %>% 
  mutate(season = "season1112")

## Bind datasets

dta_raw <- bind_rows(dta_raw_1617, dta_raw_1516, dta_raw_1415, dta_raw_1314, dta_raw_1213, dta_raw_1112)

head(dta_raw)

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

## Rename teams

dta <- dta %>% 
  mutate(club = car::recode(club, "'Neckar RIESEN Ludwigsburg'='MHP RIESEN Ludwigsburg';
                            'New Yorker Phantoms Braunschweig'='Basketball Löwen Braunschweig';
                            'LTi GIESSEN 46ers'='GIESSEN 46ers';'Brose Baskets'='Brose Bamberg'; 'BBC Bayreuth'='medi bayreuth';
                            's.Oliver Würzburg'='s.Oliver Baskets'"))

dta <- dta[order(dta$player_season, -abs(dta$games) ), ] #sort by id and reverse of abs(value)
nrow(dta)

dta_unique <- dta[ !duplicated(dta$player_season), ]              # take the first row within each id
nrow(dta_unique)

dta_small <- dta_unique %>% 
  select(-player_season) %>% 
  mutate(mpg = as.numeric((minutes/games))) %>% 
  #select(player_club, season, minutes_per_game) %>% 
  #mutate(row = 1:nrow(dta)) %>% 
  unique()

dta_unique_wide <- dta_small %>% 
  gather(variable, value, -(c(name, season))) %>%
  unite(temp, variable, season, sep = "_") %>%
  spread(temp, value) 

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


dta_long <- dta_long %>% 
  mutate(ppg = round(points/games, 2)) %>% 
  mutate(mpg = round(minutes/games, 2)) %>% 
  mutate(efpg = round(ef/games, 2)) %>% 
  mutate(season = as.factor(season),
         club = as.factor(club)) %>% 
  filter(season != "2011/12") %>% 
  filter(minutes > 20) # Keep only players who played more than 20 minutes in the season


## Mark promoted teams

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
 # filter(club == "Telekom Baskets Bonn")


# Calculate stayed ratio
dta_final <- dta_final %>% 
  mutate(morethan15mpg = ifelse(mpg > 15, "More than 15 minutes/game", "Less than 15 minutes/game")) %>% 
  mutate(morethan5ppg = ifelse(ppg > 5, "More than 5 points/game", "Less than 5 points/game"))


## Save this dataset

write.csv(dta_final, "data/beko_bbl_2012-2017.csv", fileEncoding = "utf-8", row.names = FALSE)
# dta_final_Bonn <- dta_final %>% 
#   filter(club == "Telekom Baskets Bonn")


dta_stayed <- dta_final %>% 
  group_by(club, season) %>% 
  mutate(stayed_ratio = 100 * (sum(stayed)/n())) %>% 
  select(club, season, stayed_ratio)
  
  
dta_stayed_minutes <- dta_final %>% 
  group_by(club, season) %>% 
  filter(morethan15mpg == "More than 15 minutes/game") %>% 
  mutate(stayed_ratio_morethan15mpg = 100 * (sum(stayed)/n())) %>% 
  select(club, season, stayed_ratio_morethan15mpg) %>% 
  unique()

dta_stayed_points <- dta_final %>% 
  group_by(club, season) %>% 
  filter(morethan5ppg == "More than 5 points/game") %>% 
  mutate(stayed_ratio_morethan5ppg = 100 * (sum(stayed)/n()))%>% 
  select(club, season, stayed_ratio_morethan5ppg) %>% 
  unique()

## Left join

dta_final_summarised <- left_join(dta_stayed, dta_stayed_points)

dta_final_summarised <- left_join(dta_final_summarised, dta_stayed_minutes)

dta_final_summarised <- dta_final_summarised %>% 
  unique() %>% 
  mutate(club_season = paste(season, club))

dta_final_summarised_total <- dta_final_summarised %>% 
  group_by(club) %>% 
  mutate(stayed_ratio_all = mean(stayed_ratio),
         stayed_ratio_morethan5ppg_all = mean(stayed_ratio_morethan5ppg),
         stayed_ratio_morethan15mpg_all = mean(stayed_ratio_morethan15mpg)) %>% 
  select(club, stayed_ratio_all:stayed_ratio_morethan15mpg_all) %>% 
  unique()


dta_final_summarised_long <- dta_final_summarised %>% 
  tidyr::gather(type_ratio, ratio, stayed_ratio, stayed_ratio_morethan5ppg, stayed_ratio_morethan15mpg) 
  

dta_final_summarised_long_order <- dta_final_summarised_long %>% 
  arrange(season, ratio) %>% 
  mutate(order = row_number())

dta_final_summarised_long$club <- factor(dta_final_summarised_long$club, 
                                         levels = rev(levels(dta_final_summarised_long$club)))

ggplot(dta_final_summarised_long, aes(x = club, y = ratio, order = ratio, colour = factor(type_ratio))) +
  geom_point() +
  scale_y_continuous(limits = c(0, 80), breaks = c(seq(0, 80, by = 20))) +
  scale_color_discrete(name = NULL, labels = c("Total", ">10 Minuten pro Spiel", ">5 Punkte pro Spiel")) +
  facet_wrap(~season, scales = "free", nrow = 4) +
  coord_flip() +
  ylab(NULL) +
  xlab(NULL) +
  ggtitle("Prozentualer Anteil der im Kader verbliebenen eingesetzten Spieler") +
  theme_bw() +
  theme(legend.position = "bottom",
        axis.text = element_text(colour = "black"))
ggsave("output/ratio_season.jpg", height = 12, width = 12)


 dta_final_summarised_long_total <- dta_final_summarised_total %>% 
  tidyr::gather(type_ratio, ratio, stayed_ratio_all, stayed_ratio_morethan5ppg_all, stayed_ratio_morethan10mpg_all) 



ggplot(dta_final_summarised_long_total, aes(reorder(x = club, ratio), y = ratio, colour = type_ratio)) +
  geom_point(alpha = 0.7, size = 2) +
  scale_y_continuous(limits = c(0, 70), breaks = c(seq(0, 70, by = 10))) +
  scale_color_discrete(name = NULL, labels = c("Total", ">15 Minuten pro Spiel", ">5 Punkte pro Spiel")) +
  coord_flip() +
  ylab("Prozent") +
  xlab(NULL) +
  ggtitle("Prozentualer Anteil der im Kader verbliebenen eingesetzten Spieler \n(Durchschnitt 2012 bis 2016)") +
  theme_bw() + 
  theme(legend.position = "bottom",
        axis.text = element_text(colour = "black"))
ggsave("output/ratio_total.jpg", height = 5, width = 8)


  dta_stayed_ratio <- dta_stay %>% 
  group_by(club_season1213) %>% 
  mutate(ratio_stay2013 = mean(stayed2013, na.rm = FALSE))

dta_select_clubs <- dta_stay %>% 
  select(starts_with("club_season"), name, stayed2013:stayed2016, mpg_season1213:mpg_season1617)


dta_summarised <- dta_select_clubs %>% 
  filter(!is.na(club_season1415)) %>% 
  select(club_season1415, stayed2015, mpg_season1415, name) %>% 
  filter(mpg_season1415 > 5) %>% 
  group_by(club_season1415) %>% 
  arrange(club_season1415)
  #summarise(stayed_ratio = mean(stayed2015, na.rm = TRUE))

dta_summarised
  
mutate(ratio_stayed2016 = ifelse())
  select(season1617_club, stayed2016, name) %>% 
  filter(!is.na(stayed2016))
  group_by(season1617_club) %>% 
  summarise(stayed_ratio = mean(stayed2016, na.rm = TRUE))

dta_summarised
ggplot(dta_summarised, aes(x = ))

head(dta_unique_wide)
df %>% 
  gather(variable, value, -(month:student)) %>%
  unite(temp, student, variable) %>%
  spread(temp, value)

dta_per_season <- spread(data = dta_small, 
             key = season,
             value = minutes_per_game) %>% 
  separate(player_club, c("player", "club"), sep = "_", remove = FALSE) %>% 
  arrange(club) %>% 
  filter(club == "Telekom Baskets Bonn")


dta_per_season <- dta_per_season %>% 
  mutate(stayed_2013 = ifelse(!is.na(`2012/2013`) & is.na(`2013/2014`), 1, 0)) %>% 
  mutate(stayed_2014 = ifelse(!is.na(`2013/2014`) & is.na(`2014/2015`), "stayed", "left")) %>% 
  mutate(stayed_2015 = ifelse(!is.na(`2014/2015`) & is.na(`2015/2016`), "stayed", "left")) %>% 
  mutate(stayed_2016 = ifelse(!is.na(`2015/2016`) & is.na(`2016/2017`), "stayed", "left"))

dta_summer_2013 <- dta_per_season %>% 
  filter(!is.na(`2012/2013`))

glm1 <- glm(factor(stayed_2013) ~ as.numeric(`2012/2013`), 
            data = dta_summer_2013, family = binomial(link = "logit"))

head(wb)
dta_wide <- spread(dta_small, name, season)
iris.df = as.data.frame(iris)
iris.df$row <- 1:nrow(iris.df) ## added explicit row numbers
long <- gather(iris.df, vars, val, -Species, -row) ## and made sure to keep em
wide <- spread(long, vars, val)


head(dta_small)

dta_dyadic <- merge(dta, dta, by = "name", all.x = TRUE, all.y = TRUE)

dta_subset <- dta[1:15,]

head(dta_subset)
# Select all columns except player name and season
cols <- colnames(dta)[2:max(ncol(dta)-1)]

cols
dta_spread <- reshape(dta, idvar = "name", timevar = "season", direction = "wide")

my.df <- data.frame(ID=rep(c("Günther","Günther","Wobo"), 5), TIME=rep(1:5, each=3), X=1:15, Y=16:30)


ID TIME X  Y
1  A    1 1 16
2  B    1 2 17
3  C    1 3 18
4  A    2 4 19
5  B    2 5 20
6  C    2 6 21

library(magrittr); requireNamespace("tidyr"); requireNamespace("dplyr")

my.df %>% 
  tidyr::gather_(key="variable", value="value", c("X", "Y")) %>%  # Make it even longer.
  dplyr::mutate(                                                  # Create the spread key.
    time_by_variable   = paste0(variable, "_", TIME)
  ) %>% 
  dplyr::select(ID, time_by_variable, value) %>%                  # Retain these three.
  tidyr::spread(key=time_by_variable, value=value)                # Spread/widen.

dta %>% 
  tidyr::gather_(key="variable", value="value", cols) %>%  # Make it even longer.
  dplyr::mutate(                                                  # Create the spread key.
    time_by_variable   = paste0(variable, "_", TIME)
  ) %>% 
  dplyr::select(ID, time_by_variable, value) %>%                  # Retain these three.
  tidyr::spread(key=time_by_variable, value=value)                # Spread/widen.


dta_new <- dta %>% 
  group_by(name) %>% 
  mutate(number_clubs = length(unique(club)))

dta_all_players <- dta_new %>% 
  select(name) %>% 
  unique()

nrow(dta_all)
dta_player <- dta_new %>% 
  select(name, number_clubs) %>% 
  arrange(-number_clubs) %>% 
  unique() %>% 
  filter(number_clubs > 2)
  

head(dta_player)

ggplot(dta_player, aes(x = reorder(name, number_clubs), y = number_clubs)) +
  geom_point() +
  coord_flip()


## Merge dta_new by dta_new

dta_spread <- dta_new %>% 
  ungroup() %>% 
  tidyr::spread(name, season, club)


dshead(dta)
length(unique(x)
## Now make the dataset to a wide format

dta_spread <- dta %>%
  spread(season, club, name)


mutate(player_new = gsub("[(*)]", "_", player))
