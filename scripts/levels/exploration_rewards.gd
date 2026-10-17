class_name ExplorationRewards
extends RefCounted
## Stable IDs and budgets; individual airborne detours on authored terrain.
static func specs(chapter: String) -> Array[Dictionary]:
    var points: Array[Vector2]=[]
    match chapter:
        "warped_border": points=[Vector2(2720,212),Vector2(2848,152),Vector2(3104,152),Vector2(3904,204),Vector2(5384,204),Vector2(5600,212),Vector2(6736,204),Vector2(7476,136),Vector2(7808,160),Vector2(8880,204),Vector2(9392,204)]
        "fortress_core": points=[Vector2(1616,176),Vector2(2960,208),Vector2(4624,204),Vector2(7120,176),Vector2(8504,208),Vector2(9328,204),Vector2(10000,204),Vector2(11160,208),Vector2(12944,204),Vector2(13408,176)]
        "reunion":
            # One per cleared-room intermission, offset from the supply box.
            for x in [1000,1864,2728,3592,4456,5320,6184,7048]: points.append(Vector2(x,204))
        "portal": points=[Vector2(624,208),Vector2(1320,204)]
    var result: Array[Dictionary]=[]
    for at in points:
        result.append({"id":StringName("explore_"+chapter+"_%02d"%result.size()),"data":preload("res://resources/items/emerald.tres"),"at":at,"introduced":16,"floating":true})
    return result
