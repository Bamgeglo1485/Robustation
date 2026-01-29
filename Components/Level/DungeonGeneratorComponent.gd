class_name DungeonGeneratorComponent extends Component

@export var dungeon_template: DungeonTemplate
@export var plating_tilemap: TileMapLayer
@export var wall_tilemap: TileMapLayer
 
# Массивы для хранения данных сетки и списка комнат
var grid = []
var rooms = []

# _ready вызывается, когда узел добавляется на сцену
func _ready():
	# Инициализация генератора случайных чисел
	randomize()
	# Создание сетки, заполненной стенами
	initialize_grid()
	# Генерация подземелья: размещение комнат и соединение их
	generate_dungeon()
	# Отрисовка подземелья на экране
	draw_dungeon()
 
# Инициализирует сетку, устанавливая все ячейки как стены (обозначаются 1)
func initialize_grid():
	for x in range(dungeon_template.WIDTH):
		grid.append([])  # Добавление новой строки в сетку
		for y in range(dungeon_template.HEIGHT):
			grid[x].append(1)  # Заполнение каждой ячейки в строке значением 1 (стена)
 
# Основная функция генерации подземелья: размещение комнат и их соединение
func generate_dungeon():
	for i in range(dungeon_template.MAX_ROOMS):
		# Генерация комнаты со случайным размером и позицией
		var room = generate_room()
		# Попытка разместить комнату в сетке
		if place_room(room):
			# Если это не первая комната, соединяем ее с предыдущей
			if rooms.size() > 0:
				connect_rooms(rooms[-1], room)  # Соединяем новую комнату с последней размещенной
			# Добавляем комнату в список комнат подземелья
			rooms.append(room)
 
# Генерирует комнату со случайной шириной, высотой и позицией в пределах сетки
func generate_room():
	# Определение ширины и высоты комнаты случайным образом в заданном диапазоне
	var width = randi() % (dungeon_template.MAX_ROOM_SIZE - dungeon_template.MIN_ROOM_SIZE + 1) + dungeon_template.MIN_ROOM_SIZE
	var height = randi() % (dungeon_template.MAX_ROOM_SIZE - dungeon_template.MIN_ROOM_SIZE + 1) + dungeon_template.MIN_ROOM_SIZE
	# Размещение комнаты случайным образом в сетке, гарантируя, что она вписывается в границы
	var x = randi() % (dungeon_template.WIDTH - width - 1) + 1
	var y = randi() % (dungeon_template.HEIGHT - height - 1) + 1
	# Возврат комнаты в виде объекта Rect2, представляющего ее позицию и размер
	return Rect2(x, y, width, height)
 
# Пытается разместить комнату в сетке, гарантируя отсутствие перекрытия с существующими комнатами
func place_room(room):
	# Проверка, перекрывается ли комната с существующими полами (ячейками со значением 0)
	for x in range(room.position.x, room.end.x):
		for y in range(room.position.y, room.end.y):
			if grid[x][y] == 0:  # Если ячейка уже является полом
				return false  # Комната не может быть размещена, возвращаем false
	
	# Если перекрытий не найдено, отмечаем область комнаты как полы (устанавливаем ячейки в 0)
	for x in range(room.position.x, room.end.x):
		for y in range(room.position.y, room.end.y):
			grid[x][y] = 0  # 0 представляет пол
	return true  # Комната успешно размещена, возвращаем true
 
# Соединяет две комнаты коридором, позволяя задавать ширину коридора
func connect_rooms(room1, room2):
	# Определение начальной точки коридора (центр room1)
	var start = Vector2(
		int(room1.position.x + room1.size.x / 2),
		int(room1.position.y + room1.size.y / 2))
	# Определение конечной точки коридора (центр room2)
	var end = Vector2(
		int(room2.position.x + room2.size.x / 2),
		int(room2.position.y + room2.size.y / 2))
	
	var current = start
	
	# Сначала двигаемся горизонтально к конечной точке
	while current.x != end.x:
		# Двигаемся на один шаг влево или вправо
		current.x += 1 if end.x > current.x else -1
		# Создаем коридор с указанной шириной
		@warning_ignore_start("integer_division")
		for i in range(-int(dungeon_template.CORRIDOR_WIDTH / 2), int(dungeon_template.CORRIDOR_WIDTH / 2) + 1):
			for j in range(-int(dungeon_template.CORRIDOR_WIDTH / 2), int(dungeon_template.CORRIDOR_WIDTH / 2) + 1):
				# Гарантируем, что не выходим за границы сетки
				if current.y + j >= 0 and current.y + j < dungeon_template.HEIGHT and current.x + i >= 0 and current.x + i < dungeon_template.WIDTH:
					grid[current.x + i][current.y + j] = 0  # Устанавливаем ячейки как пол
 	
	# Затем двигаемся вертикально к конечной точке
	while current.y != end.y:
		# Двигаемся на один шаг вверх или вниз
		current.y += 1 if end.y > current.y else -1
		# Создаем коридор с указанной шириной
		for i in range(-int(dungeon_template.CORRIDOR_WIDTH / 2), int(dungeon_template.CORRIDOR_WIDTH / 2) + 1):
			for j in range(-int(dungeon_template.CORRIDOR_WIDTH / 2), int(dungeon_template.CORRIDOR_WIDTH / 2) + 1):
				# Гарантируем, что не выходим за границы сетки
				if current.x + i >= 0 and current.x + i < dungeon_template.WIDTH and current.y + j >= 0 and current.y + j < dungeon_template.HEIGHT:
					grid[current.x + i][current.y + j] = 0  # Устанавливаем ячейки как пол

# Отрисовывает подземелье на экране, создавая визуальные представления сетки
func draw_dungeon():
	for x in range(dungeon_template.WIDTH):
		for y in range(dungeon_template.HEIGHT):
			var tile_position = Vector2i(x, y)
			if grid[x][y] == 0:
				plating_tilemap.set_cell(tile_position, 1, dungeon_template.base_plating_position)
			else:
				plating_tilemap.set_cell(tile_position, 1, Vector2i(-1, -1))
	
	var wall_positions: Array[Vector2i] = []
	
	for x in range(dungeon_template.WIDTH):
		for y in range(dungeon_template.HEIGHT):
			if grid[x][y] == 1:
				var has_adjacent_floor = false
				
				for dx in [-1, 0, 1]:
					for dy in [-1, 0, 1]:
						if dx == 0 and dy == 0:
							continue
							
						var nx = x + dx
						var ny = y + dy
						
						if nx >= 0 and nx < dungeon_template.WIDTH and ny >= 0 and ny < dungeon_template.HEIGHT:
							if grid[nx][ny] == 0:  # Соседняя ячейка - пол
								has_adjacent_floor = true
								break
					if has_adjacent_floor:
						break
				
				if has_adjacent_floor:
					wall_positions.append(Vector2i(x, y))
	
	for x in range(dungeon_template.WIDTH):
		for y in range(dungeon_template.HEIGHT):
			wall_tilemap.set_cell(Vector2i(x, y), 2, Vector2i(-1, -1))
	
	if wall_positions.size() > 0:
		
		wall_tilemap.set_cells_terrain_connect(
			wall_positions,
			0,
			0
		)
