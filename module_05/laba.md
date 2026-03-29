## Задание 1
### Текст задания
Бизнес-задача: На шахту «Южная» (mine_id = 2) поступил новый шахтный самосвал.

Требования:

Таблица: practice_dim_equipment
Данные:
equipment_id: 200
equipment_type_id: 2 (шахтный самосвал)
mine_id: 2
equipment_name: 'Самосвал МоАЗ-7529'
inventory_number: 'INV-TRK-200'
manufacturer: 'МоАЗ'
model: '7529'
year_manufactured: 2025
commissioning_date: '2025-03-15'
status: 'active'
has_video_recorder: TRUE
has_navigation: TRUE
Проверка: выполните SELECT и убедитесь, что запись создана.
### Решение
```
insert into practice_dim_equipment(equipment_id,equipment_type_id, mine_id,equipment_name,inventory_number,manufacturer,model,year_manufactured,commissioning_date,status,has_video_recorder,has_navigation) 
            values(200,2,2,'Самосвал МоАЗ-7529','INV-TRK-200','МоАЗ','7529',2025,'2025-03-15','active',true,true);
select * from practice_dim_equipment where equipment_id=200;
```
### Результат
```
equipment_id|equipment_type_id|mine_id|equipment_name    |inventory_number|manufacturer|model|year_manufactured|commissioning_date|status|has_video_recorder|has_navigation|
------------+-----------------+-------+------------------+----------------+------------+-----+-----------------+------------------+------+------------------+--------------+
         200|                2|      2|Самосвал МоАЗ-7529|INV-TRK-200     |МоАЗ        |7529 |             2025|        2025-03-15|active|true              |true          |
```

## Задание 2
### Текст задания
Бизнес-задача: На предприятие приняты 3 новых оператора.

Требования:

Таблица: practice_dim_operator
Добавить одним INSERT:
operator_id	tab_number	last_name	first_name	middle_name	position	qualification	hire_date	mine_id
200	TAB-200	Сидоров	Михаил	Иванович	Машинист ПДМ	4 разряд	2025-03-01	1
201	TAB-201	Петрова	Елена	Сергеевна	Оператор скипа	3 разряд	2025-03-01	2
202	TAB-202	Волков	Дмитрий	Алексеевич	Водитель самосвала	5 разряд	2025-03-10	2
Проверка: должно быть 3 новых строки с operator_id >= 200.

### Решение
```
INSERT INTO practice_dim_operator (
    operator_id,
    tab_number,
    last_name,
    first_name,
    middle_name,
    position,
    qualification,
    hire_date,
    mine_id
)
VALUES 
    (200, 'TAB-200', 'Сидоров', 'Михаил', 'Иванович', 'Машинист ПДМ', '4 разряд', '2025-03-01', 1),
    (201, 'TAB-201', 'Петрова', 'Елена', 'Сергеевна', 'Оператор скипа', '3 разряд', '2025-03-01', 2),
    (202, 'TAB-202', 'Волков', 'Дмитрий', 'Алексеевич', 'Водитель самосвала', '5 разряд', '2025-03-10', 2);

SELECT 
    operator_id,
    tab_number,
    last_name,
    first_name,
    middle_name,
    position,
    qualification,
    hire_date,
    mine_id
FROM practice_dim_operator
WHERE operator_id >= 200
ORDER BY operator_id;
```
### Результат
```
operator_id|tab_number|last_name|first_name|middle_name|position          |qualification|hire_date |mine_id|
-----------+----------+---------+----------+-----------+------------------+-------------+----------+-------+
        200|TAB-200   |Сидоров  |Михаил    |Иванович   |Машинист ПДМ      |4 разряд     |2025-03-01|      1|
        201|TAB-201   |Петрова  |Елена     |Сергеевна  |Оператор скипа    |3 разряд     |2025-03-01|      2|
        202|TAB-202   |Волков   |Дмитрий   |Алексеевич |Водитель самосвала|5 разряд     |2025-03-10|      2|
```
## Задание 3
### Текст задания
Бизнес-задача: В staging_production находятся записи о добыче. Нужно перенести только валидированные записи (is_validated = TRUE) в practice_fact_production, исключив дубликаты.

Требования:

Источник: staging_production (WHERE is_validated = TRUE)
Назначение: practice_fact_production
production_id: используйте формулу 3000 + staging_id
Условие исключения дубликатов: NOT EXISTS по комбинации (date_id, shift_id, equipment_id, operator_id)
Проверка: подсчитайте количество строк до и после INSERT.

