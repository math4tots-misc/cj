package cjx.cc

import cj.Error
import cjx.cc.CCError
import cj.Uint8Array
import cjx.cc.CCIR
import cjx.binaryen.Binaryen

class CCCodegen {
    private static val optimize = false
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
    private var labelCount = 0

    def emit(self, funcs: List[CCIR.Func]): Uint8Array {

        m.setMemory(1, 1)

        # initialize the stack pointer
        m.addGlobal("SP", i32, true, m.i32.const(8))

        for func in funcs {
            func(func)
        }

        m.validate()
        if optimize { m.optimize() }
        # IO.println(m.emitText())
        m.emitBinary()
    }

    def func(self, func: CCIR.Func) {
        locals = []
        localSlotSP = newLocal(i32)

        val stmts: List[Binaryen.Expression] = []

        val params = func.params
        for i = 0; i < params.size(); i++ {
            val param = params[i]
            val ptype = type(param.type)
            val spptr = m.local.get(localSlotSP, i32)
            stmts.add(if ptype == i32 {
                m.i32.store(param.offset, 0, spptr, m.local.get(i, ptype))
            } else if ptype == i64 {
                m.i64.store(param.offset, 0, spptr, m.local.get(i, ptype))
            } else {
                throw Error("TODO")
            })
        }

        stmts.add(stmt(func.body))
        val body = m.block(null, stmts, auto)
        m.addFunction(
            func.name,
            Binaryen.createType(func.type.paramTypes.map(t -> type(t))),
            type(func.type.returnType),
            locals,
            body)
        m.addFunctionExport(func.name, func.name)
    }

    def type(self, type: CCIR.Type): Binaryen.Type {
        when type.kind {
            case int = i32
            case ptr = i32
            case func = i32
        }
    }

    def newLocal(self, type: Binaryen.Type): Int {
        val index = locals.size()
        locals.add(type)
        index
    }

    def newLabel(self): String {
        val name = "l" + labelCount
        labelCount++
        name
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
        for stmt in stmts {
            bexprs.add(stmt(stmt))
        }
        m.block(null, bexprs, none)
    }

    def stmt(self, stmt: CCIR.Node): Binaryen.Expression {
        when stmt.kind {
            case exprStmt = m.drop(expr(stmt.arg))
            case return_ = m.return_(expr(stmt.arg))
            case block {
                val bexprs = stmt.body.map(n -> stmt(n))
                m.block(null, bexprs, none)
            }
            case for_ {
                val breakLabel = newLabel()
                val continueLabel = newLabel()
                val init = stmt(stmt.init)
                val cond = expr(stmt.cond)
                val inc = expr(stmt.inc)
                val then = stmt(stmt.then)
                m.block(null(breakLabel), [
                    init,
                    m.loop(null(continueLabel), m.block(null, [
                        m.br_if(breakLabel, m.i32.eqz(cond)),
                        then,
                        m.drop(inc),
                        m.br(continueLabel),
                    ], none))
                ], none)
            }
            case if_ = m.if_(expr(stmt.cond), stmt(stmt.then), stmt(stmt.els))
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
                m.i32.add(m.local.get(localSlotSP, i32), m.i32.const(var_.offset))
            }
            case deref = expr(expr.arg)
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
            case funcall = m.call(
                expr.func.name, expr.args.map(a -> expr(a)), type(expr.func.type.returnType))
            case addr = addr(expr.arg)
            case assign; case var_; case deref = m.i32.load(0, 0, addr(expr))
            else = throw CCError("TODO expr " + expr.kind, [expr.mark])
        }
    }
}
