package crossj.cj.js;

import java.util.function.BiConsumer;
import java.util.function.Consumer;

import crossj.base.Assert;
import crossj.base.List;
import crossj.base.Map;
import crossj.base.Pair;
import crossj.cj.CJIRClassType;
import crossj.cj.CJIRMethodCall;
import crossj.cj.CJIRReifiedMethodRef;
import crossj.cj.CJMark;

public final class CJJSOps {

    private static List<String> typedArrays = List.of("cj.Uint8Array", "cj.Int8Array", "cj.Uint16Array",
            "cj.Int16Array", "cj.Uint32Array", "cj.Int32Array", "cj.Uint64Array", "cj.Int64Array", "cj.Float32Array",
            "cj.Float64Array");

    private static List<String> dynamicBufferMethods = List.of("__new", "fromArrayBuffer", "withSize", "withCapacity",
            "empty", "fromUTF8", "ofU8s", "capacity", "size", "useLittleEndian", "resize", "getI8", "getU8", "getI16",
            "getU16", "getI32", "getU32", "getI64", "getU64", "getF32", "getF64", "getUTF8", "cut", "cutFrom", "setI8",
            "setU8", "setI16", "setU16", "setI32", "setU32", "setI64", "setU64", "setF32", "setF64", "setBuffer",
            "setUTF8", "addI8", "addU8", "addI16", "addU16", "addI32", "addU32", "addI64", "addU64", "addF32", "addF64",
            "addBuffer", "addUTF8", "toString", "repr", "__eq", "__get_buffer");

    private static List<String> dataViewMethods = List.of("__new", "fromParts", "useLittleEndian", "__get_byteLength",
            "getInt8", "getUint8", "getInt16", "getUint16", "getInt32", "getUint32", "getFloat32", "getFloat64",
            "getBigInt64", "getBigUint64", "setInt8", "setUint8", "setInt16", "setUint16", "setInt32", "setUint32",
            "setFloat32", "setFloat64", "setBigInt64", "setBigUint64");

    private static List<Pair<String, List<String>>> grandfatheredNativeMethods = List.of(
            Pair.of("cj.DataView", dataViewMethods), Pair.of("cj.DynamicBuffer", dynamicBufferMethods),
            Pair.of("cj.Range", List.of("of", "inclusive", "upto", "withStep", "iter")));

    private static List<String> nativeTruthyTypes = List.of("cj.Bool", "cj.Int", "cj.Double", "cj.String", "cj.BigInt");

    /**
     * Types that can be converted toString in the same way it would in JS.
     */
    private static List<String> nativeToStringTypes = List.of("cj.Bool", "cj.Int", "cj.Double", "cj.String",
            "cj.BigInt");

    /**
     * Types with JS supported arithmetic operations.
     *
     * Division however is treated a bit specially, so those are not automatically
     * included in this category.
     */
    private static List<String> arithmeticTypes = List.of("cj.Int", "cj.Double", "cj.BigInt");

    /**
     * Types that can be compared in JS with javascript's own comparison operators
     */
    private static List<String> nativeComparables = List.of(List.of("cj.Bool", "cj.Char", "cj.String"), arithmeticTypes)
            .flatMap(x -> x);

    /**
     * Types that can be treated like arrays in JS.
     */
    private static List<String> nativeRandomAccess = List.of(List.of("cj.List"), typedArrays).flatMap(x -> x);

    /**
     * Types that can be treated like arrays in JS.
     */
    private static List<String> nativeSliceableTypes = List
            .of(List.of("cj.String", "cj.ArrayBuffer"), nativeRandomAccess).flatMap(x -> x);

    /**
     * Types that can be iterated over natively in JS.
     */
    private static List<String> nativeIterable = List.of(List.of("cj.List", "cj.Iterator"), typedArrays)
            .flatMap(x -> x);

