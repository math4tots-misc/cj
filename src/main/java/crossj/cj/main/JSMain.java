package crossj.cj.main;

import crossj.base.FS;
import crossj.base.IO;
import crossj.base.List;
import crossj.cj.CJIRContext;
import crossj.cj.CJIRRunMode;
import crossj.cj.CJIRRunModeMain;
import crossj.cj.CJIRRunModeTest;
import crossj.cj.CJJSTranslator;

public final class JSMain {
    public static void main(String[] args) {

        var mode = Mode.Default;
        var mainClasses = List.<String>of();
        var sourceRoots = List.of(FS.join("src", "main", "cj"));
        var outPath = "";
        CJIRRunMode runMode = null;
        for (var arg : args) {
            switch (mode) {
                case Default:
                    switch (arg) {
                        case "-m":
                        case "--main-class":
                            mode = Mode.MainClass;
                            break;
                        case "-r":
                        case "--source-root":
                            mode = Mode.SourceRoot;
                            break;
                        case "-t":
                        case "--test":
                            runMode = new CJIRRunModeTest();
                            sourceRoots.add(FS.join("src", "test", "cj"));
                            break;
                        case "-o":
                        case "--out":
                            mode = Mode.Out;
                            break;
                        default: {
                            throw new RuntimeException("Unrecognized arg: " + arg);
                        }
                    }
                    break;
                case MainClass:
                    runMode = new CJIRRunModeMain(arg);
                    mainClasses.add(arg);
                    mode = Mode.Default;
                    break;
                case SourceRoot:
                    sourceRoots.add(arg);
                    mode = Mode.Default;
                    break;
                case Out:
                    outPath = arg;
                    mode = Mode.Default;
                    break;
            }
        }
        if (runMode == null) {
            throw new RuntimeException("--main-class or --test must be specified");
        }
        if (outPath.isEmpty()) {
            throw new RuntimeException("--out path cannot be empty");
        }
        var ctx = new CJIRContext();
        ctx.getSourceRoots().addAll(sourceRoots);
        ctx.loadAutoImportItems();
        if (runMode instanceof CJIRRunModeTest) {
            ctx.loadAllItemsInSourceRoots();
        }
        ctx.loadItemsRec(mainClasses);
        ctx.runAllPasses();
        if (runMode instanceof CJIRRunModeMain) {
            var mainClass = ((CJIRRunModeMain) runMode).getMainClass();
            ctx.validateMainItem(ctx.loadItem(mainClass));
        }
        var js = CJJSTranslator.translate(ctx, runMode);
        if (outPath.equals("-")) {
            IO.print(js);
        } else {
            IO.writeFile(outPath, js);
        }
    }

    private static enum Mode {
        Default, MainClass, SourceRoot, Out,
    }
}
