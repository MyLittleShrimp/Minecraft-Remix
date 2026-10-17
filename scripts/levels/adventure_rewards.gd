class_name AdventureRewards
extends RefCounted
## Finite optional supplies. Existing emerald sources and boss rewards stay fixed.
const ITEMS: Array[PickupData]=[
    preload("res://resources/items/red_mushroom.tres"),
    preload("res://resources/items/healing_mushroom.tres"),
    preload("res://resources/items/guard_mushroom.tres"),
    preload("res://resources/items/haste_mushroom.tres"),
    preload("res://resources/items/bread.tres")]
const POOL: Array[int]=[4,4,4,0,0,1,1,3,3,2]
static func reward(seed_value: int, id: String) -> PickupData:
    return ITEMS[POOL[(str(seed_value)+"/"+id).hash()%POOL.size()]]

static func blocks(chapter: String) -> Array[Dictionary]:
    var rows: Array=[]
    match chapter:
        "forest_ruins": rows=[[1760,1]]
        "spiderwood": rows=[[1880,1],[5680,3]]
        "abandoned_mine": rows=[[2160,3],[6400,1]]
        "tidal_ruins": rows=[[2128,0],[5536,2]]
        "warped_border": rows=[[3776,3],[8344,2]]
        "fortress_core": rows=[[3040,0],[7720,3],[12320,1]]
        "reunion": rows=[[1360,0],[3960,1],[5680,3],[6616,2]]
    var result: Array[Dictionary]=[]
    for i in rows.size():
        result.append({"id":StringName("bonus_%s_%d"%[chapter,i]),"x":rows[i][0],"y":208,"data":ITEMS[rows[i][1]],"introduced":17})
    return result

static func chests(chapter: String) -> Array[Dictionary]:
    var xs: Array=[]
    match chapter:
        "forest_ruins": xs=[1952,7488]
        "spiderwood": xs=[2528,6640]
        "abandoned_mine": xs=[2312,6512]
        "tidal_ruins": xs=[2592,5760]
        "warped_border": xs=[3880,8960]
        "fortress_core": xs=[3168,7856,12512]
        "reunion": xs=[1536,4128,7240]
    var result: Array[Dictionary]=[]
    for i in xs.size():
        result.append({"id":StringName("cache_%s_%d"%[chapter,i]),"at":Vector2(xs[i],224),"loot":false,"random_loot":true,"introduced":17})
    return result
