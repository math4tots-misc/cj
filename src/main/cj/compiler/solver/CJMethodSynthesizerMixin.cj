package compiler.solver

import compiler.CJError
import compiler.solver.CJInferTypeMixin
import compiler.CJAst

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
        val parameters = List[CJAst.Local]()
        val args = List[CJAst.Expr]()
        for member in cls.members {
            when member {
                case field(field) {
                    if not field.static_ and field.init.isEmpty() {
                        val type = if val t = field.type { t } else {
                            throw CJError("Could not infer type of field", [field.mark])
                        }
                        parameters.add(CJAst.Local(
                            field.mark,
                            false,
                            field.name,
                            null(type)))
                        args.add(CJAst.Expr(field.mark, CJAst.ExprData.getvar(field.name)))
                    }
                }
                else = ()
            }
        }
        val returnType = CJAst.Type(cls.mark, "Self", [])
        val body = CJAst.Expr(cls.mark, CJAst.ExprData.callname("__malloc", [], args))
        val method = CJAst.Method(
            cls.mark,
            null, # comment
            [], # annotations
            [], # modifiers
            [], # conditions
            "__new",
            [], # type parameters
            parameters,
            null(returnType),
            null(body))
        cls.members.add(CJAst.Member.method(method))
    }
}
