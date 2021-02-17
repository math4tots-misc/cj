package cjx.ez

import cjx.ez.EZMark
import cj.Error

class EZError {
    val error: Error
    val marks: List[EZMark]

    def __new(message: String, marks: List[EZMark]): Self = __malloc(Error(message), marks)
}
