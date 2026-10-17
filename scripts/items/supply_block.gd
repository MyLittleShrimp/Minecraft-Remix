class_name SupplyBlock
extends StaticBody2D

signal opened(block: SupplyBlock, actor: RemixPlayer)
@export var block_id: StringName
@export var content: PickupData
var used: bool = false
var bump_left: float = 0.0

func _ready() -> void:
    add_to_group("supply_blocks")

func bump(actor: RemixPlayer) -> void:
    if used or actor.dead:
        return
    used = true
    bump_left = 0.18
    opened.emit(self, actor)
    queue_redraw()

func reset_block() -> void:
    used = false
    bump_left = 0
    queue_redraw()

func _physics_process(delta: float) -> void:
    bump_left = maxf(0, bump_left - delta)
    queue_redraw()

func _draw() -> void:
    # Only art bounces. Moving the solid collider could push/crush the player.
    var offset := Vector2(0, -roundf(sin(bump_left / 0.18 * PI) * 5))
    draw_set_transform(offset)
    RemixArt.block(self,9 if used or content.kind==PickupData.Kind.BREAD else 8)
    if not used and content.kind==PickupData.Kind.BREAD:
        ActionArt.bread(self,offset,0.65)
