class_name ActionBurst
extends Node2D
## Contact feedback only. Timeouts and cleanup never call spawn().
var kind: StringName=&"reflect"
var duration:=0.28
var remaining:=0.28
static func spawn(parent: Node, at: Vector2, type: StringName) -> ActionBurst:
    var effect:=ActionBurst.new()
    effect.kind=type
    effect.duration=0.32 if type==&"fire_hit" else 0.28
    effect.remaining=effect.duration
    parent.add_child(effect)
    effect.global_position=at
    return effect
func _ready() -> void:
    process_mode=Node.PROCESS_MODE_PAUSABLE
    z_index=8
    add_to_group("transient_effects")
    add_to_group("action_bursts")
func _physics_process(delta: float) -> void:
    remaining-=delta
    if remaining<=0: retire()
    queue_redraw()
func retire() -> void:
    hide()
    set_physics_process(false)
    queue_free()
func _draw() -> void:
    ActionVfxArt.flash(self,kind,1-remaining/duration)
