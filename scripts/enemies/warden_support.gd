class_name WardenSupport
extends Node2D
## Owns finite reinforcements and committed floor hazards for this encounter only.
const RIFT_WARNING:=0.85
const RIFT_ACTIVE:=0.55
const RIFT_WIDTH:=64.0
const RIFT_HEIGHT:=80.0
var guards: Array[RemixEnemy]=[]
var summons: Array[Dictionary]=[]
var requested_phase:=0
var generation:=0
var phase_banner:=0.0
var rift_age:=0.0
var rift_left:=0.0
var rift_points: Array[Vector2]=[]
var rift_event: DamageEvent
var rift_casts:=0
@onready var actor: EndermanElite=get_parent()
func _ready() -> void: process_physics_priority=85
func request_guard(phase: int) -> void:
    if phase<=requested_phase: return
    requested_phase=phase
    var at:=safe_summon()
    if not at.is_finite(): return
    summons.append({"at":at,"phase":phase,"left":1.15,"generation":generation})
func safe_summon() -> Vector2:
    var candidates: Array[float]=[]
    for i in 5: candidates.append(actor.encounter_bounds.x+60+i*(actor.encounter_bounds.y-actor.encounter_bounds.x-120)/4)
    candidates.sort_custom(func(a,b) -> bool: return absf(a-actor.target.position.x)>absf(b-actor.target.position.x))
    for x in candidates:
        if absf(x-actor.target.position.x)<150 or absf(x-actor.position.x)<48: continue
        if guards.any(func(g) -> bool: return is_instance_valid(g) and g.health.current>0 and absf(x-g.position.x)<48): continue
        if summons.any(func(r) -> bool: return absf(x-r.at.x)<48): continue
        return Vector2(x,288)
    return Vector2.INF
func spawn_guard(record: Dictionary) -> void:
    if record.generation!=generation or actor.health.current<=0 or actor.target.dead or not actor.encounter_enabled: return
    var guard: RemixEnemy=SpiderEnemy.new() if record.phase==1 else RemixEnemy.new()
    guard.data=load("res://resources/enemies/spider.tres").duplicate() if record.phase==1 else load("res://resources/enemies/warped_archer.tres").duplicate()
    guard.data.label="裂隙蜘蛛" if record.phase==1 else "裂隙射手"
    guard.data.max_health=12
    guard.data.awareness=540
    guard.data.patrol_radius=80
    guard.data.contact_damage=2 if record.phase==1 else 0
    if record.phase==2:
        guard.data.aim_seconds=0.9
        guard.data.shot_recovery=1.6
        guard.data.arrow_speed=220
    guard.target=actor.target
    guard.view_camera=actor.view_camera
    guard.ui_font=actor.ui_font
    guard.position=record.at
    actor.get_parent().add_child(guard)
    guard.hitstun=0.6
    guards.append(guard)
    var level:=get_tree().current_scene
    if level.has_method("_enemy_fired"): guard.fired.connect(level._enemy_fired)
    guard.health.damaged.connect(func(_event: DamageEvent) -> void:
        if is_instance_valid(level): level.sound.play_effect(&"hit"))
    print("WARDEN_GUARD phase=%d kind=%s"%[record.phase,guard.data.label])
func begin_rift() -> void:
    rift_age=0
    rift_left=RIFT_WARNING+RIFT_ACTIVE
    rift_casts+=1
    var x: float=clampf(actor.target.position.x,actor.encounter_bounds.x+48,actor.encounter_bounds.y-48)
    var toward:=1 if x<(actor.encounter_bounds.x+actor.encounter_bounds.y)/2 else -1
    rift_points=[Vector2(x,288),Vector2(x+toward*144,288)]
    rift_event=DamageEvent.create(actor,2,4,Vector2(0,-100))
