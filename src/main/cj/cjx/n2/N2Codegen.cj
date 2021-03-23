package cjx.n2

import cj.Range
import www.sourcemap.JSBuilder
import cjx.parser.Mark
import cj.Error
import cjx.n2.N2Error
import cjx.n2.N2IR
import cj.Uint8Array
import cjx.binaryen.Binaryen

class N2Codegen {

    private val program: N2IR.Program
    private val out: JSBuilder = JSBuilder()
    private var tempVarCount = 0

    def emit(program: N2IR.Program, entryFunctionName: String): String {
        val self = Self(program)
        out.inlineSourceMap = true
        out.str("(function(){\n'use strict';\n")
        out.str(include_str!("prelude.js"))
        for func in program.funcs {
            func(func)
        }
        for struct_ in program.structs {
            struct_(struct_)
        }
        out.str("return " + trfnname(entryFunctionName) + "();")
        out.str("})()")
        out.getSource()
    }

    private def trsname(struct_: N2IR.Struct): String = "S" + struct_.name
    private def trfnname(functionName: String): String = (
        "F" + functionName.replace(".", "$D").replace("[", "$L").replace("]", "$R"))
    private def trvname(var_: N2IR.Var): String = "V" + var_.index + var_.name
    private def trflname(fieldName: String): String = "F" + fieldName

    class Blob {
        def simple(bodyString: String): Self = Self(null, out -> out.str(bodyString), false)
        def pure(bodyString: String): Self = Self(null, out -> out.str(bodyString), true)

        val prep: Fn[JSBuilder, Unit]?
        val body: Fn[JSBuilder, Unit]

        ## implies the contents of 'body' have no side deffects
        val pure: Bool

        ## implies that there's no prep needed for this blob expression
        def __get_simple(self): Bool = prep.isEmpty()

        def toPure(self, c: N2Codegen): Self {
            if pure { self } else {
                val tmpvar = c.newTempVar()
                Blob(
                    null(out -> set(out, "const " + tmpvar)),
                    out -> out.str(tmpvar),
                    true)
            }
        }

        def set(self, out: JSBuilder, target: String) {
            if val p = prep { p.call(out) }
            out.str(target)
            body.call(out)
            out.str(";")
        }

        def drop(self, out: JSBuilder) {
            if val p = prep { p.call(out) }
            if not pure {
                body.call(out)
                out.char(';')
            }
        }
    }

    @implicit(Blob, blob)
    @implicit(String, string)
    union Emittable {
        case blob(Blob)
        case string(String)
    }

    def newTempVar(self): String {
        val varName = "t" + tempVarCount
        tempVarCount++
        varName
    }

    def joinList(list: List[Emittable]): Blob {
        val simple = list.all(e -> when e { case blob(b) = b.simple; else = true })
        val prep: Fn[JSBuilder, Unit]? = if simple { null } else { null(out -> {
            for em in list {
                when em {
                    case blob(b) = if val prep = b.prep { prep.call(out) }
                    case string(..) = ()
                }
            }
        })}
        val body: Fn[JSBuilder, Unit] = out -> {
            for em in list {
                when em {
                    case blob(b) = b.body.call(out)
                    case string(s) = out.str(s)
                }
            }
        }
        Blob(prep, body, false)
    }

    def prepArgs(self, list: List[Blob]): List[Blob] {
        if list.all(e -> e.simple) { list } else { list.map(e -> e.toPure(self)) }
    }

    def joinPrep(self, list: List[Blob]): Fn[JSBuilder, Unit]? {
        if list.all(e -> e.simple) { null } else {
            val nonSimple = list.filter(e -> not e.simple)
            null(out -> {
                for e in nonSimple {
                    if val p = e.prep { p.call(out) }
                }
            })
        }
    }

    @variadic def join(self, list: List[Emittable]): Blob = joinList(list)

    def struct_(self, struct_: N2IR.Struct) {
        val params = struct_.fields.map(v -> trflname(v.name))
        val sname = trsname(struct_)
        out.addMark(struct_.mark)
        out.str("class " + sname + " extends Base{\n")
        out.str("constructor(" + ",".join(params) + "){super();")
        for param in params { out.str("this." + param + "=" + param + ";") }
        out.str("}\n")
        out.str("}\n")
    }

    def func(self, func: N2IR.Func) {
        tempVarCount = 0
        val fname = trfnname(func.name)
        val params = func.params.map(v -> trvname(v))
        val body = expr(func.body)
        out.addMark(func.mark)
        out.str("function " + fname + "(" + ",".join(params) + "){")
        body.set(out, "return ")
        out.str("}\n")
    }

