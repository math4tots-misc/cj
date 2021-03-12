package cjx.math.mat

import cjx.math.mat.Matx

class MatxOf {
    @variadic def(rows: List[List[Double]]): Matx = Matx.fromRows(rows)
}
