###############################################################################
###############################################################################
# Teal4Real
#
# A reporting tool based on shiny & teal.modules.clinical
#
# Convert any one-row-per-patient dataset to ADaM format & analyse it
###############################################################################
###############################################################################

# Teal is a reporting tool for clinical trial data in ADaM format
# https://insightsengineering.github.io/teal/

# Teal4Real allows for teal to be used for real-world data by providing tools
# to transform one-row-per-patient datasets into a format similar to ADaM,
# such that Teal understands it..

###############################################################################
# Usage
###############################################################################

# => To run Teal4Real on a demo dataset, simply open this file &
#    press "Run App" (top right in Rstudio)
# => To adapt it to your own dataset, edit the files with "user" in the name:
#       - Teal4Real_userconfig.R
#       - Teal4Real_userdata.R

###############################################################################
# Installing packages required for Teal4Real
###############################################################################

# Hint: Installing dependencies from source may take ~20 minutes in the worst case.

# Hint: for deployment to an rsconnect server it is necessary the
# repos below are defined in the global environment

# Only run the following code locally (NOT on an rsconnect server)
if (Sys.getenv("SHINY_PORT") == "") {

  #get BiocManager if not present
  if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")


  # Define order of repositories
  r <- c(

    # Comment out "develop" if you wish only stable versions (recommended)
    # Do NOT comment out "stable" (some packages have only stable versions)
    #NEST_develop = "https://pharmaverse.r-universe.dev", #get the latest bug fixes
    NEST_stable = "https://insightsengineering.r-universe.dev",

    ROCHE = options()$repos, # Roche internal CRAN or NULL

    CRAN = "https://cran.r-project.org"
  )
  bioc_repos <- BiocManager::repositories()
  r <- append(r, bioc_repos[grepl("BioC", names(bioc_repos))])
  options(repos = r)

  # Define required packages (in reverse order of dependency)
  pkgs <- c(
    "formatters",
    "rtables",
    "mmrm",
    "polyclip",
    "nestcolor",
    "tern",
    "tern.gee",
    "tern.mmrm",
    "teal.code",
    "teal.data",
    "teal.slice",
    "teal.transform",
    "teal.logger",
    "teal.reporter",
    "teal.widgets",
    "teal",
    "teal.modules.clinical"
  )

  # Install/upgrade only packages which have newer versions on the repo

  # Hint: to install all packages simply run
  # install.packages(pkgs)
  # ..though this might take a while

  # Get information about available packages
  repos <- options()$repos
  pkg_info <- available.packages(repos = repos)

  # Check which local packages must be upgraded/reinstalled

  # Hint: be aware that "local" packages may be loaded from any
  # of the libraries returned by `.libPaths()`.
  # Uninstalling older versions that may mask the latest one
  # can sometimes help avoid the need for new installation.

  # Find packages with more advanced versions on the repos
  upgrade_pkgs <- character()
  for (pkg in pkgs) {
    if (pkg %in% rownames(pkg_info)) {
      local_ver <- 0
      repo_ver <- 0
      cat(paste("\n\n\nPackage name :", pkg))

      tryCatch({
        local_ver <- packageVersion(pkg, lib.loc=.libPaths())
        cat(paste("\nLocal version: ", local_ver))
      },
      error = function(e){
        cat("\nPackage not present locally\b")
      }
      )
      tryCatch({
        repo_ver <- pkg_info[pkg, "Version"]
        cat(paste("\nRepo version: ", repo_ver))
      },
      error = function(e){
        cat("Package not present in repos\n")
      }
      )

      if (local_ver < repo_ver) {
        upgrade_pkgs <- c(upgrade_pkgs, pkg)
      }
    } else {
      message(paste("\n\nPackage ", pkg, " not found in repos"))
    }
  }

  # Update packages
  if (length(upgrade_pkgs) > 0) {
    message("\nThe following packages have a version that lags behind the one in the repository:")
    print(upgrade_pkgs)
    message("\nThis may cause problems during app deployment.")

    if(readline("Do you want to update them? (Y/N)  ") %in% c("Y", "Yes", "y")){
      install.packages(upgrade_pkgs, repos = repos)
    } else {
      message("\nNot updating..")
    }
  } else {
    message("\nAll available packages are up to date.")
  }

  # Note: if having installation problems, uninstall all packages & start over
  # remove.packages(pkgs)
}

