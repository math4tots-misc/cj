package cjx.jvm.main

import cj.FS
import cjx.jvm.JVMClass
import cj.Argv

class ListDeps {

    static val excludes: Set[String] = SetOf(
        "java/lang/String",
        "java/lang/Object",
        "java/math/BigInteger",
    )

    static val excludePkgs = [
        "java/",
        "javax/",
        "com/sun/",
        # "java/lang/",
        # "java/io/",
        # "java/awt/",
        # "javax/swing/",
    ]

    class Entry {
        val fields: Set[Tuple[String, String]] = Set([])
        val methods: Set[Tuple[String, String]] = Set([])
    }

    def main() {
        val clss: List[JVMClass] = []
        for path in Argv() {
            val buffer = FS.readFileBytes(path)
            val cls = JVMClass.fromBuffer(buffer)
            clss.add(cls)
        }
        val internals = Set.fromIterable(clss.map(cls -> cls.name))
        val externals = Map[String, Entry]([])
        val shouldExclude: Fn[String, Bool] = cls -> {
            cls in internals or cls in excludes or excludePkgs.any(pkg -> cls.startsWith(pkg))
        }
        val addCls: Fn[String, Unit] = cls -> {
            if cls.startsWith("[") {
                if cls.endsWith(";") {
                    val icls0 = cls.lstripChar('[').rstripChar(';')
                    Assert.that(icls0.startsWith("L"))
                    val icls = icls0[1:]
                    if shouldExclude.call(icls) {
                        return ()
                    }
                } else { return () }
            }
            if not shouldExclude.call(cls) {
                if cls not in externals {
                    externals[cls] = Entry()
                }
            }
        }
        val addField: Fn[String, String, String, Unit] = (cls, name, type) -> {
            addCls.call(cls)
            if cls in externals {
                externals[cls].fields.add((name, type))
            }
        }
        val addMethod: Fn[String, String, String, Unit] = (cls, name, type) -> {
            addCls.call(cls)
            if cls in externals {
                externals[cls].methods.add((name, type))
            }
        }
        for cls in clss {
            for cpinfo in cls.cp.infos {
                when cpinfo {
                    case classref(utf8i) {
                        addCls.call(cls.cp.getUtf8(utf8i))
                    }
                    case fieldref(clsi, nati) {
                        val depcls = cls.cp.getClassref(clsi)
                        val (name, type) = cls.cp.getNameAndType(nati)
                        addField.call(depcls, name, type)
                    }
                    case methodref(clsi, nati)
                    case interfaceMethodref(clsi, nati) {
                        val depcls = cls.cp.getClassref(clsi)
                        val (name, type) = cls.cp.getNameAndType(nati)
                        addMethod.call(depcls, name, type)
                    }
                    else = ()
                }
            }
        }
        for depcls in externals.keys().sorted() {
            IO.println(depcls)
            val fields = externals[depcls].fields
            val methods = externals[depcls].methods
            var any = false
            if fields {
                IO.println("  FIELDS")
                for (fieldName, fieldType) in externals[depcls].fields.sorted() {
                    IO.println("    " + fieldName + ": " + fieldType)
                }
                any = true
            }
            if methods {
                IO.println("  METHODS")
                for (methodName, methodType) in externals[depcls].methods.sorted() {
                    IO.println("    " + methodName + ": " + methodType)
                }
                any = true
            }
            if not any {
                IO.println("  NONE")
            }
        }
    }
}
