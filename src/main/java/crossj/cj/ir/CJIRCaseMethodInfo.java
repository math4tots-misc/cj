package crossj.cj.ir;

public final class CJIRCaseMethodInfo extends CJIRExtraMethodInfo {
    private final CJIRCase case_;

    public CJIRCaseMethodInfo(CJIRCase case_) {
        this.case_ = case_;
    }

    public CJIRCase getCase() {
        return case_;
    }
}
