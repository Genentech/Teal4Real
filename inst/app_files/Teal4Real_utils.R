
# Detect variables that are not present in the data
absent_vars <- function(.varnames, df){
    .varnames %>%
        {.varnames[!(. %in% names(df))] }
}

###############################################################################
# Caching of function call's results
###############################################################################

# Hint: to update the cache run `cached_cohort(update = T)`

cached_cohort <- function(update = update_cache){

  if(update){
    message("Clearing cache..")
    app_cache$reset()
  }

  message("Executing (potentially cached) cohort query..")
  return(cohort_query_mem())
}


app_cache <- cachem::cache_disk(
  dir = "./app_cache",
  max_age = Inf,
  max_size = Inf,
  logfile = NULL,
  destroy_on_finalize = FALSE
)

cohort_query_mem <- memoise::memoise(cohort_query, cache = app_cache)

###############################################################################
# Creation of ADaM datasets
###############################################################################

make_label <- function(input_str){
    str_replace_all(input_str, "[.]", "." ) %>%
        str_replace_all( "[_]", " " ) %>%
        tools::toTitleCase()
}

create_adsl <- function(
        .df,
        .top_cols = c(),
        .remove_cols = c(),
        .USUBJID = "USUBJID",
        .STUDYID = "STUDY"
        ){

    adsl <-  .df |>
        rename(USUBJID = .USUBJID) |>
        mutate(STUDYID = .STUDYID) |>
        select(-all_of(.remove_cols)) |>
        select(USUBJID, STUDYID, .top_cols, everything()) |>
        mutate(dummy_endpoints = "dummy_endpoint") %>%
        # Booleans to factors
        mutate(across(where(is.logical), factor)) %>%
        # Integers to factors
        mutate(across(where(is.integer), factor)) %>%
        tern::df_explicit_na()

    #The data is expected to have "label" attributes (derived from column names here).
    names(adsl) %>%
        walk(~{ attributes(adsl[[.x]])$label <<- make_label(.x) })

    return(adsl)
}

create_adtte <- function(
        .df,
        .USUBJID = "USUBJID",
        .STUDYID = "STUDY",
        .event_vars = NULL,
        .time_to_vars,
        .endpoint_names = .time_to_vars,
        .time_units = c("MONTHS")
        ) {

    if(length(.event_vars) != length(.time_to_vars)){
        stop("Endpoint variable lengths are inconsistent")
    }

    tmp_wide <- .df %>%
        rename(
            USUBJID = .USUBJID
        ) %>%
        mutate(
            STUDYID = .STUDYID
        ) %>%
        select(
            USUBJID,
            STUDYID,
            all_of(
                c(
                    .event_vars,
                    #.censor_vars,
                    .time_to_vars
                    )
                )
            )

    adtte_times <- tmp_wide |>
        select(-all_of(.event_vars)) %>%
        rename_at(vars(.time_to_vars), ~.endpoint_names) %>%
        pivot_longer(
            cols = all_of(.endpoint_names),
            names_to = "PARAMCD",
            values_to = "AVAL"
        )

    adtte_cnsr <- tmp_wide |>
        select(-all_of(.time_to_vars)) %>%
        rename_at(vars(.event_vars), ~.endpoint_names) %>%
        pivot_longer(
            cols = all_of(.endpoint_names),
            names_to = "PARAMCD",
            values_to = "CNSR"
        ) %>%
        mutate(
            CNSR = 1 - CNSR #it was an event
        )

    adtte <- adtte_times %>%
        left_join(
            adtte_cnsr,
            by = c("USUBJID", "STUDYID",  "PARAMCD")
        ) %>%
        mutate(AVALU = vars.time_units ) %>% #"MONTHS"
      mutate(USUBJID = factor(USUBJID))

    #The data is expected to have "label" attributes (derived from column names here)
    names(adtte) %>%
        walk(~{ attributes(adtte[[.x]])$label <<- make_label(.x) })

    return(adtte)
}
