package crossj.cj;

public final class CJIRRunModeWWW extends CJIRRunMode {
    private final String wwwdir;
    private final String mainClass;

    @Override
    public <R, A> R accept(CJIRRunModeVisitor<R, A> visitor, A a) {
        return visitor.visitWWW(this, a);
    }

    public CJIRRunModeWWW(String wwwdir, String mainClass) {
        this.wwwdir = wwwdir;
        this.mainClass = mainClass;
    }

    public String getMainClass() {
        return mainClass;
    }

    public String getWwwdir() {
        return wwwdir;
    }
}
