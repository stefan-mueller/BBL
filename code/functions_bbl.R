## Custom ggplot2 theme
theme_custom <- function (){
  theme_bw()  %+replace% 
    theme(panel.background = ggplot2::element_blank(),
          panel.grid.major.x = element_blank(),
          panel.grid.minor.x = element_blank(), 
          # panel.grid.major.y = element_blank(),
          panel.grid.minor.y = element_blank(), 
          plot.background = element_blank(),
          axis.ticks.y = element_blank(), 
          # panel.spacing = grid::unit(0.1, "lines"),
          panel.grid.major.y = element_line(linetype = "dotted"),
          legend.position = "bottom",
          axis.text = element_text(colour="black"),
          strip.background = element_blank()#,
          #plot.title = element_text(hjust = 0.5)
    )
}



# Plots per season and plotly plots
get_season_plot <- function(which_season, save){
  dta_season <- dta_final_summarised_long %>% 
    filter(season == as.character(which_season)) %>% 
    arrange(ratio) %>% 
    mutate(order = row_number()) 
  # Order ascending
  
  dta_season$club <- reorder(dta_season$club, 
                             dta_season$ratio)
  
  # Plot
  plot <- ggplot(dta_season, 
                 aes(y = club, x = ratio, 
                     colour = type_ratio, 
                     shape = type_ratio, 
                     key = Verblieben)) +
    geom_jitter(alpha = 0.6, size = 3, height = 0, width = 3) +
    scale_x_continuous(limits = c(-5, 90), breaks = c(seq(0, 90, by = 10))) +
    #scale_shape_discrete(name = NULL) +
    #scale_color_discrete(name = NULL) +
    scale_colour_manual(name = NULL, values = c("darkgreen", "blue", "red")) +
    scale_shape_manual(name = NULL, values = c(8, 2, 16)) +
    # http://sape.inf.usi.ch/quick-reference/ggplot2/shape
    xlab("Prozent") +
    ylab(NULL) +
    ggtitle(paste("Anteil verbliebener Spieler", " (", which_season, ")", sep = "")) +
    theme_custom() + 
    theme(legend.position = "bottom",
          axis.text = element_text(colour = "black"),
          legend.title.align = "0")
  ggsave(plot, file = as.character(paste("output/ratio_", save, ".jpg", sep = "")), 
         height = 5, width = 7.5)
  
  # Create plotly graph
  library(plotly)
  
  Sys.setenv("plotly_username"="stefan-mueller")
  Sys.setenv("plotly_api_key"="oOlCBQGmMIQkobHjOREr")
  
  plot_plotly <- ggplotly(plot, autosize = F, width = 800, height = 600, 
                          margin = m, tooltip = "Gehalten")
  # api_create(plotly, filename = paste("plot_bbl_stayed_", save), 
  #            sharing = "public")
  print(plot_plotly)
}

get_season_plot(which_season = "2016/17", save = "1617")
