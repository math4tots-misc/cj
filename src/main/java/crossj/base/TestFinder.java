package crossj.base;

import java.lang.annotation.Annotation;
import java.lang.reflect.Method;

public final class TestFinder {

    /**
     * Find and run all tests
     */
    public static void run(String packageName) {
        int testCount = 0;
        for (Method method : findAllTests(packageName)) {
            testCount++;
            System.out.print("Running test " + method.getDeclaringClass().getName() + " " + method.getName() + " ... ");
            try {
                method.invoke(null, new Object[0]);
            } catch (Exception e) {
                IO.println("FAILED");
                throw new RuntimeException(e);
            }
            System.out.println("OK");
        }
        IO.println(testCount + " tests pass (Java)");
    }

    private static List<Method> findAllTests(String packageName) {
        List<Method> list = List.of();

        for (Class<?> cls : findAllTestClasses(packageName)) {
            for (Method method : cls.getMethods()) {
                for (Annotation annotation : method.getAnnotations()) {
                    if (annotation instanceof Test) {
                        list.add(method);
                    }
                }
            }
        }

        return list;
    }

    private static List<Class<?>> findAllTestClasses(String packageName) {

        // For the Java version, the caller needs to set the 'TESTCLASSES'
        // environment variable

        List<Class<?>> classes = List.of();
        String testClassesStr = System.getenv().get("TESTCLASSES");
        try {
            for (String testClassName : testClassesStr.split(";")) {
                classes.add(Class.forName(testClassName));
            }
        } catch (ClassNotFoundException e) {
            throw new RuntimeException(e);
        }
        String packagePrefix = (packageName == null || packageName.length() == 0) ? "" : (packageName + ".");
        return classes.filter(cls -> cls.getCanonicalName().startsWith(packagePrefix));
    }
}
