package crossj.cj;

import crossj.base.FS;
import crossj.base.IO;
import crossj.base.List;
import crossj.base.Map;
import crossj.base.Set;

public final class CJIRContext extends CJIRContextBase {
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
    private CJIRType intType = null;
    private CJIRType doubleType = null;
    private CJIRType stringType = null;

    @Override
    CJIRContext getGlobal() {
        return this;
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
        throw CJError.of("Item " + name + " not found", marks);
    }

    public CJIRItem forceLoadItem(String name, CJMark... marks) {
        itemMap.put(name, _forceLoadItem(name, marks));
        return itemMap.get(name);
    }

    public CJIRItem loadItem(String name, CJMark... marks) {
        return itemMap.getOrInsert(name, () -> _forceLoadItem(name, marks));
    }

    public void loadItemsRec(List<String> names) {
        var seen = Set.fromIterable(names);
        var stack = names.map(name -> loadItem(name));
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

    public List<CJIRItem> getAllLoadedItems() {
        return itemMap.values().list();
    }

    /**
     * Run all analysis passes
     *
     * Call this once loadItemsRec has been called on all items you want
     * included in the program.
     */
    public void runAllPasses() {
        new CJPass01(this).run();
        new CJPass02(this).run();
        new CJPass03(this).run();
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
