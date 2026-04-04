## Задание 1
### Текст задания
Бизнес-задача: Рассчитать показатель общей эффективности оборудования (OEE) по формуле: OEE = (рабочие_часы / плановые_часы) * (фактическая_добыча / нормативная_добыча) * 100.

Требования:

Создайте функцию calc_oee(p_operating_hours NUMERIC, p_planned_hours NUMERIC, p_actual_tons NUMERIC, p_target_tons NUMERIC) с возвратом NUMERIC
Функция должна:
Возвращать NULL, если плановые часы или нормативная добыча = 0
Округлять результат до 1 десятичного знака
Быть помечена как IMMUTABLE
Протестируйте на примерах:
calc_oee(10, 12, 80, 100) — ожидаемый результат ~66.7
calc_oee(12, 12, 100, 100) — ожидаемый результат 100.0
calc_oee(8, 12, 0, 100) — ожидаемый результат 0.0
Используйте функцию в запросе к fact_production для расчёта OEE по оборудованию

### Решение
```
create or replace function calc_oee(p_operating_hours NUMERIC, p_planned_hours NUMERIC, p_actual_tons NUMERIC, p_target_tons NUMERIC)
returns numeric as $$
BEGIN
	IF p_planned_hours=0 or p_target_tons=0 THEN
		return NULL;
	else
		return ROUND(100*(p_operating_hours/p_planned_hours)*(p_actual_tons/p_target_tons),1);
	END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

select dd.full_date, calc_oee(fp.operating_hours, 12, fp.tons_mined, 100) 
from fact_production fp
join dim_date dd on fp.date_id=dd.date_id
;
```
### Результат
```
full_date |calc_oee|
----------+--------+
2024-01-01|    62.9|
2024-01-01|    74.0|
2024-01-01|    63.6|
2024-01-01|    64.1|
2024-01-01|   115.5|
2024-01-01|   117.0|
2024-01-01|   132.5|
2024-01-01|   140.8|
2024-01-01|    57.0|
2024-01-01|    67.7|
2024-01-01|    57.4|
2024-01-01|    75.4|
2024-01-01|    81.0|
2024-01-01|    73.1|
2024-01-01|   144.9|
2024-01-01|   137.9|
2024-01-02|    52.9|
2024-01-02|    59.1|
2024-01-02|    56.3|
2024-01-02|    54.1|
```

## Задание 2
### Текст задания
Бизнес-задача: Классифицировать простои по длительности для ежедневных отчётов.

Требования:

Создайте функцию classify_downtime(p_duration_min INT) с возвратом VARCHAR:
< 15 минут — «Микропростой»
15-60 минут — «Краткий простой»
61-240 минут — «Средний простой»
241-480 минут — «Длительный простой»
480 минут — «Критический простой»

Примените функцию к fact_equipment_downtime за январь 2024
Подсчитайте количество простоев каждой категории и среднюю длительность
Выведите: категория, количество, средняя длительность, процент от общего числа

### Решение
```
CREATE OR REPLACE FUNCTION classify_downtime(p_duration_min numeric) 
RETURNS VARCHAR AS $$
BEGIN
    RETURN CASE 
        WHEN p_duration_min < 15   THEN 'Микропростой'
        WHEN p_duration_min <= 60  THEN 'Краткий простой'
        WHEN p_duration_min <= 240 THEN 'Средний простой'
        WHEN p_duration_min <= 480 THEN 'Длительный простой'
        ELSE 'Критический простой'
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

WITH classified_data AS (
    SELECT 
        classify_downtime(duration_min) as category,
        duration_min
    FROM fact_equipment_downtime
    WHERE date_id BETWEEN 20240101 AND 20240131
)
SELECT 
    category AS "Категория",
    COUNT(*) AS "Количество",
    ROUND(AVG(duration_min), 1) AS "Средняя длит. (мин)",
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) || '%' AS "Процент от общего"
FROM classified_data
GROUP BY category
ORDER BY 
    -- Сортировка по логическому весу категорий
    CASE category
        WHEN 'Микропростой'       THEN 1
        WHEN 'Краткий простой'    THEN 2
        WHEN 'Средний простой'    THEN 3
        WHEN 'Длительный простой' THEN 4
        ELSE 5
    END;
```
### Результат
```
Категория         |Количество|Средняя длит. (мин)|Процент от общего|
------------------+----------+-------------------+-----------------+
Краткий простой   |        74|               30.4|72.55%           |
Средний простой   |        20|              134.3|19.61%           |
Длительный простой|         8|              480.0|7.84%            |
```
## Задание 3
### Текст задания
Бизнес-задача: Создать параметризованный отчёт, который возвращает сводку по одной единице оборудования за период.

