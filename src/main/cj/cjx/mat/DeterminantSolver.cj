package cjx.mat

import cjx.mat.GaussianEliminationListener
import cjx.mat.Matx
import cjx.mat.GaussianElimination

class DeterminantSolver : GaussianEliminationListener {
    private var denominator : Double = 1

    def swap(self, i: Int, j: Int) {
        denominator = -denominator
    }

    def scale(self, i: Int, factor: Double) {
        denominator = denominator * factor
    }

    def addWithFactor(self, i: Int, j: Int, factor: Double) {
    }

    def finish(self, invertible: Bool) {
        if not invertible {
            denominator = 0
        }
    }

    def solve(matrix: Matx) : Double {
        val solver = __malloc()
        GaussianElimination[Self].execute(matrix, solver)
        if solver.denominator == 0 { 0.0 } else { 1.0 / solver.denominator }
    }
}