    public static final Map<String, Op> OPS = Map.of(
            mkpair("cj.Bool.repr", ctx -> translateParts(ctx.args, "(\"\"+", ")")),
            mkpair("cj.Bool.toBool", ctx -> ctx.args.get(0)),

            mkpair("cj.Char.toInt", ctx -> ctx.args.get(0)),
            mkpair("cj.Char.size", ctx -> translateParts(ctx.args, "((", ")<0x10000?1:2)")),
            mkpair("cj.Char.toString", ctx -> translateParts(ctx.args, "String.fromCodePoint(", ")")),

            mkpair("cj.Int.__new", ctx -> ctx.args.get(0)), mkpair("cj.Int.toChar", ctx -> ctx.args.get(0)),
            mkpair("cj.Int.toInt", ctx -> ctx.args.get(0)), mkpair("cj.Int.toDouble", ctx -> ctx.args.get(0)),
            mkpair("cj.Int.default", ctx -> CJJSBlob2.pure("0")),
            mkpair("cj.Int.__get_zero", ctx -> CJJSBlob2.pure("0")),
            mkpair("cj.Int.__get_one", ctx -> CJJSBlob2.pure("1")),
            mkpair("cj.Int.__div", ctx -> translateOp("(", ")", "/", ctx.args)),
            mkpair("cj.Int.__truncdiv", ctx -> translateParts(ctx.args, "((", "/", ")|0)")),
            mkpair("cj.Int.hash", ctx -> ctx.args.get(0)),
            mkpair("cj.Int.toBool", ctx -> translateOp("(!!", ")", "", ctx.args)),
            mkpair("cj.Int.repr", ctx -> translateOp("(\"\"+", ")", "", ctx.args)),
            mkpair("cj.Int._fromChar", ctx -> ctx.args.get(0)),
            mkpair("cj.Int.abs", ctx -> translateParts(ctx.args, "Math.abs(", ")")),
            mkpair("cj.Int.hex", ctx -> translateParts(ctx.args, "", ".toString(16).toUpperCase()")),

            mkpair("cj.Double.__new", ctx -> ctx.args.get(0)), mkpair("cj.Double.toDouble", ctx -> ctx.args.get(0)),
            mkpair("cj.Double.default", ctx -> CJJSBlob2.pure("0")),
            mkpair("cj.Double.__get_zero", ctx -> CJJSBlob2.pure("0")),
            mkpair("cj.Double.__get_one", ctx -> CJJSBlob2.pure("1")),
            mkpair("cj.Double._fromInt", ctx -> translateOp("(", "|0)", "", ctx.args)),
            mkpair("cj.Double.abs", ctx -> translateParts(ctx.args, "Math.abs(", ")")),
            mkpair("cj.Double.hash", ctx -> translateParts(ctx.args, "(10000*", ")|0")),
            mkpair("cj.Double.toInt", ctx -> translateParts(ctx.args, "((", ")|0)")),
            mkpair("cj.Double.__pow", ctx -> translateParts(ctx.args, "(", "**", ")")),
            mkpair("cj.Double.toFixed", ctx -> translateParts(ctx.args, "", ".toFixed(", ")")),
            mkpair("cj.Double.repr", ctx -> translateOp("(\"\"+", ")", "", ctx.args)),
            mkpair("cj.Double.__div", ctx -> translateOp("(", ")", "/", ctx.args)),
            mkpair("cj.Double.__truncdiv", ctx -> translateParts(ctx.args, "((", "/", ")|0)")),

            mkpair("cj.String.__add", ctx -> {
                Assert.equals(ctx.args.size(), 2);
                Assert.equals(ctx.reifiedMethodRef.getTypeArgs().size(), 1);
                var argtype = ctx.binding.apply(ctx.reifiedMethodRef.getTypeArgs().get(0));
                if (nativeToStringTypes.contains(argtype.repr())) {
                    return translateOp("(", ")", "+", ctx.args);
                } else {
                    return null;
                }
            }), mkpair("cj.String._addstr", ctx -> translateOp("(", ")", "+", ctx.args)),
            mkpair("cj.String.toString", ctx -> ctx.args.get(0)),
            mkpair("cj.String.default", ctx -> CJJSBlob2.simplestr("''", true)),
            mkpair("cj.String.toBool", ctx -> translateOp("(!!", ")", "", ctx.args)),
            mkpair("cj.String.charAt", ctx -> ensureDefined(ctx, translateParts(ctx.args, "", ".codePointAt(", ")"))),
            mkpair("cj.String.startsWith",
                    ctx -> ensureDefined(ctx, translateParts(ctx.args, "", ".startsWith(", ")"))),
            mkpair("cj.String.endsWith", ctx -> ensureDefined(ctx, translateParts(ctx.args, "", ".endsWith(", ")"))),
            mkpair("cj.String.size", ctx -> translateParts(ctx.args, "", ".length")),
            mkpair("cj.String.__mul", ctx -> translateParts(ctx.args, "", ".repeat(", ")")),
            mkpair("cj.String.replace", ctx -> translateParts(ctx.args, "", ".split(", ").join(", ")")),
            mkpair("cj.String.lower", ctx -> translateParts(ctx.args, "", ".toLowerCase()")),
            mkpair("cj.String.upper", ctx -> translateParts(ctx.args, "", ".toUpperCase()")),
            mkpair("cj.String.parseInt", ctx -> nanToNull(ctx, translateParts(ctx.args, "parseInt(", ",10)"))),
            mkpair("cj.String.parseDouble", ctx -> nanToNull(ctx, translateParts(ctx.args, "parseFloat(", ")"))),

            mkpair("cj.StringBuilder.__new", ctx -> CJJSBlob2.simplestr("[]", false)),
            mkpair("cj.StringBuilder.add", ctx -> translateParts(ctx.args, "", ".push(", ")")),
            mkpair("cj.StringBuilder.str", ctx -> translateParts(ctx.args, "", ".push(", ")")),
            mkpair("cj.StringBuilder.char", ctx -> translateParts(ctx.args, "", ".push(String.fromCodePoint(", "))")),
            mkpair("cj.StringBuilder.toString", ctx -> translateParts(ctx.args, "", ".join('')")),
            mkpair("cj.StringBuilder.default", ctx -> CJJSBlob2.simplestr("[]", false)),

            mkpair("cj.BigInt.__new", ctx -> ctx.args.get(0)),
            mkpair("cj.BigInt.default", ctx -> CJJSBlob2.simplestr("0n", true)),
            mkpair("cj.BigInt.__get_zero", ctx -> CJJSBlob2.simplestr("0n", true)),
            mkpair("cj.BigInt.__get_one", ctx -> CJJSBlob2.simplestr("1n", true)),
            mkpair("cj.BigInt.fromInt", ctx -> translateParts(ctx.args, "BigInt(", ")")),
            mkpair("cj.BigInt.fromDouble", ctx -> translateParts(ctx.args, "BigInt(", ")")),
            mkpair("cj.BigInt.fromString", ctx -> translateParts(ctx.args, "BigInt(", ")")),
            mkpair("cj.BigInt.toInt", ctx -> translateParts(ctx.args, "Number(", ")")),
            mkpair("cj.BigInt.toDouble", ctx -> translateParts(ctx.args, "Number(", ")")),
            mkpair("cj.BigInt.repr", ctx -> translateParts(ctx.args, "(", "+'n')")),
            mkpair("cj.BigInt.hex", ctx -> translateParts(ctx.args, "", ".toString(16).toUpperCase()")),
            mkpair("cj.BigInt.isNegative", ctx -> translateParts(ctx.args, "(", "<0)")),
            mkpair("cj.BigInt.ipow", ctx -> translateParts(ctx.args, "(", "**BigInt(", "))")),
            mkpair("cj.BigInt.__truncdiv", ctx -> translateParts(ctx.args, "(", "/", ")")),
            mkpair("cj.BigInt.__div", ctx -> {
                var rationalType = (CJIRClassType) ctx.e.getType();
                var method = rationalType.findMethod("__new").getMethod();
                var llmethod = new CJJSLLMethod(rationalType, method, CJJSTypeBinding.empty(rationalType));
                ctx.requestMethod.accept(llmethod);
                return translateCall(ctx.mark, "cj$math$Rational$__new", ctx.args);
            }),

            mkpair("cj.List.__new", ctx -> translateParts(ctx.args, "", "")),
            mkpair("cj.List._clearListWithSize", ctx -> translateParts(ctx.args, "Array(", ")")),
            mkpair("cj.List.toBool", ctx -> translateOp("(", ".length!==0)", "", ctx.args)),
            mkpair("cj.List.empty", ctx -> CJJSBlob2.simplestr("[]", false)),
            mkpair("cj.List.default", ctx -> CJJSBlob2.simplestr("[]", false)),
            mkpair("cj.List.add", ctx -> translateParts(ctx.args, "", ".push(", ")")),
            mkpair("cj.List.pop", ctx -> translateParts(ctx.args, "", ".pop()")),
            mkpair("cj.List.removeIndex", ctx -> translateParts(ctx.args, "", ".splice(", ", 1)[0]")),
            mkpair("cj.List.__add", ctx -> translateParts(ctx.args, "", ".concat(", ")")),
            mkpair("cj.List.map", ctx -> translateParts(ctx.args, "", ".map(", ")")),
            mkpair("cj.List.isEmpty", ctx -> translateParts(ctx.args, "(", ".length===0)")),
            mkpair("cj.List._sortByCmp", ctx -> translateParts(ctx.args, "", ".sort(", ")")),
            mkpair("cj.List.reverse", ctx -> translateParts(ctx.args, "", ".reverse()")),
            mkpair("cj.List._clearItem", ctx -> translateParts(ctx.args, "(", "[", "]=undefined)")),
            mkpair("cj.List.__eq", ctx -> {
                var typeArgs = ctx.owner.getArgs();
                Assert.equals(typeArgs.size(), 1);
                if (nativeComparables.contains(typeArgs.get(0).repr())) {
                    ctx.requestJS("cj.List.__eq0.js");
                    return translateCall(ctx.mark, "listeq0", ctx.args);
                } else {
                    return null;
                }
            }),

            mkpair("cj.Iterator.iter", ctx -> ctx.args.get(0)),

            mkpair("cj.Nullable.isPresent", ctx -> translateParts(ctx.args, "(", "!==null)")),
            mkpair("cj.Nullable.isEmpty", ctx -> translateParts(ctx.args, "(", "===null)")),

            mkpair("cj.Error.__new", ctx -> translateParts(ctx.args, "new Error(", ")")),
            mkpair("cj.Error.message", ctx -> translateParts(ctx.args, "", ".message")),

            mkpair("cj.Math.min", ctx -> translateParts(ctx.args, "Math.min(", ",", ")")),
            mkpair("cj.Math.max", ctx -> translateParts(ctx.args, "Math.max(", ",", ")")),
            mkpair("cj.Math.floor", ctx -> translateParts(ctx.args, "Math.floor(", ")")),
            mkpair("cj.Math.ceil", ctx -> translateParts(ctx.args, "Math.ceil(", ")")),
            mkpair("cj.Math.random", ctx -> translateParts(ctx.args, "Math.random()")),

            mkpair("cj.Promise.done", ctx -> ctx.args.get(0)),

            mkpair("cj.ArrayBuffer.__new", ctx -> translateParts(ctx.args, "new ArrayBuffer(", ")")),

            mkpair("cj.DynamicBuffer.capacity", ctx -> translateParts(ctx.args, "", "[0].byteLength")),
            mkpair("cj.DynamicBuffer.size", ctx -> translateParts(ctx.args, "", "[2]")),

            mkpair("cj.IO.debug", ctx -> translateCall(ctx.mark, "console.log", ctx.args)),
            mkpair("cj.IO.printlnstr", ctx -> translateCall(ctx.mark, "console.log", ctx.args)),
            mkpair("cj.IO.eprintlnstr", ctx -> translateCall(ctx.mark, "console.error", ctx.args)),
            mkpair("cj.IO.panicstr", ctx -> translateCall(ctx.mark, "new Error", ctx.args)),

            mkpair("cj.Argv.__new",
                    ctx -> CJJSBlob2.simplestr("(typeof process===undefined?[]:process.argv)", false)),

            mkpair("cj.FS.__get_sep", ctx -> CJJSBlob2.simplestr("require('path').sep", false)),
            mkpair("cj.FS.join", ctx -> translateParts(ctx.args, "require('path').join(...", ")")),
            mkpair("cj.FS.isfile", ctx -> translateParts(ctx.args, "require('fs').lstatSync(", ").isFile()")),
            mkpair("cj.FS.isdir", ctx -> translateParts(ctx.args, "require('fs').lstatSync(", ").isDirectory()")),
            mkpair("cj.FS.readFile", ctx -> translateParts(ctx.args, "require('fs').readFileSync(", ",'utf-8')")),

            mkpair("cj.Time.now", ctx -> CJJSBlob2.simplestr("(Date.now()/1000)", false)),

            mkpair("cj.JSON.parse", ctx -> translateParts(ctx.args, "JSON.parse(", ")")),
            mkpair("cj.JSON.toInt16Array", ctx -> translateParts(ctx.args, "new Int16Array(", ")")),
            mkpair("cj.JSON.toFloat32Array", ctx -> translateParts(ctx.args, "new Float32Array(", ")")),
            mkpair("cj.JSON.toFloat64Array", ctx -> translateParts(ctx.args, "new Float64Array(", ")")),
            mkpair("cj.JSON._fromList", ctx -> ctx.args.get(0)), mkpair("cj.JSON._unsafeCast", ctx -> ctx.args.get(0)),
            mkpair("cj.JSON.__setitem", ctx -> translateParts(ctx.args, "(", "[", "]=", ")")),
            mkpair("cj.JSON.__getitem", ctx -> translateParts(ctx.args, "", "[", "]")),
            mkpair("cj.JSON._fromUnit",
                    ctx -> new CJJSBlob2(ctx.args.get(0).getPrep(), out -> out.append("null"), true)),

            mkpair("cj.String.toBool", ctx -> translateOp("(!!", ")", "", ctx.args)));