Требования:

Создайте функцию get_equipment_summary(p_equipment_id INT, p_date_from INT, p_date_to INT) с RETURNS TABLE:
report_date DATE — дата
tons_mined NUMERIC — добыча
trips INT — рейсы
operating_hours NUMERIC — рабочие часы
fuel_liters NUMERIC — расход топлива
tons_per_hour NUMERIC — производительность (тонн/час)
Пометьте как STABLE
Протестируйте вызов:
Для конкретного оборудования: SELECT * FROM get_equipment_summary(1, 20240101, 20240131)
В составе JOIN: SELECT e.equipment_name, s.* FROM dim_equipment e CROSS JOIN LATERAL get_equipment_summary(e.equipment_id, 20240101, 20240131) s WHERE e.mine_id = 1

### Решение
```
CREATE OR REPLACE FUNCTION get_equipment_summary(
    p_equipment_id INT, 
    p_date_from    INT, 
    p_date_to      INT
)
RETURNS TABLE (
    report_date     DATE,
    tons_mined      NUMERIC,
    trips           INT,
    operating_hours NUMERIC,
    fuel_liters     NUMERIC,
    tons_per_hour   NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        dd.full_date,
        SUM(fp.tons_mined) AS tons_mined,
        SUM(fp.trips_count)::INT AS trips, 
        SUM(fp.operating_hours) AS operating_hours,
        SUM(fp.fuel_consumed_l) AS fuel_liters,
        ROUND(SUM(fp.tons_mined) / NULLIF(SUM(fp.operating_hours), 0), 2) AS tons_per_hour
    FROM fact_production fp
    JOIN dim_date dd ON fp.date_id = dd.date_id
    WHERE fp.equipment_id = p_equipment_id
      AND fp.date_id BETWEEN p_date_from AND p_date_to
    GROUP BY dd.full_date
    ORDER BY dd.full_date;
END;
$$ LANGUAGE plpgsql STABLE;


SELECT 
    e.equipment_name, 
    s.* 
FROM dim_equipment e 
CROSS JOIN LATERAL get_equipment_summary(e.equipment_id, 20240101, 20240131) s 
WHERE e.mine_id = 1;
```
### Результат
```
equipment_name|report_date|tons_mined|trips|operating_hours|fuel_liters|tons_per_hour|
--------------+-----------+----------+-----+---------------+-----------+-------------+
ПДМ-001       | 2024-01-01|    153.33|   15|          21.42|     231.45|         7.16|
ПДМ-001       | 2024-01-02|    125.75|   17|          21.36|     244.46|         5.89|
ПДМ-001       | 2024-01-03|    125.32|   13|          21.09|     242.67|         5.94|
ПДМ-001       | 2024-01-04|    145.80|   14|          20.71|     241.89|         7.04|
ПДМ-001       | 2024-01-05|    136.13|   17|          21.07|     239.78|         6.46|
ПДМ-001       | 2024-01-06|     84.97|   13|          20.26|     245.40|         4.19|
ПДМ-001       | 2024-01-07|     85.19|   16|          21.46|     228.98|         3.97|
ПДМ-001       | 2024-01-08|    152.59|   18|          20.53|     236.92|         7.43|
ПДМ-001       | 2024-01-09|    155.32|   15|          21.42|     234.45|         7.25|
ПДМ-001       | 2024-01-10|    140.43|   17|          21.67|     267.85|         6.48|
ПДМ-001       | 2024-01-11|    143.98|   17|          21.52|     234.98|         6.69|
ПДМ-001       | 2024-01-12|    166.57|   12|          20.91|     264.69|         7.97|
ПДМ-001       | 2024-01-13|     80.43|   15|          21.66|     249.04|         3.71|
ПДМ-001       | 2024-01-14|     93.58|   15|          22.23|     250.61|         4.21|
ПДМ-001       | 2024-01-15|    166.12|   16|          21.93|     238.63|         7.58|
ПДМ-001       | 2024-01-16|    121.67|   16|          22.37|     234.12|         5.44|
ПДМ-001       | 2024-01-17|    152.62|   18|          21.50|     240.12|         7.10|
ПДМ-001       | 2024-01-18|    162.61|   18|          21.72|     233.21|         7.49|
ПДМ-001       | 2024-01-19|    173.25|   12|          22.61|     248.14|         7.66|
ПДМ-001       | 2024-01-20|     97.44|   17|          21.88|     250.54|         4.45|
ПДМ-001       | 2024-01-21|     94.61|   17|          21.39|     236.59|         4.42|
ПДМ-001       | 2024-01-22|    130.32|   13|          21.49|     213.13|         6.06|
ПДМ-001       | 2024-01-23|    155.59|   15|          20.31|     221.11|         7.66|
ПДМ-001       | 2024-01-24|    150.86|   17|          21.69|     236.51|         6.96|
ПДМ-001       | 2024-01-25|    131.21|   14|          21.84|     235.36|         6.01|
ПДМ-001       | 2024-01-26|    145.06|   16|          21.10|     233.15|         6.87|
ПДМ-001       | 2024-01-27|     89.63|   14|          21.77|     252.13|         4.12|
ПДМ-001       | 2024-01-28|     94.59|   12|          21.43|     241.59|         4.41|
ПДМ-001       | 2024-01-29|    143.28|   12|          22.31|     255.80|         6.42|
ПДМ-001       | 2024-01-30|    136.36|   14|          21.56|     244.14|         6.32|
ПДМ-001       | 2024-01-31|    146.82|   14|          21.60|     272.33|         6.80|
ПДМ-002       | 2024-01-01|    151.18|   12|          20.28|     208.64|         7.45|
ПДМ-002       | 2024-01-02|    118.15|   14|          22.42|     216.97|         5.27|
ПДМ-002       | 2024-01-03|    142.57|   13|          20.65|     243.82|         6.90|
ПДМ-002       | 2024-01-04|    145.84|   13|          21.51|     223.92|         6.78|
ПДМ-002       | 2024-01-05|    149.34|   14|          21.80|     246.47|         6.85|
ПДМ-002       | 2024-01-06|     79.85|   17|          22.08|     217.24|         3.62|
ПДМ-002       | 2024-01-07|     72.60|   17|          21.02|     237.62|         3.45|
ПДМ-002       | 2024-01-08|    148.25|   15|          21.54|     203.64|         6.88|
ПДМ-002       | 2024-01-09|    129.93|   17|          22.23|     240.08|         5.84|
ПДМ-002       | 2024-01-10|    125.56|   14|          22.44|     224.28|         5.60|
ПДМ-002       | 2024-01-11|    137.25|   18|          21.80|     220.57|         6.30|
ПДМ-002       | 2024-01-12|    142.48|   17|          22.01|     239.29|         6.47|
ПДМ-002       | 2024-01-13|     88.38|   17|          21.93|     239.78|         4.03|
ПДМ-002       | 2024-01-14|     85.16|   18|          22.09|     237.20|         3.86|
ПДМ-002       | 2024-01-15|    122.12|   16|          20.96|     212.00|         5.83|
ПДМ-002       | 2024-01-16|    121.90|   16|          21.56|     239.91|         5.65|
ПДМ-002       | 2024-01-17|    151.42|   14|          20.92|     203.90|         7.24|
ПДМ-002       | 2024-01-18|    153.91|   15|          21.27|     220.32|         7.24|
ПДМ-002       | 2024-01-19|    136.19|   15|          21.25|     224.24|         6.41|
ПДМ-002       | 2024-01-20|     37.11|    8|          10.38|     118.60|         3.58|
ПДМ-002       | 2024-01-21|     76.13|   17|          21.59|     216.57|         3.53|
ПДМ-002       | 2024-01-22|    124.90|   13|          21.85|     225.64|         5.72|
ПДМ-002       | 2024-01-23|    134.49|   15|          21.14|     227.25|         6.36|
ПДМ-002       | 2024-01-24|    146.60|   13|          21.22|     206.77|         6.91|
```
## Задание 4
### Текст задания


