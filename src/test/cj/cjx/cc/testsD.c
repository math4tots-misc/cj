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

int param_decay(int x[]) { return x[0]; }

void test01_incomplete_array_type() {
    aeq(4, sizeof(int(*)[10]));
    aeq(4, sizeof(int(*)[][10]));

    aeq(3, ({ int x[2]; x[0]=3; param_decay(x); }));
}

void test02_incomplete_struct() {
    aeq(4, ({ struct foo *bar; sizeof(bar); }));
    aeq(4, ({ struct T *foo; struct T {int x;}; sizeof(struct T); }));
    aeq(1, ({ struct T { struct T *next; int x; } a; struct T b; b.x=1; a.next=&b; a.next->x; }));
    aeq(4, ({ typedef struct T T; struct T { int x; }; sizeof(T); }));
}

int main() {
    test01_incomplete_array_type();
    test02_incomplete_struct();
}
