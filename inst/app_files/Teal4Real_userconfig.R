
###############################################################################
###############################################################################
#
# User-defined app configuration
#
###############################################################################
###############################################################################

update_cache = TRUE
#"FALSE" is faster but be careful you've got the right dataset!
# Hint: to update the cache run `cached_cohort(update = T)` once

###############################################################################
# App parameters
###############################################################################

# Uncomment for "Survival lung" example data
app_title <- "Teal4Real Lung Cancer Survival Demo"

app_maintainer_email <- "your_email_address@your_domain.com"

# Uncomment for "Survival lung" example data
study_name = "NCCTG_Lung_Cancer_Data"

###############################################################################
# TTE endpoints
###############################################################################

# Multiple time-to-event endpoints can be defined by using the same order across
# the following variables, e.g. vars.event_vars = c("os_status", "pfs_status")

# Uncomment for "Survival lung" example data
vars.event_vars = c("os_status")

# Uncomment for "Survival lung" example data
vars.time_to_vars = c("os_time")

# Uncomment for "Survival lung" example data
tte_endpoint_prefixes <- c("os_") # columns will be removed from ADSL using -tidyselect::starts_with

# Uncomment for "Survival lung" example data
vars.endpoint_names = c("OS")

# Uncomment for "Survival lung" example data
vars.time_units = c("DAYS")

###############################################################################
# Initial values
###############################################################################

# Uncomment for "Survival lung" example data
vars.initial_arm_var <- "regimen"

# Uncomment for "Survival lung" example data
vars.initial_endpoint <- "OS"

# Initial filter defined according to ?teal::init

# Uncomment for "Survival lung" example data
initial_filter <- teal.slice::teal_slices(
  teal.slice::teal_slice(
    dataname = "ADSL",
    varname = "ph.ecog",
    choices = "levels(adsl$ph.ecog)",
    selected = c("0", "1", "2", "3","<Missing>") #levels(adsl$ph.ecog) but adsl is not yet available here
  )
)

###############################################################################
# Variable categories
###############################################################################

# This section is to define meaningful variable groupings, in order to create a
# more user-friendly experience (influences variable order & initial choices)

# HINT: use e.g.
# absent_vars(vars.top_cols(), cached_cohort())
# to see which variables don't exist in the data

# Uncomment for "Survival lung" example data
vars.patientid <- "patientid"

vars.top_cols <- function(){
    c(
    vars.main_prognostic,
    vars.main_treatment,
    vars.main_met,
    vars.additional_biomarkers,
    vars.additional_treatment,
    vars.additional_met
    ## create additional variable categories as desired
)
}

# Uncomment for "Survival lung" example data
vars.main_prognostic <- c("age", "sex", "ph.ecog", "ph.karno", "pat.karno", "meal.cal", "wt.loss", "inst")

# Uncomment for "Survival lung" example data
vars.main_treatment <- c("regimen")

vars.additional_treatment <- c()

vars.main_met <- c()

vars.additional_met <- c()

vars.additional_biomarkers <- c()

remove_cols_adsl <- c()