###############################################################################
# Load packages
###############################################################################


library(tidyverse)
library(magrittr)
library(lubridate)
library(glue)
library(rlang)
library(cachem)
library(memoise)
library(teal.modules.clinical)
library(tern)


theme_set(theme_bw())
library(nestcolor)



# Sourcing Teal4Real dependencies
###########################################################
source("Teal4Real_userconfig.R") # Edit to configure app
source("Teal4Real_userdata.R")   # Edit to supply data generating function
source("Teal4Real_utils.R")


# Test if all user-defined variables exist in the dataset
missing_vars <- absent_vars(vars.top_cols(), cached_cohort())
if(length(missing_vars) != 0) {
    stop(paste0("The following variables are missing in the data: \n", paste0(missing_vars, collapse = "\n")))
}

source("Teal4Real_datatransform.R")


###############################################################################
# Define the Teal4Real app
###############################################################################


app <- init(
    title = app_title,
    header = tags$p(app_title),
    footer = tags$p(
        paste("Please contact ", app_maintainer_email, " in case of questions or problems.")
    ),
    data = cdisc_data(ADSL = adsl, ADTTE = adtte),
    filter = initial_filter,
    modules = modules(
        module(
            label = "Cohort attrition",
            ui = function(id) {
                ns <- NS(id)
                if (is.null(attributes(adsl)$attrition_table)) {
                    attributes(adsl)$attrition_table <- tibble(
                        Notice = paste0(
                            "Please add an attrition_table attribute ",
                            "to your dataset, to be displayed here"
                        )
                    )
                }

                attrition_table <- attributes(adsl)$attrition_table

                if (is.data.frame(attrition_table)) {
                    renderFunc <- renderTable
                    outputType <- tableOutput
                    content <- attrition_table
                } else if (is.character(attrition_table)) {
                    renderFunc <- renderUI
                    outputType <- uiOutput
                    content <- HTML(attrition_table)
                } else {
                    stop("Unsupported attribute type")
                }

                tagList(
                    tags$b("Inclusion- & Exclusion criteria:\n\n\n\n"),
                    outputType(ns("attrition_content"))
                )
            },
            server = function(input, output, session) {
                ns <- session$ns
                attrition_table <- attributes(adsl)$attrition_table

                if (is.data.frame(attrition_table)) {
                    renderFunc <- renderTable
                    content <- attrition_table
                } else if (is.character(attrition_table)) {
                    renderFunc <- renderUI
                    content <- HTML(attrition_table)
                } else {
                    stop("Unsupported attribute type")
                }

                output$attrition_content <- renderFunc(content)
            }
        ),


        # Baseline characteristics
        tm_t_summary(
            label = "Baseline characteristics",
            dataname = "ADSL",
            arm_var = choices_selected(
                variable_choices(adsl, vars.all_factors),
                vars.initial_arm_var
            ),
            summarize_vars = choices_selected(
                variable_choices(adsl, vars.all[!(vars.all %in% c("STUDYID", "dummy_endpoints"))]),
                vars.main_prognostic
            ),
            add_total = FALSE,
            useNA = "ifany",
            na_level = "<Missing>",
            numeric_stats = c(
                "mean_sd",
                "median",
                "range"
            ),
            denominator = "N"
        ),

        # Kaplan Meier
        tm_g_km(
            label = "Kaplan-Meier Plot",
            plot_width = c(1200L, 400L, 5000L),
            plot_height = c(1200L, 400L, 5000L),
            dataname = "ADTTE",
            arm_var = choices_selected(
                variable_choices(adsl, vars.all_factors[!(vars.all_factors %in% c("STUDYID", "dummy_endpoints"))]),
                vars.initial_arm_var
            ),
            paramcd = choices_selected(
                value_choices(adtte, "PARAMCD", "PARAMCD"),
                vars.initial_endpoint
            ),
            strata_var = choices_selected(
                variable_choices(adsl, vars.all_factors[!(vars.all_factors %in% c("STUDYID", "dummy_endpoints"))]),
                NULL
            ),
            facet_var = choices_selected(
                variable_choices(adsl, vars.all_factors[!(vars.all_factors %in% c("STUDYID", "dummy_endpoints"))]),
                NULL
            )
        ),

        # Cox regression
        tm_t_coxreg(
            label = "Cox regression",
            dataname = "ADTTE",
            arm_var = choices_selected(
                variable_choices(
                    adtte %>% select(-PARAMCD, -AVAL, -CNSR, -AVALU, -USUBJID, -STUDYID, -dummy_endpoints)
                ),
                vars.initial_arm_var
            ),
            paramcd = choices_selected(
                value_choices(adtte, "PARAMCD", "PARAMCD"),
                vars.initial_endpoint
            ),
            cov_var = choices_selected(
                variable_choices(
                    adtte %>% select(-PARAMCD, -AVAL, -CNSR, -AVALU, -USUBJID, -STUDYID, -dummy_endpoints)
                ),
                NULL
            ),
            strata_var = choices_selected(
                variable_choices(
                    adtte %>% select(-PARAMCD, -AVAL, -CNSR, -AVALU, -USUBJID, -STUDYID, -dummy_endpoints)
                ),
                NULL
            ),
            multivariate = TRUE
        ),
        # Barchart
        tm_g_barchart_simple(
            x = data_extract_spec(
                dataname = "ADSL",
                select = select_spec(
                    choices = variable_choices(
                        adsl %>% select(-USUBJID, -STUDYID, -dummy_endpoints)
                    ),
                    selected = vars.initial_arm_var,
                    multiple = FALSE
                )
            ),
            fill = data_extract_spec(
                dataname = "ADSL",
                select = select_spec(
                    choices = variable_choices(
                        adsl %>% select(-USUBJID, -STUDYID, -dummy_endpoints)
                    ),
                    selected = NULL,
                    multiple = FALSE
                )
            ),
            x_facet = data_extract_spec(
                dataname = "ADSL",
                select = select_spec(
                    choices = variable_choices(
                        adsl %>% select(-USUBJID, -STUDYID, -dummy_endpoints)
                    ),
                    selected = NULL,
                    multiple = FALSE
                )
            ),
            y_facet = data_extract_spec(
                dataname = "ADSL",
                select = select_spec(
                    choices = variable_choices(
                        adsl %>% select(-USUBJID, -STUDYID, -dummy_endpoints)
                    ),
                    selected = NULL,
                    multiple = FALSE
                )
            ),
            label = "Count Barchart",
            plot_options = NULL,
            plot_height = c(600L, 200L, 2000L),
            plot_width = NULL,
            pre_output = NULL,
            post_output = NULL,
            ggplot2_args = teal.widgets::ggplot2_args()
        ),
        # Logistic regression
        tm_t_logistic(
            label = "Logistic Regression",
            dataname = "ADSL",
            arm_var = choices_selected(
                variable_choices(adsl, vars.all_factors),
                vars.initial_arm_var
            ),
            paramcd = choices_selected(
                value_choices(adsl, "dummy_endpoints"),
                "dummy_endpoint"
            ),
            cov_var = choices_selected(
                variable_choices(adsl, vars.all[!(vars.all %in% c("STUDYID", "dummy_endpoints"))]),
                vars.main_prognostic[1]
            ),
            avalc_var = choices_selected(
                variable_choices(
                    adsl,
                    vars.all_factors[!(vars.all_factors %in% c("STUDYID", "dummy_endpoints"))]
                ),
                vars.all_factors[!(vars.all_factors %in% c("STUDYID", "dummy_endpoints"))][1]
            )
        )
    )
)

if(interactive()){
    app <-  shinyApp(ui = app$ui, server = app$server)
    shiny::runApp(app)
}

