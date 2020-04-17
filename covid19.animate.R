library(gganimate)

covid.cases_10 <- covid.getall("ConfirmedCases",10)

covid.cases <- covid.cases_10$delay
for( cases in seq(20,1000, 10) ) {
  covid.cases <- rbind(
    covid.cases,
    covid.getall("ConfirmedCases",cases)$delay
  )
}

animate(
  covid.plot(covid.cases,"animation") + 
    transition_states(Ref,
      transition_length = 2,
      state_length = 1) +
    ease_aes('cubic-in-out') +
    ggtitle('Nombre de jours entre {closest_state} et différentes mesures',
            subtitle = 'Frame {frame} of {nframes}'),
  nframes = 230, fps=20,
  end_pause = 30,
  width = 600, height = 300)

anim_save("confirmedcase.gif")




covid.deaths_1 <- covid.getall("ConfirmedDeaths",1)

covid.deaths <- covid.deaths_1$delay
for( deaths in seq(2,100, 1) ) {
  covid.deaths <- rbind(
    covid.deaths,
    covid.getall("ConfirmedDeaths",deaths)$delay
  )
}

animate(
  covid.plot(covid.deaths,"animation") + 
    transition_states(Ref,
                      transition_length = 2,
                      state_length = 1) +
    ease_aes('cubic-in-out') +
    ggtitle('Nombre de jours entre {closest_state} et différentes mesures',
            subtitle = 'Frame {frame} of {nframes}'),
  nframes = 230, fps=20,
  end_pause = 30,
  width = 600, height = 300)

anim_save("confirmeddeaths.gif")

