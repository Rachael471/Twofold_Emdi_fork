#' Visualizes regional disaggregated estimates on a map
#'
#' Function \code{map_plot} creates spatial visualizations of the estimates
#' obtained by small area estimation methods.
#'
#' @param object an object of type emdi, containing the estimates to be
#' visualized.
#' @param indicator optional character vector that selects which indicators
#' shall be returned: (i) all calculated indicators ("all");
#' (ii) each indicator name: "Mean", "Quantile_10", "Quantile_25", "Median",
#' "Quantile_75", "Quantile_90", "Head_Count", "Poverty_Gap", "Gini",
#' "Quintile_Share" or the function name/s of "custom_indicator/s";
#' (iii) groups of indicators: "Quantiles", "Poverty" or
#' "Inequality". Note, additional custom indicators can be
#' defined as argument for model-based approaches (see also \code{\link{ebp}} or
#' \code{\link{ebp_tf}}) and do not appear in groups of indicators even though
#' these might belong to one of the groups. If the \code{model} argument is of
#' type "fh", indicator can be set to "all", "Direct", FH", or "FH_Bench"
#' (if emdi object is overwritten by function benchmark). Defaults to "all".
#' If the \code{model} argument is of type "fh_tf" and the \code{level} is
#' "subdomain", indicator can be set to "all", "Direct" or "FH_TF". If the
#' \code{model} argument is of type "fh_tf" and the \code{level} is "domain",
#' indicator can be set to "all" or "FH_TF".
#' @param MSE optional logical. If \code{TRUE}, the MSE is also visualized.
#' Defaults to \code{FALSE}.
#' @param CV optional logical. If \code{TRUE}, the CV is also visualized.
#' Defaults to \code{FALSE}.
#' @param level argument is required for "ebp_tf" and "fh_tf". There are two
#' options on which level the results are to be plotted: (i) at domain level
#' ("domain") or (ii) at subdomain level ("subdomain"). \code{map_obj} object
#' must be specified at the corresponding level.
#' @param map_obj an \code{"sf", "data.frame"} object as defined by the
#' \pkg{sf} package on which the data should be visualized.
#' @param map_dom_id a character string containing the name of a variable in
#' \code{map_obj} that indicates the domains/subdomains.
#' @param map_tab a \code{data.frame} object with two columns that match the
#' domain/subdomain variable from the census data set (first column) with the
#' domain/subdomain variable in the map_obj (second column). This should only be
#' used if the IDs in both objects differ.
#' @param color a \code{vector} of length 2 defining the lowest and highest
#' color in the plots.
#' @param scale_points a structure defining the lowest and the highest
#' value of the colorscale. If a numeric vector of length two is given, this
#' scale will be used for every plot.
#' @param guide character passed to
#' \code{scale_colour_gradient} from \pkg{ggplot2}.
#' Possible values are "none", "colourbar", and "legend".
#' @param return_data if set to \code{TRUE}, a fortified data frame including
#' the map data as well as the chosen indicators is returned. Customized maps
#' can easily be obtained from this data frame via the package \pkg{ggplot2}.
#' Defaults to \code{FALSE}.
#' @return Creates the plots demanded, and, if selected, a fortified data.frame
#' containing the mapdata and chosen indicators.
#' @seealso \code{\link{direct}}, \code{\link{ebp}},
#' \code{\link{ebp_tf}}, \code{\link{fh}}, \code{\link{fh_tf}},
#' \code{\link{emdiObject}}, \code{\link[sf]{sf}}
#' @examples
#' \donttest{
#' data("eusilcA_pop")
#' data("eusilcA_smp")
#'
#' # Generate emdi object with additional indicators; here via function ebp()
#' emdi_model <- ebp(
#'   fixed = eqIncome ~ gender + eqsize + cash +
#'     self_empl + unempl_ben + age_ben + surv_ben + sick_ben +
#'     dis_ben + rent + fam_allow + house_allow + cap_inv +
#'     tax_adj, pop_data = eusilcA_pop,
#'   pop_domains = "district", smp_data = eusilcA_smp,
#'   smp_domains = "district", threshold = 11064.82,
#'   transformation = "box.cox", L = 50, MSE = TRUE, B = 50
#' )
#'
#' # Load shape file
#' load_shapeaustria()
#'
#' # Create map plot for mean indicator - point and MSE estimates but no CV
#' map_plot(
#'   object = emdi_model, MSE = TRUE, CV = FALSE,
#'   map_obj = shape_austria_dis, indicator = c("Mean"),
#'   map_dom_id = "PB"
#' )
#'
#' # Create a suitable mapping table to use numerical identifiers of the shape
#' # file
#'
#' # First find the right order
#' dom_ord <- match(shape_austria_dis$PB, emdi_model$ind$Domain)
#'
#' #Create the mapping table based on the order obtained above
#' map_tab <- data.frame(pop_data_id = emdi_model$ind$Domain[dom_ord],
#'                       shape_id = shape_austria_dis$BKZ)
#'
#' # Create map plot for mean indicator - point and CV estimates but no MSE
#' # using the numerical domain identifiers of the shape file
#'
#' map_plot(
#'   object = emdi_model, MSE = FALSE, CV = TRUE,
#'   map_obj = shape_austria_dis, indicator = c("Mean"),
#'   map_dom_id = "BKZ", map_tab = map_tab
#' )
#' }
#' @export
#' @importFrom reshape2 melt
#' @importFrom ggplot2 aes geom_polygon geom_sf facet_wrap coord_equal labs
#' @importFrom ggplot2 theme element_blank scale_fill_gradient ggplot ggtitle
#' @importFrom rlang .data

