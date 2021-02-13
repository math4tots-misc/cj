package cjx.jl1

import cjx.jl1.JLAstMethod
import cjx.jl1.JLAstType
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
    var _isUnion = false
    val name: String  # fully qualified name
    var _superClass: Nullable[JLIRClass] = null
    val interfaces: List[JLIRClass] = []
    val fields: List[JLIRField] = []
    val fieldMap: Map[String, JLIRField] = Map()
    val methods: List[JLIRMethod] = []
    val methodMap: Map[String, JLIRMethod] = Map()
    val methodTemplates: List[JLAstMethod] = []
    val methodTemplateMap: Map[String, JLAstMethod] = Map()
    var unreifiedName: String = ""
    val templateArgumentsMap: Map[String, JLIRTemplateArgument] = Map()
    val templateArgumentsList: List[JLIRTemplateArgument] = []
    val _nonStaticFields: Nullable[List[JLIRField]] = null
    var _nextLambdaId = 0

    def isNative(self): Bool = "native" in modifiers
    def toJVMName(self): String = name.replace(".", "/")
    def isInterface(self): Bool = _isInterface
    def isUnion(self): Bool = _isUnion
    def isAbstract(self): Bool = "abstract" in modifiers

    def __set_superClass(self, cls: JLIRClass) { _superClass = null(cls) }
    def __get_superClass(self): JLIRClass = _superClass.get()

    def newLambdaId(self): Int {
        val id = _nextLambdaId
        _nextLambdaId = _nextLambdaId + 1
        id
    }

    def newLambdaClassName(self): String = name + "$lambda$" + newLambdaId()

    def addField(self, field: JLIRField) {
        fields.add(field)
        fieldMap[field.name] = field
    }

    def addMethod(self, method: JLIRMethod) {
        methods.add(method)
        methodMap[method.name] = method
    }

    def addMethodTemplate(self, methodTemplate: JLAstMethod) {
        methodTemplates.add(methodTemplate)
        methodTemplateMap[methodTemplate.name] = methodTemplate
    }

    def getDeclaredMethod(self, mark: JLMark, name: String): JLIRMethod = {
        if null(method) = methodMap.getOrNull(name) {
            method
        } else {
            throw JLError("Method " + name + " not found in class " + self.name, [mark])
        }
    }

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

    def getMethodTemplateOrNull(self, name: String): Nullable[JLAstMethod] {
        if null(template) = methodTemplateMap.getOrNull(name) {
            null(template)
        } else {
            null
        }
    }

    def addTemplateArgument(self, name: String, arg: JLIRTemplateArgument) {
        templateArgumentsMap[name] = arg
        templateArgumentsList.add(arg)
    }

    def getTemplateArgumentOrNull(self, name: String): Nullable[JLIRTemplateArgument] {
        templateArgumentsMap.getOrNull(name)
    }

    def toAstType(self, mark: JLMark): JLAstType = JLAstType(mark, JLAstType.Data.klass(name, []))

    def extends(self, other: JLIRClass): Bool {
        if id == other.id {
            true
        } else if other.isInterface() {
            val stack = [self]
            while stack {
                val current = stack.pop()
                if current.id == other.id {
                    return true
                }
                stack.addAll(current.interfaces)
            }
            false
        } else {
            var current = self
            while current._superClass.isPresent() {
                current = current.superClass
                if current.id == other.id {
                    return true
                }
            }
            false
        }
    }

    def isFinal(self): Bool = "final" in modifiers
}
