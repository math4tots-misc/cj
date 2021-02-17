package cjx.jl3

import cjx.jl3.J3Mark
import cj.Error

class J3Error {
    val error: Error
    val marks: List[J3Mark]

    def __new(message: String, marks: List[J3Mark]): Self = __malloc(Error(message), marks)
}
