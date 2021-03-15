package cjx.binaryen

import cj.Uint8Array

native class Binaryen {
    def __get_none(): Type = js!(Type, "binaryen.none")
    def __get_i32(): Type = js!(Type, "binaryen.i32")
    def __get_i64(): Type = js!(Type, "binaryen.i64")
    def __get_f32(): Type = js!(Type, "binaryen.f32")
    def __get_f64(): Type = js!(Type, "binaryen.f64")
    def __get_auto(): Type = js!(Type, "binaryen.auto")
    def __get_unreachable(): Type = js!(Type, "binaryen.unreachable")

    def createType(types: List[Type]): Type = js!(Type, "binaryen.createType(", types, ")")

    native class Module {
        def(): Self = js!(Self, "new binaryen.Module()")
        def __get_local(self): ModuleLocal = js!(ModuleLocal, self, ".local")
        def __get_global(self): ModuleGlobal = js!(ModuleGlobal, self, ".global")
        def __get_i32(self): ModuleI32 = js!(ModuleI32, self, ".i32")
        def __get_i64(self): ModuleI64 = js!(ModuleI64, self, ".i64")
        def return_(self, value: Expression): Expression = js!(
            Expression, self, ".return(", value, ")")
        def emitText(self): String = js!(String, self, ".emitText()")
        def emitBinary(self): Uint8Array = js!(Uint8Array, self, ".emitBinary()")
        def optimize(self) = js!(Unit, self, ".optimize()")
        def validate(self): Bool = js!(Bool, self, ".validate()")
        def dispose(self) = js!(Unit, self, ".dispose()")
        def addFunction(
                self,
                name: String,
                params: Type,
                results: Type,
                vars: List[Type],
                body: Expression): Function = js!(
                    Function,
                    self, ".addFunction(", name, ",", params, ",", results, ",", vars, ",", body, ")")
        def addFunctionExport(self, internalName: String, externalName: String) = js!(
            Unit, self, ".addFunctionExport(", internalName, ",", externalName, ")")
    }
    native class ModuleLocal {
        def get(self, index: Int, type: Type): Expression = js!(
            Expression, self, ".get(", index, ",", type, ")")
        def set(self, index: Int, value: Expression): Expression = js!(
            Expression, self, ".set(", index, ",", value, ")")
        def tee(self, index: Int, value: Expression): Expression = js!(
            Expression, self, ".tee(", index, ",", value, ")")
    }
    native class ModuleGlobal {
        def get(self, name: String, type: Type): Expression = js!(
            Expression, self, ".get(", name, ",", type, ")")
        def set(self, name: String, value: Expression): Expression = js!(
            Expression, self, ".set(", name, ",", value, ")")
    }
    trait IntOps {
        def add(self, left: Expression, right: Expression): Expression = js!(
            Expression, self, ".add(", left, ",", right, ")")
    }
    native class ModuleI32 : IntOps {}
    native class ModuleI64 : IntOps {}
    native class Function {}
    native class Expression {}
    native class Type {}
}
