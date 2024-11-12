

# Very simple lung cancer example dataset from the 'survival' package
get_survival_lung_cancer_data <- function() {

  res <- survival::lung %>%
    dplyr::rename(os_time = time, os_status = status) %>%
    mutate(
      patientid = factor(row_number()),
      regimen = sample(c("Regimen A", "Regimen B"), nrow(.), replace = T),
      sex = factor(sex),
      ph.ecog = factor(ph.ecog),
      os_status = if_else(os_status == 1, 0, 1),
      inst = factor(inst)
    ) %>%
    select(patientid, regimen, everything()) %>%
    as_tibble()

  # Create a more interesting treatment variable 
  # (assume no treatment effect but correlation of prognosis and treatment)
  cox_model <- coxph(Surv(res$os_time, res$os_status) ~ 
    sex + ph.ecog + ph.karno , data = res)

  res <- res %>%
    mutate(
        probA = predict(cox_model, type = "lp", newdata = res) %>%
                    scale() %>%
                    pnorm(), 
        ref_prob = runif(nrow(.)),
        regimen = if_else(probA > ref_prob, 
            "Regimen A", "Regimen B"),
        regimen = factor(regimen)
    ) %>%
    select(-probA, -ref_prob)

  atts <- paste0(
    "<p>This is the place to display a cohort attrition table, detailing how the analysis dataset was obtained from a larger database.</p>",
    "<p>&nbsp;</p>",
    "<p>Instead of I/E criteria we display variable info for this demo dataset, which is based on the lung dataset of the survival R package.</p>",
    "<p>&nbsp;</p>",
    "<p><strong>NCCTG_Lung_Cancer_Data</strong> from the 'survival' R package.</p>",
    "<p>A simulated treatment variable was added to make the demo more interesting.</p>",
    "<p>-----------------------</p>",
    "<p><strong>Variables</strong></p>",
    "<p>---------</p>",
    "<p><strong>patientid</strong>: Patient identifier</p>",
    "<p><strong>inst</strong>: Institution code</p>",
    "<p><strong>os_time</strong>: Time to death or censoring (days)</p>",
    "<p><strong>os_status</strong>: Censoring status 1=censored, 2=dead</p>",
    "<p><strong>age</strong>: Age in years</p>",
    "<p><strong>sex</strong>: Male=1 Female=2</p>",
    "<p><strong>ph.ecog</strong>: ECOG performance score as rated by the physician. 0=asymptomatic, 1= symptomatic but completely ambulatory, 2= in bed <50% of the day, 3= in bed > 50% of the day but not bedbound, 4 = bedbound</p>",
    "<p><strong>ph.karno</strong>: Karnofsky performance score (bad=0-good=100) rated by physician</p>",
    "<p><strong>pat.karno</strong>: Karnofsky performance score as rated by patient</p>",
    "<p><strong>meal.cal</strong>: Calories consumed at meals</p>",
    "<p><strong>wt.loss</strong>: Weight loss in last six months (pounds)</p>"
)

  attributes(res)$attrition_table <- atts

  return(res)
}
