
# Month Hall problem
# https://en.wikipedia.org/wiki/Monty_Hall_problem
# https://en.wikipedia.org/wiki/Central_limit_theorem

# Suppose you're on a game show, and you're given the choice of three doors: Behind one door is a car; behind the others, goats. 
# You pick a door, say No. 1, and the host, who knows what's behind the doors, opens another door, say No. 3, which has a goat. 
# He then says to you, "Do you want to pick door No. 2?" Is it to your advantage to switch your choice?

# import libraries --------------------------------------------------------

.libPaths('W:/work/learning_r/R/win-library/3.5')
library(data.table)
library(ggplot2)

library(foreach)
library(doParallel)
library(snow)

library(knitr)
library(kableExtra)

# todo
# make parallel
# create ouput print level (1-3)

set.seed(42)

theme_set(theme_light(base_size=18))

plot_save <- function(plot, width=980, height=700, text_factor=1, filename='plot.png') {
  dpi <- text_factor * 100
  width_calc <- width / dpi
  height_calc <- height / dpi
  ggsave(filename = filename, dpi = dpi, width = width_calc, height = height_calc, units = 'in', plot = plot)
}

'%!in%' <- function(x,y)!('%in%'(x,y))

n_rounds <- c(10, 100)
n_games <- c(10, 100)
combos <- as.data.table(merge(n_rounds, n_games))
colnames(combos) <- c('n_rounds', 'n_games')
combos

n_doors <- 3
doors_arr <- 1:n_doors

mhp_res <- data.table(n_rounds=numeric(), n_games=numeric(), n_round=numeric(), switch_wins=numeric(), stay_wins=numeric())

for (i in 1:nrow(combos)) {
  n_rounds <- combos[i, n_rounds]
  n_games <- combos[i, n_games]
  
  for (n_round in 1:n_rounds) {
    stay_wins <- 0
    switch_wins <- 0
    for (n_game in 1:n_games) {
      prize <- sample(doors_arr, 1)
      contestant <- sample(doors_arr, 1)
      
      doors_avaiable_to_open <- doors_arr[doors_arr %!in% c(prize, contestant)]
      
      if (length(doors_avaiable_to_open) == 1) {
        doors_opened <- doors_avaiable_to_open
      } else {
        doors_opened <- sample(doors_avaiable_to_open, n_doors-2)
      }
      
      doors_available_to_contestant <- doors_arr[doors_arr %!in% doors_opened]
      
      contestant_switch <- doors_available_to_contestant[doors_available_to_contestant %!in% contestant]
      print(paste0('round: ', n_round, ' game: ', n_game, ' prize: ', prize, ' contestant: ', contestant, 
                   ' doors availlable to contestant: ', paste(doors_available_to_contestant, collapse = ','), 
                   ' contestant switch: ', contestant_switch))
      
      if (prize == contestant) {
        stay_wins <- stay_wins + 1
        print('stay wins')
      }
      if (prize == contestant_switch) {
        switch_wins <- switch_wins + 1
        print('switch wins')
      }
      
      print(paste0('stay win: ', round(100 * stay_wins / n_game), '% ', 'switch win: ', round(100 * switch_wins / n_game), '%'))
      
    }
    
    round_dt <- data.table(n_rounds=n_rounds, n_games=n_games, n_round=n_round, switch_wins=switch_wins, stay_wins=stay_wins)
    mhp_res <- rbind(mhp_res, round_dt)
    
  }
}

mhp_res

mhp_res_melt <- melt(mhp_res, id.vars=c('n_rounds', 'n_games', 'n_round'), measure.vars=c('switch_wins', 'stay_wins'))
mhp_res_melt
mhp_res_sum <- mhp_res_melt[order(n_rounds, n_games, variable), .(mean_win=mean(value), sd_win=sd(value)), by=.(n_rounds, n_games, variable)]
mhp_res_sum
fwrite(mhp_res_sum, '')
kable(mhp_res_sum, format='markdown')

ggplot(mhp_res_melt[n_rounds==100 & n_games==10, ], aes(x=value, color=variable)) + 
  geom_histogram(aes(y=..count..), bins=30, position='identity', fill='white', alpha=.3, binwidth=1, size=1.5)

ggplot(mhp_res_melt[n_rounds==100 & n_games==10, ], aes(x=value, color=variable, fill=variable)) + 
  geom_histogram(aes(y=..count..), bins=30, position='dodge', binwidth=1, alpha=.3, size=1.5)


ggplot(mhp_res_melt[n_rounds==100 & n_games==10, ], aes(x=value, color=variable, fill=variable)) + 
  geom_histogram(aes(y=..density..), bins=30, position='dodge', binwidth=1, alpha=.5, size=1.5)

ggplot(mhp_res_melt[n_rounds==100 & n_games==10, ], aes(x=value, color=variable, fill=variable)) + 
  geom_density(alpha=.1, size=1.5)

for (i in c(10, 100)) {
  mhp_plt <- ggplot(mhp_res_melt[n_rounds==100 & n_games==i, ], aes(x=value, color=variable, fill=variable)) + 
    geom_histogram(aes(y=..density..), bins=30, position='identity', alpha=.1, binwidth=1, size=1.25) +
    geom_density(alpha=.1, size=1.25) + 
    geom_vline(data=mhp_res_mean[n_rounds==100 & n_games==i, ], aes(xintercept=mean_win, color=variable), linetype='dashed', size=2) + 
    labs(title=paste0('100 rounds ', i, ' games'))
  plot_save(mhp_plt, width=898, height=698, text_factor=1, filename=paste0(''))
}











