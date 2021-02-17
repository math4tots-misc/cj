package cjx.math.mat

import cjx.math.mat.GaussianElimination
import cjx.math.mat.Matx
import cj.Float64Array
import cjx.math.mat.GaussianEliminationListener

class InverseMatrixSolver : GaussianEliminationListener {
    private var invertible = true
    private val rows : List[Float64Array]

    def(n: Int): Self = __malloc(Matx.identity(n).rows())

    def swap(self, i: Int, j: Int) {
        rows.swap(i, j)
    }

    def scale(self, i: Int, factor: Double) {
        rows[i].scale(factor)
    }

    def addWithFactor(self, i: Int, j: Int, factor: Double) {
        rows[i].addWithFactor(rows[j], factor)
    }

    def finish(self, invertible: Bool) {
        self.invertible = invertible
    }

    def invert(matrix: Matx) : Nullable[Matx] {
        Assert.withMessage(matrix.isSquare(), "InverseMatrixSolver requires a square matrix")
        val solver = Self(matrix.c)
        GaussianElimination[Self].execute(matrix, solver)
        if solver.invertible { null(Matx.fromRowArrays(solver.rows)) } else { null }
    }
}
