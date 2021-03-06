#' @include internal.R Constraint-proto.R
NULL

#' Add contiguity constraints
#'
#' Add constraints to a conservation planning \code{\link{problem}} to ensure
#' that all selected planning units are spatially connected with each other
#' and form a single contiguous unit.
#'
#' @param x \code{\link{ConservationProblem-class}} object.
#'
#' @param zones \code{matrix} or \code{Matrix} object describing the
#'   connection scheme for different zones. Each row and column corresponds
#'   to a different zone in the argument to \code{x}, and cell values must
#'   contain binary \code{numeric} values (i.e. one or zero) that indicate
#'   if connected planning units (as specified in the argument to
#'   \code{data}) should be still considered connected if they are allocated to
#'   different zones. The cell values along the diagonal
#'   of the matrix indicate if planning units should be subject to
#'   contiguity constraints when they are allocated to a given zone. Note
#'   arguments to \code{zones} must be symmetric, and that a row or column has
#'   a value of one then the diagonal element for that row or column must also
#'   have a value of one. The default argument to \code{zones} is an identity
#'   matrix (i.e. a matrix with ones along the matrix diagonal and zeros
#'   elsewhere), so that planning units are only considered connected if they
#'   are both allocated to the same zone.
#'
#' @param data \code{NULL}, \code{matrix}, \code{Matrix}, \code{data.frame}
#'   object showing which planning units are connected with each
#'   other. The argument defaults to \code{NULL} which means that the
#'   connection data is calculated automatically using the
#'   \code{\link{connected_matrix}} function. See the Details section for more
#'   information.
#'
#' @details This function uses connection data to identify solutions that
#'   form a single contiguous unit. In earlier versions of the
#'   \pkg{prioritizr} package, it was known as the
#'   \code{add_connected_constraints} function. It was inspired by the
#'   mathematical formulations detailed in {\"O}nal and Briers (2006).
#'
#'   The argument to \code{data} can be specified in several ways:
#'
#'   \describe{
#'
#'   \item{\code{NULL}}{connection data should be calculated automatically
#'     using the \code{\link{connected_matrix}} function. This is the default
#'     argument. Note that the connection data must be manually defined
#'     using one of the other formats below when the planning unit data
#'     in the argument to \code{x} is not spatially referenced (e.g.
#'     in \code{data.frame} or \code{numeric} format).}
#'
#'   \item{\code{matrix}, \code{Matrix}}{where rows and columns represent
#'     different planning units and the value of each cell indicates if the
#'     two planning units are connected or not. Cell values should be binary
#'     \code{numeric} values (i.e. one or zero). Cells that occur along the
#'     matrix diagonal have no effect on the solution at all because each
#'     planning unit cannot be a connected with itself.}
#'
#'   \item{\code{data.frame}}{containing the fields (columns)
#'     \code{"id1"}, \code{"id2"}, and \code{"boundary"}. Here, each row
#'     denotes the connectivity between two planning units following the
#'     \emph{Marxan} format. The field \code{boundary} should contain
#'     binary \code{numeric} values that indicate if the two planning units
#'     specified in the fields \code{"id1"} and \code{"id2"} are connected
#'     or not. This data can be used to describe symmetric or
#'     asymmetric relationships between planning units. By default,
#'     input data is assumed to be symmetric unless asymmetric data is
#'     also included (e.g. if data is present for planning units 2 and 3, then
#'     the same amount of connectivity is expected for planning units 3 and 2,
#'     unless connectivity data is also provided for planning units 3 and 2).}
#'
#'   }
#'
#' @return \code{\link{ConservationProblem-class}} object with the constraints
#'   added to it.
#'
#' @seealso \code{\link{constraints}}.
#'
#' @references
#' {\"{O}}nal H and Briers RA (2006) Optimal selection of a connected
#' reserve network. \emph{Operations Research}, 54: 379--388.
#'
#' @examples
#' # load data
#' data(sim_pu_raster, sim_features, sim_pu_zones_stack, sim_features_zones)
#'
#' # create minimal problem
#' p1 <- problem(sim_pu_raster, sim_features) %>%
#'       add_min_set_objective() %>%
#'       add_relative_targets(0.2) %>%
#'       add_binary_decisions()
#'
#' # create problem with added connected constraints
#' p2 <- p1 %>% add_contiguity_constraints()
#' \donttest{
#' # solve problems
#' s <- stack(solve(p1), solve(p2))
#'
#' # plot solutions
#' plot(s, main = c("basic solution", "connected solution"), axes = FALSE,
#'      box = FALSE)
#' }
#' # create minimal problem with multiple zones, and limit the solver to
#' # 30 seconds to obtain solutions in a feasible period of time
#' p3 <- problem(sim_pu_zones_stack, sim_features_zones) %>%
#'       add_min_set_objective() %>%
#'       add_relative_targets(matrix(0.2, ncol = 3, nrow = 5)) %>%
#'       add_default_solver(time_limit = 30) %>%
#'       add_binary_decisions()
#'
#' # create problem with added constraints to ensure that the planning units
#' # allocated to each zone form a separate contiguous unit
#' z4 <- diag(3)
#' print(z4)
#' p4 <- p3 %>% add_contiguity_constraints(z4)
#'
#' # create problem with added constraints to ensure that the planning
#' # units allocated to each zone form a separate contiguous unit,
#' # except for planning units allocated to zone 2 which do not need
#' # form a single contiguous unit
#' z5 <- diag(3)
#' z5[3, 3] <- 0
#' print(z5)
#' p5 <- p3 %>% add_contiguity_constraints(z5)
#'
#' # create problem with added constraints that ensure that the planning
#' # units allocated to zones 1 and 2 form a contiguous unit
#' z6 <- diag(3)
#' z6[1, 2] <- 1
#' z6[2, 1] <- 1
#' print(z6)
#' p6 <- p3 %>% add_contiguity_constraints(z6)
#' \donttest{
#' # solve problems
#' s2 <- lapply(list(p3, p4, p5, p6), solve)
#' s2 <- lapply(s2, category_layer)
#' s2 <- stack(s2)
#'
#' # plot solutions
#' plot(s2, axes = FALSE, box = FALSE,
#'      main = c("basic solution", "p4", "p5", "p6"))
#' }
#' # create a problem that has a main "reserve zone" and a secondary
#' # "corridor zone" to connect up import areas. Here, each feature has a
#' # target of 30 % of its distribution. If a planning unit is allocated to the
#' # "reserve zone", then the prioritization accrues 100 % of the amount of
#' # each feature in the planning unit. If a planning unit is allocated to the
#' # "corridor zone" then the prioritization accrues 40 % of the amount of each
#' # feature in the planning unit. Also, the cost of managing a planning unit
#' # in the "corridor zone" is 45 % of that when it is managed as the
#' # "reserve zone". Finally, the problem has constraints which
#' # ensure that all of the selected planning units form a single contiguous
#' # unit, so that the planning units allocated to the "corridor zone" can
#' # link up the planning units allocated to the "reserve zone"
#'
#' # create planning unit data
#' pus <- sim_pu_zones_stack[[c(1, 1)]]
#' pus[[2]] <- pus[[2]] * 0.45
#' print(pus)
#'
#' # create biodiversity data
#' fts <- zones(sim_features, sim_features * 0.4,
#'              feature_names = names(sim_features),
#'              zone_names = c("reserve zone", "corridor zone"))
#' print(fts)
#'
#' # create targets
#' targets <- tibble::tibble(feature = names(sim_features),
#'                           zone = list(zone_names(fts))[rep(1, 5)],
#'                           target = cellStats(sim_features, "sum") * 0.2,
#'                           type = rep("absolute", 5))
#' print(targets)
#'
#' # create zones matrix
#' z7 <- matrix(1, ncol = 2, nrow = 2)
#' print(z7)
#'
#' # create problem
#' p7 <- problem(pus, fts) %>%
#'       add_min_set_objective() %>%
#'       add_manual_targets(targets) %>%
#'       add_contiguity_constraints(z7) %>%
#'       add_binary_decisions()
#' \donttest{
#' # solve problems
#' s7 <- category_layer(solve(p7))
#'
#' # plot solutions
#' plot(s7, "solution", axes = FALSE, box = FALSE)
#' }
#' @name add_contiguity_constraints
#'
#' @exportMethod add_contiguity_constraints
#'
#' @aliases add_contiguity_constraints,ConservationProblem,ANY,matrix-method add_contiguity_constraints,ConservationProblem,ANY,data.frame-method add_contiguity_constraints,ConservationProblem,ANY,ANY-method
NULL

