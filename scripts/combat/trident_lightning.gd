class_name TridentLightning
extends Node2D
## Lock distinct visible enemies, track during the tell, then strike from above.
var wielder: RemixPlayer
var event: DamageEvent
var reach:=640.0
var target_limit:=3
var splash_radius:=48.0
var splash_damage:=12
var windup:=0.35
var age:=0.0
var struck:=false
var spent:=false
var targets: Array[CombatHurtbox]=[]
var strike_points: Array[Vector2]=[]
var head_points: Array[Vector2]=[]
var foot_points: Array[Vector2]=[]
var hit_health: Dictionary={}
var sky_y:=0.0

static func bounds(box: CombatHurtbox) -> Rect2:
    var extent:=box.size
    for child in box.get_children():
        if child is CollisionShape2D and child.shape is RectangleShape2D:
            extent=child.shape.size
            break
    return box.global_transform*Rect2(-extent*0.5,extent)

static func eligible(box: CombatHurtbox,caster: RemixPlayer,faction: int,range_limit: float) -> bool:
    if not is_instance_valid(box) or box.is_queued_for_deletion() or not box.is_inside_tree(): return false
    if not is_instance_valid(box.health) or box.health.current<=0 or box.health.faction==faction or not box.get_collision_layer_value(5): return false
    var actor:=box.get_parent()
    if not actor.is_in_group("enemies") and not actor.is_in_group("training_targets"): return false
    if not box.is_visible_in_tree() or actor.is_queued_for_deletion() or actor.process_mode==Node.PROCESS_MODE_DISABLED: return false
    if actor is RavagerEnemy and not actor.active: return false
    if caster.global_position.distance_to(box.global_position)>range_limit: return false
    var visible_rect: Rect2=box.get_viewport().get_canvas_transform()*bounds(box)
    return box.get_viewport_rect().intersects(visible_rect)

static func candidates(caster: RemixPlayer,faction: int,range_limit: float) -> Array[CombatHurtbox]:
    var result: Array[CombatHurtbox]=[]
    var health_ids: Dictionary={}
    for group in ["enemies","training_targets"]:
        for actor in caster.get_tree().get_nodes_in_group(group):
            var box:=actor.get("receiver") as CombatHurtbox
            if not eligible(box,caster,faction,range_limit): continue
            var id:=box.health.get_instance_id()
            if health_ids.has(id): continue
            health_ids[id]=true
            result.append(box)
    var level:=caster.get_tree().current_scene
    var boss: Node=level.boss_actor() if is_instance_valid(level) and level.has_method("boss_actor") else null
    result.sort_custom(func(a: CombatHurtbox,b: CombatHurtbox) -> bool:
        var a_boss: bool=a.get_parent()==boss
        var b_boss: bool=b.get_parent()==boss
        if a_boss!=b_boss: return a_boss
        var da:=caster.global_position.distance_squared_to(a.global_position)
        var db:=caster.global_position.distance_squared_to(b.global_position)
        return da<db if not is_equal_approx(da,db) else a.get_instance_id()<b.get_instance_id())
    return result

func _ready() -> void:
    process_physics_priority=5
    var glow := Node2D.new()
    glow.name = "Glow"
    glow.set_script(preload("res://scripts/art/lightning_glow.gd"))
    add_child(glow)
    add_to_group("projectiles")
    update_locks()

func update_locks() -> void:
    # Keep surviving locks stable. Refill only dead, hidden or off-screen slots.
    targets=targets.filter(func(box) -> bool: return is_instance_valid(box) and eligible(box,wielder,event.faction,reach))
    for box in candidates(wielder,event.faction,reach):
        if targets.size()>=target_limit: break
        if targets.any(func(t: CombatHurtbox) -> bool: return t.health==box.health): continue
        targets.append(box)
    strike_points.clear()
    head_points.clear()
    foot_points.clear()
    sky_y=(get_viewport().get_canvas_transform().affine_inverse()*Vector2.ZERO).y-12
    for box in targets:
        var rect:=bounds(box)
        strike_points.append(rect.get_center())
        head_points.append(Vector2(rect.get_center().x,rect.position.y))
        foot_points.append(Vector2(rect.get_center().x,rect.end.y))

func _physics_process(delta: float) -> void:
    if spent: return
    if not is_instance_valid(wielder) or wielder.dead:
        retire()
        return
    age+=delta
    if not struck:
        update_locks()
        if age>=windup:
            strike()
            struck=true
    if age>=windup+PixelVfxArt.LIGHTNING_TAIL: retire()
    queue_redraw()

func strike() -> void:
    # Direct hits win over splash: never 12+24 or repeated hits on a wide boss.
    for box in targets:
        hit(box,event.amount)
    for box in candidates(wielder,event.faction,reach):
        if hit_health.has(box.health.get_instance_id()): continue
        var rect:=bounds(box)
        for point in strike_points:
            var closest:=point.clamp(rect.position,rect.end)
            if point.distance_to(closest)>splash_radius: continue
            var query:=PhysicsRayQueryParameters2D.create(point,box.global_position,1)
            query.hit_from_inside=true
            if not get_world_2d().direct_space_state.intersect_ray(query).is_empty(): continue
            hit(box,splash_damage)
            break

func hit(box: CombatHurtbox,amount: int) -> void:
    if not eligible(box,wielder,event.faction,reach): return
    var id:=box.health.get_instance_id()
    if hit_health.has(id): return
    hit_health[id]=amount
    box.receive(event.with_amount(amount))

func retire() -> void:
    spent=true
    hide()
    set_physics_process(false)
    queue_free()

func _draw() -> void:
    for index in strike_points.size():
        var head:=to_local(head_points[index])
        var foot:=to_local(foot_points[index])
        var start:=to_local(Vector2(head_points[index].x,minf(sky_y,head_points[index].y-100)))
        if not struck:
            var glow:=clampf(age/windup,0,1)
            draw_line(start,head+Vector2(0,-10),Color(0.4,0.9,1,0.13+glow*0.12),1)
            draw_polyline(PackedVector2Array([head+Vector2(-10,-7),head+Vector2(-10,-13),head+Vector2(10,-13),head+Vector2(10,-7)]),Color(0.6,1,0.95,0.6+0.4*glow),2)
            draw_colored_polygon(PackedVector2Array([head+Vector2(0,-5),head+Vector2(-3,-10),head+Vector2(3,-10)]),Color("f4f7cb"))
            continue
        PixelVfxArt.lightning(self,age-windup,start,head,foot)