map_plot <- function(object,
                     indicator = "all",
                     MSE = FALSE,
                     CV = FALSE,
                     level = NULL,
                     map_obj = NULL,
                     map_dom_id = NULL,
                     map_tab = NULL,
                     color = c("white", "red4"),
                     scale_points = NULL,
                     guide = "colourbar",
                     return_data = FALSE
) {

  if (is.null(map_obj)) {

    message("No Map Object has been provided. An artificial polygone is used for
             visualization")

    map_pseudo(object    = object,
               indicator = indicator,
               panelplot = FALSE,
               MSE       = MSE,
               CV        = CV,
               level      =level
    )
  } else if (!inherits(map_obj, "sf")) {

    stop("map_obj is not of class sf from the sf package")

  } else {

    if (length(color) != 2 || !is.vector(color)) {
      stop(paste("col needs to be a vector of length 2 defining the starting,",
                 "mid and upper color of the map-plot"))
    }

    plot_real(object       = object,
              indicator    = indicator,
              MSE          = MSE,
              CV           = CV,
              map_obj      = map_obj,
              map_dom_id   = map_dom_id,
              map_tab      = map_tab,
              col          = color,
              scale_points = scale_points,
              return_data  = return_data,
              guide        = guide,
              level        = level
    )
  }
}

map_pseudo <- function(object, indicator, panelplot, MSE, CV, level) {

  x <- y <- id <- value <- NULL

  values <-  estimators(object    = object,
                        indicator = indicator,
                        MSE       = MSE,
                        CV        = CV,
                        level     =level
  )$ind

  indicator <- colnames(values)[-1]

  tplot <- get_polygone(values = values)

  if (panelplot) {
    ggplot(tplot, aes(x = x, y = y)) +
      geom_polygon(aes(
        group = id,
        fill = value
      )) +
      facet_wrap(~variable,
                 ncol = ceiling(sqrt(length(unique(tplot$variable))))
      )
  } else {
    for (ind in indicator) {
      print(print(ggplot(tplot[tplot$variable == ind, ], aes(x = x, y = y)) +
        ggtitle(paste0(ind)) +
        geom_polygon(aes(
          group = id,
          fill = value
        ))))
      cat("Press [enter] to continue")
      line <- readline()
    }
  }
}

plot_real <- function(object,
                      indicator = "all",
                      MSE = FALSE,
                      CV = FALSE,
                      map_obj = NULL,
                      map_dom_id = NULL,
                      map_tab = NULL,
                      col = col,
                      scale_points = NULL,
                      return_data = FALSE,
                      guide = NULL,
                      level = NULL) {


  if (!is.null(map_obj) && is.null(map_dom_id)) {
    stop("No Domain ID for the map object is given")
  }

  long <- lat <- group <- NULL

  if (any(inherits(object, which = TRUE, c("ebp_tf", "fh_tf")))) {
    map_data <- estimators(object    = object,
                           indicator = indicator,
                           MSE       = MSE,
                           CV        = CV,
                           level     = level
    )$ind
    if (!is.null(level) && level =="domain"){
      if (!is.null(map_tab)) {
        map_data <- merge(x    = map_data,
                          y    = map_tab,
                          by.x = "Domain",
                          by.y = names(map_tab)[1]
        )
        matcher <- match(map_obj[[map_dom_id]],
                         map_data[, names(map_tab)[2]])

        if (any(is.na(matcher))) {
          if (all(is.na(matcher))) {
            stop("Domains of map_tab and Map object do not match. Check map_tab")
          } else {
            warnings(paste("Not all Domains of map_tab and Map object could be",
                           "matched. Check map_tab"))
          }
        }

        map_data <- map_data[matcher, ]
        map_data <- map_data[, !colnames(map_data) %in%
                               c("Domain", map_dom_id), drop = F]
        map_data$Domain <- map_data[, colnames(map_data) %in% names(map_tab)]
      } else {
        matcher <- match(map_obj[[map_dom_id]], map_data[, "Domain"])

        if (any(is.na(matcher))) {
          if (all(is.na(matcher))) {
            stop(paste("Domain of emdi object and Map object do not match.",
                       "Try using map_tab"))
          } else {
            warnings(paste("Not all Domains of emdi object and Map object",
                           "could be matched. Try using map_tab"))
          }
        }
        map_data <- map_data[matcher, ]
      }
    }else if (!is.null(level) && level == "subdomain"){
      if (!is.null(map_tab)) {
        map_data <- merge(x    = map_data,
                          y    = map_tab,
                          by.x = "Subdomain",
                          by.y = names(map_tab)[1]
        )
        matcher <- match(map_obj[[map_dom_id]],
                         map_data[, names(map_tab)[2]])

        if (any(is.na(matcher))) {
          if (all(is.na(matcher))) {
            stop("Domains of map_tab and Map object do not match. Check map_tab")
          } else {
            warnings(paste("Not all Domains of map_tab and Map object could be",
                           "matched. Check map_tab"))
          }
        }

        map_data <- map_data[matcher, ]
        map_data <- map_data[, !colnames(map_data) %in%
                               c("Subdomain", map_dom_id), drop = F]
        map_data$Domain <- map_data[, colnames(map_data) %in% names(map_tab)]
      } else {
        matcher <- match(map_obj[[map_dom_id]], map_data[, "Subdomain"])

        if (any(is.na(matcher))) {
          if (all(is.na(matcher))) {
            stop(paste("Domain of emdi object and Map object do not match.",
                       "Try using map_tab"))
          } else {
            warnings(paste("Not all Domains of emdi object and Map object",
                           "could be matched. Try using map_tab"))
          }
        }
        map_data <- map_data[matcher, ]
      }
    }

  }else{
    map_data <- estimators(object    = object,
                           indicator = indicator,
                           MSE       = MSE,
                           CV        = CV
    )$ind

    if (!is.null(map_tab)) {
      map_data <- merge(x    = map_data,
                        y    = map_tab,
                        by.x = "Domain",
                        by.y = names(map_tab)[1]
      )
      matcher <- match(map_obj[[map_dom_id]],
                       map_data[, names(map_tab)[2]])

      if (any(is.na(matcher))) {
        if (all(is.na(matcher))) {
          stop("Domains of map_tab and Map object do not match. Check map_tab")
        } else {
          warnings(paste("Not all Domains of map_tab and Map object could be",
                         "matched. Check map_tab"))
        }
      }

      map_data <- map_data[matcher, ]
      map_data <- map_data[, !colnames(map_data) %in%
                             c("Domain", map_dom_id), drop = F]
      map_data$Domain <- map_data[, colnames(map_data) %in% names(map_tab)]
    } else {
      matcher <- match(map_obj[[map_dom_id]], map_data[, "Domain"])

      if (any(is.na(matcher))) {
        if (all(is.na(matcher))) {
          stop(paste("Domain of emdi object and Map object do not match.",
                     "Try using map_tab"))
        } else {
          warnings(paste("Not all Domains of emdi object and Map object",
                         "could be matched. Try using map_tab"))
        }
      }
      map_data <- map_data[matcher, ]
    }
  }

  if (any(inherits(object, which = TRUE, c("ebp_tf", "fh_tf")))) {
    if(!is.null(level) && level=="domain") {
      map_obj.merged <- merge(map_obj, map_data, by.x = map_dom_id, by.y = "Domain")
      indicator <- colnames(map_data)
      indicator <- indicator[!(indicator %in% c("Domain", "shape_id", colnames(map_tab)))]
    }else if (!is.null(level) && level == "subdomain"){
      map_obj.merged <- merge(map_obj, map_data, by.x = map_dom_id, by.y = "Subdomain")
      indicator <- colnames(map_data)
      indicator <- indicator[!(indicator %in% c("Subdomain", "shape_id"))]
    }
  }else{
    map_obj.merged <- merge(map_obj, map_data, by.x = map_dom_id, by.y = "Domain")
    indicator <- colnames(map_data)
    indicator <- indicator[!(indicator %in% c("Domain", "shape_id", colnames(map_tab)))]
    }



  for (ind in indicator) {

    map_obj.merged[[ind]][!is.finite(map_obj.merged[[ind]])] <- NA

    scale_point <- get_scale_points(y            = map_obj.merged[[ind]],
                                    ind          = ind,
                                    scale_points = scale_points
    )

    print(ggplot(data = map_obj.merged,
                 aes(long, lat, group = group, fill = .data[[ind]])) +
            geom_sf(color = "azure3") +
            labs(x = "", y = "", fill = ind) +
            ggtitle(gsub(pattern = "_", replacement = " ", x = ind)) +
            scale_fill_gradient(low    = col[1],
                                high   = col[2],
                                limits = scale_point,
                                guide  = guide
            ) +
            theme(axis.ticks   = element_blank(),
                  axis.text    = element_blank(),
                  legend.title = element_blank()
            )
    )

    if (!ind == tail(indicator, 1)) {
      cat("Press [enter] to continue")
      line <- readline()
    }
  }
  if (return_data) {
    return(map_obj.merged)
  }
}

get_polygone <- function(values) {

  if (is.null(dim(values))) {
    values <- as.data.frame(values)
  }

  n <- nrow(values)
  cols <- ceiling(sqrt(n))
  n <- cols^2

  values["id"] <- seq_len(nrow(values))

  poly <- data.frame(id       = rep(seq_len(n), each = 4),
                     ordering = seq_len((n * 4)),
                     x        = c(0, 1, 1, 0) +
                       rep(0:(cols - 1), each = (cols * 4)),
                     y        = rep(c(0, 0, 1, 1) +
                                      rep(0:(cols - 1), each = 4), cols)
  )

  combo <- merge(poly, values, by = "id", all = TRUE, sort = FALSE)

  melt(data    = combo[order(combo$ordering), ],
       id.vars = c("id", "x", "y", "ordering")
  )
}

get_scale_points <- function(y, ind, scale_points) {

  result <- NULL

  if (!is.null(scale_points)) {
    if (inherits(scale_points, "numeric") && length(scale_points) == 2) {
      result <- scale_points
    }
  }
  if (is.null(result)) {
    rg <- range(y, na.rm = TRUE)
    result <- rg
  }
  return(result)
}