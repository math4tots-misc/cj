package crossj.cj;

import crossj.base.FS;
import crossj.base.IO;
import crossj.base.List;
import crossj.base.Map;
import crossj.base.Pair;
import crossj.base.Repr;
import crossj.base.Set;

public final class CJIRContext extends CJIRContextBase {

    static final List<String> autoImportItemNames = List.of("cj.Unit", "cj.Never", "cj.Bool", "cj.Char", "cj.Int",
            "cj.Double", "cj.String", "cj.Repr", "cj.ToString", "cj.List", "cj.IO", "cj.Iterable", "cj.Iterator",
            "cj.Eq", "cj.Hash", "cj.Fn0", "cj.Fn1", "cj.Fn2", "cj.Fn3", "cj.Fn4");

    /**
     * These are the names that can only be used in special contexts.
     *
     * These names cannot be used as type names, unless their full name corresponds
     * to one of the exceptions explicitly listed
     */
    static final Map<String, List<String>> specialTypeNameMap = Map.of(Pair.of("Unit", List.of("cj.Unit")),
            Pair.of("Never", List.of("cj.Never")), Pair.of("Fn", List.of()), Pair.of("Tuple", List.of()),
            Pair.of("Self", List.of()));

    /**
     * Source roots to search for cj files.
     */
    private final List<String> sourceRoots = List.of();

    /**
     * Map from an item's full name to its IR
     */
    private final Map<String, CJIRItem> itemMap = Map.of();

    private CJIRItem listItem = null;
    private CJIRType unitType = null;
    private CJIRType boolType = null;
    private CJIRType charType = null;
    private CJIRType intType = null;
    private CJIRType doubleType = null;
    private CJIRType stringType = null;

    @Override
    CJIRContext getGlobal() {
        return this;
    }

    public List<String> getSourceRoots() {
        return sourceRoots;
    }

    private CJIRItem _forceLoadItem(String name, CJMark... marks) {
        var relpath = name.replace(".", FS.getSeparator()) + ".cj";
        for (var sourceRoot : sourceRoots) {
            var path = FS.join(sourceRoot, relpath);
            if (FS.isFile(path)) {
                var data = IO.readFile(path);
                return new CJIRItem(CJParser.parseString(path, data));
            }
        }
        throw CJError.of("Item " + Repr.of(name) + " not found", marks);
    }

    public CJIRItem forceLoadItem(String name, CJMark... marks) {
        itemMap.put(name, _forceLoadItem(name, marks));
        return itemMap.get(name);
    }

    public CJIRItem loadItem(String name, CJMark... marks) {
        return itemMap.getOrInsert(name, () -> _forceLoadItem(name, marks));
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

    @Override
    CJIRItem getListItem() {
        if (listItem == null) {
            listItem = loadItem("cj.List");
        }
        return listItem;
    }

    @Override
    CJIRType getListType(CJIRType innerType, CJMark... marks) {
        return itemToType(getListItem(), List.of(innerType), marks);
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
    CJIRType getUnitType() {
        if (unitType == null) {
            unitType = getTypeWithArgs("cj.Unit", List.of());
        }
        return unitType;
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
}
