package compiler.solver

import compiler.CJError
import compiler.CJAst
import compiler.CJIR

trait CJAnnotationMixin {

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
}