Ожидаемый результат: 4 новых записи (1 запись с is_validated = FALSE пропущена).
### Решение
```
select count(*) from practice_fact_production pfp;

INSERT INTO practice_fact_production
(production_id,
date_id,
shift_id,
mine_id,
shaft_id,
equipment_id,
operator_id,
location_id,
ore_grade_id,
tons_mined,
tons_transported,
trips_count,
distance_km,
fuel_consumed_l,
operating_hours,
loaded_at)
SELECT 3000+staging_id,
	   date_id,
	   shift_id,
	   mine_id,
	   shaft_id,
	   equipment_id,
	   operator_id, 
	   location_id, 
	   ore_grade_id, 
	   tons_mined, 
	   tons_transported, 
	   trips_count, 
	   distance_km, 
	   fuel_consumed_l, 
	   operating_hours,
	   loaded_at
FROM staging_production WHERE NOT EXISTS (
    SELECT 1 
    FROM practice_fact_production pfp
    WHERE pfp.date_id = staging_production.date_id
        AND pfp.shift_id = staging_production.shift_id
        and pfp.shaft_id=staging_production.shaft_id
        AND pfp.equipment_id = staging_production.equipment_id
        AND pfp.operator_id = staging_production.operator_id
) and is_validated=true;

select count(*) from practice_fact_production pfp;
```
### Результат
```
count|
-----+
  472|

count|
-----+
  476|
```

## Задание 4
### Текст задания
Бизнес-задача: Добавить новый тип сорта руды и записать факт добавления в лог.

Требования:

Вставить в practice_dim_ore_grade:
ore_grade_id: 300
grade_name: 'Экспортный'
grade_code: 'EXPORT'
fe_content_min: 63.00
fe_content_max: 68.00
description: 'Руда для экспортных поставок'
Использовать RETURNING для получения ore_grade_id и grade_name
На основе полученных данных вставить запись в practice_equipment_log:
equipment_id: 0 (справочные данные)
action: 'INSERT'
details: 'Добавлен сорт руды: Экспортный (EXPORT)'
Подсказка: Используйте CTE (WITH ... AS) для объединения INSERT ... RETURNING и второго INSERT.
### Решение
```
WITH new_ore_grade AS (
    INSERT INTO practice_dim_ore_grade (
        ore_grade_id,
        grade_name,
        grade_code,
        fe_content_min,
        fe_content_max,
        description
    )
    VALUES (
        300,
        'Экспортный',
        'EXPORT',
        63.00,
        68.00,
        'Руда для экспортных поставок'
    )
    RETURNING ore_grade_id, grade_name, grade_code
)
INSERT INTO practice_equipment_log (
    equipment_id,
    action,
    details
)
SELECT 
    0 AS equipment_id,
    'INSERT' AS action,
    'Добавлен сорт руды: ' || grade_name || ' (' || grade_code || ')' AS details
FROM new_ore_grade;

SELECT * FROM practice_dim_ore_grade WHERE ore_grade_id = 300;
SELECT * FROM practice_equipment_log WHERE details LIKE '%Экспортный%';
```
### Результат
```
ore_grade_id|grade_name|grade_code|fe_content_min|fe_content_max|description                 |
------------+----------+----------+--------------+--------------+----------------------------+
         300|Экспортный|EXPORT    |         63.00|         68.00|Руда для экспортных поставок|

log_id|equipment_id|action|old_status|new_status|changed_by|changed_at             |details                                |
------+------------+------+----------+----------+----------+-----------------------+---------------------------------------+
     1|           0|INSERT|          |          |user1     |2026-03-29 11:41:44.037|Добавлен сорт руды: Экспортный (EXPORT)|
```

## Задание 5
### Текст задания
Бизнес-задача: По итогам ежемесячного осмотра необходимо обновить статусы оборудования.

Требования:

Перевести в статус 'maintenance' все единицы оборудования шахты «Северная» (mine_id = 1), у которых year_manufactured <= 2018
Использовать UPDATE ... RETURNING для получения списка затронутых единиц
Проверка: Выведите equipment_id, equipment_name, year_manufactured для всех единиц со статусом 'maintenance'.
### Решение
```
update practice_dim_equipment pde set status='maintenance' where pde.year_manufactured<=2018 and pde.mine_id=1 returning equipment_id,equipment_name,year_manufactured,status;

```
### Результат
```
equipment_id|equipment_name|year_manufactured|status     |
------------+--------------+-----------------+-----------+
           3|ПДМ-003       |             2018|maintenance|
          12|Вагонетка-001 |             2016|maintenance|
          13|Вагонетка-002 |             2016|maintenance|
          16|Скип-001      |             2010|maintenance|
          17|Скип-002      |             2015|maintenance|

```

