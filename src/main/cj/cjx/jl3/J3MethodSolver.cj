package cjx.jl3

import cjx.jl3.J3Data
import cjx.jl3.J3Method
import cjx.jl3.J3Class
import cjx.jl3.J3Solver

@derive(new)
class J3MethodSolver {
    val solver: J3Solver
    val cls: J3Class
    val method: J3Method
    val map: Map[String, J3Data]
}