### Решение
```
CREATE OR REPLACE FUNCTION get_production_filtered(
    p_date_from         INT,
    p_date_to           INT,
    p_mine_id           INT DEFAULT NULL,
    p_shift_id          INT DEFAULT NULL,
    p_equipment_type_id INT DEFAULT NULL
)
RETURNS TABLE (
    mine_name      VARCHAR,
    shift_name     VARCHAR,
    equipment_type VARCHAR,
    total_tons     NUMERIC,
    total_trips    BIGINT,
    equip_count    BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        dm.mine_name,
        ds.shift_name,
        det.type_name AS equipment_type,
        SUM(fp.tons_mined) AS total_tons,
        SUM(fp.trips_count) AS total_trips,
        COUNT(DISTINCT fp.equipment_id) AS equip_count
    FROM fact_production fp
    JOIN dim_mine dm ON fp.mine_id = dm.mine_id
    JOIN dim_equipment de ON fp.equipment_id = de.equipment_id
    JOIN dim_equipment_type det ON de.equipment_type_id = det.equipment_type_id
	join dim_shift ds on fp.shift_id=ds.shift_id
    WHERE fp.date_id BETWEEN p_date_from AND p_date_to
      AND (p_mine_id IS NULL OR fp.mine_id = p_mine_id)
      AND (p_shift_id IS NULL OR fp.shift_id = p_shift_id)
      AND (p_equipment_type_id IS NULL OR de.equipment_type_id = p_equipment_type_id)
    GROUP BY dm.mine_name, ds.shift_name, det.type_name
    ORDER BY dm.mine_name, ds.shift_name;
END;
$$ LANGUAGE plpgsql STABLE;

SELECT * FROM get_production_filtered(20240101, 20240131);

SELECT * FROM get_production_filtered(20240101, 20240131, p_mine_id := 1);

SELECT * FROM get_production_filtered(20240101, 20240131, 1, 1);

```
### Результат
```
mine_name       |shift_name   |equipment_type               |total_tons|total_trips|equip_count|
----------------+-------------+-----------------------------+----------+-----------+-----------+
Шахта "Северная"|Дневная смена|Погрузочно-доставочная машина|   5609.90|        654|          3|
Шахта "Северная"|Дневная смена|Шахтный самосвал             |   8167.86|        323|          2|
Шахта "Северная"|Ночная смена |Погрузочно-доставочная машина|   5731.41|        666|          3|
Шахта "Северная"|Ночная смена |Шахтный самосвал             |   7889.44|        322|          2|
Шахта "Южная"   |Дневная смена|Погрузочно-доставочная машина|   4088.13|        476|          2|
Шахта "Южная"   |Дневная смена|Шахтный самосвал             |   3912.29|        150|          1|
Шахта "Южная"   |Ночная смена |Погрузочно-доставочная машина|   4129.69|        477|          2|
Шахта "Южная"   |Ночная смена |Шахтный самосвал             |   3723.62|        148|          1|

mine_name       |shift_name   |equipment_type               |total_tons|total_trips|equip_count|
----------------+-------------+-----------------------------+----------+-----------+-----------+
Шахта "Северная"|Дневная смена|Погрузочно-доставочная машина|   5609.90|        654|          3|
Шахта "Северная"|Дневная смена|Шахтный самосвал             |   8167.86|        323|          2|
Шахта "Северная"|Ночная смена |Погрузочно-доставочная машина|   5731.41|        666|          3|
Шахта "Северная"|Ночная смена |Шахтный самосвал             |   7889.44|        322|          2|

mine_name       |shift_name   |equipment_type               |total_tons|total_trips|equip_count|
----------------+-------------+-----------------------------+----------+-----------+-----------+
Шахта "Северная"|Дневная смена|Погрузочно-доставочная машина|   5609.90|        654|          3|
Шахта "Северная"|Дневная смена|Шахтный самосвал             |   8167.86|        323|          2|
```
## Задание 5
### Текст задания
Бизнес-задача: Создать процедуру для архивации старых данных телеметрии.

