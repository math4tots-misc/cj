package cjx.cc

import cjx.parser.MError
import cjx.cc.C2Locals
import cjx.cc.C2IR.TranslationUnit
import cjx.cc.C2IR.Taggable
import cjx.cc.C2IR.Ordinary

class C2Scope {
    val translationUnit: TranslationUnit = TranslationUnit()
    var _locals: C2Locals? = null
    val tagMap: Map[String, Taggable] = MapOf()

    def getOrNull(self, name: String): Ordinary? {
        if val ordinary = translationUnit.getOrNull(name) { return null(ordinary) }
        if val locals = _locals { return locals.getOrNull(name) }
        null
    }

    def getCurrentScopeTaggableOrNull(self, name: String): Taggable? {
        val map = if val locals = _locals { locals.tagMaps.last() } else { tagMap }
        map.getOrNull(name)
    }

    def getTaggableOrNull(self, name: String): Taggable? {
        if val locals = _locals {
            val maps = locals.tagMaps
            for i = maps.size() - 1; i >= 0; i-- {
                if val tag = maps[i].getOrNull(name) {
                    return null(tag)
                }
            }
        }
        if val tag = tagMap.getOrNull(name) { return null(tag) }
        null
    }

    def addTaggable(self, taggable: Taggable) {
        if taggable.tag.isEmpty() {
            throw MError("Given taggable has no tag", [taggable.mark])
        }
        val name = taggable.tag.get()
        if val locals = _locals {
            val map = locals.tagMaps.last()
            if val oldTaggable = map.getOrNull(name) {
                throw MError("Duplicate tag definition", [taggable.mark, oldTaggable.mark])
            }
            map[name] = taggable
            return ()
        }
        if val oldTaggable = tagMap.getOrNull(name) {
            throw MError("Duplicate tag definition", [taggable.mark, oldTaggable.mark])
        }
        tagMap[name] = taggable
    }
}
