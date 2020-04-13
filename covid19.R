library(tidyverse)

countries = c("Austria", "Belgium", "Czech Republic", "France", 
              "Germany", "Greece", "Hungary", "Italy", "Poland", 
              "Portugal", "Spain", "United Kingdom")

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

covid.getdelay <- function(df, min=1) {
  df %>%
    group_by(CountryName) %>%
    filter(Test >= min) %>%
    summarise(Date.ref = first(Date)) %>%
    ungroup() %>%
    right_join(df) %>%
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
    select(CountryName, Days.since.ref, Campagne.information:Restriction.voyages) %>% 
    pivot_longer(
      cols = Campagne.information:Restriction.voyages,
      names_to = "key",
      values_to = "value",
    ) %>%
    mutate(key = factor(key, levels = keys)) %>%
    filter(value == TRUE)%>%
    group_by(CountryName, key) %>%
    arrange(Days.since.ref) %>%
    summarise(Days.since.ref = first(Days.since.ref))
}

covid.gettable <- function(df) {
  df %>%
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

covid$Test <- covid$ConfirmedDeaths
covid.first_death <- covid.getdelay(covid,1)
covid.first_death.table <- covid.gettable(covid.first_death)

covid$Test <- covid$ConfirmedCases
covid.ten_cases <- covid.getdelay(covid,10)
covid.ten_cases.table <- covid.gettable(covid.ten_cases)

quantile(filter(covid.first_death, key == "Campagne.information")$Days.since.ref, na.rm = TRUE)
