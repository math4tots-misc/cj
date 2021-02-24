package compiler.solver

import compiler.CJItemKind
import compiler.solver.CJSolverBaseMixin
import compiler.CJError
import compiler.CJAst
import compiler.CJIR

trait CJAnnotationMixin: CJSolverBaseMixin {

    def annotateMethod(self, method: CJIR.Method, annotations: List[CJAst.Annotation]) {
        for annotation in annotations {
            switch annotation.name {
                case "variadic" = { method.variadic = true }
                case "test" = { method.test = true }
                case "generic" = ()
                case "genericSelf" = ()
                else = throw CJError(
                    "Unrecognized method annotation " + annotation.name.repr(), [annotation.mark])
            }
        }
    }

    def annotateField(self, field: CJIR.Field, annotations: List[CJAst.Annotation]) {
        for annotation in annotations {
            switch annotation.name {
                case "lateinit" = { field.lateinit = true }
                else = throw CJError(
                    "Unrecognized field annotation " + annotation.name.repr(), [annotation.mark])
            }
        }
    }

    def annotateItem(self, item: CJAst.Item, annotations: List[CJAst.Annotation]) {
        var nullable = false
        for annotation in annotations {
            switch annotation.name {
                case "implicit" = ()
                case "nullable" = { nullable = true }
                case "derive" {
                    for arg in annotation.args {
                        switch arg.name {
                            case "hash" = ()
                            case "default" = ()
                            case "repr" = ()
                            case "pod" = ()
                            else = throw CJError(
                                "Unrecognized derive " + arg.name.repr(), [arg.mark])
                        }
                    }
                }
                else = throw CJError(
                    "Unrecognized item annotation " + annotation.name.repr(), [annotation.mark])
            }
        }
        if item.kind != CJItemKind.trait_ and not nullable {
            item.traitDeclarations.add(CJAst.TraitDeclaration(
                item.mark,
                CJAst.Trait(item.mark, "NonNull", []),
                []))
        }
    }
}