methods::setGeneric("add_contiguity_constraints",
  signature = methods::signature("x", "zones", "data"),
  function(x, zones = diag(number_of_zones(x)), data = NULL)
  standardGeneric("add_contiguity_constraints"))

#' @name add_contiguity_constraints
#' @usage \S4method{add_contiguity_constraints}{ConservationProblem,ANY,ANY}(x, zones, data)
#' @rdname add_contiguity_constraints
methods::setMethod("add_contiguity_constraints",
  methods::signature("ConservationProblem", "ANY", "ANY"),
  function(x, zones, data) {
    # assert valid arguments
    assertthat::assert_that(inherits(x, "ConservationProblem"),
     inherits(zones, c("matrix", "Matrix")),
     inherits(data, c("NULL", "Matrix")))
    if (!is.null(data)) {
      # check argument to data if not NULL
      data <- methods::as(data, "dgCMatrix")
      assertthat::assert_that(all(data@x %in% c(0, 1)),
        ncol(data) == nrow(data), number_of_total_units(x) == ncol(data),
        all(is.finite(data@x)), Matrix::isSymmetric(data))
      d <- list(connected_matrix = data)
    } else {
      # check that planning unit data is spatially referenced
      assertthat::assert_that(inherits(x$data$cost, c("Spatial", "Raster")),
        msg = paste("argument to data must be supplied because planning unit",
                    "data are not in a spatially referenced format"))
      d <- list()
    }
    # convert zones to matrix
    zones <- as.matrix(zones)
    assertthat::assert_that(
      isSymmetric(zones), ncol(zones) == number_of_zones(x),
      is.numeric(zones), all(zones %in% c(0, 1)),
      all(colMeans(zones) <= diag(zones)), all(rowMeans(zones) <= diag(zones)))
    colnames(zones) <- x$zone_names()
    rownames(zones) <- colnames(zones)
    # add constraints
    x$add_constraint(pproto(
      "ContiguityConstraint",
      Constraint,
      data = d,
      name = "Contiguity constraints",
      parameters = parameters(
        binary_parameter("apply constraints?", 1L),
        binary_matrix_parameter("zones", zones, symmetric = TRUE)),
      calculate = function(self, x) {
        assertthat::assert_that(inherits(x, "ConservationProblem"))
        # generate connected matrix if null
        if (is.Waiver(self$get_data("connected_matrix"))) {
          # create matrix
          data <- connected_matrix(x$data$cost)
          # coerce matrix to full matrix
          data <- methods::as(data, "dgCMatrix")
          # store data
          self$set_data("connected_matrix", data)
        }
        # return success
        invisible(TRUE)
      },
      apply = function(self, x, y) {
        assertthat::assert_that(inherits(x, "OptimizationProblem"),
          inherits(y, "ConservationProblem"))
        if (as.logical(self$parameters$get("apply constraints?")[[1]])) {
          # extract data and parameters
          ind <- y$planning_unit_indices()
          d <- self$get_data("connected_matrix")[ind, ind, drop = FALSE]
          z <- self$parameters$get("zones")
          # extract clusters from z
          z_cl <- igraph::graph_from_adjacency_matrix(z, diag = FALSE,
            mode = "undirected", weighted = NULL)
          z_cl <-  igraph::clusters(z_cl)$membership
          # set cluster memberships to zero if constraints not needed
          z_cl <- z_cl * diag(z)
          # convert d to lower triangle sparse matrix
          d <- Matrix::forceSymmetric(d, uplo = "L")
          class(d) <- "dgCMatrix"
          # apply constraints if any zones have contiguity constraints
          if (max(z_cl) > 0)
            rcpp_apply_contiguity_constraints(x$ptr, d, z_cl)
        }
        invisible(TRUE)
      }))
})

#' @name add_contiguity_constraints
#' @usage \S4method{add_contiguity_constraints}{ConservationProblem,ANY,data.frame}(x, zones, data)
#' @rdname add_contiguity_constraints
methods::setMethod("add_contiguity_constraints",
  methods::signature("ConservationProblem", "ANY", "data.frame"),
  function(x, zones, data) {
    # assert that does not have zone1 and zone2 columns
    assertthat::assert_that(inherits(data, "data.frame"),
      !assertthat::has_name(data, "zone1"),
      !assertthat::has_name(data, "zone2"))
    # add constraints
    add_contiguity_constraints(x, zones, marxan_boundary_data_to_matrix(x, data))
})

#' @name add_contiguity_constraints
#' @usage \S4method{add_contiguity_constraints}{ConservationProblem,ANY,matrix}(x, zones, data)
#' @rdname add_contiguity_constraints
methods::setMethod("add_contiguity_constraints",
  methods::signature("ConservationProblem", "ANY", "matrix"),
  function(x, zones, data) {
    # add constraints
    add_contiguity_constraints(x, zones, methods::as(data, "dgCMatrix"))
})
