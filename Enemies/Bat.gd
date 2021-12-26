extends KinematicBody2D

const EnemyDeathEffect = preload("res://Effects/EnemyDeathEffect.tscn")

export var ACCELERATION = 300
export var MAX_SPEED = 50
export var FRICTION = 200

enum {
	IDLE,
	WANDER,
	CHASE
}

var velocity = Vector2.ZERO
var knockback = Vector2.ZERO
var state = CHASE

onready var sprite = $Sprite
onready var stats = $Stats
onready var player_detection_zone = $PlayerDetectionZone
onready var hurtbox = $Hurtbox
onready var soft_collision = $SoftCollision
onready var wander_controller = $WanderController

func _physics_process(delta):
	knockback = knockback.move_toward(Vector2.ZERO, FRICTION * delta)
	knockback = move_and_slide(knockback)
	
	match state:
		IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
			seek_player()
			reset_wander_if_timer_exhausted()
		WANDER:
			seek_player()
			reset_wander_if_timer_exhausted()
			move_toward_point(wander_controller.target_position, delta)
			if global_position.distance_to(wander_controller.target_position) < MAX_SPEED * delta:
				state = pick_random_state([IDLE, WANDER])
		CHASE:
			var player = player_detection_zone.player
			if player != null:
				move_toward_point(player.global_position, delta)
			else:
				state = IDLE

	if soft_collision.is_colliding():
		velocity += soft_collision.get_push_vector() * delta * 400
	velocity = move_and_slide(velocity)

func move_toward_point(point, delta):
	var dir = global_position.direction_to(point)
	velocity = velocity.move_toward(dir * MAX_SPEED, ACCELERATION * delta)
	sprite.flip_h = velocity.x < 0

func reset_wander_if_timer_exhausted():
	if wander_controller.get_time_left() <= 0:
		state = pick_random_state([IDLE, WANDER])
		wander_controller.start_wander_timer(rand_range(1, 3))

func seek_player():
	if player_detection_zone.can_see_player():
		state = CHASE

func pick_random_state(state_list):
	state_list.shuffle()
	return state_list.pop_front()

func _on_Hurtbox_area_entered(area):
	stats.health -= area.damage
	knockback = area.knockback_vector * 120
	hurtbox.create_hit_effect()

func _on_Stats_no_health():
	queue_free()
	var enemyDeathEffect = EnemyDeathEffect.instance()
	get_parent().add_child(enemyDeathEffect)
	enemyDeathEffect.global_position = global_position
