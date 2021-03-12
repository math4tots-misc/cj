package cj

native class Argv {
    def(): List[String] = js!(List[String], "(typeof process===undefined)?[]:process.argv.slice(2)")
}
