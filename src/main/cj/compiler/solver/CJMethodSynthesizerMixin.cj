package compiler.solver

import compiler.CJModifier
import cjx.parser.MError
import compiler.solver.CJInferTypeMixin
import compiler.CJAst
import compiler.CJAst.Expr
import compiler.CJAst.ExprData as ED

trait CJMethodSynthesizerMixin: CJInferTypeMixin {

    ## If a '__new' method is not already defined, will create a default one
    ## that passes all its arguments as is to '__malloc'
    def synthesizeNew(self, cls: CJAst.Item) {
        if cls.native_ {
            return ()
        }
        for member in cls.members {
            when member {
                case method(method) = if method.name == "__new" { return () }
                else = ()
            }
        }
        val parameters = List[CJAst.Local].empty()
        val args = List[Expr].empty()
        for member in cls.members {
            when member {
                case field(field) {
                    if not field.static_ and field.init.isEmpty() {
                        val type = if val t = field.type { t } else {
                            throw MError("Could not infer type of field", [field.mark])
                        }
                        parameters.add(CJAst.Local(
                            field.mark,
                            false,
                            field.name,
                            null(type)))
                        args.add(Expr(field.mark, ED.getvar(field.name)))
                    }
                }
                else = ()
            }
        }
        val returnType = CJAst.Type(cls.mark, "Self", [])
        val body = Expr(cls.mark, ED.callname("__malloc", [], args))
        val method = CJAst.Method(
            cls.mark,
            null, # comment
            [], # annotations
            [CJModifier.synthetic],
            [], # conditions
            "__new",
            [], # type parameters
            parameters,
            null(returnType),
            null(body))
        cls.members.add(CJAst.Member.method(method))
    }

    def synthesizeEq(self, item: CJAst.Item) {
        when item.kind {
            case class_ = _synthesizeEqForClass(item)
            case union_ = _synthesizeEqForUnion(item)
            case trait_ = throw MError("derive eq not supported for traits", [item.mark])
        }
    }

    def synthesizeHash(self, item: CJAst.Item) {
        when item.kind {
            case class_ = _synthesizeHashForClass(item)
            case union_ = _synthesizeHashForUnion(item)
            case trait_ = throw MError("derive hash not supported for traits", [item.mark])
        }
    }

    def synthesizeRepr(self, item: CJAst.Item) {
        when item.kind {
            case class_ = _synthesizeReprForClass(item)
            case union_ = _synthesizeReprForUnion(item)
            case trait_ = throw MError("derive repr not supported for traits", [item.mark])
        }
    }

    def synthesizeDefault(self, item: CJAst.Item) {
        when item.kind {
            case class_ = _synthesizeDefaultForClass(item)
            case union_ = throw MError("derive default not supported for unions", [item.mark])
            case trait_ = throw MError("derive default not supported for traits", [item.mark])
        }
    }

    def _synthesizeEqForClass(self, item: CJAst.Item) {
        val mark = item.mark
        var body = Expr(mark, ED.bool(true))
        for field in item.nonStaticFields {
            body = Expr(mark, ED.logicalAnd(
                body,
                Expr(mark, ED.call(null, "__eq", [], [
                    Expr(mark, ED.getfield(Expr(mark, ED.getvar("self")), field.name)),
                    Expr(mark, ED.getfield(Expr(mark, ED.getvar("other")), field.name))]))))
        }
        val method = CJAst.Method(
            mark,
            null, # comment
            [], # annotations
            [CJModifier.synthetic],
            [], # conditions
            "__eq",
            [], # type parameters
            [
                CJAst.Local(mark, false, "self", null(CJAst.Type(mark, "Self", []))),
                CJAst.Local(mark, false, "other", null(CJAst.Type(mark, "Self", []))),
            ],
            null(CJAst.Type(mark, "Bool", [])),
            null(body))
        item.members.add(CJAst.Member.method(method))
    }

