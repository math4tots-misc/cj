package cj

@derive(repr)
union Endian: Eq, Hash {
    case little
    case big
    def __eq(self, other: Self): Bool = self is other
    def hash(self): Int = __tag()
    def isLittle(self): Bool = self is little
    def isBig(self): Bool = self is big
}
