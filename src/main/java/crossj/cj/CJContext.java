package crossj.cj;

import crossj.base.FS;
import crossj.base.IO;
import crossj.base.List;
import crossj.base.Map;
import crossj.base.Pair;
import crossj.base.Repr;
import crossj.base.Set;
import crossj.base.Str;
import crossj.cj.ast.CJAstItemDefinition;

public final class CJContext extends CJContextBase {

    static final List<String> autoImportItemNames = List.of("cj.Any", "cj.Unit", "cj.NoReturn", "cj.Nullable",
            "cj.NonNull", "cj.Bool", "cj.Char", "cj.Int", "cj.Double", "cj.String", "cj.BigInt", "cj.Repr", "cj.ToBool",
            "cj.ToChar", "cj.ToInt", "cj.ToDouble", "cj.ToString", "cj.ToList", "cj.List", "cj.Map", "cj.MapOf",
            "cj.Set", "cj.SetOf", "cj.Assert", "cj.IO", "cj.Iterable", "cj.Iterator", "cj.Promise", "cj.Eq", "cj.Ord",
            "cj.Hash", "cj.Fn0", "cj.Fn1", "cj.Fn2", "cj.Fn3", "cj.Fn4", "cj.Tuple2", "cj.Tuple3", "cj.Tuple4",
            "cj.Default");

    /**
     * These are the names that can only be used in special contexts.
     *
     * These names cannot be used as type names, unless their full name corresponds
     * to one of the exceptions explicitly listed
     */
    static final Map<String, List<String>> specialTypeNameMap = Map.of(Pair.of("Any", List.of("cj.Any")),
            Pair.of("Unit", List.of("cj.Unit")), Pair.of("Nullable", List.of("cj.Nullable")),
            Pair.of("NonNull", List.of("cj.NonNull")), Pair.of("List", List.of("cj.List")),
            Pair.of("Map", List.of("cj.Map")), Pair.of("MapOf", List.of("cj.MapOf")), Pair.of("Set", List.of("cj.Set")),
            Pair.of("SetOf", List.of("cj.SetOf")), Pair.of("NoReturn", List.of("cj.NoReturn")),
            Pair.of("Fn", List.of()), Pair.of("Fn0", List.of("cj.Fn0")), Pair.of("Fn1", List.of("cj.Fn1")),
            Pair.of("Fn2", List.of("cj.Fn2")), Pair.of("Fn3", List.of("cj.Fn3")), Pair.of("Fn4", List.of("cj.Fn4")),
            Pair.of("Tuple", List.of()), Pair.of("Tuple2", List.of("cj.Tuple2")),
            Pair.of("Tuple3", List.of("cj.Tuple3")), Pair.of("Tuple4", List.of("cj.Tuple4")),
            Pair.of("Iterator", List.of("cj.Iterator")), Pair.of("Promise", List.of("cj.Promise")),
            Pair.of("Default", List.of("cj.Default")), Pair.of("Self", List.of()));

    /**
     * Source roots to search for cj files.
     */
    private final List<String> sourceRoots = List.of();

    /**
     * Map from an item's full name to its IR
     */
    private final Map<String, CJIRItem> itemMap = Map.of();

    private CJIRItem listItem = null;
    private CJIRItem tuple2Item = null;
    private CJIRItem tuple3Item = null;
    private CJIRItem tuple4Item = null;
    private CJIRItem nullableItem = null;
    private CJIRItem promiseItem = null;
    private CJIRItem iterableItem = null;
    private CJIRType unitType = null;
    private CJIRType noReturnType = null;
    private CJIRType boolType = null;
    private CJIRType charType = null;
    private CJIRType intType = null;
    private CJIRType doubleType = null;
    private CJIRType stringType = null;
    private CJIRType bigIntType = null;
    private CJIRTrait anyTrait = null;
    private CJIRTrait toBoolTrait = null;

    @Override
    CJContext getGlobal() {
        return this;
    }

    public List<String> getSourceRoots() {
        return sourceRoots;
    }

    private String getItemPathOrNull(String name) {
        var relpath = name.replace(".", FS.getSeparator()) + ".cj";
        for (var sourceRoot : sourceRoots) {
            var path = FS.join(sourceRoot, relpath);
            if (FS.isFile(path)) {
                return path;
            }
        }
        return null;
    }

    private CJIRItem _forceLoadItem(String name, CJMark... marks) {
        var path = getItemPathOrNull(name);
        if (path != null) {
            var data = IO.readFile(path);
            var item = itemFromAst(CJParser.parseString(path, data));
            if (!item.getFullName().equals(name)) {
                throw CJError.of("Expected " + path + " to contain " + name + " but found " + item.getFullName(),
                        item.getMark());
            }
            return item;
        }
        throw CJError.of("Item " + Repr.of(name) + " not found", marks);
    }

