extends CharacterBody3D

@export var max_hp := 60
@export var move_speed := 2.5
@export var detection_range := 10.0
@export var attack_range := 1.6
@export var damage := 8
@export var xp_reward := 35
@export var gold_reward := 12

var hp := 60
var target: Node3D
var attack_timer := 0.0

func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	target = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	attack_timer = max(attack_timer - delta, 0.0)
	if is_instance_valid(target):
		var distance := global_position.distance_to(target.global_position)
		if distance <= detection_range and distance > attack_range:
			var dir := (target.global_position - global_position)
			dir.y = 0
			dir = dir.normalized()
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed
			look_at(global_position + dir, Vector3.UP)
		elif distance <= attack_range:
			velocity.x = 0
			velocity.z = 0
			if attack_timer <= 0.0 and target.has_method("take_damage"):
				target.take_damage(damage)
				attack_timer = 1.2
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed * delta * 4)
			velocity.z = move_toward(velocity.z, 0, move_speed * delta * 4)
	move_and_slide()

func take_damage(amount: int, attacker: Node = null) -> void:
	hp -= amount
	if attacker != null:
		target = attacker
	if hp <= 0:
		if is_instance_valid(attacker) and attacker.has_method("gain_rewards"):
			attacker.gain_rewards(xp_reward, gold_reward)
		queue_free()
