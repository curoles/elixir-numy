/**
 * @brief  Fit B-Spline with GSL.
 * @author Igor Lesik 2020
 *
 * A smoothing basis spline (B-spline) differs from an interpolating spline
 * in that the resulting curve is not required to pass through each datapoint.
 * 
 * B-splines are commonly used as basis functions to ﬁt smoothing curves to large data sets.
 * To do this, the abscissa axis is broken up into some number of intervals,
 * where the endpoints of each interval are called _breakpoints_.
 * These breakpoints are then converted to knots by imposing various continuity
 * and smoothness conditions at each interface. 
 */

struct BSplineSolver
{
    // The computation of B-spline functions requires a preallocated workspace.
    gsl_bspline_workspace* wrkspace;

    // Number of basis functions.
    const size_t ncoeffs;

    const size_t nbreak;

    gsl_vector* B;   // splines
    gsl_vector* c;   // coeffs
    gsl_matrix* cov;

    double chisq, Rsq, dof, tss;

    BSplineSolver(size_t nbasis, size_t order = 4):
        ncoeffs(nbasis), nbreak(ncoeffs + 2 - order)
    {
        wrkspace = gsl_bspline_alloc(order, nbreak);
        B = gsl_vector_alloc(ncoeffs);
        c = gsl_vector_alloc(ncoeffs);
        cov = gsl_matrix_alloc(ncoeffs, ncoeffs);
    }

   ~BSplineSolver() {
        gsl_matrix_free(cov);
        gsl_vector_free(c);
        gsl_vector_free(B);
        gsl_bspline_free(wrkspace);
    }

    int make_knots_uniform(const double a, const double b) {
        return gsl_bspline_knots_uniform(a, b, wrkspace); 
    }

    void fit(gsl_vector* x, gsl_vector* y, gsl_vector* w, size_t data_size) {
        // ??? min/max? XXX make_knots_uniform(a, b);
        gsl_matrix* X = gsl_matrix_alloc(data_size, ncoeffs);
        make_fit_matrix(X, data_size);
        gsl_multifit_linear_workspace* mw = gsl_multifit_linear_alloc(data_size, ncoeffs)
        gsl_multifit_wlinear(X, w, y, c, cov, &chisq, mw);
        gsl_multifit_linear_free(mw);
        gsl_matrix_free(X);

        dof = data_size - ncoeffs;
        tss = gsl_stats_wtss(w->data, 1, y->data, 1, y->size);
        Rsq = 1.0 - chisq / tss;
    }

    void make_fit_matrix(gsl_matrix* X, gsl_vector* x, size_t data_size) {
        for (size_t i = 0; i < data_size; ++i) {
            double xi = gsl_vector_get(x, i);
            /* compute B_j(xi) for all j */
            gsl_bspline_eval(xi, B, wrkspace);
            /* fill in row i of X */
            for (size_t j = 0; j < ncoeffs; ++j) {
                double Bj = gsl_vector_get(B, j);
                gsl_matrix_set(X, i, j, Bj);
            }
        }
    }
};