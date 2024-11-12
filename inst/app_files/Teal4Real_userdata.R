
###############################################################################
###############################################################################
#
# Dataset generation
#
###############################################################################
###############################################################################

###############################################################################
# Sourcing of dependencies for data generation
###############################################################################

library(survival)

source("Teal4Real_example_datasets.R")

# Hint: Install packages from git using a personal access token - this way
# the rsconnect server will know where to get the package upon publishing
# e.g.  devtools::install_github("RWDScodeshare/realworldPFS", host = "github.roche.com/api/v3", auth_token = "<your personal access token>")

###############################################################################
# Define the data-generating function (results will be cached)
###############################################################################

# Hint: to update the cache run `cached_cohort(update = T)`

cohort_query <- function(){ 
  # Uncomment the demo dataset's code or add your own function here

  # Example dataset "Survival lung" (lung cancer data from the 'survival' R package)
  get_survival_lung_cancer_data()
}
