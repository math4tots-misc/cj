package cjx.notc

import cjx.parser.Mark

class NCIR {
    static val ptrSize = 4

    class Program {
        val funcs: List[Func] = []
    }

    class Var {
        val mark: Mark
        val type: Type
        val name: String
        val index: Int
    }

    class Func {
        val mark: Mark
        val returnType: Type
        val name: String
        val nparams: Int
        val locals: List[Var]
        var body: Expr = ?
        def __get_params(self): List[Var] = locals[:nparams]
    }

    union Type {
        case int

        def size(self): Int = when self {
            case int = NCIR.ptrSize
        }
    }

    class Expr: Repr {
        enum { # expression kinds
            kINT
        }

        private static val kindNames: List[String] = static_field_names!(Self, "k[A-Z]+")

        val mark: Mark
        val kind: Int
        var type: Type = ?
        var intValue: Int = ?

        def int(mark: Mark, value: Int): Self {
            val self = Self(mark, kINT)
            self.intValue = value
            self
        }

        def repr(self): String {
            val kindstr = kindNames[kind]
            switch kind {
                else = kindstr
            }
        }
    }
}
