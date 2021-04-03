package uu.main

import cj.Argv
import uu.UUC

class Compiler {
    def main() {
        val ctx = UUC()
        ctx.addSourceRoot("main")
        ctx.load(Argv())
    }
}
