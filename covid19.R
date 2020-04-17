library(tidyverse)
library(gganimate)


countries <- c("Austria", "Belgium", "Czech Republic", "France", 
              "Germany", "Greece", "Hungary", "Italy", "Poland", 
              "Portugal", "Spain", "United Kingdom")

countries.sel <- c("France", "Germany", "Italy", "United Kingdom")

keys <- c(
  "Campagne.information",
  "Annulations.évènements",
  "Fermeture.école",
  "Fermeture.lieu_de_travail",
  "Restriction.transports_publics",
  "Restriction.déplacements",
  "Restriction.voyages")

labels <- c(
  "Campagne d'information",
  "Annulations d'évènements",
  "Fermeture des écoles",
  "Fermeture des lieux de travail",
  "Restriction des transports publics",
  "Restriction des déplacements",
  "Restriction des voyages")


covid <- read.csv("OxCGRT_Download_130420_075000_Full.csv") %>%
  mutate(Date = as.Date(as.character(Date),"%Y%m%d")) 

covid.getdelay <- function(var, min) {
  covid %>%
    group_by(CountryName) %>%
    filter(!!as.symbol(var) >= min) %>%
    summarise(Date.ref = first(Date)) %>%
    ungroup() %>%
    right_join(covid) %>%
    mutate(Days.since.ref = Date - Date.ref) %>%
    arrange(CountryName,Date) %>%
    mutate(
      Campagne.information = case_when(
        S5_Public.information.campaigns == 1 ~ TRUE,
        TRUE ~ FALSE),
      Annulations.évènements = case_when(
        S3_Cancel.public.events == 2 ~ TRUE,
        TRUE ~ FALSE),
      Fermeture.école = case_when(
        S1_School.closing == 2 & S1_IsGeneral == 1 ~ TRUE,
        TRUE ~ FALSE),
      Fermeture.lieu_de_travail = case_when(
        S2_Workplace.closing == 2 & S2_IsGeneral == 1 ~ TRUE,
        TRUE ~ FALSE),
      Restriction.transports_publics = case_when(
        S4_Close.public.transport >= 1 ~ TRUE,
        TRUE ~ FALSE),
      Restriction.déplacements = case_when(
        S6_Restrictions.on.internal.movement == 2 & S6_IsGeneral == 1 ~ TRUE,
        TRUE ~ FALSE),
      Restriction.voyages = case_when(
        S7_International.travel.controls == 3 ~ TRUE,
        TRUE ~ FALSE)
    ) %>%
    select(CountryName, Date, Date.ref, ConfirmedCases, ConfirmedDeaths, Days.since.ref, Campagne.information:Restriction.voyages) %>% 
    pivot_longer(
      cols = Campagne.information:Restriction.voyages,
      names_to = "key",
      values_to = "value",
    ) %>%
    mutate(
      key = factor(key, levels = keys),
      Days.since.ref = as.numeric(Days.since.ref)) %>%
    filter(value == TRUE)%>%
    #group_by(CountryName, Date.ref, key) %>%
    #arrange() %>%
    #summarise(Days.since.ref = first(Days.since.ref)) %>%
    group_by(CountryName, key) %>%
    top_n(1,desc(Days.since.ref)) %>%
    ungroup()
}

covid.gettable <- function(df) {
  df %>% 
    select(CountryName, key, Days.since.ref) %>%
    pivot_wider(
      names_from = key,
      values_from = Days.since.ref) %>%
    filter(CountryName %in% countries) %>%
    select(CountryName, 
           "Annulations.évènements",
           "Fermeture.école",
           "Fermeture.lieu_de_travail",
           "Restriction.déplacements",
           "Restriction.voyages")
}


covid.getsum <- function(df) {
  df %>%
    group_by(key) %>%
    summarise(
      Minimum = min(Days.since.ref, na.rm = TRUE),
      Moyenne = round(mean(Days.since.ref, na.rm = TRUE)),
      Maximum = max(Days.since.ref, na.rm = TRUE),
    ) %>%
    full_join(
      subset(df,CountryName=="France",c(key,Days.since.ref))
    ) %>%
    mutate(key = labels) %>%
    setNames(c("Mesure","Minimum","Moyenne","Maximum","France"))
}

covid.getall <- function(var, min) {
  minstr <- ifelse(is.numeric(min), sprintf("%05d",min), min)
  df <- covid.getdelay(var, min) %>%
    mutate(Ref=paste(var,minstr,sep='_'))
  all <- list(
    delay = df,
    table = covid.gettable(df),
    sum = covid.getsum(df)
  )
}

covid.plot <- function(df, title) {
  df.sel <- df %>%
    filter(CountryName %in% countries.sel) %>%
    mutate(CountryName = factor(CountryName, levels=countries.sel)) %>%
    arrange(desc(CountryName))
  
  df %>% arrange(-CountryName) %>%
    mutate(key = fct_rev(key)) %>%
    ggplot(aes(x=key,y=Days.since.ref)) + 
    geom_boxplot() +
    geom_point( aes(fill=CountryName, 
                    stroke = case_when(CountryName == "France" ~ 1.3, TRUE ~ 0.5)),
                data = df.sel,
                shape=23, size=5) +
    coord_flip() +
    scale_x_discrete(labels = rev(labels)) +
    xlab("Mesure") + ylab("Nombre de jours") +
    ggtitle(title) +
    theme_excel_new() +
    theme(plot.title = element_text(hjust = 1))  +
    guides(shape="legend")
}

covid.calendar <- covid.getall("Date","2020-03-16")
covid.deaths_1 <- covid.getall("ConfirmedDeaths",1)
covid.deaths_10 <- covid.getall("ConfirmedDeaths",10)
covid.cases_10 <- covid.getall("ConfirmedCases",10)
covid.cases_1000 <-  covid.getall("ConfirmedCases",1000)



