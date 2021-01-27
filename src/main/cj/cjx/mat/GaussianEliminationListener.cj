package cjx.mat

trait GaussianEliminationListener {
    ## Callback for when two rows are swapped
    ##
    ## R[i] <-> R[j]
    ##
    def swap(self: Self, i: Int, j: Int)

    ## Callback for when a row is being scaled by the given factor
    ##
    ## factor * R[i] -> R[i]
    ##
    def scale(self: Self, i: Int, factor: Double)

    ## Callback for when a row is being added to by a multiple of another row.
    ##
    ## R[i] + factor * R[j] -> R[i]
    ##
    def addWithFactor(self: Self, i: Int, j: Int, factor: Double)

    ## Callback for when the elimination has finished
    ##
    ## - invertible: true iff the original matrix was invertible
    ##
    def finish(self: Self, invertible: Bool)
}
