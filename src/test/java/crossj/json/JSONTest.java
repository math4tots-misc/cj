package crossj.json;

import org.junit.jupiter.api.Test;

import crossj.base.Assert;

public final class JSONTest {

    @Test
    public void testComparison() {
        Assert.notEquals(JSON.of(false), JSON.of());
        Assert.notEquals(JSON.of(false), JSON.of(true));
        Assert.equals(JSON.of(false), JSON.of(false));
        Assert.equals(JSON.of(), JSON.of());
    }

    @Test
    public void testParser() {
        Assert.equals(JSON.parse("true"), JSON.of(true));
        Assert.equals(JSON.parse("false"), JSON.of(false));
        Assert.equals(JSON.parse("-14"), JSON.of(-14));
        Assert.equals(JSON.parse("14"), JSON.of(14));
        Assert.equals(JSON.parse("7.44"), JSON.of(7.44));
        Assert.equals(JSON.parse("\"hello world!\""), JSON.of("hello world!"));
        Assert.equals(JSON.parse("[]"), JSON.array());
        Assert.equals(JSON.parse("[[], {}, \"hello\", \"world\"]"),
                JSON.array(JSON.array(), JSON.object(), "hello", "world"));
        Assert.equals(JSON.parse("{}"), JSON.object());
        Assert.equals(JSON.parse("{\"hello\": false}"), JSON.object("hello", false));
        Assert.equals(JSON.parse("{\"hello\": false, \"world\": true}"), JSON.object("hello", false, "world", true));
    }
}
