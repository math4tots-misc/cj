// Tests
//   * structs and unions
//   * long and short types
//   * nested type declarators
//   * typedefs
//   * sizeof(typename)
//   * usual arithmetic conversions
//   * augmented assignment and other operators
//   * logical operators

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
void aeql(long lhs, long rhs) {
    if (lhs != rhs) {
        __putsi("lhs0 = ", lhs);
        __putsi("lhs1 = ", lhs / 1073741824);
        __putsi("rhs0 = ", rhs);
        __putsi("rhs1 = ", rhs / 1073741824);
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

void tests07_struct_union_assignment() {
    aeq(3, ({ struct {int a,b;} x,y; x.a=3; y=x; y.a; }));
    aeq(7, ({ struct t {int a,b;}; struct t x; x.a=7; struct t y; struct t *z=&y; *z=x; y.a; }));
    aeq(7, ({ struct t {int a,b;}; struct t x; x.a=7; struct t y, *p=&x, *q=&y; *q=*p; y.a; }));
    aeq(5, ({ struct t {char a, b;} x, y; x.a=5; y=x; y.a; }));

    aeq(3, ({ struct {int a,b;} x,y; x.a=3; y=x; y.a; }));
    aeq(7, ({ struct t {int a,b;}; struct t x; x.a=7; struct t y; struct t *z=&y; *z=x; y.a; }));
    aeq(7, ({ struct t {int a,b;}; struct t x; x.a=7; struct t y, *p=&x, *q=&y; *q=*p; y.a; }));
    aeq(5, ({ struct t {char a, b;} x, y; x.a=5; y=x; y.a; }));

    aeq(3, ({ union {int a,b;} x,y; x.a=3; y.a=5; y=x; y.a; }));
    aeq(3, ({ union {struct {int a,b;} c;} x,y; x.c.b=3; y.c.b=5; y=x; y.c.b; }));
}

long sub_long(long a, long b, long c) {
  return a - b - c;
}

void tests08_long() {
    aeq(16, ({ struct {char a; long b;} x; sizeof(x); }));
    aeq(8, ({ long x; sizeof(x); }));
    aeql(1, sub_long(7, 3, 3));
    aeql(2l, sub_long(7, 2, 3));
    aeql(-1, sub_long(7, 5, 3));
}

int sub_short(short a, short b, short c) {
  return a - b - c;
}

void tests09_short() {
    aeq(1, sub_short(7, 3, 3));
}

void tests10_nested_decls() {
    aeq(12, ({ char *x[3]; sizeof(x); }));
    aeq(4, ({ char (*x)[3]; sizeof(x); }));
    aeq(1, ({ char (x); sizeof(x); }));
    aeq(3, ({ char (x)[3]; sizeof(x); }));
    aeq(12, ({ char (x[3])[4]; sizeof(x); }));
    aeq(4, ({ char (x[3])[4]; sizeof(x[0]); }));
    aeq(3, ({ char *x[3]; char y; x[0]=&y; y=3; x[0][0]; }));
    aeq(4, ({ char x[3]; char (*y)[3]=&x; y[0][0]=4; y[0][0]; }));
}

void tests11_mixed_declspec() {
    aeq(1, ({ char x; sizeof(x); }));
    aeq(2, ({ short int x; sizeof(x); }));
    aeq(2, ({ int short x; sizeof(x); }));
    aeq(4, ({ int x; sizeof(x); }));
    aeq(8, ({ long int x; sizeof(x); }));
    aeq(8, ({ int long x; sizeof(x); }));
    aeq(8, ({ long long x; sizeof(x); }));
}

typedef int MyInt, MyInt2[4];
typedef int;

void tests12_typedef() {
    aeq(1, ({ typedef int t; t x=1; x; }));
    aeq(1, ({ typedef struct {int a;} t; t x; x.a=1; x.a; }));
    aeq(1, ({ typedef int t; t t2=1; t2; }));
    aeq(2, ({ typedef struct {int a;} t; { typedef int t; } t x; x.a=2; x.a; }));
    aeq(4, ({ typedef t; t x; sizeof(x); }));
    aeq(3, ({ MyInt x=3; x; }));
    aeq(16, ({ MyInt2 x; sizeof(x); }));

    // The following line was part of the original chibicc tests, but I don't
    // think this would compile with a standard C compiler, given that typedefs
    // and variable names share the 'ordinary' namespace.
    // In fact, this fails to compile when i test with clang.
    // aeq(1, ({ typedef int t; t t=1; t; }));
}

void tests13_sizeof_type() {
    aeq(1, sizeof(char));
    aeq(2, sizeof(short));
    aeq(2, sizeof(short int));
    aeq(2, sizeof(int short));
    aeq(4, sizeof(int));
    aeq(8, sizeof(long));
    aeq(8, sizeof(long int));
    aeq(8, sizeof(long int));
    aeq(4, sizeof(char *));
    aeq(4, sizeof(int *));
    aeq(4, sizeof(long *));
    aeq(4, sizeof(int **));
    aeq(4, sizeof(int(*)[4]));
    aeq(16, sizeof(int*[4]));
    aeq(16, sizeof(int[4]));
    aeq(48, sizeof(int[3][4]));
    aeq(8, sizeof(struct {int a; int b;}));
}

void tests14_cast() {
    aeq(131585, (int)8590066177L);
    aeq(513, (short)8590066177L);
    aeq(1, (char)8590066177L);
    aeq(1, (int)(long)1);
    aeq(0, (int)(long)&*(int *)0);
    aeq(513, ({ int x=512; *(char *)&x=1; x; }));
    aeq(5, ({ int x=5; long y=(long)&x; *(int*)y; }));
}

void tests15_usual_arith_conv() {
    aeq(0, 1073741824 * 100 / 100);

    aeq(8, sizeof(-10 + (long)5));
    aeq(8, sizeof(-10 - (long)5));
    aeq(8, sizeof(-10 * (long)5));
    aeq(8, sizeof(-10 / (long)5));
    aeq(8, sizeof((long)-10 + 5));
    aeq(8, sizeof((long)-10 - 5));
    aeq(8, sizeof((long)-10 * 5));
    aeq(8, sizeof((long)-10 / 5));

    aeq((long)-5, -10 + (long)5);
    aeq((long)-15, -10 - (long)5);
    aeq((long)-50, -10 * (long)5);
    aeq((long)-2, -10 / (long)5);

    aeq(1, -2 < (long)-1);
    aeq(1, -2 <= (long)-1);
    aeq(0, -2 > (long)-1);
    aeq(0, -2 >= (long)-1);

    aeq(1, (long)-2 < -1);
    aeq(1, (long)-2 <= -1);
    aeq(0, (long)-2 > -1);
    aeq(0, (long)-2 >= -1);

    aeq(0, 2147483647 + 2147483647 + 2);
    aeq((long)-1, ({ long x; x=-1; x; }));

    aeq(1, ({ char x[3]; x[0]=0; x[1]=1; x[2]=2; char *y=x+1; y[0]; }));
    aeq(0, ({ char x[3]; x[0]=0; x[1]=1; x[2]=2; char *y=x+1; y[-1]; }));
    aeq(5, ({ struct t {char a;} x, y; x.a=5; y=x; y.a; }));
}

int g1;
int *g1_ptr() { return &g1; }
char int_to_char(int x) { return x; }
int div_long(long a, long b) {
  return a / b;
}

void tests16_more_type_conv() {
    g1 = 3;
    aeq(3, *g1_ptr());
    aeq(5, int_to_char(261));
    aeq(-5, div_long(-10, 2));
}

_Bool bool_fn_add(_Bool x) { return x + 1; }
_Bool bool_fn_sub(_Bool x) { return x - 1; }

void tests17_bool() {
    aeq(0, ({ _Bool x=0; x; }));
    aeq(1, ({ _Bool x=1; x; }));
    aeq(1, ({ _Bool x=2; x; }));
    aeq(1, (_Bool)1);
    aeq(1, (_Bool)2);
    aeq(0, (char)256);
    aeq(0, (_Bool)(char)256);

    aeq(1, bool_fn_add(3));
    aeq(0, bool_fn_sub(3));
    aeq(1, bool_fn_add(-3));
    aeq(0, bool_fn_sub(-3));
    aeq(1, bool_fn_add(0));
    aeq(1, bool_fn_sub(0));

    // aeq(1, true);
    // aeq(1, false);
}

void tests18_charlit() {
    aeq(97, 'a');
    aeq(10, '\n');
    aeq(128, '\x80');
}

void tests19_enum() {
    aeq(0, ({ enum { zero, one, two }; zero; }));
    aeq(1, ({ enum { zero, one, two }; one; }));
    aeq(2, ({ enum { zero, one, two }; two; }));
    aeq(5, ({ enum { five=5, six, seven }; five; }));
    aeq(6, ({ enum { five=5, six, seven }; six; }));
    aeq(0, ({ enum { zero, five=5, three=3, four }; zero; }));
    aeq(5, ({ enum { zero, five=5, three=3, four }; five; }));
    aeq(3, ({ enum { zero, five=5, three=3, four }; three; }));
    aeq(4, ({ enum { zero, five=5, three=3, four }; four; }));
    aeq(4, ({ enum { zero, one, two } x; sizeof(x); }));
    aeq(4, ({ enum t { zero, one, two }; enum t y; sizeof(y); }));
}

static int static_fn() { return 3; }

void tests20_static_fn() {
    aeq(3, static_fn());
}

void tests21_for_local() {
    aeq(55, ({ int j=0; for (int i=0; i<=10; i=i+1) j=j+i; j; }));
    aeq(3, ({ int i=3; int j=0; for (int i=0; i<=10; i=i+1) j=j+i; i; }));
}

void tests22_augassign() {
    aeq(7, ({ int i=2; i+=5; i; }));
    aeq(7, ({ int i=2; i+=5; }));
    aeq(3, ({ int i=5; i-=2; i; }));
    aeq(3, ({ int i=5; i-=2; }));
    aeq(6, ({ int i=3; i*=2; i; }));
    aeq(6, ({ int i=3; i*=2; }));
    aeq(3, ({ int i=6; i/=2; i; }));
    aeq(3, ({ int i=6; i/=2; }));
}

void tests23_post_incr() {
    aeq(2, ({ int i=2; i++; }));
    aeq(2, ({ int i=2; i--; }));
    aeq(3, ({ int i=2; i++; i; }));
    aeq(1, ({ int i=2; i--; i; }));
    aeq(1, ({ int a[3]; a[0]=0; a[1]=1; a[2]=2; int *p=a+1; *p++; }));
    aeq(1, ({ int a[3]; a[0]=0; a[1]=1; a[2]=2; int *p=a+1; *p--; }));

    aeq(0, ({ int a[3]; a[0]=0; a[1]=1; a[2]=2; int *p=a+1; (*p++)--; a[0]; }));
    aeq(0, ({ int a[3]; a[0]=0; a[1]=1; a[2]=2; int *p=a+1; (*(p--))--; a[1]; }));
    aeq(2, ({ int a[3]; a[0]=0; a[1]=1; a[2]=2; int *p=a+1; (*p)--; a[2]; }));
    aeq(2, ({ int a[3]; a[0]=0; a[1]=1; a[2]=2; int *p=a+1; (*p)--; p++; *p; }));

    aeq(0, ({ int a[3]; a[0]=0; a[1]=1; a[2]=2; int *p=a+1; (*p++)--; a[0]; }));
    aeq(0, ({ int a[3]; a[0]=0; a[1]=1; a[2]=2; int *p=a+1; (*p++)--; a[1]; }));
    aeq(2, ({ int a[3]; a[0]=0; a[1]=1; a[2]=2; int *p=a+1; (*p++)--; a[2]; }));
    aeq(2, ({ int a[3]; a[0]=0; a[1]=1; a[2]=2; int *p=a+1; (*p++)--; *p; }));
}

void tests24_pre_incr() {
    aeq(3, ({ int i=2; ++i; }));
    aeq(2, ({ int a[3]; a[0]=0; a[1]=1; a[2]=2; int *p=a+1; ++*p; }));
    aeq(0, ({ int a[3]; a[0]=0; a[1]=1; a[2]=2; int *p=a+1; --*p; }));
}

void test25_int_literals() {
    aeq(511, 0777);
    aeq(0, 0x0);
    aeq(10, 0xa);
    aeq(10, 0XA);
    aeq(48879, 0xbeef);
    aeq(48879, 0xBEEF);
    aeq(48879, 0XBEEF);
    aeq(0, 0b0);
    aeq(1, 0b1);
    aeq(47, 0b101111);
    aeq(47, 0B101111);
}

void test26_logical_not() {
    aeq(0, !1);
    aeq(0, !2);
    aeq(1, !0);
    aeq(1, !(char)0);
    aeq(0, !(long)3);
    aeq(4, sizeof(!(char)0));
    aeq(4, sizeof(!(long)0));
}

void test27_bitwise_not() {
    aeq(-1, ~0);
    aeq(0, ~-1);
}

void test28_rem() {
    aeq(5, 17%6);
    aeq(5, ((long)17)%6);
    aeq(2, ({ int i=10; i%=4; i; }));
    aeq(2, ({ long i=10; i%=4; i; }));
}

void test29_bitwise_ops() {
    aeq(0, 0&1);
    aeq(1, 3&1);
    aeq(3, 7&3);
    aeq(10, -1&10);

    aeq(1, 0|1);
    aeq(0b10011, 0b10000|0b00011);

    aeq(0, 0^0);
    aeq(0, 0b1111^0b1111);
    aeq(0b110100, 0b111000^0b001100);

    aeq(2, ({ int i=6; i&=3; i; }));
    aeq(7, ({ int i=6; i|=3; i; }));
    aeq(10, ({ int i=15; i^=5; i; }));
}

int lbc;

int incrlbc() {
    return lbc++;
}

void test30_logical_binops() {
    aeq(1, 0||1);
    aeq(1, 0||(2-2)||5);
    aeq(0, 0||0);
    aeq(0, 0||(2-2));

    aeq(0, 0&&1);
    aeq(0, (2-2)&&5);
    aeq(1, 1&&5);

    // test short circuiting
    aeq(lbc, 0);
    aeq(0, incrlbc()&&incrlbc());
    aeq(lbc, 1); // incrlbc() should have been called exactly once
    aeq(1, incrlbc()||incrlbc());
    aeq(lbc, 2); // incrlbc() should have been called exactly one more time
    aeq(1, incrlbc()&&incrlbc());
    aeq(lbc, 4); // incrlbc() should have been called exactly two more times
}

int main() {
    test01_struct();
    test02_tagged_struct();
    test03_structs_assignment();
    test04_structs_return();
    test05_arrow();
    tests06_union();
    tests07_struct_union_assignment();
    tests08_long();
    tests09_short();
    tests10_nested_decls();
    tests11_mixed_declspec();
    tests12_typedef();
    tests13_sizeof_type();
    tests14_cast();
    tests15_usual_arith_conv();
    tests16_more_type_conv();
    tests17_bool();
    tests18_charlit();
    tests19_enum();
    tests20_static_fn();
    tests21_for_local();
    tests22_augassign();
    tests23_post_incr();
    tests24_pre_incr();
    test25_int_literals();
    test26_logical_not();
    test27_bitwise_not();
    test28_rem();
    test29_bitwise_ops();
    test30_logical_binops();
}
