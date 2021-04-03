package compiler.codegen

import cjx.parser.MError
import compiler.codegen.CJJSBlob
import compiler.CJIR.ItemDef
import compiler.CJIR.Expr

class CJExprgen {
    val itemMap: Map[String, ItemDef]

    def gen(self, expr: Expr): CJJSBlob {
        when expr.data {
            case int(i) = CJJSBlob.pure("" + i)
            else name(..) = throw MError("TODO CJExprgen.gen " + name, [expr.mark])
        }
    }
}
