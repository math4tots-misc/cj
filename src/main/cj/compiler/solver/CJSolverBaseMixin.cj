package compiler.solver

import compiler.CJIR.Type

trait CJSolverBaseMixin {
    def __get_noreturnType(self): Type
    def __get_unitType(self): Type
    def __get_boolType(self): Type
    def __get_charType(self): Type
    def __get_intType(self): Type
    def __get_doubleType(self): Type
    def __get_stringType(self): Type
    def __get_bigintType(self): Type
}