Требования:

Создайте таблицу-архив: CREATE TABLE archive_telemetry (LIKE fact_equipment_telemetry INCLUDING ALL)
Создайте процедуру archive_old_telemetry(p_before_date_id INT, OUT p_archived INT, OUT p_deleted INT):
Шаг 1: Скопировать записи из fact_equipment_telemetry в archive_telemetry, где date_id < p_before_date_id
COMMIT после копирования
Шаг 2: Удалить скопированные записи из исходной таблицы
COMMIT после удаления
Вернуть количество скопированных и удалённых записей
Добавьте RAISE NOTICE для логирования каждого шага
Протестируйте: CALL archive_old_telemetry(20240101, NULL, NULL)
Проверьте данные в архивной таблице
Важно: Не забудьте очистить тестовые данные после проверки!

### Решение
```
CREATE TABLE IF NOT EXISTS archive_telemetry (LIKE fact_equipment_telemetry INCLUDING ALL);

CREATE OR REPLACE PROCEDURE archive_old_telemetry(
    p_before_date_id INT, 
    INOUT p_archived INT DEFAULT 0, 
    INOUT p_deleted  INT DEFAULT 0
)
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE NOTICE '--- Начало архивации данных до даты % ---', p_before_date_id;

    INSERT INTO archive_telemetry 
    SELECT * FROM fact_equipment_telemetry 
    WHERE date_id < p_before_date_id;
    
    GET DIAGNOSTICS p_archived = ROW_COUNT;
    RAISE NOTICE 'Шаг 1 завершен: скопировано % записей.', p_archived;
   
    COMMIT;

    IF p_archived > 0 THEN
        DELETE FROM fact_equipment_telemetry 
        WHERE date_id < p_before_date_id;
        
        GET DIAGNOSTICS p_deleted = ROW_COUNT;
        RAISE NOTICE 'Шаг 2 завершен: удалено % записей.', p_deleted;
        
        COMMIT;
    ELSE
        RAISE NOTICE 'Нет данных для удаления.';
    END IF;

    RAISE NOTICE '--- Архивация успешно завершена ---';
END;
$$;

CALL archive_old_telemetry(20240201, 0, 0);

SELECT COUNT(*) FROM archive_telemetry;

-- Проверяем отсутствие старых данных в основной таблице
SELECT COUNT(*) FROM fact_equipment_telemetry WHERE date_id < 20240201;
```
### Результат
```
count|
-----+
 7440|

 count|
-----+
    0|
```
## Задание 6
### Текст задания
Бизнес-задача: Создать функцию для быстрой проверки количества записей в любой таблице за период.

