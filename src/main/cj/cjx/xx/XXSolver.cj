package cjx.xx

import cj.StringBuilder
import cjx.xx.llir.XXLLIRClass
import cjx.xx.XXError
import cjx.xx.XXMark
import cjx.xx.XXAst
import cjx.xx.llir.XXLLIRType

@derive(new)
class XXSolver {
    val classMap: Map[String, XXLLIRClass] = Map()
    val templateMap: Map[String, Tuple[Scope, XXAst.Item]] = Map()
    val traitMap: Map[String, Tuple[Scope, String, XXAst.Item]] = Map()
    val todos: List[List[Fn[Unit]]] = []

    def todo(self, level: Int, f: Fn[Unit]) {
        while level >= todos.size() {
            todos.add([])
        }
        todos[level].add(f)
    }

    def solve(self) {
        var repeat = true
        while repeat {
            var i = 0
            while i < todos.size() and not todos[i] {
                i++
            }
            if i < todos.size() {
                todos[i].pop().call()
            } else {
                repeat = false
            }
        }
    }

    @derive(repr)
    union Data {
        case number(Double)
        case string(String)
        case fullName(String)
        case type(XXLLIRType)
    }

    class Scope {
        val parent: Nullable[Scope]
        val map: Map[String, Data] = Map()
        def new(p: Self): Self = __malloc(null(p))
        def newRoot(): Self = {
            val self = __malloc(null)
            self.map["NoReturn"] = Data.type(XXLLIRType.noreturn())
            self.map["Unit"] = Data.type(XXLLIRType.unit())
            self.map["Bool"] = Data.type(XXLLIRType.bool())
            self.map["Int"] = Data.type(XXLLIRType.int())
            self.map["Double"] = Data.type(XXLLIRType.double())
            self
        }
    }