    def _synthesizeHashForClass(self, item: CJAst.Item) {
        val mark = item.mark
        val exprs = [Expr(mark, ED.int(17))]
        for field in item.nonStaticFields {
            exprs.add(Expr(mark, ED.call(null, "hash", [], [
                Expr(mark, ED.getfield(Expr(mark, ED.getvar("self")), field.name))])))
        }
        val body = Expr(mark, ED.call(null, "hash", [], [Expr(mark, ED.list(exprs))]))
        val method = CJAst.Method(
            mark,
            null, # comment
            [], # annotations
            [CJModifier.synthetic],
            [], # conditions
            "hash",
            [], # type parameters
            [CJAst.Local(mark, false, "self", null(CJAst.Type(mark, "Self", [])))],
            null(CJAst.Type(mark, "Int", [])),
            null(body))
        item.members.add(CJAst.Member.method(method))
    }

    def _synthesizeReprForClass(self, item: CJAst.Item) {
        val mark = item.mark
        var body = Expr(mark, ED.string(item.shortName + "("))
        for field in item.nonStaticFields {
            body = Expr(mark, ED.call(null, "__add", [], [
                body, Expr(mark, ED.call(null, "repr", [], [
                    Expr(mark, ED.getfield(Expr(mark, ED.getvar("self")), field.name))]))]))
        }
        body = Expr(mark, ED.call(null, "__add", [], [
            body, Expr(mark, ED.string(")"))]))
        val method = CJAst.Method(
            mark,
            null, # comment
            [], # annotations
            [CJModifier.synthetic],
            [], # conditions
            "repr",
            [], # type parameters
            [CJAst.Local(mark, false, "self", null(CJAst.Type(mark, "Self", [])))],
            null(CJAst.Type(mark, "String", [])),
            null(body))
        item.members.add(CJAst.Member.method(method))
    }

    def _synthesizeDefaultForClass(self, item: CJAst.Item) {
        val mark = item.mark
        val args = (item.nonStaticFields
            .filter(f -> f.init.isEmpty() and not f.lateinit)
            .map(f -> Expr(mark, ED.call(
                null(CJAst.Type(mark, "Default", [])), "__new", [], []))))
        val body = Expr(mark, ED.callname("__malloc", [], args))
        val method = CJAst.Method(
            mark,
            null, # comment
            [], # annotations
            [CJModifier.synthetic],
            [], # conditions
            "default",
            [], # type parameters
            [], # parameters
            null(CJAst.Type(mark, "Self", [])),
            null(body))
        item.members.add(CJAst.Member.method(method))
    }

    def _synthesizeEqForUnion(self, item: CJAst.Item) {
        throw MError("TODO derive(eq) for union", [item.mark])
    }

    def _synthesizeHashForUnion(self, item: CJAst.Item) {
        throw MError("TODO derive(hash) for union", [item.mark])
    }

    def _synthesizeReprForUnion(self, item: CJAst.Item) {
        val mark = item.mark
        val cases = List[CJAst.WhenCase].empty()
        for case_ in item.cases {
            val decls = List[CJAst.Local].empty()
            for i = 0; i < case_.types.size(); i++ {
                decls.add(CJAst.Local(mark, false, "a" + i, null))
            }
            val caseBody = if case_.types {
                var b = Expr(mark, ED.string(case_.name + "("))
                for i = 0; i < case_.types.size(); i++ {
                    if i > 0 {
                        b = Expr(mark, ED.call(null, "__add", [], [
                            b, Expr(mark, ED.string(", "))]))
                    }
                    b = Expr(mark, ED.call(null, "__add", [], [
                        b, Expr(mark, ED.call(null, "repr", [], [
                            Expr(mark, ED.getvar("a" + i))]))]))
                }
                b = Expr(mark, ED.call(null, "__add", [], [
                    b, Expr(mark, ED.string(")"))]))
                b
            } else { Expr(mark, ED.string(case_.name)) }
            cases.add(CJAst.WhenCase(
                [(mark, case_.name, decls, false)],
                caseBody))
        }
        val body = Expr(mark, ED.when_(Expr(mark, ED.getvar("self")), cases, null))
        val method = CJAst.Method(
            mark,
            null, # comment
            [], # annoatations
            [CJModifier.synthetic],
            [], # conditions
            "repr",
            [], # type parameters
            [CJAst.Local(mark, false, "self", null(CJAst.Type(mark, "Self", [])))],
            null(CJAst.Type(mark, "String", [])),
            null(body))
        item.members.add(CJAst.Member.method(method))
    }
}