    def expr(self, expr: N2IR.Expr): Blob {
        switch expr.kind {
            case N2IR.Expr.kINT = Blob.pure("" + expr.intValue)
            case N2IR.Expr.kINT_ADD = join("((", expr(expr.lhs), "+", expr(expr.rhs), ")|0)")
            case N2IR.Expr.kINT_SUB = join("((", expr(expr.lhs), "-", expr(expr.rhs), ")|0)")
            case N2IR.Expr.kINT_MUL = join("((", expr(expr.lhs), "*", expr(expr.rhs), ")|0)")
            case N2IR.Expr.kINT_REM = join("((", expr(expr.lhs), "%", expr(expr.rhs), ")|0)")
            case N2IR.Expr.kINT_DIV = join("((", expr(expr.lhs), "/", expr(expr.rhs), ")|0)")
            case N2IR.Expr.kINT_EQ = join("(", expr(expr.lhs), "===", expr(expr.rhs), ")")
            case N2IR.Expr.kINT_NE = join("(", expr(expr.lhs), "!==", expr(expr.rhs), ")")
            case N2IR.Expr.kINT_LT = join("(", expr(expr.lhs), "<", expr(expr.rhs), ")")
            case N2IR.Expr.kINT_LE = join("(", expr(expr.lhs), "<=", expr(expr.rhs), ")")
            case N2IR.Expr.kSTR = Blob.pure(expr.stringValue.repr())
            case N2IR.Expr.kSTR_LEN = join(expr(expr.arg), ".length")
            case N2IR.Expr.kSTR_ADD = join("(", expr(expr.lhs), "+", expr(expr.rhs), ")")
            case N2IR.Expr.kGETVAR = Blob.pure(trvname(expr.var_))
            case N2IR.Expr.kSETVAR = join("(", trvname(expr.var_), "=", expr(expr.arg), ")")
            case N2IR.Expr.kDECLVAR = Blob(
                null(out -> {
                    val varname = trvname(expr.var_)
                    if val init = expr.var_.init {
                        expr(init).set(out, "let " + varname + "=")
                    } else {
                        out.str("let " + varname + ";")
                    }
                }),
                out -> out.str("undefined"),
                true)
            case N2IR.Expr.kARRAY {
                val args = expr.args.map(arg -> expr(arg))
                val prep = joinPrep(args)
                Blob(prep, out -> {
                    out.str("[")
                    for i = 0; i < args.size(); i++ {
                        if i { out.str(",") }
                        args[i].body.call(out)
                    }
                    out.str("]")
                }, false)
            }
            case N2IR.Expr.kARRAY_LEN = join("(", expr(expr.arg), ".length)")
            case N2IR.Expr.kIF {
                val cond = expr(expr.cond)
                val then = expr(expr.then)
                val els = expr(expr.els)
                if then.simple and els.simple {
                    join("(", cond, "?", then, ":", els, ")")
                } else {
                    val tmpvar = newTempVar()
                    Blob(
                        null(out -> {
                            out.str("var " + tmpvar + ";")
                            if val p = cond.prep { p.call(out) }
                            out.str("if(")
                            cond.body.call(out)
                            out.str("){")
                            then.set(out, tmpvar + "=")
                            out.str("}else{")
                            els.set(out, tmpvar + "=")
                            out.str("}")
                        }),
                        out -> out.str(tmpvar),
                        true,
                    )
                }
            }
            case N2IR.Expr.kCALL {
                Assert.equal(expr.func.nparams, expr.args.size())
                val fname = trfnname(expr.func.name)
                val args = prepArgs(expr.args.map(arg -> expr(arg)))
                val prep = joinPrep(args)
                Blob(prep, out -> {
                    out.str(fname + "(")
                    for i = 0; i < args.size(); i++ {
                        if i { out.str(",") }
                        args[i].body.call(out)
                    }
                    out.str(")")
                }, false)
            }
            case N2IR.Expr.kNEWSTRUCT {
                val struct_ = expr.struct_
                Assert.equal(struct_.fields.size(), expr.args.size())
                val sname = trsname(struct_)
                val args = prepArgs(expr.args.map(arg -> expr(arg)))
                val prep = joinPrep(args)
                Blob(prep, out -> {
                    out.str("new " + sname + "(")
                    for i = 0; i < args.size(); i++ {
                        if i { out.str(",") }
                        args[i].body.call(out)
                    }
                    out.str(")")
                }, false)
            }
            case N2IR.Expr.kGETFIELD {
                val inner = expr(expr.arg)
                Blob(inner.prep, out -> {
                    inner.body.call(out)
                    out.str("." + trflname(expr.var_.name))
                }, false)
            }
            case N2IR.Expr.kRETURN {
                val arg = expr(expr.arg)
                Blob(
                    null(out -> arg.set(out, "return ")),
                    out -> out.str("UNREACHABLE"),
                    true)
            }
            case N2IR.Expr.kBLOCK {
                val stmts = expr.stmts.map(s -> expr(s))
                if expr.type.isVoid() {
                    Blob(
                        null(out -> {
                            if expr.newScope { out.str("{") }
                            for stmt in stmts { stmt.drop(out) }
                            if expr.newScope { out.str("}") }
                        }),
                        out -> out.str("undefined"),
                        true,
                    )
                } else {
                    val tmpvar = newTempVar()
                    Blob(
                        null(out -> {
                            out.str("let " + tmpvar + ";")
                            if expr.newScope { out.str("{") }
                            for stmt in stmts[:-1] {
                                stmt.drop(out)
                            }
                            stmts[-1].set(out, tmpvar + "=")
                            if expr.newScope { out.str("}") }
                        }),
                        out -> out.str(tmpvar),
                        true
                    )
                }
            }
            case N2IR.Expr.kJS {
                val args = expr.args.map(arg -> expr(arg))
                Blob(
                    if args.all(a -> a.simple) { null } else { null(out -> {
                        for i = 0; i < args.size(); i++ {
                            if expr.args[i].kind != N2IR.Expr.kSTR {
                                if val p = args[i].prep { p.call(out) }
                            }
                        }
                        for arg in args {
                            if val p = arg.prep { p.call(out) }
                        }
                    })},
                    out -> {
                        out.char('(')
                        for i = 0; i < args.size(); i++ {
                            if expr.args[i].kind == N2IR.Expr.kSTR {
                                out.str(expr.args[i].stringValue)
                            } else {
                                args[i].body.call(out)
                            }
                        }
                        out.char(')')
                    },
                    false
                )
            }
            else = throw N2Error("TODO expr " + expr, [expr.mark])
        }
    }
}
