class_name GhastVolley
extends Node
## Both actors stay active. Stagger only the start of their full charge tells.
const WARNING_GAP:=1.25
var cooldown:=0.0
func _physics_process(delta: float) -> void:
    cooldown=maxf(0.0,cooldown-delta)
func claim_warning() -> bool:
    if cooldown>0: return false
    cooldown=WARNING_GAP
    return true
func reset() -> void: cooldown=0.0
