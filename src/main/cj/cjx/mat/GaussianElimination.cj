package cjx.mat

import cjx.mat.GaussianEliminationListener
import cjx.mat.Matrix
import cj.Float64Array

## Performs gaussian elimination to reduced row echelon form
class GaussianElimination[Listener : GaussianEliminationListener] {
    def execute(matrix: Matrix, listener: Listener) {
        val gelim = __malloc(listener, matrix.rows())
        gelim.run()
    }

    val listener : Listener
    val rows : List[Float64Array]

    private def swap(self, i: Int, j: Int) {
        if i != j {
            rows.swap(i, j)
            listener.swap(i, j)
        }
    }

    private def addWithFactor(self, dest: Int, src: Int, factor: Double) {
        if factor != 0 {
            val destRow = rows[dest]
            val srcRow = rows[src]
            val c = srcRow.size()
            for i = 0; i < c; i++ {
                destRow[i] = destRow[i] + srcRow[i] * factor
            }
            listener.addWithFactor(dest, src, factor)
        }
    }

    private def finish(self, invertible: Bool) {
        listener.finish(invertible)
    }

    private def run(self) {
        val nrows = rows.size()
        val ncols = rows[0].size()

        for c = 0; c < ncols; c++ {
            # make rows[c, c] = 1 and rows[r, c] = 0 for all other r

            # for numerical stability, find the row with largest coefficient for
            # column c among those remaining (i.e. find the pivot)
            var bestRow = 0
            var bestValue = 0.0
            for r = c; r < nrows; r++ {
                val value = rows[r][c].abs()
                if value > bestValue {
                    bestRow = r
                    bestValue = value
                }
            }
            if bestValue == 0 {
                # this column only has zeros
                finish(false)
                return ()
            }

            # rearrange so that row c has the largest coefficient for column c
            swap(bestRow, c)

            # clear out column c for all rows c+1 to end.
            val srcCoef = rows[c][c]
            for r = c + 1; r < nrows; r++ {
                val dstCoef = rows[r][c]
                addWithFactor(r, c, -dstCoef/srcCoef)
            }
        }

        # At this point, we're in row echelon form.
        # todo-lowpri: Consider allowing some listeners to get access to the matrix here and
        # exiting early.
        # This may be useful for e.g. computing LU decomposition

        # We no longer need to actually update the row values from here --
        # we can deduce what the remaining operations are without further modifications.
        for c = ncols - 1; c >= 0; c -= 1 {
            # clear out all entries [r, c] for r < c
            val srcCoef = rows[c][c]
            for r = 0; r < c; r++ {
                val dstCoef = rows[r][c]
                val factor = -dstCoef/srcCoef
                if factor != 0 {
                    listener.addWithFactor(r, c, factor)
                }
            }
        }

        # Now we should have a diagonal matrix -- just apply scaling
        for i = 0; i < ncols; i++ {
            listener.scale(i, 1.0 / rows[i][i])
        }

        finish(true)
    }
}
