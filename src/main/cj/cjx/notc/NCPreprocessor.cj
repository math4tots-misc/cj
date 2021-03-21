package cjx.notc

import cjx.parser.Mark
import cjx.notc.NCLexer
import cj.FS
import cjx.notc.NCError
import cjx.notc.NCToken

class NCPreprocessor {
    val sourceRoot: String
    val includedPaths: Set[String] = SetOf()

    def lex(self, filepath: String, contents: String): List[NCToken] {
        process(filepath, NCLexer.lex(filepath, contents))
    }

    def process(self, filepath: String, input: List[NCToken]): List[NCToken] {
        val output: List[NCToken] = []
        _process(filepath, input, output)
        output
    }

    def _process(self, filepath: String, input: List[NCToken], output: List[NCToken]) {
        for i = 0; i < input.size(); i++ {
            if input[i].type == '#' {
                i++
                if input[i].type != NCToken.tID and input[i].stringValue != "include" {
                    throw NCError(
                        "Expected 'include' but got " + input[i],
                        [Mark(filepath, input[i].line, input[i].column)])
                }
                i++
                if input[i].type != NCToken.tSTRING {
                    throw NCError(
                        "Expected string literal but got " + input[i],
                        [Mark(filepath, input[i].line, input[i].column)])
                }
                val includePath = input[i].stringValue
                i++
                if input[i].type != '\n' {
                    throw NCError(
                        "Expected newline but got " + input[i],
                        [Mark(filepath, input[i].line, input[i].column)])
                }
                if includePath not in includedPaths {
                    includedPaths.add(includePath)
                    val includeContents = FS.readFile(FS.join(sourceRoot, includePath))
                    _process(includePath, NCLexer.lex(includePath, includeContents), output)
                }
            } else {
                output.add(input[i])
            }
        }
    }
}
