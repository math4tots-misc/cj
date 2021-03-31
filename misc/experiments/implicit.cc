/**
 * Just some example code to help me understand the usual arithmetic conversion and
 * integer promotion
 */
#include <iostream>
using namespace std;

int main() {
    char a = 1, b = 2;
    int integer = 0;
    auto c = a;
    auto d = '5';
    auto apb = typeid(decltype(a + b)).name();
    cout << "a+b -> " << apb << endl;                                     // integer
    cout << "a -> " << typeid(decltype(a)).name() << endl;                // char
    cout << "c -> " << typeid(decltype(c)).name() << endl;                // char
    cout << "d -> " << typeid(decltype(d)).name() << endl;                // char
    cout << "integer -> " << typeid(decltype(integer)).name() << endl;    // integer
    a = integer; // integer narrowing
}
