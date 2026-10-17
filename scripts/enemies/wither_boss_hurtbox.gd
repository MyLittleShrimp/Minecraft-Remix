extends CombatHurtbox
func receive(event: DamageEvent) -> void:
    var boss: WitherBoss=get_parent()
    if boss.active and boss.health.current>0: health.queue_damage(event)
