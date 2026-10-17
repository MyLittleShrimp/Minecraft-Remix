extends Node2D
## Authored poses: idle4/run6/jump3/hurt2/death3/sword3/bow3.
var clock := 0.0
var death_time := 0.0
var animation_frame := 0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
    var actor := get_parent() as RemixPlayer
    if get_tree().paused and not actor.dead: return
    clock += delta
    death_time = death_time+delta if actor.dead else 0.0
    queue_redraw()

func _draw() -> void:
    var actor := get_parent() as RemixPlayer
    var weapon := actor.get_node_or_null("Equipment") as WeaponController
    var frame := int(clock*3)%4
    if actor.dead: frame=15+mini(2,int(death_time*9))
    elif actor.hitstun_left>0: frame=4 if actor.hitstun_left>0.07 else 5
    elif weapon!=null and weapon.sword_time>=0:
        frame=18 if weapon.sword_time<weapon.sword_weapon.windup else (19 if weapon.sword_time<weapon.sword_weapon.windup+weapon.sword_weapon.active_seconds else 20)
    elif weapon!=null and weapon.equipped().kind==WeaponData.Kind.TRIDENT and (weapon.charging or weapon.shot_pose_left>0):
        frame=19 if weapon.shot_pose_left>0 else 18
    elif weapon!=null and not weapon.equipped().is_melee() and (weapon.charging or weapon.shot_pose_left>0):
        frame=23 if weapon.shot_pose_left>0 else (22 if weapon.charge>0.18 else 21)
    elif not actor.is_on_floor(): frame=12 if actor.velocity.y< -60 else (14 if actor.velocity.y>60 else 13)
    elif absf(actor.velocity.x)>6: frame=6+posmod(int(actor.steps*0.65),6)
    elif weapon!=null and not weapon.equipped().is_melee(): frame=21
    animation_frame=frame
    draw_rect(Rect2(-10,-2,20,3),Color(0.05,0.12,0.14,0.25))
    ActionArt.actor(self,"steve",frame,46,actor.facing)
