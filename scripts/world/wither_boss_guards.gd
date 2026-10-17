class_name WitherBossGuards
extends Node2D
## Two prewarmed, finite reinforcements. No scene creation on phase change.
const SLOTS: Array[float]=[420.0,600.0,680.0,860.0]
var level: Node
var arena_offset := 0.0
var guards: Array[WitherSkeleton]=[]
var pending: Array[Dictionary]=[]
var requested:=false
var spawned:=0
func _ready() -> void:
    process_physics_priority=2
    WitherArt.prepare()
    for i in 2:
        var guard:=WitherSkeleton.new()
        guard.data=preload("res://resources/enemies/wither_skeleton.tres").duplicate()
        guard.data.label="凋灵骷髅护卫"
        guard.encounter_bounds=Vector2(344+arena_offset,936+arena_offset)
        guard.active=false
        guard.target=level.player
        guard.view_camera=level.camera
        guard.ui_font=level.ui_font
        guard.position=Vector2(SLOTS[i*3]+arena_offset,288)
        add_child(guard)
        guard.health.damaged.connect(func(_event: DamageEvent) -> void: level.sound.play_effect(&"hit"))
        guards.append(guard)
    clear()
func clear() -> void:
    pending.clear()
    requested=false
    spawned=0
    for guard in guards:
        guard.set_active(false)
        guard.health.pending.clear()
        guard.collision_layer=0
        guard.process_mode=Node.PROCESS_MODE_DISABLED
        guard.visible=false
    queue_redraw()
func request(phase: int) -> void:
    if phase!=2 or requested or not level.arena_active or level.wither_boss.health.current<=0: return
    requested=true
    for i in 2:
        var x:=safe_slot()
        pending.append({"index":i,"x":x,"left":1.1+i*0.45})
    level.toast="狂暴增援 · 两名凋灵骷髅即将入场，避开地面符文"
    level.toast_left=3.5
    queue_redraw()
func safe_slot(ignore_index: int=-1) -> float:
    var choices:=SLOTS.duplicate()
    for i in choices.size(): choices[i]+=arena_offset
    choices.sort_custom(func(a: float,b: float) -> bool: return absf(a-level.player.position.x)>absf(b-level.player.position.x))
    for x in choices:
        if absf(x-level.player.position.x)<100: continue
        if pending.any(func(p: Dictionary) -> bool: return p.index!=ignore_index and absf(p.x-x)<120): continue
        if guards.any(func(g: WitherSkeleton) -> bool: return g.active and g.health.current>0 and absf(g.position.x-x)<56): continue
        return x
    return -1.0
func live_count() -> int:
    var count:=0
    for guard in guards:
        if guard.active and guard.health.current>0: count+=1
    return count
func overlaps(area: Rect2) -> bool:
    for guard in guards:
        if guard.active and guard.health.current>0 and area.intersects(Rect2(guard.global_position-Vector2(10,42),Vector2(20,42))): return true
    return false
func _physics_process(delta: float) -> void:
    if not level.arena_active or level.defeated or level.completed or level.wither_boss.health.current<=0: return
    for record in pending.duplicate():
        # Recheck after the player has seen the marker: never materialize on them.
        if record.x<0 or absf(record.x-level.player.position.x)<80:
            record.x=safe_slot(record.index)
            record.left=maxf(record.left,0.9)
            continue
        record.left-=delta
        if record.left<=0:
            var guard:=guards[int(record.index)]
            guard.reset_target()
            guard.position=Vector2(record.x,288)
            guard.spawn_point=guard.position
            guard.collision_layer=32
            guard.visible=true
            guard.process_mode=Node.PROCESS_MODE_INHERIT
            guard.set_active(true)
            pending.erase(record)
            spawned+=1
            print("WITHER_GUARD index=%d x=%.0f"%[record.index,record.x])
    queue_redraw()
func _draw() -> void:
    for record in pending:
        if record.x<0: continue
        var at:=Vector2(record.x,285)
        draw_arc(at,22,PI,TAU,16,Color("dca3ef"),2)
        draw_line(at-Vector2(26,0),at+Vector2(26,0),Color("f0b3a6"),2)
        for i in 5:
            var rise:=fposmod(record.left*32+i*8,30)
            draw_rect(Rect2(at+Vector2(i*9-18,-rise-3),Vector2(2,3)),Color("ad80ce"))
        draw_string(level.ui_font,at+Vector2(-34,-39),"骸骨增援 %.1f"%record.left,HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("ffe4c1"))
