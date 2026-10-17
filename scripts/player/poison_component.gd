class_name PoisonComponent
extends Node2D
const DURATION := 6.0
const INTERVAL := 2.0
var remaining := 0.0
var tick_left := INTERVAL
var ticks_total := 0
@onready var actor: RemixPlayer = get_parent()
@onready var health: HealthComponent = actor.get_node("Health")
func _ready() -> void:
    process_physics_priority=90
    health.damaged.connect(_on_damage)
    health.died.connect(clear)
func _on_damage(event: DamageEvent) -> void:
    if event.get_meta("poison_impact",false) and health.current>0:
        if remaining<=0: tick_left=INTERVAL
        remaining=DURATION # Refresh duration, never stack or postpone the next tick.
func clear() -> void:
    remaining=0
    tick_left=INTERVAL
    queue_redraw()
func _physics_process(delta: float) -> void:
    if actor.dead or actor.controls_locked or health.current<=0: return
    if remaining>0:
        var elapsed := minf(delta,remaining)
        tick_left-=elapsed
        remaining=maxf(0,remaining-delta)
        if tick_left<=0.0001:
            tick_left+=INTERVAL
            var event:=DamageEvent.create(self,0,1)
            event.bypass_invulnerability=true
            event.set_meta("poison_tick",true)
            health.queue_damage(event)
            ticks_total+=1
    queue_redraw()
func _draw() -> void:
    if remaining<=0: return
    for i in 4:
        var x := -13+posmod(i*11,27)
        var y := -12-posmod(int(remaining*16)+i*13,34)
        draw_rect(Rect2(x,y,3,3),Color("95e679"))
