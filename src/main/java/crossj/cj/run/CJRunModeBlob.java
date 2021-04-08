package crossj.cj.run;

import crossj.base.List;

public final class CJRunModeBlob extends CJRunMode {
    private final List<String> rootClasses;

    public CJRunModeBlob(List<String> rootClasses) {
        this.rootClasses = rootClasses;
    }

    @Override
    public <R, A> R accept(CJRunModeVisitor<R, A> visitor, A a) {
        return visitor.visitBlob(this, a);
    }

    public List<String> getRootClasses() {
        return rootClasses;
    }
}
