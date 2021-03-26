void assert(int cond);

int foo(int rep) {
    if (rep) {
        return foo(rep - 1) + 1;
    } else {
        assert(1);
        return 0;
    }
}

int main() {
    assert(1);
    foo(4);
}
