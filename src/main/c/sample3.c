int __puti(int i);

int add(int a, int b) { return a + b; }

int main() {
    __puti(add(3, 17));
}
