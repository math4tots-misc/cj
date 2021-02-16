package cjx.xx.llir

import cjx.xx.llir.XXLLIRType
import cjx.xx.XXMark
import cjx.xx.llir.XXLLIRLocal

@derive(new)
class XXLLIRLocals {
    val list: List[XXLLIRLocal] = []

    def add(
            self,
            mark: XXMark,
            modifiers: List[String],
            name: String,
            type: XXLLIRType): XXLLIRLocal {
        val id = list.size()
        val local = XXLLIRLocal(mark, id, modifiers, name, type)
        list.add(local)
        local
    }
}
