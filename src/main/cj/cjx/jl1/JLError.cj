package cjx.jl1

import cjx.jl1.JLMark
import cj.Error

class JLError {
    val error: Error
    val marks: List[JLMark]

    def new(message: String, marks: List[JLMark]): Self = __malloc(Error(message), marks)
}
