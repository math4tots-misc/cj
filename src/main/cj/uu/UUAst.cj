package uu

import cjx.parser.Mark

class UUAst {

    class File {
        val mark: Mark
        val packageName: String
        val imports: List[Import]
        val item: Item
    }

    class Import {
        val mark: Mark
        val fullName: String
        val alias: String
    }

    class Item {
        union Kind: Hash {
            case class_
            case union_
            case trait_
            case interface_
            def __eq(self, other: Self): Bool = tag!(self) is tag!(other)
            def hash(self): Int = tag!(self)
        }

        val mark: Mark
        val comment: String?
        val annotations: List[Annotation]
        val modifiers: List[Modifier]
        val kind: Kind
        val shortName: String
        val member: List[Member]
    }

    class Annotation {
        val mark: Mark
        val name: String
        val args: List[Annotation]
    }

    union Modifier: Hash {
        case native_
        case static_
        case public_
        case private_
        case async_
        case synthetic
        def __eq(self, other: Self): Bool = tag!(self) is tag!(other)
        def hash(self): Int = tag!(self)
    }

    union Member {
        case item(Item)
    }

    class Expr {
        union Kind {
            case int
        }
        val kind: Kind
        var intValue: Int = ?
    }
}
