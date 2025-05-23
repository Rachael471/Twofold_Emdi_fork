#' @rdname compare_plot
#' @export
compare_plot.ebp_tf <- function(model = NULL, direct = NULL, level=NULL, indicator = "all",
                             MSE = FALSE, CV = FALSE, label = "orig",
                             color = c("blue", "lightblue3"),
                             shape = c(16, 16), line_type = c(
                               "solid",
                               "solid"
                             ),
                             gg_theme = NULL, ...) {
  compare_plot_check(
    model = model, indicator = indicator, level=level,
    label = label, color = color, shape = shape,
    line_type = line_type, gg_theme = gg_theme
  )

  if (inherits(direct, "fh")) {
    stop(strwrap(prefix = " ", initial = "",
                 paste0("It is not possible to compare the point and MSE
                        estimates of a model of type 'fh', to the point and MSE
                        estimates of an 'ebp' object."
                        )))
  }

  if ((inherits(model, "ebp") && is.null(direct)) |
      (inherits(direct, "ebp") && is.null(model))) {
    stop(strwrap(prefix = " ", initial = "",
                 paste0("If the model is of type 'ebp', the input argument
                        direct is required.")))
  } else if (inherits(model, "ebp") && inherits(direct, "direct")) {
    compare_plot_ebp(
      model = model, direct = direct, indicator = indicator,
      MSE = MSE, CV = CV,
      label = label, color = color, shape = shape,
      line_type = line_type, gg_theme = gg_theme
    )
  }

  if ((inherits(model, "ebp_tf") && is.null(direct)) |
    (inherits(direct, "ebp_tf") && is.null(model))) {
    stop(strwrap(prefix = " ", initial = "",
                 paste0("If the model is of type 'ebp_tf', the input argument
                        direct is required.")))
  } else if (inherits(model, "ebp_tf") && inherits(direct, "direct")) {
    compare_plot_ebp_tf(
      model = model, direct = direct, indicator = indicator,
      MSE = MSE, CV = CV,level = level,
      label = label, color = color, shape = shape,
      line_type = line_type, gg_theme = gg_theme
    )
  }
}


#' Shows plots for the comparison of estimates
#'
#' For all indicators or a selection of indicators two plots are returned. The
#' first plot is a scatter plot of estimates to compare and the second is a line
#' plot with these estimates.
#' @param model an object of type "emdi", either "ebp", "ebp_tf", "fh" or "fh_tf",
#' representing point and MSE estimates.
#' @param direct an object of type "direct", "emdi", representing point
#' and MSE estimates. If the input argument \code{model} is of type "ebp" or
#' "ebp_tf", \code{direct} is required. If the input argument \code{model} is
#' of type "fh", the \code{direct} component is already included in the input
#' argument \code{model}. If the input argument \code{model} is
#' of type "fh_tf" and  the input argument \code{level} is "domain",
#' \code{direct} is required. If the input argument \code{model} is
#' of type "fh_tf" and  the input argument \code{level} is "subdomain",
#' the \code{direct} component is already included in the input argument
#' \code{model}.
#' @param indicator optional character vector that selects which indicators
#' shall be returned: (i) all calculated indicators ("all");
#' (ii) each indicator name: "Mean", "Quantile_10", "Quantile_25", "Median",
#' "Quantile_75", "Quantile_90", "Head_Count",
#' "Poverty_Gap", "Gini", "Quintile_Share" or the function name/s of
#' "custom_indicator/s"; (iii) groups of indicators: "Quantiles", "Poverty",
#' "Inequality" or "Custom". If two of these groups are selected, only the first
#' one is returned. Defaults to "all". Note, additional custom indicators can be
#' defined as argument for model-based approaches (see also \code{\link{ebp}},
#' \code{\link{ebp_tf}}) and do not appear in groups of indicators even though
#' these might belong to one of the groups.
#' @param MSE optional logical. If \code{TRUE}, the MSE estimates of the direct
#' and model-based estimates are compared via suitable plots. Defaults to
#' \code{FALSE}.
#' @param CV optional logical. If \code{TRUE}, the coefficient of variation
#' estimates of the direct and model-based estimates are compared via suitable
#' plots. Defaults to \code{FALSE}.
#' @param level argument is required for "ebp_tf" and "fh_tf". There are two
#' options on which level the results are to be compared: (i) at domain level
#' ("domain") or (ii) at subdomain level ("subdomain"). \code{direct} object
#' must be defined at the corresponding level.
#' @param label argument that enables to customize title and axis labels. There
#' are three options to label the evaluation plots: (i) original labels
#' ("orig"), (ii) axis labels but no title ("no_title"), (iii) neither axis
#' labels nor title ("blank").
#' @param color a vector with two elements determining color schemes in returned
#' plots.
#' @param shape a numeric vector with two elements determining the shape of
#' points in returned plots.
#' @param line_type a character vector with two elements determining the line
#' types in returned plots.
#' @param gg_theme \code{\link[ggplot2]{theme}} list from package \pkg{ggplot2}.
#' For using this argument, package \pkg{ggplot2} must be loaded via
#' \code{library(ggplot2)}.
#' @param ... further arguments passed to or from other methods.
#' @return A scatter plot and a line plot comparing direct and model-based
#' estimators for each selected indicator obtained by
#' \code{\link[ggplot2]{ggplot}}. If the input arguments MSE and CV are set to
#' TRUE two extra plots are created, respectively: the MSE/CV estimates of the
#' direct and model-based estimates are compared by boxplots and scatter plots.
#' @noRd

compare_plot_ebp_tf <- function(model, direct, indicator = "all", MSE = FALSE,
                             CV = FALSE, level=NULL, label = "orig",
                             color = c("blue", "lightblue3"),
                             shape = c(16, 16), line_type = c("solid", "solid"),
                             gg_theme = NULL) {
  Model_based <- NULL
  Direct <- NULL
  ID <- NULL
  value <- NULL
  Method <- NULL

  ind_direct <- point_emdi(object = direct, indicator = indicator)$ind
  selected_direct <- colnames(ind_direct)[-1]
  colnames(ind_direct) <- c(
    "Domain",
    paste0(colnames(ind_direct)[-1], "_Direct")
  )

  #__________________________Rachael____________________________________________
  if (inherits(model, "ebp_tf")) {
    if (!is.null(level) && level == "domain") {
      ind_model <- point_emdi(object = model, indicator = indicator)$ind_Domain
    }else if (!is.null(level) && level == "subdomain") {
      ind_model <- point_emdi(object = model, indicator = indicator)$ind_Subdomain
      #colnames(ind_model$ind)[1] <- "Domain"
    }
  }else{
    ind_model <- point_emdi(object = model, indicator = indicator)$ind
  }
  #_____________________________________________________________________________
  selected_model <- colnames(ind_model)[-1]
  colnames(ind_model) <- c("Domain", paste0(colnames(ind_model)[-1], "_Model"))
  smp_size <- (table(direct$framework$smp_domains_vec))

  compare_plot_check2(ind_direct, ind_model)

  Data <- merge(ind_direct, ind_model, by = "Domain")

  matcher <- match(Data$Domain, names(smp_size))
  Data$smp_size <- as.numeric(smp_size)[matcher]

  if (inherits(model, "ebp_tf")) {
    if (MSE == TRUE || CV == TRUE) {
      precisions_direct <-
        mse_emdi(object = direct, indicator = indicator, CV = TRUE)
      colnames(precisions_direct$ind) <-
        c("Domain", paste0(colnames(precisions_direct$ind)[-1], "_Direct_MSE"))
      colnames(precisions_direct$ind_cv) <-
        c("Domain", paste0(colnames(precisions_direct$ind_cv)[-1], "_Direct_CV"))

      precisions_model <-
        mse_emdi(object = model, indicator = indicator, CV = TRUE)
      colnames(precisions_model$ind_Domain) <-
        c("Domain", paste0(colnames(precisions_model$ind_Domain)[-1], "_Model_MSE"))
      colnames(precisions_model$ind_cv_Domain) <-
        c("Domain", paste0(colnames(precisions_model$ind_cv_Domain)[-1], "_Model_CV"))
      colnames(precisions_model$ind_Subdomain) <-
        c("Domain", paste0(colnames(precisions_model$ind_Subdomain)[-1], "_Model_MSE"))
      colnames(precisions_model$ind_cv_Subdomain) <-
        c("Domain", paste0(colnames(precisions_model$ind_cv_Subdomain)[-1], "_Model_CV"))

      if (MSE == TRUE) {
        if (!is.null(level) && level == "domain") {
          Data <- merge(Data, precisions_direct$ind, id = "Domain")
          Data <- merge(Data, precisions_model$ind_Domain, id = "Domain")
        }else if (!is.null(level) && level == "subdomain") {
          Data <- merge(Data, precisions_direct$ind, id = "Domain")
          Data <- merge(Data, precisions_model$ind_Subdomain, id = "Domain")
        }
      }
      if (CV == TRUE) {
        if (!is.null(level) && level == "domain") {
          Data <- merge(Data, precisions_direct$ind_cv, id = "Domain")
          Data <- merge(Data, precisions_model$ind_cv_Domain, id = "Domain")
          Data$smp_size2 <- Data$smp_size
        }else if (!is.null(level) && level == "subdomain") {
          Data <- merge(Data, precisions_direct$ind_cv, id = "Domain")
          Data <- merge(Data, precisions_model$ind_cv_Subdomain, id = "Domain")
          Data$smp_size2 <- Data$smp_size
        }
      }
    }
  } else {
    if (MSE == TRUE || CV == TRUE) {
      precisions_direct <-
        mse_emdi(object = direct, indicator = indicator, CV = TRUE)
      colnames(precisions_direct$ind) <-
        c("Domain", paste0(colnames(precisions_direct$ind)[-1], "_Direct_MSE"))
      colnames(precisions_direct$ind_cv) <-
        c("Domain", paste0(colnames(precisions_direct$ind_cv)[-1], "_Direct_CV"))

      precisions_model <-
        mse_emdi(object = model, indicator = indicator, CV = TRUE)
      colnames(precisions_model$ind) <-
        c("Domain", paste0(colnames(precisions_model$ind)[-1], "_Model_MSE"))
      colnames(precisions_model$ind_cv) <-
        c("Domain", paste0(colnames(precisions_model$ind_cv)[-1], "_Model_CV"))

      if (MSE == TRUE) {
        Data <- merge(Data, precisions_direct$ind, id = "Domain")
        Data <- merge(Data, precisions_model$ind, id = "Domain")
      }
      if (CV == TRUE) {
        Data <- merge(Data, precisions_direct$ind_cv, id = "Domain")
        Data <- merge(Data, precisions_model$ind_cv, id = "Domain")
        Data$smp_size2 <- Data$smp_size
      }
    }
  }

  selected_indicators <- selected_model[selected_model %in% selected_direct]
  if(level == "subdomain"){
    compare_plots(
      object = Data, type = "tf_sub", level=level,
      selected_indicators = selected_indicators,
      MSE = MSE, CV = CV, label = label, color = color,
      shape = shape, line_type = line_type, gg_theme = gg_theme
    )
  }else if(level == "domain"){
    compare_plots(
      object = Data, type = "unit", level=level,
      selected_indicators = selected_indicators,
      MSE = MSE, CV = CV, label = label, color = color,
      shape = shape, line_type = line_type, gg_theme = gg_theme
    )
  }

}