func _physics_process(delta: float) -> void:
    if actor.health.current<=0 or actor.target.dead or not actor.encounter_enabled:
        if not guards.is_empty() or not summons.is_empty() or rift_left>0: clear_all()
        return
    phase_banner=maxf(0,phase_banner-delta)
    for request in summons.duplicate():
        request.left-=delta
        if request.left>0: continue
        # A player entering a spawn marker postpones it, never spawns on them.
        if absf(request.at.x-actor.target.position.x)<75 or absf(request.at.x-actor.position.x)<38:
            var replacement:=safe_summon()
            if replacement.is_finite(): request.at=replacement
            request.left=1.15
            continue
        summons.erase(request)
        spawn_guard.call_deferred(request)
    if rift_left>0:
        rift_age+=delta
        rift_left=maxf(0,rift_left-delta)
        if rift_age>=RIFT_WARNING and rift_left>0:
            var body:=Rect2(actor.target.position+Vector2(-9,-44),Vector2(18,44))
            for point in rift_points:
                if Rect2(point-Vector2(RIFT_WIDTH/2,RIFT_HEIGHT),Vector2(RIFT_WIDTH,RIFT_HEIGHT)).intersects(body):
                    actor.target.get_node("Health").queue_damage(rift_event)
    queue_redraw()
func clear_all() -> void:
    generation+=1
    summons.clear()
    var source_ids: Array[int]=[]
    for guard in guards:
        if not is_instance_valid(guard): continue
        source_ids.append(guard.get_instance_id())
        guard.set_physics_process(false)
        guard.receiver.set_deferred("collision_layer",0)
        guard.queue_free()
    for projectile in get_tree().get_nodes_in_group("projectiles"):
        if projectile is ArrowProjectile and is_instance_valid(projectile.event) and projectile.event.source_id in source_ids: projectile.retire()
    guards.clear()
    requested_phase=0
    phase_banner=0
    rift_left=0
    rift_age=0
    rift_points.clear()
    rift_event=null
    rift_casts=0
    queue_redraw()
func _draw() -> void:
    for request in summons:
        var at:=to_local(request.at)
        draw_rect(Rect2(at+Vector2(-22,-5),Vector2(44,5)),Color("e5aeef"))
        draw_rect(Rect2(at+Vector2(-22,-48),Vector2(44,48)),Color("d69aef"),false,1)
        draw_string(actor.ui_font,at+Vector2(-31,-56),"%s %.1f"%["蜘蛛将至" if request.phase==1 else "射手将至",request.left],HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("eec8fa"))
    if rift_left>0:
        var active:=rift_age>=RIFT_WARNING
        for point in rift_points:
            var at:=to_local(point)
            var rect:=Rect2(at-Vector2(RIFT_WIDTH/2,RIFT_HEIGHT),Vector2(RIFT_WIDTH,RIFT_HEIGHT))
            draw_rect(rect,Color(1,0.12,0.30,0.40 if active else 0.10+0.06*sin(rift_age*22)))
            draw_rect(rect,Color("ff829c"),false,2)
            draw_rect(Rect2(at+Vector2(-RIFT_WIDTH/2,-5),Vector2(RIFT_WIDTH,5)),Color("ff476c"))
            if active:
                for i in 4:
                    var x:=at.x-24+i*16
                    draw_line(Vector2(x,at.y-4),Vector2(x+sin(rift_age*25+i)*5,at.y-RIFT_HEIGHT+8),Color("f3b4ff"),3)
            else: draw_string(actor.ui_font,at+Vector2(-26,-RIFT_HEIGHT-8),"爆发 %.1f"%(RIFT_WARNING-rift_age),HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("ffc4d2"))
    if phase_banner>0:
        var at:=to_local(Vector2(actor.view_camera.global_position.x,151))
        draw_rect(Rect2(at-Vector2(112,19),Vector2(224,29)),Color("321b49"))
        draw_line(at-Vector2(112,18),at+Vector2(112,-18),Color("ed9aff"),2)
        draw_string(actor.ui_font,at+Vector2(-90,0),"第二阶段 · 裂隙狂怒",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("f5cdff"))