Требования:

Создайте функцию count_fact_records(p_table_name TEXT, p_date_from INT, p_date_to INT) с возвратом BIGINT:
Принимает имя таблицы фактов (fact_production, fact_equipment_downtime и т.д.)
Формирует динамический запрос через EXECUTE format()
Используйте %I для безопасной подстановки имени таблицы
Используйте $1, $2 через USING для параметров дат
Добавьте проверку: таблица должна начинаться с fact_ (иначе — RAISE EXCEPTION)
Протестируйте:
SELECT count_fact_records('fact_production', 20240101, 20240131)
SELECT count_fact_records('fact_equipment_downtime', 20240101, 20240131)
SELECT count_fact_records('dim_mine', 20240101, 20240131) — должна быть ошибка

### Решение
```
CREATE OR REPLACE FUNCTION count_fact_records(
    p_table_name TEXT, 
    p_date_from  INT, 
    p_date_to    INT
)
RETURNS BIGINT AS $$
DECLARE
    v_result BIGINT;
    v_query  TEXT;
BEGIN
    IF p_table_name NOT LIKE 'fact_%' THEN
        RAISE EXCEPTION 'Доступ запрещен: Таблица % не является таблицей фактов (должна начинаться с fact_)', p_table_name;
    END IF;

    v_query := format('SELECT COUNT(*) FROM %I WHERE date_id BETWEEN $1 AND $2', p_table_name);

    EXECUTE v_query 
    USING p_date_from, p_date_to 
    INTO v_result;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql STABLE;


SELECT count_fact_records('fact_production', 20240101, 20240131) AS prod_count;

SELECT count_fact_records('fact_equipment_downtime', 20240101, 20240131) AS downtime_count;

SELECT count_fact_records('dim_mine', 20240101, 20240131);
```
### Результат
```
prod_count|
----------+
       482|

downtime_count|
--------------+
           102|

SQL Error [P0001]: ERROR: Доступ запрещен: Таблица dim_mine не является таблицей фактов (должна начинаться с fact_)
  Где: PL/pgSQL function count_fact_records(text,integer,integer) line 7 at RAISE

Позиция ошибки:
```
## Задание 7
### Текст задания
Бизнес-задача: Создать универсальный генератор отчётов, который строит GROUP BY по указанному измерению.

