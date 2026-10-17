class_name WildlifeContent
extends RefCounted
## Optional, finite food sources; no hostile-clear or emerald contribution.
const FOODS: Array[PickupData]=[
    preload("res://resources/items/rabbit_meat.tres"),preload("res://resources/items/mutton.tres"),
    preload("res://resources/items/pork.tres"),preload("res://resources/items/chicken_meat.tres"),
    preload("res://resources/items/beef.tres"),preload("res://resources/items/mushroom_stew.tres")]
const LABELS: Array[String]=["兔子","羊","猪","鸡","牛","哞菇"]
static func specs(chapter: String) -> Array[Dictionary]:
    var rows: Array=[]
    match chapter:
        "forest_ruins": rows=[["forest_rabbit",0,1856],["forest_chicken",3,5320],["forest_pig",2,7552]]
        "spiderwood": rows=[["trail_rabbit",0,2730],["ridge_sheep",1,3760],["bank_pig",2,5670],["wood_chicken",3,1520],["wood_cow",4,7270]]
        "abandoned_mine": rows=[["mine_rabbit",0,2870],["mine_chicken",3,5750],["mine_cow",4,9180]]
        "tidal_ruins": rows=[["tide_chicken",3,2460],["tide_pig",2,4784],["tide_sheep",1,7016]]
        "warped_border": rows=[["warped_mooshroom_a",5,1520],["warped_rabbit",0,5490],["warped_mooshroom_b",5,9020]]
        "fortress_core": rows=[["fortress_pig_a",2,2860],["fortress_chicken",3,8500],["fortress_pig_b",2,13060]]
        "reunion": rows=[["reunion_chicken",3,1104],["reunion_sheep",1,3712],["reunion_cow",4,7144]]
        "portal": rows=[["portal_rabbit",0,432]]
    var result: Array[Dictionary]=[]
    for row in rows:
        result.append({"id":StringName(row[0]),"species":row[1],"x":float(row[2]),"label":LABELS[row[1]],"food":FOODS[row[1]],"roam":40.0,
            "introduced":17 if chapter=="forest_ruins" else 3 if row[0] in ["trail_rabbit","ridge_sheep","bank_pig"] else 16})
    return result
