# Internal documentation -------------------------------------------------------

# The function notation defines the notational framework for the EBP twofold
# approach  e.g. number of households in population or sample (per domain),
# distinction between in-sample and out-of-sample
# see Molina and Rao (2003) p.370-371


framework_ebp_tf <- function(fixed, pop_data, pop_domains, pop_subdomains,
                             smp_data, smp_domains, smp_subdomains,
                             threshold, custom_indicator = NULL, na.rm,
                             pop_weights) {

  # Reduction of number of variables
  mod_vars <- all.vars(fixed)
  mod_vars <- mod_vars[mod_vars != as.character(fixed[2])]
  smp_vars <- c(as.character(fixed[2]), mod_vars, smp_domains, smp_subdomains)
  pop_vars <- c(mod_vars, pop_domains, pop_subdomains, pop_weights)
  smp_data <- smp_data[, smp_vars]
  weights <- weights
  pop_weights <- pop_weights
  fw_tf_check1(
    pop_data = pop_data, mod_vars = mod_vars, pop_domains = pop_domains,
    pop_subdomains = pop_subdomains,  smp_data = smp_data,
    fixed = fixed, smp_domains = smp_domains, smp_subdomains = smp_subdomains,
    threshold = threshold, pop_weights = pop_weights
  )

  pop_data <- pop_data[, pop_vars]

  # Deletion of NA
  if (na.rm == TRUE) {
    pop_data <- na.omit(pop_data)
    smp_data <- na.omit(smp_data)
  } else if (any(is.na(pop_data)) || any(is.na(smp_data))) {
    stop(strwrap(prefix = " ", initial = "",
                 "EBP does not work with missing values. Set na.rm = TRUE in
                 function ebp."))
  }


  pop_data[[pop_subdomains]] <- as.character(pop_data[[pop_subdomains]])
  pop_data[[pop_domains]] <- as.character(pop_data[[pop_domains]])
  smp_data[[smp_subdomains]] <- as.character(smp_data[[smp_subdomains]])
  smp_data[[smp_domains]] <- as.character(smp_data[[smp_domains]])


  # Order of domains
  pop_data <- pop_data[order(pop_data[[pop_domains]],
                             pop_data[[pop_subdomains]]),]

  levels_tmp <- unique(pop_data[[pop_domains]])
  pop_data[[pop_domains]] <- factor(pop_data[[pop_domains]],
                                    levels = levels_tmp)
  pop_domains_vec <- pop_data[[pop_domains]]

  smp_data[[smp_domains]] <- factor(smp_data[[smp_domains]],
                                    levels = levels_tmp)

  rm(levels_tmp)

  smp_data <- smp_data[order(smp_data[[smp_domains]],
                             smp_data[[smp_subdomains]]),]


  smp_domains_vec <- smp_data[[smp_domains]]
  smp_domains_vec <- droplevels(smp_domains_vec)

  levels_subdom_tmp <- unique(pop_data[[pop_subdomains]])
  pop_data[[pop_subdomains]] <- factor(pop_data[[pop_subdomains]],
                                       levels = levels_subdom_tmp)

  pop_subdomains_vec <- pop_data[[pop_subdomains]]
  smp_data[[smp_subdomains]] <- factor(smp_data[[smp_subdomains]],
                                       levels = levels_subdom_tmp)
  rm(levels_subdom_tmp)

  smp_subdomains_vec <- smp_data[[smp_subdomains]]
  smp_subdomains_vec <- droplevels(smp_subdomains_vec)
  #_____________________________________________________________________________


  fw_tf_check2(
    pop_domains = pop_domains, pop_subdomains = pop_subdomains,
    pop_domains_vec = pop_domains_vec, pop_subdomains_vec = pop_subdomains_vec,
    smp_domains = smp_domains, smp_subdomains = smp_subdomains,
    smp_domains_vec = smp_domains_vec, smp_subdomains_vec = smp_subdomains_vec
  )


  # Number of households in population per domain
  N_pop <- length(pop_domains_vec)
  # Number of households in sample per domain
  N_smp <- length(smp_domains_vec)
  # Number of households in population per subdomain
  Ndt_pop <- length(pop_subdomains_vec)
  # Number of households in sample per subdomain
  Ndt_smp <- length(smp_subdomains_vec)
  # Number of out-of-sample households
  N_unobs <- N_pop - N_smp
  # Number of domains in the population
  N_dom_pop <- length(unique(pop_domains_vec))
  # Number of domains in the population on aggregated level
  #N_dom_pop_agg <- length(unique(aggregate_to_vec))
  # Number of domains in the sample
  N_dom_smp <- length(unique(smp_domains_vec))
  # Number of out-of-sample domains
  N_dom_unobs <- N_dom_pop - N_dom_smp
  # Number of households in population per domain
  n_pop <- as.vector(table(pop_domains_vec))
  # Number of households in sample per domain
  smp_domains_vec_tmp <- as.numeric(smp_domains_vec)
  n_smp <- as.vector(table(smp_domains_vec_tmp))

  # Indicator variables that indicate if domain is in- or out-of-sample
  obs_dom <- pop_domains_vec %in% unique(smp_domains_vec)
  dist_obs_dom <- unique(pop_domains_vec) %in% unique(smp_domains_vec)

  subdom_names <- names(table(smp_subdomains_vec))
  dom_names <- names(table(smp_domains_vec))

  # Number of subdomains in the population
  N_subdom_pop <- length(unique(pop_subdomains_vec))
  # Number of subdomains in the sample
  N_subdom_smp <- length(unique(smp_subdomains_vec))
  # Number of out-of-sample subdomains
  N_subdom_unobs <- N_subdom_pop - N_subdom_smp
  # Number of households in population per subdomain
  ndt_pop <- as.vector(table(pop_subdomains_vec))
  # Number of households in sample per subdomain
  smp_subdomains_vec_tmp <- as.numeric(smp_subdomains_vec)
  ndt_smp <- as.vector(table(smp_subdomains_vec_tmp))

  # Indicator variables that indicate if subdomain is in- or out-of-sample
  obs_subdom <- pop_subdomains_vec %in% unique(smp_subdomains_vec)
  dist_obs_subdom <- unique(pop_subdomains_vec) %in% unique(smp_subdomains_vec)

  #Indicator variable that indicate if subdomain is out of sample in a sampled domain
  unobs_subdom_obs_dom <- obs_dom & !obs_subdom

  unsampled_subdoms_smpdoms <- pop_data
  unsampled_subdoms_smpdoms$dom_sampled <- obs_dom
  unsampled_subdoms_smpdoms$subdom_sampled <- obs_subdom
  # Filter for sampled subdomains only
  unsampled_subdoms_smpdoms <- unsampled_subdoms_smpdoms %>%
    dplyr::filter(dom_sampled == TRUE & subdom_sampled == FALSE)
  # Convert the column to a factor with all levels from pop_domains
  lvls_unsampled_subdoms_smpdoms <- levels(unsampled_subdoms_smpdoms[[pop_domains]])
  lvls_unsampled_subdoms_smpdoms <- factor(unsampled_subdoms_smpdoms[[pop_domains]],
                               levels = lvls_unsampled_subdoms_smpdoms)
  n_pop_unsampled_subdoms <- as.numeric(table(lvls_unsampled_subdoms_smpdoms))
  rm(unsampled_subdoms_smpdoms)
  rm(lvls_unsampled_subdoms_smpdoms)
#_________________________________________________________________


  fw_tf_check3(
    obs_dom = obs_dom, obs_subdom = obs_subdom, dist_obs_dom = dist_obs_dom,
    dist_obs_subdom = dist_obs_subdom, pop_domains = pop_domains,
    pop_subdomains = pop_subdomains, smp_domains = smp_domains,
    smp_subdomains = smp_subdomains)

  indicator_list <- list(
    fast_mean = function(y, pop_weights, threshold) {
      t(weighted.mean(y, pop_weights))
    },
    hcr = function(y, pop_weights, threshold) {
       t(weighted.mean(y < threshold, pop_weights))
    },
    pgap = function(y, pop_weights, threshold) {
      sum((1 - (y[y < threshold]/threshold)) * pop_weights[y < threshold])/
        sum(pop_weights)
    },
    gini = function(y, pop_weights, threshold) {
        n <- length(y)
        pop_weights <- pop_weights[order(y)]
        y <- sort(y)
        auc <- sum((cumsum(c(0, (y * pop_weights)[1:(n-1)])) +
                      ((y * pop_weights) / 2)) * pop_weights)
        auc <- (auc / sum(pop_weights)) / sum((y * pop_weights))
        G <- 1 - (2* auc)
        return(G)
    },
    qsr = function(y, pop_weights, threshold) {
      quant14 <- wtd.quantile(x = y, weights = pop_weights, probs = c(0.2, 0.8))

      iq1 <- y <= quant14[1]
      iq4 <- y > quant14[2]
      t((sum(pop_weights[iq4] * y[iq4]) / sum(pop_weights[iq4])) /
           (sum(pop_weights[iq1] * y[iq1]) / sum(pop_weights[iq1])))
    },
    quants = function(y, pop_weights, threshold) {
      if(length(unique(pop_weights)) == 1 & 1 %in% unique(pop_weights)){
        t(quantile(x = y, probs = c(.10, .25, .5, .75, .9)))
      }else{
        t(wtd.quantile(x = y, weights = pop_weights,
                       probs = c(.10, .25, .5, .75, .9)))
      }
    }
  )

  indicator_names <- c(
    "Mean",
    "Head_Count",
    "Poverty_Gap",
    "Gini",
    "Quintile_Share",
    "Quantile_10",
    "Quantile_25",
    "Median",
    "Quantile_75",
    "Quantile_90"
  )


  if (!is.null(custom_indicator) && length(custom_indicator) > 0) {
    for(i in 1:length(custom_indicator)) {
      formals(custom_indicator[[i]]) <- alist(y=, pop_weights=, threshold=)
    }

    indicator_list <- c(indicator_list, custom_indicator)
    indicator_names <- c(indicator_names, names(custom_indicator))
  }

  if (is.null(threshold)) {
    threshold <- 0.6 * median(smp_data[[paste(fixed[2])]])
    message(strwrap(prefix = " ", initial = "",
                    paste0("The threshold for the HCR and the PG is
                          automatically set to 60% of the median of the
                          dependent variable and equals ", threshold)))
  }


  return(list(
    pop_data = pop_data,
    pop_domains_vec = pop_domains_vec,
    pop_subdomains_vec = pop_subdomains_vec,
    pop_domains = pop_domains,
    pop_subdomains = pop_subdomains,
    smp_data = smp_data,
    smp_domains_vec = smp_domains_vec,
    smp_subdomains_vec = smp_subdomains_vec,
    smp_domains = smp_domains,
    smp_subdomains = smp_subdomains,
    N_pop = N_pop,
    N_smp = N_smp,
    N_unobs = N_unobs,
    N_dom_pop = N_dom_pop,
    N_subdom_pop = N_subdom_pop,
    N_dom_smp = N_dom_smp,
    N_subdom_smp = N_subdom_smp,
    N_dom_unobs = N_dom_unobs,
    N_subdom_unobs = N_subdom_unobs,
    n_pop = n_pop,
    n_smp = n_smp,
    obs_dom = obs_dom,
    obs_subdom = obs_subdom,
    dist_obs_dom = dist_obs_dom,
    dist_obs_subdom = dist_obs_subdom,
    unobs_subdom_obs_dom = unobs_subdom_obs_dom,
    n_pop_unsampled_subdoms = n_pop_unsampled_subdoms,
    subdom_names = subdom_names,
    dom_names = dom_names,
    ndt_pop = ndt_pop,
    ndt_smp = ndt_smp,
    indicator_list = indicator_list,
    indicator_names = indicator_names,
    threshold = threshold,
    pop_weights = pop_weights
  ))
}
