package cjx.xx

import cjx.xx.XXMark
import cj.Error

class XXError {
    val error: Error
    val marks: List[XXMark]

    def __new(message: String, marks: List[XXMark]): Self = __malloc(Error(message), marks)
}
