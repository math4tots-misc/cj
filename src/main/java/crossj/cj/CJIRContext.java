package crossj.cj;

import crossj.base.FS;
import crossj.base.IO;
import crossj.base.List;
import crossj.base.Map;
import crossj.base.Set;

public final class CJIRContext {
    /**
     * Source roots to search for cj files.
     */
    private final List<String> sourceRoots = List.of();

    /**
     * Map from an item's full name to its IR
     */
    private final Map<String, CJIRItem> itemMap = Map.of();

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
    }
}
