package compiler.solver

import compiler.CJError
import compiler.CJMark
import compiler.solver.CJData

class CJScope {
    static val autoImportedNames: List[String] = ["cj.Any", "cj.Unit", "cj.NoReturn",
        "cj.Nullable", "cj.NonNull", "cj.Bool", "cj.Char", "cj.Int", "cj.Double", "cj.String",
        "cj.BigInt", "cj.Repr", "cj.ToBool", "cj.ToChar", "cj.ToInt", "cj.ToDouble",
        "cj.ToString", "cj.ToList", "cj.List", "cj.Map", "cj.Set", "cj.Assert", "cj.IO",
        "cj.Iterable", "cj.Iterator", "cj.Promise", "cj.Eq", "cj.Ord", "cj.Hash", "cj.Fn0",
        "cj.Fn1", "cj.Fn2", "cj.Fn3", "cj.Fn4", "cj.Tuple2", "cj.Tuple3", "cj.Tuple4", "cj.Default"]

    static val root: Self = newRoot()

    val parent: Self?
    val map: Map[String, CJData] = Map([])
    def(parent: Self): Self = __malloc(null(parent))
    private def newRoot(): Self = {
        val self = __malloc(null)
        for name in autoImportedNames {
            Assert.that(name.startsWith("cj."))
            self.map[name["cj.".size():]] = CJData.fullName(name)
        }
        self
    }
    def newFileScope(): Self = Self(root)
    def set(self, mark: CJMark, key: String, data: CJData) {
        if key in map {
            throw CJError(key.repr() + " already defined in this scope", [mark])
        }
        map[key] = data
    }
    def getOrNull(self, key: String): CJData? {
        var scope = self
        while true {
            if val data = scope.map.getOrNull(key) {
                return null(data)
            } else if val p = scope.parent {
                scope = p
            } else {
                return null
            }
        }
    }
    def __contains(self, key: String): Bool = getOrNull(key).isPresent()
    def get(self, mark: CJMark, key: String): CJData {
        if val data = getOrNull(key) {
            data
        } else {
            throw CJError(key.repr() + " not defined in this scope", [mark])
        }
    }
    def dumpKeys(self): List[List[String]] {
        var scope = self
        val list: List[List[String]] = []
        while true {
            list.add(scope.map.keys().toList())
            if val parent = scope.parent {
                scope = parent
            } else { return list }
        }
    }
}
