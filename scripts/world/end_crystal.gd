class_name EndCrystal
extends Node2D
const ART=preload("res://assets/art/m4-dragon/crystal.png")
var health: HealthComponent
var receiver: CombatHurtbox
var dragon: EnderDragon
var active:=false
var warning_left:=0.0
var burst_left:=0.0
var healing_used:=0
var explosions:=0
var seconds:=0.0
func _ready() -> void:
    process_physics_priority=85
    health=HealthComponent.new()
    health.max_health=12
    health.faction=2
    health.invulnerability_seconds=0
    health.strongest_per_tick=false
    add_child(health)
    health.process_physics_priority=70
    receiver=CombatHurtbox.new()
    receiver.health=health
    receiver.size=Vector2(26,36)
    add_child(receiver)
    receiver.collision_layer=0
    health.died.connect(func() -> void:
        receiver.set_deferred("collision_layer",0)
        warning_left=0.65 if active else 0.0)
func set_active(value: bool) -> void:
    active=value
    receiver.set_deferred("collision_layer",16 if active and health.current>0 else 0)
    if not value: warning_left=0; burst_left=0
func reset_crystal() -> void:
    health.reset_health()
    healing_used=0
    explosions=0
    set_active(false)
func _physics_process(delta: float) -> void:
    seconds+=delta
    burst_left=maxf(0,burst_left-delta)
    if warning_left>0 and active:
        # Postpone the burst until the current attack ends; never combine
        # crystal splash with a committed dive/breath/bite.
        warning_left=maxf(0.001,warning_left-delta)
        if warning_left<=0.001 and dragon.battle not in [EnderDragon.Battle.BREATH,EnderDragon.Battle.DIVE,EnderDragon.Battle.BITE,EnderDragon.Battle.TAIL]:
            warning_left=0
            burst_left=0.35
            explosions+=1
            var shape:=CircleShape2D.new()
            shape.radius=44
            var query:=PhysicsShapeQueryParameters2D.new()
            query.shape=shape
            query.transform=Transform2D(0,global_position)
            query.collision_mask=8
            query.collide_with_areas=true
            query.collide_with_bodies=false
            var event:=DamageEvent.create(self,2,3)
            for hit in get_world_2d().direct_space_state.intersect_shape(query): hit.collider.receive(event)
    queue_redraw()
func _draw() -> void:
    if health.current>0:
        var tint:=Color.WHITE if active else Color("73718d")
        draw_texture_rect(ART,Rect2(-22,-26+sin(seconds*2)*2,44,48),false,tint)
        draw_rect(Rect2(-15,-33,30,2),Color("352443"))
        draw_rect(Rect2(-15,-33,30.0*health.current/12,2),Color("edb5ff"))
    else:
        for i in 5: draw_rect(Rect2(-15+i*7,18-i%2*3,5,3),Color("726388"))
    if warning_left>0:
        draw_circle(Vector2.ZERO,44,Color(0.9,0.12,0.45,0.12))
        draw_arc(Vector2.ZERO,44,0,TAU,40,Color("ff719f"),2)
        for i in 8:
            var p:=Vector2.from_angle(i*TAU/8+seconds*3)*36
            draw_rect(Rect2(p,Vector2(3,3)),Color("ffe0ed"))
    if burst_left>0:
        draw_arc(Vector2.ZERO,44*(1-burst_left/0.35),0,TAU,32,Color("ffb9ed"),3)
