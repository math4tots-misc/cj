package crossj.cj;

import crossj.base.Assert;
import crossj.base.Repr;
import crossj.base.Str;
import crossj.base.Tuple;

/**
 * A cj token
 */
public final class CJToken {
    // various token types

    // general categories (1-10)
    public static final int EOF = 1;
    public static final int DOUBLE = 2;
    public static final int INT = 3;
    public static final int ID = 4;
    public static final int CHAR = 5;
    public static final int STRING = 6;
    public static final int TYPE_ID = 7;
    public static final int COMMENT = 8;
    public static final int BIGINT = 9;

    // multi-character symbols (13-31)
    public static final int DOTDOT = 13;
    public static final int MINUSMINUS = 14;
    public static final int PLUSPLUS = 15;
    public static final int RSHIFTU = 16;
    public static final int EQ = 17;
    public static final int NE = 18;
    public static final int LE = 19;
    public static final int GE = 20;
    public static final int LSHIFT = 21;
    public static final int RSHIFT = 22;
    public static final int TRUNCDIV = 23;
    public static final int POWER = 24;
    public static final int RIGHT_ARROW = 25;
    public static final int PLUS_EQ = 26;
    public static final int MINUS_EQ = 27;
    public static final int STAR_EQ = 28;
    public static final int DIV_EQ = 29;
    public static final int TRUNCDIV_EQ = 30;
    public static final int REM_EQ = 31;

    // token types in the range 32-127 are reserved for ASCII single character
    // token types.

    // keywords
    public static final int KW_DEF = 201;
    public static final int KW_CLASS = 202;
    public static final int KW_TRUE = 203;
    public static final int KW_FALSE = 204;
    public static final int KW_NULL = 205;
    public static final int KW_IF = 206;
    public static final int KW_ELSE = 207;
    public static final int KW_IMPORT = 208;
    public static final int KW_WHILE = 209;
    public static final int KW_BREAK = 210;
    public static final int KW_CONTINUE = 211;
    public static final int KW_VAR = 212;
    public static final int KW_VAL = 213;
    // public static final int KW_NEW = 214;
    public static final int KW_TRAIT = 215;
    public static final int KW_NATIVE = 216;
    public static final int KW_STATIC = 217;
    public static final int KW_PRIVATE = 218;
    public static final int KW_PUBLIC = 219;
    public static final int KW_PACKAGE = 220;
    public static final int KW_RETURN = 221;
    public static final int KW_AND = 222;
    public static final int KW_OR = 223;
    public static final int KW_IS = 224;
    public static final int KW_NOT = 225;
    public static final int KW_IN = 226;
    // public static final int KW_THEN = 227;
    public static final int KW_SWITCH = 228;
    public static final int KW_CASE = 229;
    public static final int KW_UNION = 230;
    public static final int KW_ENUM = 231;
    public static final int KW_WHEN = 232;
    public static final int KW_AS = 233;
    public static final int KW_FOR = 234;
    public static final int KW_ASYNC = 235;
    public static final int KW_AWAIT = 236;
    public static final int KW_THROW = 237;
    public static final int KW_TRY = 238;
    public static final int KW_CATCH = 239;
    public static final int KW_FINALLY = 240;

    public static final Tuple<Integer> KEYWORD_TYPES = Tuple.of(KW_DEF, KW_CLASS, KW_TRUE, KW_FALSE, KW_NULL, KW_IF,
            KW_ELSE, KW_IMPORT, KW_WHILE, KW_BREAK, KW_CONTINUE, KW_VAR, KW_VAL, /* KW_NEW, */ KW_TRAIT, KW_NATIVE,
            KW_STATIC, KW_PRIVATE, KW_PUBLIC, KW_PACKAGE, KW_RETURN, KW_AND, KW_OR, KW_IS, KW_NOT, KW_IN, /* KW_THEN, */
            KW_SWITCH, KW_CASE, KW_UNION, KW_ENUM, KW_WHEN, KW_AS, KW_FOR, KW_ASYNC, KW_AWAIT, KW_THROW, KW_TRY,
            KW_CATCH, KW_FINALLY);

    public final int type;
    public final String text;
    public final int line;
    public final int column;

    private CJToken(int type, String text, int line, int column) {
        this.type = type;
        this.text = text;
        this.line = line;
        this.column = column;
    }

    public static CJToken of(int type, String text, int line, int column) {
        return new CJToken(type, text, line, column);
    }

    public static CJToken ofInt(String text, int line, int column) {
        return of(INT, text, line, column);
    }

    public static CJToken ofDouble(String text, int line, int column) {
        return of(DOUBLE, text, line, column);
    }

    public static CJToken ofId(String text, int line, int column) {
        return of(ID, text, line, column);
    }

    @Override
    public String toString() {
        return "CJToken.of(" + typeToString(type) + ", " + Repr.reprstr(text) + ", " + line + ", " + column + ")";
    }

    @Override
    public boolean equals(Object obj) {
        if (!(obj instanceof CJToken)) {
            return false;
        }
        var b = (CJToken) obj;
        return type == b.type && text.equals(b.text) && line == b.line && column == b.column;
    }

