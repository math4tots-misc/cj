package compiler.solver

import compiler.solver.CJMethodSynthesizerMixin
import compiler.CJItemKind
import compiler.solver.CJSolverBaseMixin
import cjx.parser.MError
import compiler.CJAst
import compiler.CJIR

trait CJAnnotationMixin: CJSolverBaseMixin, CJMethodSynthesizerMixin {

    def annotateMethod(self, method: CJIR.Method, annotations: List[CJAst.Annotation]) {
        for annotation in annotations {
            switch annotation.name {
                case "variadic" = { method.variadic = true }
                case "test" = { method.test = true }
                case "generic" = ()
                case "genericSelf" = ()
                else = throw MError(
                    "Unrecognized method annotation " + annotation.name.repr(), [annotation.mark])
            }
        }
    }

    def annotateField(self, field: CJIR.Field, annotations: List[CJAst.Annotation]) {
        for annotation in annotations {
            switch annotation.name {
                case "lateinit" = { field.lateinit = true }
                else = throw MError(
                    "Unrecognized field annotation " + annotation.name.repr(), [annotation.mark])
            }
        }
    }

    def annotateItem(self, item: CJAst.Item, annotations: List[CJAst.Annotation]) {
        var nullable = false
        var eq = false
        var hash = false
        var default = false
        var repr = false
        var pod = false
        for annotation in annotations {
            switch annotation.name {
                case "implicit" = ()
                case "nullable" = { nullable = true }
                case "derive" {
                    for arg in annotation.args {
                        switch arg.name {
                            case "eq" = { eq = true }
                            case "hash" = { hash = true }
                            case "default" = { default = true }
                            case "repr" = { repr = true }
                            case "pod" = { pod = true }
                            else = throw MError(
                                "Unrecognized derive " + arg.name.repr(), [arg.mark])
                        }
                    }
                }
                else = throw MError(
                    "Unrecognized item annotation " + annotation.name.repr(), [annotation.mark])
            }
        }
        if item.kind != CJItemKind.trait_ and not nullable {
            _addTraitDecl(item, "NonNull")
        }
        if eq or hash or pod {
            _addTraitDecl(item, "Eq")
            synthesizeEq(item)
        }
        if hash or pod {
            _addTraitDecl(item, "Hash")
            synthesizeHash(item)
        }
        if repr or pod {
            _addTraitDecl(item, "Repr")
            synthesizeRepr(item)
        }
        if default {
            _addTraitDecl(item, "Default")
            synthesizeDefault(item)
        }
    }

    def _addTraitDecl(self, item: CJAst.Item, traitName: String) {
        item.traitDeclarations.add(CJAst.TraitDeclaration(
            item.mark, CJAst.Trait(item.mark, traitName, []), []))
    }
}