Требования:

Создайте функцию build_production_report(p_group_by TEXT, p_date_from INT, p_date_to INT, p_order_by TEXT DEFAULT 'total_tons DESC'):
p_group_by — одно из: 'mine', 'shift', 'operator', 'equipment', 'equipment_type'
Возвращает TABLE (dimension_name VARCHAR, total_tons NUMERIC, total_trips BIGINT, avg_productivity NUMERIC)
Используйте CASE для определения JOIN и поля группировки (НЕ подставляйте пользовательский ввод напрямую в SQL)
Поддержите сортировку через p_order_by (разрешённые значения: 'total_tons DESC', 'total_tons ASC', 'dimension_name ASC')
Протестируйте все варианты группировки
Убедитесь, что некорректный p_group_by вызывает RAISE EXCEPTION
Подсказка:

CASE p_group_by
    WHEN 'mine' THEN
        v_join := 'JOIN dim_mine d ON fp.mine_id = d.mine_id';
        v_field := 'd.mine_name';
    WHEN 'equipment' THEN
        v_join := 'JOIN dim_equipment d ON fp.equipment_id = d.equipment_id';
        v_field := 'd.equipment_name';
    -- ...
END CASE;

RETURN QUERY EXECUTE format(
    'SELECT %s::VARCHAR, ROUND(SUM(fp.tons_mined), 2), ... FROM fact_production fp %s WHERE ... GROUP BY 1 ORDER BY %s',
    v_field, v_join, v_order
) USING p_date_from, p_date_to;

