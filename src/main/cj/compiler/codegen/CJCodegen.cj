package compiler.codegen

import compiler.codegen.CJExprgen
import compiler.CJIR.ItemDef
import compiler.CJIR.Method
import www.sourcemap.JSBuilder

class CJCodegen {
    val itemMap: Map[String, ItemDef] = MapOf()
    val out: JSBuilder = JSBuilder()
    var egen: CJExprgen = ?

    def emit(self, items: List[ItemDef]): JSBuilder {
        out.str("(function(){\n'use strict';\n")
        for item in items {
            itemMap[item.name] = item
        }
        egen = CJExprgen(itemMap)
        for item in items {
            emitItem(item)
        }
        out.str("})();")
        out
    }

    def trMetaName(itemName: String): String = "MC$" + itemName.replace(".", "$")
    def trMethodName(methodName: String): String = "M$" + methodName
    def trLVarName(localVarName: String): String = "L$" + localVarName
    def trTVarName(typeVarName: String): String = "TV$" + typeVarName

    def emitItem(self, item: ItemDef) {
        val jsItemName = trMetaName(item.name)
        out.str("class " + jsItemName + "{\n")
        for method in item.methods {
            emitMethod(item, method)
        }
        out.str("}\n")
    }

    def emitMethod(self, item: ItemDef, method: Method) {
        if method.body.isEmpty() {
            return ()
        }
        val body = method.body.get()
        val jsMethodName = trMethodName(method.name)
        val tparams = method.typeParameters
        val params = method.parameters
        val jsParamNames = (
            tparams.map(tp -> trTVarName(tp.name)) + params.map(p -> trLVarName(p.name)))
        out.str(jsMethodName + "(" + ",".join(jsParamNames) + "){")
        val jsBody = egen.gen(body)
        jsBody.emitSet(out, "return ")
        out.str("}\n")
    }
}
