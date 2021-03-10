package crossj.cj.js;

import crossj.base.List;
import crossj.base.Map;
import crossj.cj.CJIRType;

public final class CJJSTypeIdRegistry {
    private final List<CJIRType> typeById = List.of();
    private final Map<CJIRType, Integer> idByType = Map.of();

    public int getId(CJIRType type) {
        var id = idByType.getOrNull(type);
        if (id != null) {
            return id;
        }
        var intid = typeById.size();
        typeById.add(type);
        idByType.put(type, intid);
        return intid;
    }
}