### Решение
```
CREATE OR REPLACE FUNCTION build_production_report(
    p_group_by  TEXT, 
    p_date_from INT, 
    p_date_to   INT, 
    p_order_by  TEXT DEFAULT 'total_tons DESC'
)
RETURNS TABLE (
    dimension_name    VARCHAR, 
    total_tons        NUMERIC, 
    total_trips       BIGINT, 
    avg_productivity  NUMERIC
) AS $$
DECLARE
    v_join  TEXT;
    v_field TEXT;
    v_order TEXT;
    v_query TEXT;
BEGIN
    CASE p_group_by
        WHEN 'mine' THEN
            v_join := 'JOIN dim_mine d ON fp.mine_id = d.mine_id';
            v_field := 'd.mine_name';
        WHEN 'shift' THEN
            v_join := 'JOIN dim_shift ds ON fp.shift_id=ds.shift_id'; 
            v_field := 'ds.shift_name';
        WHEN 'operator' THEN
            v_join := 'JOIN dim_operator d ON fp.operator_id = d.operator_id';
            v_field := 'd.operator_name';
        WHEN 'equipment' THEN
            v_join := 'JOIN dim_equipment d ON fp.equipment_id = d.equipment_id';
            v_field := 'd.equipment_name';
        WHEN 'equipment_type' THEN
            v_join := 'JOIN dim_equipment e ON fp.equipment_id = e.equipment_id 
                       JOIN dim_equipment_type d ON e.equipment_type_id = d.equipment_type_id';
            v_field := 'd.type_name';
        ELSE
            RAISE EXCEPTION 'Некорректное измерение: %. Допустимы: mine, shift, operator, equipment, equipment_type', p_group_by;
    END CASE;

    v_order := CASE p_order_by
        WHEN 'total_tons DESC'   THEN '2 DESC'
        WHEN 'total_tons ASC'    THEN '2 ASC'
        WHEN 'dimension_name ASC' THEN '1 ASC'
        ELSE '2 DESC' 
    END;

    v_query := format(
        'SELECT 
            %s::VARCHAR, 
            ROUND(SUM(fp.tons_mined), 2), 
            SUM(fp.trips_count),
            ROUND(AVG(fp.tons_mined / NULLIF(fp.operating_hours, 0)), 2)
         FROM fact_production fp 
         %s 
         WHERE fp.date_id BETWEEN $1 AND $2 
         GROUP BY 1 
         ORDER BY %s',
        v_field, v_join, v_order
    );

    RETURN QUERY EXECUTE v_query USING p_date_from, p_date_to;
END;
$$ LANGUAGE plpgsql STABLE;

SELECT * FROM build_production_report('mine', 20240101, 20240131);

SELECT * FROM build_production_report('equipment_type', 20240101, 20240131, 'dimension_name ASC');

SELECT * FROM build_production_report('wrong_field', 20240101, 20240131);
```
### Результат
```
dimension_name  |total_tons|total_trips|avg_productivity|
----------------+----------+-----------+----------------+
Шахта "Северная"|  27398.61|       1965|            8.46|
Шахта "Южная"   |  15853.73|       1251|            8.27|

dimension_name               |total_tons|total_trips|avg_productivity|
-----------------------------+----------+-----------+----------------+
Погрузочно-доставочная машина|  19559.13|       2273|            6.04|
Шахтный самосвал             |  23693.21|        943|           12.36|

SQL Error [P0001]: ERROR: Некорректное измерение: wrong_field. Допустимы: mine, shift, operator, equipment, equipment_type
  Где: PL/pgSQL function build_production_report(text,integer,integer,text) line 26 at RAISE
```
## Задание 8
### Текст задания

Бизнес-задача: Создать процедуру ETL для ежедневной загрузки и валидации производственных данных.

Требования:

