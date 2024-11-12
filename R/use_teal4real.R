
#' Install Teal4Real files
#'
#' This function asks the user to choose a directory where to place the R files that make up the Teal4Real shiny app.
#' Take into consideration that in order to publish a Teal4Reall app to an rsconnect server, any R code required to generate
#' the analysis dataset should be either in the same folder as the Teal4Real files, linked into said folder using dynamic links,
#' or accessible via calling exported functions of a data generation package.
#'
#' Of the copied files, those with "user" in the file name have to be configured by the user/programmer creating a Teal4Real app.
#'
#' @param overwrite Should existing Teal4Real app files be overwritten?
#'
#' @export
#'
#' @examples
#' \dontrun{
#' Teal4Real::use_teal4real()
#' }
use_teal4real<- function(overwrite = FALSE){
    target_folder <- "."
    app_folder <- system.file("app_files", package="Teal4Real", mustWork=TRUE)
    if (interactive()){
        tryCatch({
            target_folder <- rstudioapi::selectDirectory(
                path = getwd(),
                caption = "Please choose a folder where to place the Teal4Real shiny app files."
            )
        }, error = function(e) {
        #FIXME this doesn't work, files are written to the current directory
        target_folder <- readline(prompt="Please enter the directory path: ")
        })
    } else {
        stop("Teal4Real::use_teal4real must be called in interactive mode.")
    }

    message(paste0("Copying Teal4Real files into target folder: ", target_folder, "\n"))
    if(overwrite) {message("Overwriting existing Teal4Real files (option overwrite = TRUE)")}

    #copy app files one by one
    app_files <- list.files(app_folder, full.names = F)

    for(i in app_files) {
        target_file <-file.path(target_folder, i)
        source_file <- file.path(app_folder, i)

        if(file.exists(target_file) & !overwrite){
            message(prompt = paste0(
                target_file,
                " already exists & will not be overwritten.\nRemove existing file or use overwrite = TRUE.\n\n")
            )
            file.copy(from=source_file, to=target_file, overwrite = F)
        } else {
            file.copy(from=source_file, to=target_file, overwrite = T)
        }
    }

    invisible()
}
