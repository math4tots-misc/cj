package crossj.cj.js2;

import crossj.base.Map;

public final class CJJSMethodNameRegistry {
    private final Map<String, Integer> bindingToId = Map.of();

    private String getName(String itemName, String methodName, CJJSTypeBinding binding) {
        return getNonGenericName(itemName, methodName) + (binding.isEmpty() ? "" : "$" + getBindingId(binding));
    }

    public String getNonGenericName(String itemName, String methodName) {
        return itemName.replace(".", "$") + "$" + methodName;
    }

    public String nameForReifiedMethod(CJJSLLMethod reifiedMethod) {
        return getName(reifiedMethod.getFinalOwnerType().getItem().getFullName(), reifiedMethod.getMethod().getName(),
                reifiedMethod.getBinding());
    }

    private int getBindingId(CJJSTypeBinding binding) {
        return bindingToId.getOrInsert(binding.getIdStr(), () -> {
            var id = bindingToId.size();
            // IO.println(id + " -> " + binding.getIdStr());
            return id;
        });
    }
}
