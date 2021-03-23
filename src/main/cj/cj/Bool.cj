package cj

native class Bool: ToBool, Repr, Hash {
    def toBool(self): Self = self
    def repr(self): String = if self { "true" } else { "false" }
    def __eq(self, other: Self): Bool = self is other

    ## follow Java's Boolean.hashCode
    def hash(self): Int = if self { 1231 } else { 1237 }
}
