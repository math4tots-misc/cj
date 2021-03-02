package crossj.cj.js;

import crossj.base.Map;

public final class CJJSMethodNameRegistry {
    private final Map<String, Integer> bindingToId = Map.of();

    public String getName(String itemName, String methodName, CJJSTypeBinding binding) {
        return itemName.replace(".", "$") + "$" + methodName + (binding.isEmpty() ? "" : "$" + getBindingId(binding));
    }

    private int getBindingId(CJJSTypeBinding binding) {
        return bindingToId.getOrInsert(binding.toString(), () -> bindingToId.size());
    }
}