    static {
        for (int i = 2; i <= 4; i++) {
            var type = "cj.Tuple" + i;
            for (int j = 0; j < i; j++) {
                int index = j;
                OPS.put(type + ".get" + j, ctx -> translateParts(ctx.args, "", "[" + index + "]"));
            }
        }

        for (int i = 0; i <= 4; i++) {
            var type = "cj.Fn" + i;
            OPS.put(type + ".call", ctx -> translateDynamicCall(ctx.mark, ctx.args));
        }

        for (var type : nativeTruthyTypes) {
            if (!type.equals("cj.Bool")) {
                var key = type + ".toBool";
                OPS.put(key, ctx -> translateParts(ctx.args, "(!!", ")"));
            }
        }

        for (var type : nativeToStringTypes) {
            var key = type + ".toString";
            if (!OPS.containsKey(key)) {
                OPS.put(key, ctx -> translateParts(ctx.args, "(''+", ")"));
            }
        }

        for (var type : arithmeticTypes) {
            OPS.put(type + ".__pos", ctx -> translateParts(ctx.args, "", ""));
            OPS.put(type + ".__neg", ctx -> translateParts(ctx.args, "(-", ")"));
            OPS.put(type + ".__invert", ctx -> translateParts(ctx.args, "(~", ")"));
            OPS.put(type + ".__add", ctx -> translateParts(ctx.args, "(", "+", ")"));
            OPS.put(type + ".__sub", ctx -> translateParts(ctx.args, "(", "-", ")"));
            OPS.put(type + ".__mul", ctx -> translateParts(ctx.args, "(", "*", ")"));
            OPS.put(type + ".__rem", ctx -> translateParts(ctx.args, "(", "%", ")"));
        }

        for (var type : List.of("cj.Int")) {
            for (var pair : List.of(Pair.of("__rshift", ">>"), Pair.of("__rshiftu", ">>>"),
                    Pair.of("__lshift", "<<"))) {
                var opName = pair.get1();
                var op = pair.get2();
                OPS.put(type + "." + opName, ctx -> translateParts(ctx.args, "(", op, ")"));
            }
        }

        for (var type : List.of("cj.Int", "cj.BigInt")) {
            for (var pair : List.of(Pair.of("__and", "&"), Pair.of("__or", "|"), Pair.of("__xor", "^"))) {
                var opName = pair.get1();
                var op = pair.get2();
                OPS.put(type + "." + opName, ctx -> translateParts(ctx.args, "(", op, ")"));
            }
        }

        for (var type : nativeComparables) {
            OPS.put(type + ".__eq", ctx -> translateParts(ctx.args, "(", "===", ")"));
            OPS.put(type + ".__ne", ctx -> translateParts(ctx.args, "(", "!==", ")"));
            OPS.put(type + ".__lt", ctx -> translateParts(ctx.args, "(", "<", ")"));
            OPS.put(type + ".__le", ctx -> translateParts(ctx.args, "(", "<=", ")"));
            OPS.put(type + ".__gt", ctx -> translateParts(ctx.args, "(", ">", ")"));
            OPS.put(type + ".__ge", ctx -> translateParts(ctx.args, "(", ">=", ")"));
        }

        for (var type : nativeRandomAccess) {
            OPS.put(type + ".size", ctx -> translateParts(ctx.args, "", ".length"));
            OPS.put(type + ".isEmpty", ctx -> translateParts(ctx.args, "(", ".length===0)"));
            OPS.put(type + ".__getitem", ctx -> translateParts(ctx.args, "", "[", "]"));
            OPS.put(type + ".__setitem", ctx -> translateParts(ctx.args, "(", "[", "]=", ")"));
        }

        for (var type : nativeSliceableTypes) {
            OPS.put(type + ".size", ctx -> translateParts(ctx.args, "", ".length"));
            OPS.put(type + ".isEmpty", ctx -> translateParts(ctx.args, "(", ".length===0)"));
            OPS.put(type + ".__getitem", ctx -> translateParts(ctx.args, "", "[", "]"));
            OPS.put(type + ".__setitem", ctx -> translateParts(ctx.args, "(", "[", "]=", ")"));
            OPS.put(type + ".__sliceTo", ctx -> translateParts(ctx.args, "", ".slice(0,", ")"));
            OPS.put(type + ".__sliceFrom", ctx -> translateParts(ctx.args, "", ".slice(", ")"));
            OPS.put(type + ".__slice", ctx -> translateParts(ctx.args, "", ".slice(", ",", ")"));
        }

        for (var type : nativeIterable) {
            OPS.put(type + ".toList", ctx -> translateParts(ctx.args, "Array.from(", ")"));
            if (!type.equals("cj.Iterator")) {
                OPS.put(type + ".iter", ctx -> translateParts(ctx.args, "", "[Symbol.iterator]()"));
            }
            OPS.put(type + ".toFloat32Array", ctx -> translateParts(ctx.args, "new Float32Array(", ")"));
            OPS.put(type + ".toFloat64Array", ctx -> translateParts(ctx.args, "new Float64Array(", ")"));
            OPS.put(type + ".toUint8Array", ctx -> translateParts(ctx.args, "new Uint8Array(", ")"));
            OPS.put(type + ".toInt8Array", ctx -> translateParts(ctx.args, "new Int8Array(", ")"));
            OPS.put(type + ".toUint16Array", ctx -> translateParts(ctx.args, "new Uint16Array(", ")"));
            OPS.put(type + ".toInt16Array", ctx -> translateParts(ctx.args, "new Int16Array(", ")"));
            OPS.put(type + ".toUint32Array", ctx -> translateParts(ctx.args, "new Uint32Array(", ")"));
            OPS.put(type + ".toInt32Array", ctx -> translateParts(ctx.args, "new Int32Array(", ")"));
            OPS.put(type + ".toUint64Array", ctx -> translateParts(ctx.args, "new Uint64Array(", ")"));
            OPS.put(type + ".toInt64Array", ctx -> translateParts(ctx.args, "new Int64Array(", ")"));
        }

        for (var typedArray : typedArrays) {
            Assert.that(typedArray.startsWith("cj."));
            var name = typedArray.substring(3);
            OPS.put(typedArray + ".__new", ctx -> translateParts(ctx.args, "new " + name + "(", ")"));
            OPS.put(typedArray + ".__eq", ctx -> {
                ctx.requestJS("cj.List.__eq0.js");
                return translateCall(ctx.mark, "listeq0", ctx.args);
            });
            OPS.put(typedArray + ".withSize", ctx -> translateParts(ctx.args, "new " + name + "(", ")"));
            OPS.put(typedArray + ".repr", ctx -> translateParts(ctx.args, "'" + name + "('+(", ").join(', ')+')'"));
        }

        for (var type : List.of(List.of("cj.DataView"), typedArrays).flatMap(x -> x)) {
            OPS.put(type + ".__get_buffer", ctx -> translateParts(ctx.args, "", ".buffer"));
            OPS.put(type + ".__get_byteOffset", ctx -> translateParts(ctx.args, "", ".byteOffset"));
        }

        for (var type : List.of(List.of("cj.ArrayBuffer", "cj.DataView"), typedArrays).flatMap(x -> x)) {
            OPS.put(type + ".__get_byteLength", ctx -> translateParts(ctx.args, "", ".byteLength"));
        }

        for (var pair : grandfatheredNativeMethods) {
            var className = pair.get1();
            var fileName = className + ".js";
            for (var methodName : pair.get2()) {
                var key = className + "." + methodName;
                if (OPS.containsKey(key)) {
                    continue;
                }
                OPS.put(key, ctx -> {
                    ctx.requestJS(fileName);
                    return translateCall(ctx.mark, className.replace(".", "$") + ".M$" + methodName, ctx.args);
                });
            }
        }
    }

