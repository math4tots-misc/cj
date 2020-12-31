package crossj.cj.main;

import crossj.base.IO;
import crossj.cj.CJLexer;

public final class LexerMain {

    public static void main(String[] args) {
        var input = IO.readStdin();
        var tokens = CJLexer.lex(input).get();
        for (var token : tokens) {
            IO.println(token);
        }
    }
}
