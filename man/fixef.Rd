% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/nlme_methods.R
\name{fixef}
\alias{fixef}
\alias{fixed.effects}
\alias{fixef.ebp}
\alias{fixed.effects.ebp}
\alias{fixef.ebp_tf}
\alias{fixed.effects.ebp_tf}
\alias{fixef.fh}
\alias{fixed.effects.fh}
\alias{fixef.fh_tf}
\alias{fixed.effects.fh_tf}
\title{Extract Fixed Effects from an emdi Object}
\usage{
\method{fixef}{ebp}(object, ...)

\method{fixed.effects}{ebp}(object, ...)

\method{fixef}{ebp_tf}(object, ...)

\method{fixed.effects}{ebp_tf}(object, ...)

\method{fixef}{fh}(object, ...)

\method{fixed.effects}{fh}(object, ...)

\method{fixef}{fh_tf}(object, ...)

\method{fixed.effects}{fh_tf}(object, ...)
}
\arguments{
\item{object}{an object of type "emdi", depending on any of the used method:
"ebp", "ebp_tf", "fh" or "fh_tf".}

\item{...}{additional arguments that are not used in this method.}
}
\value{
For classes "ebp", "ebp_tf", "fh" and "fh_tf" a vector containing
the fixed effects is returned.
}
\description{
Methods \code{fixef.ebp}, \code{fixef.ebp_tf}, \code{fixef.fh} and
\code{fixef.fh_tf} extract the fixed effects from an emdi object of class
"ebp", "ebp_tf", "fh" or "fh_tf".
}
\details{
The alias \code{fixed.effects} can also be used instead of
\code{fixef}. The generic function \code{fixef} is imported from package
nlme and re-exported to make the S3-methods available, even though the nlme
package itself is not loaded or attached. For default documentation,
see \code{\link[nlme]{fixed.effects}}.
}
\examples{
\donttest{
# Example for class ebp
emdi_model <- ebp(
  fixed = eqIncome ~ gender + eqsize + cash + self_empl +
    unempl_ben + age_ben + surv_ben + sick_ben + dis_ben + rent + fam_allow +
    house_allow + cap_inv + tax_adj, pop_data = eusilcA_pop,
  pop_domains = "district", smp_data = eusilcA_smp, smp_domains = "district",
  na.rm = TRUE
)

fixef(emdi_model)
}
}
\seealso{
\code{\link{ebp}}, \code{\link{ebp_tf}}, \code{\link{fh}},
\code{\link{fh_tf}}, \code{\link[nlme]{fixed.effects}}
}
