class_name EndPortalState
extends RefCounted
## Trial-local, conserved story inventory. Every transaction is idempotent.
var pearls := 3
var powder := 3
var eyes := 0
var crafted := false
var slots := 0
var entered := false

func craft() -> bool:
    if crafted or pearls < 3 or powder < 3: return false
    pearls -= 3
    powder -= 3
    eyes += 3
    crafted = true
    return true

func insert(index: int) -> bool:
    if index < 0 or index > 2 or not crafted or eyes <= 0 or has_eye(index): return false
    slots |= 1 << index
    eyes -= 1
    return true

func has_eye(index: int) -> bool: return index >= 0 and index < 3 and (slots & (1 << index)) != 0
func count() -> int: return int(has_eye(0)) + int(has_eye(1)) + int(has_eye(2))
func is_open() -> bool: return crafted and slots == 7
func arrive() -> bool:
    if not is_open() or entered: return false
    entered = true
    return true
func record() -> Dictionary:
    return {"portal_crafted":crafted,"portal_slots":slots,"portal_entered":entered}
func restore(recorded: Dictionary) -> bool:
    if not recorded.has_all(["portal_crafted","portal_slots","portal_entered"]): return false
    var c: Variant=recorded.portal_crafted
    var s: Variant=recorded.portal_slots
    var e: Variant=recorded.portal_entered
    if not c is bool or not s is int or not e is bool: return false
    if s < 0 or s > 7 or (not c and s != 0) or (e and (not c or s != 7)): return false
    crafted=c
    slots=s
    entered=e
    pearls=0 if crafted else 3
    powder=pearls
    eyes=3-count() if crafted else 0
    return true
