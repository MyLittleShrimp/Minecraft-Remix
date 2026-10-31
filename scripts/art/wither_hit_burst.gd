class_name WitherHitBurst
extends Node2D
## One visual per physical impact. No hurtbox, damage query or follow-up damage.
var remaining := EnemyVfxArt.WITHER_BURST_SECONDS
var enraged := false

static func spawn(parent: Node, at: Vector2, second_phase: bool) -> WitherHitBurst:
    var burst := WitherHitBurst.new()
    burst.enraged=second_phase
    parent.add_child(burst)
    burst.global_position=at
    return burst

func _ready() -> void:
    process_mode=Node.PROCESS_MODE_PAUSABLE
    z_index=8
    # Existing room/reset cleanup also clears lingering impact visuals.
    add_to_group("projectiles")
    add_to_group("wither_hit_bursts")

func _physics_process(delta: float) -> void:
    remaining-=delta
    if remaining<=0: retire()
    queue_redraw()

func retire() -> void:
    hide()
    set_physics_process(false)
    queue_free()

func _draw() -> void:
    EnemyVfxArt.wither_burst(self,Vector2.ZERO,remaining,enraged)