Создайте staging-таблицу:
CREATE TABLE staging_daily_production (
    date_id INT,
    equipment_id INT,
    shift_id INT,
    operator_id INT,
    tons_mined NUMERIC,
    trips_count INT,
    operating_hours NUMERIC,
    fuel_consumed_l NUMERIC,
    loaded_at TIMESTAMP DEFAULT NOW()
);
Создайте процедуру process_daily_production(p_date_id INT) с OUT-параметрами p_validated INT, p_rejected INT, p_loaded INT:
Шаг 1: Проверка — есть ли данные в staging за указанную дату. Если нет — RAISE EXCEPTION
Шаг 2: Валидация — пометить записи с невалидными данными (tons_mined < 0, equipment_id не в dim_equipment, и т.д.). Используйте вспомогательную таблицу staging_rejected для отбракованных записей
COMMIT
Шаг 3: Удалить старые данные из fact_production за эту дату (upsert-логика)
Шаг 4: Вставить валидные записи из staging в fact_production
COMMIT
Вернуть количество валидных, отбракованных и загруженных записей
Добавьте RAISE NOTICE на каждом шаге
Протестируйте:
Вставьте тестовые данные в staging (корректные и некорректные)
Вызовите процедуру
Проверьте результаты в fact_production и staging_rejected
### Решение
```
CREATE TABLE staging_daily_production (
    date_id INT,
    equipment_id INT,
    shift_id INT,
    operator_id INT,
    tons_mined NUMERIC,
    trips_count INT,
    operating_hours NUMERIC,
    fuel_consumed_l NUMERIC,
    loaded_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS staging_rejected (
    LIKE staging_daily_production INCLUDING ALL,
    reject_reason TEXT,
    rejected_at TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE PROCEDURE process_daily_production(
    p_date_id INT,
    OUT p_validated INT,
    OUT p_rejected INT,
    OUT p_loaded INT
)
LANGUAGE plpgsql
AS $$
BEGIN

    IF NOT EXISTS (SELECT 1 FROM staging_daily_production WHERE date_id = p_date_id) THEN
        RAISE EXCEPTION 'Данные за дату % отсутствуют в staging_daily_production', p_date_id;
    END IF;

    RAISE NOTICE 'Шаг 1: Данные найдены. Начинаю валидацию...';

    INSERT INTO staging_rejected (
        date_id, equipment_id, shift_id, operator_id, tons_mined, 
        trips_count, operating_hours, fuel_consumed_l, loaded_at, reject_reason
    )
    SELECT s.date_id, s.equipment_id, s.shift_id, s.operator_id, s.tons_mined, 
           s.trips_count, s.operating_hours, s.fuel_consumed_l, s.loaded_at,
           CASE 
             WHEN s.tons_mined < 0 THEN 'Отрицательная добыча'
             WHEN s.trips_count < 0 THEN 'Отрицательное кол-во рейсов'
             WHEN e.equipment_id IS NULL THEN 'Неизвестное оборудование (ID=' || s.equipment_id || ')'
             WHEN o.operator_id IS NULL THEN 'Неизвестный оператор (ID=' || s.operator_id || ')'
             ELSE 'Нарушение бизнес-логики'
           END
    FROM staging_daily_production s
    LEFT JOIN dim_equipment e ON s.equipment_id = e.equipment_id
    LEFT JOIN dim_operator o ON s.operator_id = o.operator_id
    WHERE s.date_id = p_date_id 
      AND (s.tons_mined < 0 
           OR s.trips_count < 0 
           OR e.equipment_id IS NULL 
           OR o.operator_id IS NULL);

    GET DIAGNOSTICS p_rejected = ROW_COUNT;
    DELETE FROM staging_daily_production 
    WHERE date_id = p_date_id 
      AND (tons_mined < 0 
           OR trips_count < 0
           OR equipment_id NOT IN (SELECT equipment_id FROM dim_equipment)
           OR operator_id NOT IN (SELECT operator_id FROM dim_operator));

    RAISE NOTICE 'Шаг 2: Валидация завершена. Отбраковано: % зап.', p_rejected;
    COMMIT; 

    DELETE FROM fact_production WHERE date_id = p_date_id;
    RAISE NOTICE 'Шаг 3: Старые данные за % удалены из fact_production.', p_date_id;
    INSERT INTO fact_production (
        date_id, equipment_id, shift_id, operator_id, 
        tons_mined, trips_count, operating_hours, fuel_consumed_l
    )
    SELECT date_id, equipment_id, shift_id, operator_id, 
           tons_mined, trips_count, operating_hours, fuel_consumed_l
    FROM staging_daily_production
    WHERE date_id = p_date_id;

    GET DIAGNOSTICS p_loaded = ROW_COUNT;
    p_validated := p_loaded; 

    DELETE FROM staging_daily_production WHERE date_id = p_date_id;

    RAISE NOTICE 'Шаг 4: Загрузка завершена. Добавлено в факт: % зап.', p_loaded;
    COMMIT;

END;
$$;


TRUNCATE TABLE staging_daily_production;
TRUNCATE TABLE staging_rejected;

INSERT INTO staging_daily_production(date_id, equipment_id, shift_id, operator_id, tons_mined, trips_count, operating_hours, fuel_consumed_l) 
VALUES
(20250120, 1, 1, 10, 500.5, 12, 11.5, 250.0),  
(20250120, 1, 2, 10, -50.0, 5, 4.0, 80.0),    
(20250120, 1, 1, 999999, 300.0, 8, 9.0, 150.0); 

SELECT * FROM staging_daily_production;

CALL process_daily_production(20250120, 0, 0, 0);
```