    def scopeSet(self, mark: XXMark, scope: Scope, key: String, value: Data) {
        if key in scope.map {
            throw XXError("Name '" + key + "' already defined in this scope", [mark])
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

    def scopeGet(self, mark: XXMark, scope: Scope, key: String): Data {
        if null(value) = scopeGetOrNull(scope, key) {
            value
        } else {
            throw XXError("Name '" + key + "' not found in this scope", [mark])
        }
    }

    def scopeGetString(self, mark: XXMark, scope: Scope, key: String): String {
        val data = scopeGet(mark, scope, key)
        when data {
            case string(value) = value
            else = throw XXError("Expected string but got " + data.repr(), [mark])
        }
    }

    def checkNoTypeArgs(self, astType: XXAst.Type) {
        if astType.args {
            throw XXError("Template arguments are not allowed here", [astType.mark])
        }
    }

    ## Solve a compile time expression
    def solveCTExpr(self, scope: Scope, expr: XXAst.Expr): Data {
        when expr.data {
            case type(t) = Data.type(solveType(scope, t))
            case int(i) = Data.number(i)
            else = throw XXError("Expected compile time expression", [expr.mark])
        }
    }

    def solveType(self, scope: Scope, astType: XXAst.Type): XXLLIRType {
        val data = scopeGet(astType.mark, scope, astType.name)
        when data {
            case type(type) = {
                checkNoTypeArgs(astType)
                type
            }
            case fullName(fullName) = {
                val args = astType.args.map(arg -> solveCTExpr(scope, arg))
                val reifiedName = getReifiedName(astType.mark, fullName, args)
                if null(cls) = classMap.getOrNull(reifiedName) {
                    XXLLIRType.klass(cls.name)
                } else if null((itemScope, astItem)) = templateMap.getOrNull(fullName) {
                    reifyItem(astType.mark, reifiedName, itemScope, astItem, args)
                    if null(cls) = classMap.getOrNull(reifiedName) {
                        XXLLIRType.klass(cls.name)
                    } else {
                        throw XXError(
                            "" + reifiedName + " is probably not a class", [astType.mark])
                    }
                } else {
                    throw XXError("Item " + fullName + " not found", [astType.mark])
                }
            }
            else = throw XXError(data.repr() + " is not a type", [astType.mark])
        }
    }

    def reifyItem(
            self,
            mark: XXMark,
            reifiedName: String,
            itemScope: Scope,
            astItem: XXAst.Item,
            args: List[Data]) {
        val reifiedScope = Scope(itemScope)
        val expected = astItem.templateParameters.size()
        if expected != args.size() {
            throw XXError(
                "Expected " + expected + " template arguments but got " + args.size(), [mark])
        }
        for i = 0; i < expected; i++ {
            scopeSet(mark, reifiedScope, astItem.templateParameters[i].name, args[i])
        }
        addItem(reifiedScope, reifiedName, astItem)
    }

    def getReifiedName(self, mark: XXMark, baseName: String, args: List[Data]): String {
        val sb = StringBuilder()
        sb.add(baseName)
        if args {
            sb.add("$t$")
            for arg in args {
                when arg {
                    case number(d) = {
                        val i = d.toInt()
                        if i < 0 {
                            sb.add("im" + -i)
                        } else {
                            sb.add("i" + i)
                        }
                    }
                    case type(t) = when t {
                        case noreturn = "N"
                        case void = "V"
                        case unit = "U"
                        case bool = "Z"
                        case int = "I"
                        case double = "D"
                        case klass(clsname) = classMap[clsname].id
                    }
                    else = throw XXError(arg.repr() + " is not a valid template argument", [mark])
                }
            }
        }
        sb.toString()
    }

    def solveCTBoolExpr(self, scope: Scope, expr: XXAst.Expr): Bool {
        val data = solveCTExpr(scope, expr)
        when data {
            case number(d) = (d != 0)
            case string(s) = s.size() != 0
            else = throw XXError(
                "Expected bool expression but got " + data, [expr.mark])
        }
    }

    def solveClassOrInterfaceType(self, scope: Scope, astType: XXAst.Type): String {
        val type = solveType(scope, astType)
        when type {
            case klass(clsname) = clsname
            else = throw XXError("Expected class or interface type", [astType.mark])
        }
    }

    def addFile(self, file: XXAst.File) {
        val packageName = file.packageName
        val fileScope = Scope.newRoot()
        scopeSet(file.mark, fileScope, "@package", Data.string(packageName))
        for import_ in file.imports {
            scopeSet(import_.mark, fileScope, import_.alias, Data.fullName(import_.fullName))
        }
        for astItem in file.items {
            val itemFullName = packageName + "." + astItem.shortName
            scopeSet(astItem.mark, fileScope, astItem.shortName, Data.fullName(itemFullName))
        }
        for astItem in file.items {
            val itemFullName = packageName + "." + astItem.shortName
            addItem0(fileScope, itemFullName, astItem)
        }
    }

    private def addItem0(self, outerScope: Scope, fullName: String, astItem: XXAst.Item) {
        if astItem.templateParameters {
            templateMap[fullName] = (outerScope, astItem)
        } else {
            val itemScope = Scope(outerScope)
            addItem(itemScope, fullName, astItem)
        }
    }

    private def addItem(self, itemScope: Scope, itemName: String, astItem: XXAst.Item) {
        for nestedItem in astItem.nestedItems {
            val nestedItemName = itemName + "$" + nestedItem.shortName
            addItem0(itemScope, nestedItemName, nestedItem)
        }
        when astItem.kind {
            case class_ = addClass(itemScope, itemName, astItem)
            case trait_ = { traitMap[itemName] = (itemScope, itemName, astItem) }
            case union_ = throw XXError("TODO addItem union", [astItem.mark])
            case interface_ = throw XXError("TODO addItem interface", [astItem.mark])
        }
    }

    private def addClass(self, classScope: Scope, className: String, classItem: XXAst.Item) {
        scopeSet(classItem.mark, classScope, "Self", Data.fullName(className))
        val id = classMap.size()
        val cls = XXLLIRClass(classItem.mark, id, classItem.modifiers, className)
        classMap[className] = cls
    }
}
