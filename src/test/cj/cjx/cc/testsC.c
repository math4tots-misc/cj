// Tests
//   * structs

/*
 * Some multiline comments
 * Some multiline comments
 * Some multiline comments
 */

void __putsi(char *s, int x);
void assert(int cond);
void aeq(int lhs, int rhs) {
    if (lhs != rhs) {
        __putsi("lhs = ", lhs);
        __putsi("rhs = ", rhs);
    }
    assert(lhs == rhs);
}

void test01_struct() {
    int ptrSize = 4;

    aeq(({ struct {int a; int b;} x; x.a=1; x.b=2; x.a; }), 1);
    aeq(({ struct {int a; int b;} x; x.a=1; x.b=2; x.b; }), 2);
    aeq(({ struct {char a; int b; char c;} x; x.a=1; x.b=2; x.c=3; x.a; }), 1);
    aeq(({ struct {char a; int b; char c;} x; x.b=1; x.b=2; x.c=3; x.b; }), 2);
    aeq(({ struct {char a; int b; char c;} x; x.a=1; x.b=2; x.c=3; x.c; }), 3);

    aeq(({ struct {char a; char b;} x[3]; char *p=x; p[0]=0; x[0].a; }), 0);
    aeq(({ struct {char a; char b;} x[3]; char *p=x; p[1]=1; x[0].b; }), 1);
    aeq(({ struct {char a; char b;} x[3]; char *p=x; p[2]=2; x[1].a; }), 2);
    aeq(({ struct {char a; char b;} x[3]; char *p=x; p[3]=3; x[1].b; }), 3);

    aeq(({ struct {char a[3]; char b[5];} x; char *p=&x; x.a[0]=6; p[0]; }), 6);
    aeq(({ struct {char a[3]; char b[5];} x; char *p=&x; x.b[0]=7; p[3]; }), 7);

    aeq(({ struct { struct { char b; } a; } x; x.a.b=6; x.a.b; }), 6);

    aeq(({ struct {int a;} x; sizeof(x); }), ptrSize);
    aeq(({ struct {int a; int b;} x; sizeof(x); }), 2 * ptrSize);
    aeq(({ struct {int a, b;} x; sizeof(x); }), 2 * ptrSize);
    aeq(({ struct {int a[3];} x; sizeof(x); }), 3 * ptrSize);
    aeq(({ struct {int a;} x[4]; sizeof(x); }), 4 * ptrSize);
    aeq(({ struct {int a[3];} x[2]; sizeof(x); }), 2 * 3 * ptrSize);
    aeq(({ struct {char a; char b;} x; sizeof(x); }), 2);
    aeq(({ struct {char a; int b;} x; sizeof(x); }), 8); // char is padded for alignment
    aeq(({ struct {int a; char b;} x; sizeof(x); }), 8); // char is padded for alignment
    aeq(({ struct {} x; sizeof(x); }), 0);
}

void test02_tagged_struct() {
    aeq(({ struct t {int a; int b;} x; struct t y; sizeof(y); }), 8);
    aeq(({ struct t {int a; int b;}; struct t y; sizeof(y); }), 8);
    aeq(({ struct t {char a[2];}; { struct t {char a[4];}; } struct t y; sizeof(y); }), 2);
    aeq(({ struct t {int x;}; int t=1; struct t y; y.x=2; t+y.x; }), 3);
}

struct Foo {
    int x;
};

int structArg(struct Foo foo) {
    return foo.x + 2;
}

void setArg(struct Foo foo) {
    foo.x = 294;
}

void setArgp(struct Foo *foo) {
    (*foo).x = 294;
}

void test03_structs_assignment() {
    aeq(({ struct Foo foo; foo.x = 3; structArg(foo); }), 5);
    aeq(({ struct Foo foo; foo.x = 331; setArg(foo); foo.x; }), 331);
    aeq(({ struct Foo foo; foo.x = 331; setArgp(&foo); foo.x; }), 294);
    aeq(({ struct Foo a, b; b.x = 5; a.x = 3; b = a; b.x; }), 3);
}

struct Foo newFoo(int x) {
    struct Foo foo;
    foo.x = x;
    return foo;
}

struct Foo newFoo2(struct Foo a, struct Foo b) {
    struct Foo foo;
    foo.x = a.x * b.x;
    return foo;
}

void test04_structs_return() {
    aeq(({ newFoo(5).x; }), 5);
    aeq(({ newFoo(5).x + newFoo(7).x; }), 12);

    // tries to test that space is properly allocated for temporary structs
    // returned from functions
    aeq(({ newFoo2(newFoo(5), newFoo(7)).x; }), 35);
}

void test05_arrow() {
    aeq(({ struct t {char a;} x; struct t *y = &x; x.a=3; y->a; }), 3);
    aeq(({ struct t {char a;} x; struct t *y = &x; y->a=3; x.a; }), 3);
}

void tests06_union() {
    aeq(({ union { int a; char b[6]; } x; sizeof(x); }), 8);
    aeq(({ union { int a; char b[4]; } x; x.a = 515; x.b[0]; }), 3);
    aeq(({ union { int a; char b[4]; } x; x.a = 515; x.b[1]; }), 2);
    aeq(({ union { int a; char b[4]; } x; x.a = 515; x.b[2]; }), 0);
    aeq(({ union { int a; char b[4]; } x; x.a = 515; x.b[3]; }), 0);
}

int main() {
    test01_struct();
    test02_tagged_struct();
    test03_structs_assignment();
    test04_structs_return();
    test05_arrow();
    tests06_union();
}
