package cjx.cc

import cjx.cc.CCError
import cjx.cc.CCExpr
import cjx.cc.CCParser
import www.wa.WebAssembly
import cj.Uint8Array
import cjx.binaryen.Binaryen

class CCompiler {
    private static val none: Binaryen.Type = Binaryen.none
    private static val i32: Binaryen.Type = Binaryen.i32
    private static val i64: Binaryen.Type = Binaryen.i64
    private static val f32: Binaryen.Type = Binaryen.f32
    private static val f64: Binaryen.Type = Binaryen.f64
    private static val unreachable: Binaryen.Type = Binaryen.unreachable
    private static val auto: Binaryen.Type = Binaryen.auto

    def compileString(string: String): Uint8Array {
        val module = Binaryen.Module()

        val expr = CCParser.parseExpression("main", string)

        module.addFunction("main", Binaryen.createType([]), i32, [], module.block(
            null,
            [expr(module, expr)],
            auto))
        module.addFunctionExport("main", "main")

        module.emitBinary()
    }

    def compileAndRunMain(string: String): Int {
        val binary = compileString(string)
        val module = WebAssembly.Module(binary)
        val instance = WebAssembly.Instance(module, jsobj!())
        instance.exports.call("main").unsafeCast()
    }

    private def expr(m: Binaryen.Module, expr: CCExpr): Binaryen.Expression {
        when expr.kind {
            case int = m.i32.const(expr.intValue)
            case ineg = m.i32.sub(m.i32.const(0), expr(m, expr.args[0]))
            else = throw CCError("TODO expr " + expr.kind, [expr.mark])
        }
    }
}
