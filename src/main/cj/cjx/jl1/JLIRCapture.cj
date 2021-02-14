package cjx.jl1

import cjx.jl1.JLType
import cjx.jl1.JLIRLocal

@derive(new)
class JLIRCapture {

    union Source {
        case local(JLIRLocal)
        case capture(JLIRCapture)

        def __get_name(self): String = when self {
            case local(local) = local.name
            case capture(capture) = capture.name
        }

        def __get_type(self): JLType = when self {
            case local(local) = local.type
            case capture(capture) = capture.type
        }
    }

    val id: Int

    ## Reference to the local variable in the outer scope
    val source: Source

    def __get_name(self): String = source.name
    def __get_type(self): JLType = source.type
}