    private static CJIRItem itemFromAst(CJAstItemDefinition ast) {
        var annotationProcessor = CJIRAnnotationProcessor.processItem(ast);
        return new CJIRItem(ast, annotationProcessor);
    }

    /**
     * Returns the outermost item name from the given item name.
     *
     * E.g. foo.bar.Baz.Inner -> foo.bar.Baz foo.bar.Baz -> foo.bar.Baz
     * foo.Bar.Baz.Inner -> foo.Bar
     */
    private static String getOutermostItemName(String itemName) {
        var parts = List.<String>of();
        for (var part : Str.split(itemName, ".")) {
            var firstChar = part.charAt(0);
            parts.add(part);
            if ('A' <= firstChar && firstChar <= 'Z') {
                break;
            }
        }
        return Str.join(".", parts);
    }

    public CJIRItem loadItem(String name, CJMark... marks) {
        var item = itemMap.getOrNull(name);
        if (item != null) {
            return item;
        }
        var outerItem = _forceLoadItem(getOutermostItemName(name), marks);
        itemMap.put(outerItem.getFullName(), outerItem);
        if (getItemPathOrNull(name + "_") != null) {
            loadItem(name + "_", marks);
        }

        var ast = outerItem.getAst();
        fillItemMapWithDescendantItems(ast);
        item = itemMap.getOrNull(name);
        if (item == null) {
            throw CJError.of("Item " + name + " not found", marks);
        }
        return item;
    }

    private void fillItemMapWithDescendantItems(CJAstItemDefinition ast) {
        for (var member : ast.getMembers()) {
            if (member instanceof CJAstItemDefinition) {
                var astItem = (CJAstItemDefinition) member;
                var childItem = itemFromAst(astItem);
                itemMap.put(childItem.getFullName(), childItem);
                fillItemMapWithDescendantItems(astItem);
            }
        }
    }

    private static List<String> listClassNames(String sourceRoot) {
        var stack = FS.list(sourceRoot);
        var out = List.<String>of();
        while (stack.size() > 0) {
            var subdir = stack.pop();
            for (var child : FS.list(FS.join(sourceRoot, subdir))) {
                var innerRelpath = FS.join(subdir, child);
                var childPath = FS.join(sourceRoot, innerRelpath);
                if (isValidPackageComponent(child) && FS.isDir(childPath)) {
                    stack.add(innerRelpath);
                } else if (child.endsWith(".cj") && FS.isFile(childPath)) {
                    var name = innerRelpath.substring(0, innerRelpath.length() - ".cj".length())
                            .replace(FS.getSeparator(), ".");
                    out.add(name);
                }
            }
        }
        return out;
    }

    private static boolean isValidPackageComponent(String name) {
        if (name.isEmpty()) {
            return false;
        }
        if (!isValidStartChar(name.charAt(0))) {
            return false;
        }
        for (int i = 1; i < name.length(); i++) {
            if (!isValidMiddleChar(name.charAt(i))) {
                return false;
            }
        }
        return true;
    }

    private static boolean isValidStartChar(char ch) {
        return ch == '_' || 'a' <= ch && ch <= 'z';
    }

    private static boolean isValidMiddleChar(char ch) {
        return isValidStartChar(ch) || '0' <= ch && ch <= '9';
    }

    public void loadAllItemsInSourceRoots() {
        for (var sourceRoot : sourceRoots) {
            loadItemsRec(listClassNames(sourceRoot));
        }
    }

    public void loadItemsRec(List<String> names, CJMark... marks) {
        var seen = Set.fromIterable(names);
        var stack = names.map(name -> loadItem(name, marks));
        while (stack.size() > 0) {
            var item = stack.pop();
            for (var imp : item.getAst().getImports()) {
                var importName = imp.getFullName();
                if (!seen.contains(importName)) {
                    seen.add(importName);
                    stack.add(loadItem(importName, imp.getMark()));
                }
            }
        }
    }

    public void loadAutoImportItems() {
        loadItemsRec(autoImportItemNames);
    }

    public List<CJIRItem> getAllLoadedItems() {
        return List.sortedBy(itemMap.values().list(), (a, b) -> a.getFullName().compareTo(b.getFullName()));
    }

    /**
     * Run all analysis passes
     *
     * Call this once loadItemsRec has been called on all items you want included in
     * the program.
     */
    public void runAllPasses() {
        new CJPass01(this).run();
        new CJPass02(this).run();
        new CJPass03(this).run();
        new CJPass04(this).run();
        new CJPass05(this).run();
    }

    CJIRItem getTuple2Item() {
        if (tuple2Item == null) {
            tuple2Item = loadItem("cj.Tuple2");
        }
        return tuple2Item;
    }

    CJIRItem getTuple3Item() {
        if (tuple3Item == null) {
            tuple3Item = loadItem("cj.Tuple3");
        }
        return tuple3Item;
    }