    private static Pair<String, Op> mkpair(String key, Op op) {
        return Pair.of(key, op);
    }

    public static final class Context {
        // private final String key;
        private final CJMark mark;
        private final CJJSTypeBinding binding;
        private final CJIRMethodCall e;
        private final List<CJJSBlob2> args;
        private final CJIRClassType owner;
        private final CJIRReifiedMethodRef reifiedMethodRef;
        // private final CJJSReifiedMethod llmethod;
        private final Consumer<CJJSLLMethod> requestMethod;
        private final BiConsumer<String, CJMark> requestNative;

        public Context(String key, CJJSTypeBinding binding, CJIRMethodCall e, List<CJJSBlob2> args, CJIRClassType owner,
                CJIRReifiedMethodRef reifiedMethodRef, CJJSLLMethod llmethod, Consumer<CJJSLLMethod> requestMethod,
                BiConsumer<String, CJMark> requestNative) {
            // this.key = key;
            this.mark = e.getMark();
            this.binding = binding;
            this.e = e;
            this.args = args;
            this.owner = owner;
            this.reifiedMethodRef = reifiedMethodRef;
            // this.llmethod = llmethod;
            this.requestMethod = requestMethod;
            this.requestNative = requestNative;
        }

        void requestJS(String fileName) {
            requestNative.accept(fileName, mark);
        }
    }

