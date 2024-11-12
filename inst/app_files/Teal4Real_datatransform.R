


# Convert the input data to ADaM format
###########################################################


adsl <- create_adsl(
    .df = cached_cohort(update = update_cache) %>%
        select(-starts_with(tte_endpoint_prefixes)),
    .top_cols = vars.top_cols(),
    .remove_cols = remove_cols_adsl,
    .USUBJID = vars.patientid,
    .STUDYID =  as.factor(study_name)
)


adtte <- create_adtte(
    .df = cached_cohort(update = update_cache) ,
    .USUBJID = vars.patientid,
    .STUDYID =  as.factor(study_name),
    .event_vars = vars.event_vars,
    .time_to_vars = vars.time_to_vars,
    .endpoint_names = vars.endpoint_names,
    .time_units = vars.time_units
)



#Create an ADTTE dataset with covariates (needed by Cox reg module)
adtte <- adtte %>%
    left_join(adsl, by = c("USUBJID", "STUDYID"))




# Data-derived variable groups
###########################################################

vars.all <- setdiff(names(adsl), c("USUBJID", study_name))
vars.all_factors <- names(which(sapply(adsl[, vars.all], is.factor)))
