package cj

import cj.Error

native class IO {
    def println[T?: ToString](t: T) = js!(Unit, "console.log(", t.toString(), ")")
    def print[T?: ToString](t: T)
    def eprintln[T?: ToString](t: T) = js!(Unit, "console.error(", t.toString(), ")")
    def panic[T?: ToString](t: T): NoReturn = throw Error(t.toString())

    def debug[T](t: T) = js!(Unit, "console.log(", t, ")")
    def printstr(s: String) = js!(
        Unit,
        "(typeof process!=='undefined')?process.stdout.write(",s,"):console.log(", s, ")")

    ## Read all of stdin as a string
    def input(): String = js!(String, "require('fs').readFileSync(0,{encoding:'utf-8'})")
}