## Задание 6
### Текст задания
Бизнес-задача: Установить флаг has_navigation = TRUE для всего оборудования, которое имеет хотя бы один активный датчик навигации (sensor_type_id, соответствующий типу 'NAV').

Требования:

Таблица: practice_dim_equipment
Подзапрос: выбрать equipment_id из dim_sensor, у которых sensor_type_id соответствует навигационному типу датчика
Обновить только те записи, где has_navigation = FALSE
Подсказка: Используйте JOIN с dim_sensor_type для определения типа датчика.
### Решение
```
update practice_dim_equipment pde set has_navigation=true where pde.equipment_id in (select equipment_id from "public".dim_sensor ds join "public".dim_sensor_type dst on ds.sensor_type_id=dst.sensor_type_id where dst.type_code like '%NAV%') and pde.has_navigation=false;
```

## Задание 7
### Текст задания
Бизнес-задача: Удалить все аварийные показания телеметрии (is_alarm = TRUE) за 15 марта 2024 г., но сохранить их в архиве.

Требования:

Использовать CTE с DELETE ... RETURNING
Вставить удалённые данные в practice_archive_telemetry
После операции проверить:
В practice_fact_telemetry нет записей с is_alarm = TRUE за 20240315
В practice_archive_telemetry появились архивные записи
Ожидаемый результат:

Количество удалённых/архивированных записей зависит от текущего состояния данных
В архивной таблице поле archived_at заполнено автоматически

### Решение
```
WITH deleted_telemetry AS (
    DELETE FROM practice_fact_telemetry
    WHERE date_id = 20240315
        AND is_alarm = TRUE
    RETURNING *
)
INSERT INTO practice_archive_telemetry (
    telemetry_id,
    date_id,
    time_id,
    equipment_id,
    sensor_id,
    location_id,
    sensor_value,
    is_alarm,
    quality_flag,
    loaded_at,
    archived_at
)
SELECT 
    telemetry_id,
    date_id,
    time_id,
    equipment_id,
    sensor_id,
    location_id,
    sensor_value,
    is_alarm,
    quality_flag,
    loaded_at,
    CURRENT_TIMESTAMP AS archived_at
FROM deleted_telemetry;
```

## Задание 8
### Текст задания
Бизнес-задача: Синхронизировать справочник причин простоев из staging-таблицы.

Требования:

Целевая таблица: practice_dim_downtime_reason
Источник: staging_downtime_reasons
Ключ соединения: reason_code
WHEN MATCHED: обновить reason_name, category, description
WHEN NOT MATCHED: вставить новую запись (сгенерировать reason_id = MAX + 1)
Проверка:

Перед MERGE: посмотрите содержимое обеих таблиц
После MERGE: убедитесь, что:
Существующие записи обновлены
Новые записи добавлены
Нет дубликатов по reason_code
### Решение
```

WITH max_id AS (
    SELECT COALESCE(MAX(reason_id), 0) AS max_reason_id 
    FROM practice_dim_downtime_reason
)
MERGE INTO practice_dim_downtime_reason AS target
USING (
    SELECT 
        s.reason_name,
        s.reason_code,
        s.category,
        s.description,
        ROW_NUMBER() OVER (ORDER BY s.reason_code) + (SELECT max_reason_id FROM max_id) AS new_id
    FROM staging_downtime_reasons s
) AS source
ON target.reason_code = source.reason_code
WHEN MATCHED THEN
    UPDATE SET
        reason_name = source.reason_name,
        category = source.category,
        description = source.description
WHEN NOT MATCHED THEN
    INSERT (reason_id, reason_name, reason_code, category, description)
    VALUES (source.new_id, source.reason_name, source.reason_code, source.category, source.description);
```
### Результат
```
reason_id|reason_name                      |reason_code|category       |description                                |
---------+---------------------------------+-----------+---------------+-------------------------------------------+
        1|Плановое техническое обслуживание|MAINT_PLAN |плановый       |Регламентное ТО по графику                 |
        2|Аварийный ремонт                 |REPAIR_EMRG|внеплановый    |Отказ узла или агрегата                    |
        3|Замена шин / гусениц             |TIRE_CHANGE|плановый       |Плановая замена ходовой части              |
        4|Отсутствие оператора             |NO_OPERATOR|организационный|Оператор не вышел на смену                 |
        5|Ожидание погрузки                |WAIT_LOAD  |организационный|Простой в ожидании погрузки                |
        6|Ожидание транспорта              |WAIT_TRANS |организационный|Простой в ожидании самосвала               |
        7|Заправка топливом                |REFUELING  |плановый       |Заправка машины дизтопливом                |
        8|Перегрев двигателя               |OVERHEAT   |внеплановый    |Остановка из-за перегрева                  |
        9|Обрушение породы                 |ROCK_FALL  |внеплановый    |Остановка из-за геологических условий      |
       10|Проветривание забоя              |VENTILATION|плановый       |Ожидание проветривания после взрывных работ|
       11|Электроснабжение                 |POWER_OUT  |внеплановый    |Перебои в электроснабжении                 |
       12|Диагностика и калибровка         |DIAGNOSTICS|плановый       |Диагностика и настройка оборудования       |
       13|Замена ковша                     |BUCKET_RPL |плановый       |Замена изношенного ковша ПДМ               |
       14|Поломка ходовой части            |CHASSIS_BRK|внеплановый    |Внеплановый ремонт ходовой части           |
       15|Плановое ТО двигателя            |ENG_MAINT  |плановый       |Регламентное техобслуживание двигателя     |
       16|Замена гидравлического масла     |HYD_OIL    |плановый       |Плановая замена гидравлического масла      |
       17|Отказ датчика навигации          |NAV_FAIL   |внеплановый    |Выход из строя навигационного модуля       |
```

