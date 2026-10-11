extends CharacterBody3D

@export var move_speed := 6.0
@export var sprint_speed := 9.0
@export var acceleration := 12.0
@export var rotation_speed := 10.0
@export var max_hp := 100
@export var attack_damage := 25
@export var attack_range := 2.2
@export var attack_cooldown := 0.65

var hp := 100
var level := 1
var experience := 0
var gold := 0
var can_attack := true

@onready var camera_pivot: Node3D = $CameraPivot

func _ready() -> void:
	hp = max_hp
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * 0.003)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x - event.relative.y * 0.003, -0.9, 0.45)
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event.is_action_pressed("attack"):
		attack()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 20.0 * delta

	var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_vec.x, 0.0, input_vec.y)).normalized()
	var speed := sprint_speed if Input.is_action_pressed("sprint") else move_speed
	var target := direction * speed
	velocity.x = move_toward(velocity.x, target.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target.z, acceleration * delta)
	move_and_slide()

func attack() -> void:
	if not can_attack:
		return
	can_attack = false
	var enemies := get_tree().get_nodes_in_group("enemies")
	var closest: Node3D = null
	var closest_distance := attack_range
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var distance := global_position.distance_to(enemy.global_position)
		if distance <= closest_distance:
			closest = enemy
			closest_distance = distance
	if closest != null and closest.has_method("take_damage"):
		closest.take_damage(attack_damage, self)
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func gain_rewards(xp: int, coins: int) -> void:
	experience += xp
	gold += coins
	var needed := level * 100
	while experience >= needed:
		experience -= needed
		level += 1
		max_hp += 15
		hp = max_hp
		attack_damage += 3
		needed = level * 100

func take_damage(amount: int) -> void:
	hp = max(hp - amount, 0)
	if hp <= 0:
		global_position = Vector3(0, 1, 6)
		hp = max_hp
