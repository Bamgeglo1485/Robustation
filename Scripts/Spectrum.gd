class_name Spectrum extends Control

# The code was taken from a random source and modified 

const VU_COUNT = 50
const FREQ_MAX = 11050.0
const MIN_DB = 70
const LINE_WIDTH = 0.5

var spectrum: AudioEffectSpectrumAnalyzerInstance
var energy_history: Array[float] = []
var history_size: int = 100

@export var color_component: Component
@export var sensivity: float = 2

func _ready():
	spectrum = AudioServer.get_bus_effect_instance(0, 0)
	
	for i in range(history_size):
		energy_history.append(0.0)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw():
	if !spectrum:
		return
	
	var control_size = size
	var max_height = control_size.y
	var mid_height = max_height / 2
	
	var total_energy = 0.0
	var prev_hz = 0.0
	
	for i in range(VU_COUNT):
		var hz = (i + 1) * FREQ_MAX / VU_COUNT
		var magnitude: float = spectrum.get_magnitude_for_frequency_range(prev_hz, hz).length()
		var energy = clamp((MIN_DB + linear_to_db(magnitude)) / MIN_DB, 0, 1)
		total_energy += energy
		prev_hz = hz
	
	var avg_energy = total_energy / VU_COUNT
	
	energy_history.push_back(avg_energy)
	if energy_history.size() > history_size:
		energy_history.pop_front()
	
	var points: PackedVector2Array = []
	var step_x = control_size.x / (history_size - 1)
	
	for i in range(energy_history.size()):
		var x = i * step_x
		var energy = energy_history[i]
		var y = mid_height - (energy * mid_height * sensivity)
		points.append(Vector2(x, y))
	
	var color: Color = Color(0.97, 0.0, 0.45, 0.518)
	if color_component:
		color = color_component.color
	
	draw_polyline(points, color, LINE_WIDTH, true)
