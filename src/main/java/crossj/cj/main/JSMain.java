package crossj.cj.main;

import crossj.base.FS;
import crossj.base.IO;
import crossj.base.List;
import crossj.cj.CJIRContext;
import crossj.cj.CJIRRunModeMain;
import crossj.cj.CJJSTranslator;

public final class JSMain {
    public static void main(String[] args) {

        var mode = Mode.Default;
        var mainClass = "";
        var sourceRoots = List.of(FS.join("src", "main", "cj"));
        var outPath = "";
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
                    mainClass = arg;
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
        if (mainClass.isEmpty()) {
            throw new RuntimeException("--main-class cannot be empty");
        }
        if (outPath.isEmpty()) {
            throw new RuntimeException("--out path cannot be empty");
        }
        var ctx = new CJIRContext();
        ctx.getSourceRoots().addAll(sourceRoots);
        ctx.loadAutoImportItems();
        ctx.loadItemsRec(List.of(mainClass));
        ctx.runAllPasses();
        ctx.validateMainItem(ctx.loadItem(mainClass));
        var js = CJJSTranslator.translate(ctx, new CJIRRunModeMain(mainClass));
        if (outPath.equals("-")) {
            IO.print(js);
        } else {
            IO.writeFile(outPath, js);
        }
    }

    private static enum Mode {
        Default,
        MainClass,
        SourceRoot,
        Out,
    }
}
