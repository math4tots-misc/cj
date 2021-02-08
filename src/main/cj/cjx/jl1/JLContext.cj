package cjx.jl1

import cjx.jl1.JLError
import cjx.jl1.JLMark
import cjx.jl1.JLType
import cjx.jl1.JLIRClass

@derive(new)
class JLContext {
    val classMap: Map[String, JLIRClass] = Map()

    def getClassType(self, mark: JLMark, qualifiedClassName: String): JLType = (
        JLType.klass(getClass(mark, qualifiedClassName)))

    def getClass(self, mark: JLMark, qualifiedClassName: String): JLIRClass {
        if null(cls) = classMap.getOrNull(qualifiedClassName) {
            cls
        } else {
            throw JLError("Class " + qualifiedClassName + " not found", [mark])
        }
    }
}
