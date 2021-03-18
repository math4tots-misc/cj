package cjx.cc

import cjx.cc.CCError
import cj.Uint8Array
import cjx.cc.CCIR
import cjx.binaryen.Binaryen

class CCCodegen {
    private static val none: Binaryen.Type = Binaryen.none
    private static val i32: Binaryen.Type = Binaryen.i32
    private static val i64: Binaryen.Type = Binaryen.i64
    private static val f32: Binaryen.Type = Binaryen.f32
    private static val f64: Binaryen.Type = Binaryen.f64
    private static val unreachable: Binaryen.Type = Binaryen.unreachable
    private static val auto: Binaryen.Type = Binaryen.auto

    private val m: Binaryen.Module = Binaryen.Module()
    private var localSlotSP = 0
    private var locals: List[Binaryen.Type] = []

    def emit(self, stmts: List[CCIR.Node]): Uint8Array {

        m.setMemory(1, 1)

        # initialize the stack pointer
        m.addGlobal("SP", i32, true, m.i32.const(8))

        locals = [i32]   # the first non-param local is a local copy of SP
        localSlotSP = 0  # the index into locals reserved for a copy of SP

        val body = stmts(stmts)

        m.addFunction("main", Binaryen.createType([]), i32, locals, body)
        m.addFunctionExport("main", "main")

        m.validate()
        m.optimize()
        # IO.println(m.emitText())
        m.emitBinary()
    }

    def newLocal(self, type: Binaryen.Type): Int {
        val index = locals.size()
        locals.add(type)
        index
    }

    def withLocal[R](self, type: Binaryen.Type, f: Fn[Int, R]): R {
        val local = newLocal(type)
        f.call(local)
        # while methods like withLocal help to reflect syntactically
        # the idea that temporary variables are scoped, we don't actually
        # do any kind of manual reuse. Instead, we let Binaryen's
        # optimizer figure out the best way to recycle locals.
    }

    def stmts(self, stmts: List[CCIR.Node]): Binaryen.Expression {
        val bexprs: List[Binaryen.Expression] = []

        # initialize local variable '0' with "SP"
        bexprs.add(m.local.set(localSlotSP, m.global.get("SP", i32)))

        if stmts {
            for i = 0; i + 1 < stmts.size(); i++ {
                bexprs.add(m.drop(stmt(stmts[i])))
            }
            bexprs.add(stmt(stmts.last()))
        }
        m.block(null, bexprs, auto)
    }

    def stmt(self, stmt: CCIR.Node): Binaryen.Expression {
        when stmt.kind {
            case exprStmt = expr(stmt.arg)
            else = throw CCError("TODO stmt " + stmt.kind, [stmt.mark])
        }
    }

    def addr(self, expr: CCIR.Node): Binaryen.Expression {
        when expr.kind {
            case assign {
                withLocal(i32, tmp ->
                    m.block(null, [
                        m.local.set(tmp, addr(expr.lhs)),
                        m.i32.store(0, 0, m.local.get(tmp, i32), expr(expr.rhs)),
                        m.local.get(tmp, i32),
                    ], i32))
            }
            case var_ {
                val var_ = expr.var_
                m.i32.add(m.local.get(localSlotSP, i32), m.i32.const(var_.id * 8))
            }
            else = throw CCError("Not an lvalue", [expr.mark])
        }
    }

    def expr(self, expr: CCIR.Node): Binaryen.Expression {
        when expr.kind {
            case int = m.i32.const(expr.intValue)
            case neg = m.i32.sub(m.i32.const(0), expr(expr.arg))
            case pos = expr(expr.arg)
            case add = m.i32.add(expr(expr.lhs), expr(expr.rhs))
            case sub = m.i32.sub(expr(expr.lhs), expr(expr.rhs))
            case mul = m.i32.mul(expr(expr.lhs), expr(expr.rhs))
            case div = m.i32.div_s(expr(expr.lhs), expr(expr.rhs))
            case eq = m.i32.eq(expr(expr.lhs), expr(expr.rhs))
            case ne = m.i32.ne(expr(expr.lhs), expr(expr.rhs))
            case lt = m.i32.lt_s(expr(expr.lhs), expr(expr.rhs))
            case le = m.i32.le_s(expr(expr.lhs), expr(expr.rhs))
            case assign; case var_ = m.i32.load(0, 0, addr(expr))
            else = throw CCError("TODO expr " + expr.kind, [expr.mark])
        }
    }
}
