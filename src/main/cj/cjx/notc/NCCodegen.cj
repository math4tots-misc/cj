package cjx.notc

import cjx.parser.Mark
import cj.Error
import cjx.notc.NCError
import cjx.notc.NCIR
import cj.Uint8Array
import cjx.binaryen.Binaryen

class NCCodegen {
    private static val optimize = true
    private static val none: Binaryen.Type = Binaryen.none
    private static val i32: Binaryen.Type = Binaryen.i32
    private static val i64: Binaryen.Type = Binaryen.i64
    private static val f32: Binaryen.Type = Binaryen.f32
    private static val f64: Binaryen.Type = Binaryen.f64
    private static val unreachable: Binaryen.Type = Binaryen.unreachable
    private static val auto: Binaryen.Type = Binaryen.auto

    private val program: NCIR.Program
    private val m: Binaryen.Module = Binaryen.Module()
    private var labelCount = 0

    def emit(program: NCIR.Program): Uint8Array {
        val self = Self(program)
        m.setMemory(1, 1024)
        for func in program.funcs {
            func(func)
        }
        m.validate()
        if optimize { m.optimize() }
        m.emitBinary()
    }

    def newLabel(self): String {
        val label = "l" + labelCount
        labelCount++
        label
    }

    def func(self, func: NCIR.Func) {
        m.addFunction(
            func.name,
            Binaryen.createType(func.params.map(v -> type(v.mark, v.type))),
            type(func.mark, func.returnType),
            func.locals.map(v -> type(v.mark, v.type)),
            expr(func.body))
        m.addFunctionExport(func.name, func.name)
    }

    def type(self, mark: Mark, type: NCIR.Type): Binaryen.Type {
        when type {
            case unreachable = unreachable
            case void = i32
            case int = i32
            case type = i32
            case array(..) = i32
            case func(..) = throw NCError("func type not supported here", [mark])
        }
    }

    def expr(self, expr: NCIR.Expr): Binaryen.Expression {
        switch expr.kind {
            case NCIR.Expr.kINT = m.i32.const(expr.intValue)
            case NCIR.Expr.kINT_ADD = m.i32.add(expr(expr.lhs), expr(expr.rhs))
            case NCIR.Expr.kINT_SUB = m.i32.sub(expr(expr.lhs), expr(expr.rhs))
            case NCIR.Expr.kINT_MUL = m.i32.mul(expr(expr.lhs), expr(expr.rhs))
            case NCIR.Expr.kINT_REM = m.i32.rem_s(expr(expr.lhs), expr(expr.rhs))
            case NCIR.Expr.kINT_DIV = m.i32.div_s(expr(expr.lhs), expr(expr.rhs))
            case NCIR.Expr.kINT_EQ = m.i32.eq(expr(expr.lhs), expr(expr.rhs))
            case NCIR.Expr.kINT_NE = m.i32.ne(expr(expr.lhs), expr(expr.rhs))
            case NCIR.Expr.kINT_LT = m.i32.lt_s(expr(expr.lhs), expr(expr.rhs))
            case NCIR.Expr.kINT_LE = m.i32.le_s(expr(expr.lhs), expr(expr.rhs))
            case NCIR.Expr.kGETVAR = m.local.get(expr.var_.index, type(expr.mark, expr.var_.type))
            case NCIR.Expr.kSETVAR = m.local.tee(expr.var_.index, expr(expr.arg), type(expr.mark, expr.var_.type))
            case NCIR.Expr.kIF = m.if_(expr(expr.cond), expr(expr.then), expr(expr.els))
            case NCIR.Expr.kWHILE {
                val continueLabel = newLabel()
                val breakLabel = newLabel()
                m.block(null, [
                    m.block(null(breakLabel), [
                        m.loop(null(continueLabel), m.block(null, [
                            m.br_if(breakLabel, m.i32.eqz(expr(expr.cond))),
                            m.drop(expr(expr.then)),
                            m.br(continueLabel),
                        ], none)),
                    ], none),
                    expr(NCIR.Expr.nop(expr.mark)),
                ], type(expr.mark, NCIR.Type.void))
            }
            case NCIR.Expr.kCALL = m.call(
                expr.func.name, expr.args.map(a -> expr(a)), type(expr.mark, expr.func.returnType))
            case NCIR.Expr.kRETURN = m.return_(expr(expr.arg))
            case NCIR.Expr.kBLOCK {
                val bexprs: List[Binaryen.Expression] = []
                if expr.stmts {
                    for stmt in expr.stmts[:-1] {
                        bexprs.add(m.drop(expr(stmt)))
                    }
                    bexprs.add(expr(expr.stmts[-1]))
                } else {
                    bexprs.add(m.i32.const(0)) # void
                }
                m.block(null, bexprs, type(expr.mark, expr.type))
            }
            case NCIR.Expr.kMEMSIZE = m.memory.size()
            case NCIR.Expr.kLOAD = m.i32.load(0, 0, expr(expr.arg))
            case NCIR.Expr.kSTORE = {
                m.block(null, [
                    m.i32.store(0, 0, expr(expr.lhs), expr(expr.rhs)),
                    expr(NCIR.Expr.nop(expr.mark))
                ], type(expr.mark, NCIR.Type.void))
            }
            else = throw NCError("TODO expr " + expr, [expr.mark])
        }
    }
}