    public static String typeToString(int type) {
        switch (type) {
            case EOF:
                return "CJToken.EOF";
            case INT:
                return "CJToken.INT";
            case DOUBLE:
                return "CJToken.DOUBLE";
            case ID:
                return "CJToken.ID";
            case CHAR:
                return "CJToken.CHAR";
            case STRING:
                return "CJToken.STRING";
            case TYPE_ID:
                return "CJToken.TYPE_ID";
            case COMMENT:
                return "CJToken.COMMENT";
            case BIGINT:
                return "CJToken.BIGINT";
            case DOTDOT:
                return "CJToken.DOTDOT";
            case MINUSMINUS:
                return "CJToken.MINUSMINUS";
            case PLUSPLUS:
                return "CJToken.PLUSPLUS";
            case RSHIFTU:
                return "CJToken.RSHIFTU";
            case EQ:
                return "CJToken.EQ";
            case NE:
                return "CJToken.NE";
            case LE:
                return "CJToken.LE";
            case GE:
                return "CJToken.GE";
            case LSHIFT:
                return "CJToken.LSHIFT";
            case RSHIFT:
                return "CJToken.RSHIFT";
            case TRUNCDIV:
                return "CJToken.TRUNCDIV";
            case POWER:
                return "CJToken.POWER";
            case RIGHT_ARROW:
                return "CJToken.RIGHT_ARROW";
            case PLUS_EQ:
                return "CJToken.PLUS_EQ";
            case MINUS_EQ:
                return "CJToken.MINUS_EQ";
            case STAR_EQ:
                return "CJToken.STAR_EQ";
            case DIV_EQ:
                return "CJToken.DIV_EQ";
            case TRUNCDIV_EQ:
                return "CJToken.TRUNCDIV_EQ";
            case REM_EQ:
                return "CJToken.REM_EQ";
            case KW_DEF:
                return "CJToken.KW_DEF";
            case KW_CLASS:
                return "CJToken.KW_CLASS";
            case KW_TRUE:
                return "CJToken.KW_TRUE";
            case KW_FALSE:
                return "CJToken.KW_FALSE";
            case KW_NULL:
                return "CJToken.KW_NULL";
            case KW_IF:
                return "CJToken.KW_IF";
            case KW_ELSE:
                return "CJToken.KW_ELSE";
            case KW_IMPORT:
                return "CJToken.KW_IMPORT";
            case KW_WHILE:
                return "CJToken.KW_WHILE";
            case KW_BREAK:
                return "CJToken.KW_BREAK";
            case KW_CONTINUE:
                return "CJToken.KW_CONTINUE";
            case KW_VAR:
                return "CJToken.KW_VAR";
            case KW_VAL:
                return "CJToken.KW_VAL";
            // case KW_NEW:
            // return "CJToken.KW_NEW";
            case KW_TRAIT:
                return "CJToken.KW_TRAIT";
            case KW_NATIVE:
                return "CJToken.KW_NATIVE";
            case KW_STATIC:
                return "CJToken.KW_STATIC";
            case KW_PRIVATE:
                return "CJToken.KW_PRIVATE";
            case KW_PUBLIC:
                return "CJToken.KW_PUBLIC";
            case KW_PACKAGE:
                return "CJToken.KW_PACKAGE";
            case KW_RETURN:
                return "CJToken.KW_RETURN";
            case KW_AND:
                return "CJToken.KW_AND";
            case KW_OR:
                return "CJToken.KW_OR";
            case KW_IS:
                return "CJToken.KW_IS";
            case KW_NOT:
                return "CJToken.KW_NOT";
            case KW_IN:
                return "CJToken.KW_IN";
            // case KW_THEN:
            // return "CJToken.KW_THEN";
            case KW_SWITCH:
                return "CJToken.KW_SWITCH";
            case KW_CASE:
                return "CJToken.KW_CASE";
            case KW_UNION:
                return "CJToken.KW_UNION";
            case KW_ENUM:
                return "CJToken.KW_ENUM";
            case KW_WHEN:
                return "CJToken.KW_WHEN";
            case KW_AS:
                return "CJToken.KW_AS";
            case KW_FOR:
                return "CJToken.KW_FOR";
            case KW_ASYNC:
                return "CJToken.KW_ASYNC";
            case KW_AWAIT:
                return "CJToken.KW_AWAIT";
            case KW_THROW:
                return "CJToken.KW_THROW";
            case KW_TRY:
                return "CJToken.KW_TRY";
            case KW_CATCH:
                return "CJToken.KW_CATCH";
            case KW_FINALLY:
                return "CJToken.KW_FINALLY";
            case '\n':
                return "'\\n'";
            default:
                if (type >= 32 && type <= 127) {
                    return "'" + Str.fromCodePoint(type) + "'";
                } else {
                    return "Unknown(" + type + ")";
                }
        }
    }

    public static String keywordTypeToString(int type) {
        var name = typeToString(type);
        Assert.withMessage(name.startsWith("CJToken.KW_"), name);
        return name.substring("CJToken.KW_".length(), name.length()).toLowerCase();
    }

    public static int charLiteralToInt(String rawText, CJMark... marks) {
        switch (rawText) {
            case "'\\''":
                return (int) '\'';
            case "'\\\"'":
                return (int) '"';
            case "'\\\\'":
                return (int) '\\';
            case "'\\n'":
                return (int) '\n';
            case "'\\t'":
                return (int) '\t';
            case "'\\r'":
                return (int) '\r';
            case "'\\f'":
                return (int) '\f';
            case "'\\0'":
                return (int) '\0';
        }
        if (rawText.length() >= 3 && rawText.charAt(0) == '\'' && rawText.charAt(rawText.length() - 1) == '\'') {
            var codePoint = rawText.codePointAt(1);
            if (Character.toString(codePoint).length() + 2 == rawText.length()) {
                return codePoint;
            }
        }
        throw CJError.of("Could not convert character literal to int: " + rawText, marks);
    }
}
