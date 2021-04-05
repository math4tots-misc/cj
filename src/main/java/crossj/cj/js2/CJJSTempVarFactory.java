package crossj.cj.js2;

final class CJJSTempVarFactory {
    private int nextId = 0;

    void reset() {
        nextId = 0;
    }

    String newName() {
        return "L$" + nextId++;
    }
}
