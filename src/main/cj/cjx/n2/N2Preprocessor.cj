package cjx.n2

import cjx.parser.Mark
import cjx.n2.N2Lexer
import cj.FS
import cjx.n2.N2Error
import cjx.n2.N2Token

class N2Preprocessor {
    val sourceRoot: String
    val includedPaths: Set[String] = SetOf()

    def lex(self, filepath: String, contents: String): List[N2Token] {
        process(filepath, N2Lexer.lex(filepath, contents))
    }

    def process(self, filepath: String, input: List[N2Token]): List[N2Token] {
        val output: List[N2Token] = []
        _process(filepath, input, output)
        output
    }

    def _process(self, filepath: String, input: List[N2Token], output: List[N2Token]) {
        for i = 0; i < input.size(); i++ {
            if input[i].type == '#' {
                i++
                if input[i].type != N2Token.tID and input[i].stringValue != "include" {
                    throw N2Error(
                        "Expected 'include' but got " + input[i],
                        [Mark(filepath, input[i].line, input[i].column)])
                }
                i++
                if input[i].type != N2Token.tSTRING {
                    throw N2Error(
                        "Expected string literal but got " + input[i],
                        [Mark(filepath, input[i].line, input[i].column)])
                }
                val includePath = input[i].stringValue
                i++
                if input[i].type != '\n' {
                    throw N2Error(
                        "Expected newline but got " + input[i],
                        [Mark(filepath, input[i].line, input[i].column)])
                }
                if includePath not in includedPaths {
                    includedPaths.add(includePath)
                    val includeContents = FS.readFile(FS.join(sourceRoot, includePath))
                    _process(includePath, N2Lexer.lex(includePath, includeContents), output)
                }
            } else {
                output.add(input[i])
            }
        }
    }
}