    CJIRItem getTuple4Item() {
        if (tuple4Item == null) {
            tuple4Item = loadItem("cj.Tuple4");
        }
        return tuple4Item;
    }

    CJIRType getTupleType(List<CJIRType> args, CJMark... marks) {
        CJIRItem item;
        switch (args.size()) {
        case 2:
            item = getTuple2Item();
            break;
        case 3:
            item = getTuple3Item();
            break;
        case 4:
            item = getTuple4Item();
            break;
        default:
            throw CJError.of("Tuple" + args.size() + " is not supported", marks);
        }
        checkItemArgs(item, args);
        return new CJIRClassType(item, args);
    }

    @Override
    CJIRItem getListItem() {
        if (listItem == null) {
            listItem = loadItem("cj.List");
        }
        return listItem;
    }

    @Override
    CJIRType getListType(CJIRType innerType, CJMark... marks) {
        var listItem = getListItem();
        var args = List.of(innerType);
        checkItemArgs(listItem, args);
        return new CJIRClassType(listItem, args);
    }

    @Override
    CJIRItem getNullableItem() {
        if (nullableItem == null) {
            nullableItem = loadItem("cj.Nullable");
        }
        return nullableItem;
    }

    @Override
    CJIRType getNullableType(CJIRType innerType, CJMark... marks) {
        var nullableItem = getNullableItem();
        var args = List.of(innerType);
        checkItemArgs(nullableItem, args, marks);
        return new CJIRClassType(nullableItem, args);
    }

    @Override
    CJIRItem getPromiseItem() {
        if (promiseItem == null) {
            promiseItem = loadItem("cj.Promise");
        }
        return promiseItem;
    }

    @Override
    CJIRType getPromiseType(CJIRType innerType, CJMark... marks) {
        return itemToType(getPromiseItem(), List.of(innerType), marks);
    }

    @Override
    CJIRItem getIterableItem() {
        if (iterableItem == null) {
            iterableItem = loadItem("cj.Iterable");
        }
        return iterableItem;
    }

    @Override
    CJIRType getIterableType(CJIRType innerType, CJMark... marks) {
        return itemToType(getIterableItem(), List.of(innerType), marks);
    }

    @Override
    CJIRClassType itemToType(CJIRItem item, List<CJIRType> args, CJMark... marks) {
        checkItemArgs(item, args, marks);
        return new CJIRClassType(item, args);
    }

    @Override
    CJIRClassType getTypeWithArgs(String itemName, List<CJIRType> args, CJMark... marks) {
        var item = loadItem(itemName, marks);
        return itemToType(item, args, marks);
    }

    @Override
    CJIRTrait itemToTrait(CJIRItem item, List<CJIRType> args, CJMark... marks) {
        checkItemArgs(item, args, marks);
        return new CJIRTrait(item, args);
    }

    @Override
    CJIRTrait getTraitWithArgs(String itemName, List<CJIRType> args, CJMark... marks) {
        var item = loadItem(itemName, marks);
        return itemToTrait(item, args, marks);
    }

    @Override
    CJIRType getUnitType() {
        if (unitType == null) {
            unitType = getTypeWithArgs("cj.Unit", List.of());
        }
        return unitType;
    }

    @Override
    CJIRType getNoReturnType() {
        if (noReturnType == null) {
            noReturnType = getTypeWithArgs("cj.NoReturn", List.of());
        }
        return noReturnType;
    }

    @Override
    CJIRType getBoolType() {
        if (boolType == null) {
            boolType = getTypeWithArgs("cj.Bool", List.of());
        }
        return boolType;
    }

    @Override
    CJIRType getCharType() {
        if (charType == null) {
            charType = getTypeWithArgs("cj.Char", List.of());
        }
        return charType;
    }

    @Override
    CJIRType getIntType() {
        if (intType == null) {
            intType = getTypeWithArgs("cj.Int", List.of());
        }
        return intType;
    }

    @Override
    CJIRType getDoubleType() {
        if (doubleType == null) {
            doubleType = getTypeWithArgs("cj.Double", List.of());
        }
        return doubleType;
    }

    @Override
    CJIRType getStringType() {
        if (stringType == null) {
            stringType = getTypeWithArgs("cj.String", List.of());
        }
        return stringType;
    }

    CJIRType getBigIntType() {
        if (bigIntType == null) {
            bigIntType = getTypeWithArgs("cj.BigInt", List.of());
        }
        return bigIntType;
    }

    @Override
    CJIRTrait getToBoolTrait() {
        if (toBoolTrait == null) {
            toBoolTrait = getTraitWithArgs("cj.ToBool", List.of());
        }
        return toBoolTrait;
    }

    CJIRTrait getAnyTrait() {
        if (anyTrait == null) {
            anyTrait = getTraitWithArgs("cj.Any", List.of());
        }
        return anyTrait;
    }
}
