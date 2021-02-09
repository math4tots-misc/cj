package cjx.jl1

import cjx.jl1.JLIRTemplateArgument
import cjx.jl1.JLIRFieldRef
import cjx.jl1.JLIRMethodRef
import cjx.jl1.JLError
import cjx.jl1.JLIRField
import cjx.jl1.JLIRMethod
import cjx.jl1.JLType
import cjx.jl1.JLMark

@derive(new)
class JLIRClass {
    val mark: JLMark
    val id: Int # global unique identifier
    val modifiers: List[String]
    val _isInterface: Bool
    val name: String  # fully qualified name
    val interfaces: List[JLIRClass] = []
    val fields: List[JLIRField] = []
    val fieldMap: Map[String, JLIRField] = Map()
    val methods: List[JLIRMethod] = []
    val methodMap: Map[String, JLIRMethod] = Map()
    val templateArguments: Map[String, JLIRTemplateArgument] = Map()

    def isNative(self): Bool = "native" in modifiers
    def toJVMName(self): String = name.replace(".", "/")
    def isInterface(self): Bool = _isInterface

    def addField(self, field: JLIRField) {
        fields.add(field)
        fieldMap[field.name] = field
    }

    def addMethod(self, method: JLIRMethod) {
        methods.add(method)
        methodMap[method.name] = method
    }

    def getDeclaredMethod(self, name: String): JLIRMethod = methodMap[name]

    def getFieldRef(self, mark: JLMark, name: String): JLIRFieldRef = {
        if null(fieldref) = getFieldRefOrNull(name) {
            fieldref
        } else {
            throw JLError("Field " + name + " not found in class " + self.name, [mark])
        }
    }

    def getFieldRefOrNull(self, name: String): Nullable[JLIRFieldRef] = {
        if null(field) = fieldMap.getOrNull(name) {
            null(JLIRFieldRef(self, field))
        } else {
            null
        }
    }

    def getMethodRef(self, mark: JLMark, name: String): JLIRMethodRef = {
        if null(methoddref) = getMethodRefOrNull(name) {
            methoddref
        } else {
            throw JLError("Method " + name + " not found in class " + self.name, [mark])
        }
    }

    def getMethodRefOrNull(self, name: String): Nullable[JLIRMethodRef] = {
        if null(method) = methodMap.getOrNull(name) {
            null(JLIRMethodRef(self, method))
        } else {
            for iface in interfaces {
                if null(methodref) = iface.getMethodRefOrNull(name) {
                    return null(methodref)
                }
            }
            null
        }
    }
}