    public interface Op {
        /**
         * Tries to apply the operator to the given context.
         *
         * May return null.
         */
        CJJSBlob2 apply(Context ctx);
    }

    static CJJSBlob2 translateOp(String prefix, String postfix, String op, List<CJJSBlob2> args) {
        return CJJSExpressionTranslator2.translateOp(prefix, postfix, op, args);
    }

    static CJJSBlob2 translateCall(CJMark mark, String funcName, List<CJJSBlob2> args) {
        return CJJSExpressionTranslator2.translateCall(mark, funcName, args);
    }

    static CJJSBlob2 translateDynamicCall(CJMark mark, List<CJJSBlob2> args) {
        return CJJSExpressionTranslator2.translateDynamicCall(mark, args);
    }

    static CJJSBlob2 translateParts(List<CJJSBlob2> args, String... parts) {
        return CJJSExpressionTranslator2.translateParts(args, parts);
    }

    static CJJSBlob2 ensureDefined(Context ctx, CJJSBlob2 inner) {
        ctx.requestJS("defined.js");
        return new CJJSBlob2(inner.getPrep(), out -> {
            out.append("defined(");
            inner.emitBody(out);
            out.append(")");
        }, false);
    }

    static CJJSBlob2 nanToNull(Context ctx, CJJSBlob2 inner) {
        ctx.requestJS("nan-to-null.js");
        return new CJJSBlob2(inner.getPrep(), out -> {
            out.append("nanToNull(");
            inner.emitBody(out);
            out.append(")");
        }, false);
    }
}