## Задание 9
### Текст задания
Бизнес-задача: Реализовать идемпотентную загрузку операторов. Скрипт должен быть безопасен для повторного запуска.

Требования:

Написать INSERT ... ON CONFLICT для таблицы practice_dim_operator
Вставить/обновить 3 записи:
TAB-200: если существует — обновить position и qualification
TAB-201: если существует — обновить position и qualification
TAB-NEW: новый оператор — вставить
Конфликт по: tab_number
При конфликте: обновить только position и qualification (DO UPDATE SET)
Проверка: запустите запрос дважды. Результат должен быть одинаковым.
### Решение
```
INSERT INTO practice_dim_operator (
	operator_id,
    tab_number,
    last_name,
    first_name,
    middle_name,
    position,
    qualification,
    hire_date,
    mine_id,
    status
)
VALUES 
    (100,'TAB-200', 'Сидоров', 'Михаил', 'Иванович', 'Машинист ПДМ', '4 разряд', '2025-03-01', 1, 'active'),
    (101,'TAB-201', 'Петрова', 'Елена', 'Сергеевна', 'Оператор скипа', '3 разряд', '2025-03-01', 2, 'active'),
    (102,'TAB-NEW', 'Волков', 'Дмитрий', 'Алексеевич', 'Водитель самосвала', '5 разряд', '2025-03-10', 2, 'active')
ON CONFLICT (tab_number) 
DO UPDATE SET
    position = EXCLUDED.position,
    qualification = EXCLUDED.qualification;

```
### Результат
```
operator_id|tab_number|last_name|first_name|middle_name  |position          |qualification|hire_date |mine_id|status|
-----------+----------+---------+----------+-------------+------------------+-------------+----------+-------+------+
          1|ТН-001    |Иванов   |Алексей   |Петрович     |Машинист ПДМ      |5 разряд     |2015-03-01|      1|active|
          2|ТН-002    |Петров   |Сергей    |Николаевич   |Машинист ПДМ      |5 разряд     |2016-07-15|      1|active|
          3|ТН-003    |Сидоров  |Дмитрий   |Александрович|Машинист самосвала|4 разряд     |2018-01-10|      1|active|
          4|ТН-004    |Козлов   |Андрей    |Викторович   |Машинист самосвала|5 разряд     |2014-09-20|      1|active|
          5|ТН-005    |Новиков  |Михаил    |Сергеевич    |Машинист ПДМ      |4 разряд     |2019-04-05|      2|active|
          6|ТН-006    |Морозов  |Владимир  |Иванович     |Машинист ПДМ      |5 разряд     |2013-11-12|      2|active|
          7|ТН-007    |Волков   |Николай   |Дмитриевич   |Машинист самосвала|4 разряд     |2020-02-01|      2|active|
          8|ТН-008    |Соловьёв |Павел     |Андреевич    |Оператор подъёма  |5 разряд     |2012-06-01|      1|active|
          9|ТН-009    |Лебедев  |Евгений   |Михайлович   |Оператор подъёма  |4 разряд     |2017-08-20|      2|active|
         10|ТН-010    |Кузнецов |Игорь     |Олегович     |Машинист ПДМ      |3 разряд     |2022-01-15|      1|active|
        100|TAB-200   |Сидоров  |Михаил    |Иванович     |Машинист ПДМ      |4 разряд     |2025-03-01|      1|active|
        101|TAB-201   |Петрова  |Елена     |Сергеевна    |Оператор скипа    |3 разряд     |2025-03-01|      2|active|
        102|TAB-NEW   |Волков   |Дмитрий   |Алексеевич   |Водитель самосвала|5 разряд     |2025-03-10|      2|active|

```