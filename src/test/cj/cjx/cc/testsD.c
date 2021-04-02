// Tests, partD

void __putsi(char *s, int x);
void assert(int cond);
void aeq(int lhs, int rhs) {
    if (lhs != rhs) {
        __putsi("lhs = ", lhs);
        __putsi("rhs = ", rhs);
    }
    assert(lhs == rhs);
}

void test01_incomplete_array_type() {
    aeq(4, sizeof(int(*)[10]));
    aeq(4, sizeof(int(*)[][10]));
}

int main() {
    test01_incomplete_array_type();
}
