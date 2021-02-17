package cjx.ez

import cjx.ez.EZExprSolver
import cjx.ez.EZError
import cjx.ez.EZAst
import cjx.ez.EZMark
import cjx.ez.EZIR

class EZSolver {
    val classMap: Map[String, EZIR.Class] = Map()
    val todos: List[List[Fn[Unit]]] = []

    def todo(self, level: Int, f: Fn[Unit]) {
        while level >= todos.size() {
            todos.add([])
        }
        todos[level].add(f)
    }

    def solve(self) {
        solveLevel(1000)
    }

    def solveLevel(self, level: Int) {
        var repeat = true
        while repeat {
            var i = 0
            while i < todos.size() and i < level and not todos[i] {
                i++
            }
            if i < todos.size() and i < level {
                todos[i].pop().call()
            } else {
                repeat = false
            }
        }
    }

    def newClass(self, mark: EZMark, modifiers: List[String], name: String): EZIR.Class {
        val id = classMap.size()
        val cls = EZIR.Class(mark, id, modifiers, name)
        classMap[name] = cls
        cls
    }

    @derive(repr)
    union Data {
        case string(String)
        case fullName(String)
        case type(EZIR.Type)
        case local(EZIR.Local)
    }

    class Scope {
        val parent: Nullable[Scope]
        val map: Map[String, Data] = Map()
        def __new(p: Self): Self = __malloc(null(p))
        def newRoot(): Self = {
            val self = __malloc(null)
            self.map["NoReturn"] = Data.fullName("jl1.NoReturn")
            self.map["Unit"] = Data.fullName("jl1.Unit")
            self.map["Bool"] = Data.fullName("jl1.Bool")
            self.map["Int"] = Data.fullName("jl1.Int")
            self.map["Double"] = Data.fullName("jl1.Double")
            self
        }
    }

    def scopeSet(self, mark: EZMark, scope: Scope, key: String, value: Data) {
        if key in scope.map {
            throw EZError("Name '" + key + "' already defined in this scope", [mark])
        }
        scope.map[key] = value
    }

    def scopeGetOrNull(self, var scope: Scope, key: String): Nullable[Data] {
        while true {
            if null(value) = scope.map.getOrNull(key) {
                return null(value)
            }
            if null(parent) = scope.parent {
                scope = parent
            } else {
                return null
            }
        }
    }

    def scopeGet(self, mark: EZMark, scope: Scope, key: String): Data {
        if null(value) = scopeGetOrNull(scope, key) {
            value
        } else {
            throw EZError("Name '" + key + "' not found in this scope", [mark])
        }
    }

    def solveType(self, scope: Scope, astType: EZAst.Type): EZIR.Type {
        val args = astType.args.map(arg -> solveType(scope, arg))
        val data = scopeGet(astType.mark, scope, astType.name)
        when data {
            case fullName(fullName) = {
                getType(astType.mark, fullName, args)
            }
            case type(type) = {
                if args {
                    throw EZError(type.repr() + " does not accept type arguments", [astType.mark])
                }
                type
            }
            else = throw EZError(data.repr() + " is not a type", [astType.mark])
        }
    }

    def getType(self, mark: EZMark, fullName: String, args: List[EZIR.Type]): EZIR.Type {
        if args {
            throw EZError("Type arguments not yet supported", [mark])
        }
        if null(cls) = classMap.getOrNull(fullName) {
            EZIR.Type(cls.name)
        } else {
            throw EZError("Type " + fullName + " not found", [mark])
        }
    }

    def getNoReturnType(self): EZIR.Type {
        getType(Default(), "jl1.NoReturn", [])
    }

    def getUnitType(self): EZIR.Type {
        getType(Default(), "jl1.Unit", [])
    }

    def getBoolType(self): EZIR.Type {
        getType(Default(), "jl1.Bool", [])
    }

    def getIntType(self): EZIR.Type {
        getType(Default(), "jl1.Int", [])
    }

    def getDoubleType(self): EZIR.Type {
        getType(Default(), "jl1.Double", [])
    }

    def addFile(self, file: EZAst.File) {
        val scope = Scope.newRoot()
        for item in file.items {
            when item {
                case class_(astcls) = {
                    addClass(scope, file.packageName, astcls)
                }
            }
        }
    }

    def addClass(self, outerScope: Scope, packageName: String, astcls: EZAst.Class) {
        val fullName = packageName + "." + astcls.shortName
        val ircls = newClass(astcls.mark, astcls.modifiers, fullName)
        scopeSet(astcls.mark, outerScope, astcls.shortName, Data.fullName(fullName))
        val classScope = Scope(outerScope)
        for member in astcls.members {
            addMember(ircls, classScope, member)
        }
    }

    class LocalFactory {
        var nextId = 0
        def newLocal(self, mark: EZMark, name: String, type: EZIR.Type): EZIR.Local {
            val id = nextId
            nextId = nextId + 1
            EZIR.Local(mark, id, name, type)
        }
    }

    def addMember(self, ircls: EZIR.Class, classScope: Scope, member: EZAst.Member) {
        when member {
            case field(astField) = addField(ircls, classScope, astField)
            case method(astMethod) = addMethod(ircls, classScope, astMethod)
        }
    }

    def addField(self, ircls: EZIR.Class, classScope: Scope, astField: EZAst.Field) {
        todo(0, () -> {
            val fieldType = solveType(classScope, astField.type)
            val irField = EZIR.Field(
                astField.mark, astField.modifiers, astField.name, fieldType)
            ircls.addField(irField)
        })
    }

    def addMethod(self, ircls: EZIR.Class, classScope: Scope, astMethod: EZAst.Method) {
        todo(0, () -> {
            val localFactory = LocalFactory()
            val parameters = astMethod.parameters.map(p ->
                localFactory.newLocal(p.mark, p.name, solveType(classScope, p.type.get())))
            val returnType = solveType(classScope, astMethod.returnType)
            val irMethod = EZIR.Method(
                astMethod.mark,
                astMethod.modifiers,
                astMethod.name,
                parameters,
                returnType)
            ircls.addMethod(irMethod)
            if null(astBody) = astMethod.body {
                todo(2, () -> {
                    val methodScope = Scope(classScope)
                    for parameter in parameters {
                        scopeSet(
                            parameter.mark, methodScope, parameter.name, Data.local(parameter))
                    }
                    val exprSolver = EZExprSolver(self, localFactory, methodScope)
                    val irBody = exprSolver.solve(astBody, null(returnType))
                    irMethod.body = null(irBody)
                })
            }
        })
    }
}
