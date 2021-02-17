package cjx.xx.llir

import cj.StringBuilder
import cjx.xx.llir.XXLLIRType
import cjx.xx.XXMark

class XXLLIRExpr {
    union Data {
        case int(Int)
        case block(List[XXLLIRExpr])
    }
    val mark: XXMark
    val type: XXLLIRType
    val data: Data
    val terminatesFlow: Bool

    def(mark: XXMark, type: XXLLIRType, data: Data): Self {
        __malloc(mark, type, data, type.isNoReturn() or when data {
            case block(exprs) = exprs and exprs.last().terminatesFlow
            else = false
        })
    }

    def inspect(self): String {
        val sb = StringBuilder()
        _inspect(sb, 0)
        sb.toString()
    }

    def _inspect(self, sb: StringBuilder, depth: Int) {
        sb.add("  " * depth + mark.line + "," + type + ": ")
        when data {
            case int(i) = sb.add("int(" + i + ")\n")
            case block(exprs) = {
                sb.add("block\n")
                for expr in exprs {
                    expr._inspect(sb, depth + 1)
                }
            }
        }
    }
}
