## Задание 1
### Текст задания
Бизнес-задача: Зафиксировать данные о добыче за одну смену. Все данные смены должны быть записаны вместе или не записаны вовсе.

Требования:

Начните транзакцию
Вставьте 5 записей в fact_production для одной смены (date_id = 20250310, shift_id = 1, mine_id = 1, различные equipment_id)
Проверьте, что записи видны в текущей сессии
Зафиксируйте транзакцию
Проверьте, что записи сохранились после COMMIT
Повторите с другой сменой (shift_id = 2), но выполните ROLLBACK вместо COMMIT
Убедитесь, что записи второй смены не сохранились
### Решение
```
BEGIN;

INSERT INTO fact_production (
    production_id,
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
) VALUES 
    (1001, 20250310, 1, 1, 3, 1, 1, 1, 1, 85.50, 92.30, 7, 10.50, 125.40, 11.20, CURRENT_TIMESTAMP),
    (1002, 20250310, 1, 1, 3, 2, 2, 2, 1, 78.20, 85.10, 6, 9.80, 118.30, 10.50, CURRENT_TIMESTAMP),
    (1003, 20250310, 1, 1, 4, 3, 10, 6, 2, 68.75, 72.40, 5, 8.90, 105.60, 9.80, CURRENT_TIMESTAMP),
    (1004, 20250310, 1, 1, 4, 4, 3, 7, 3, 72.40, 79.20, 6, 9.20, 112.80, 10.20, CURRENT_TIMESTAMP),
    (1005, 20250310, 1, 1, 5, 5, 4, 8, 1, 81.30, 88.50, 7, 10.10, 120.90, 10.80, CURRENT_TIMESTAMP);

SELECT * FROM fact_production 
WHERE date_id = 20250310 AND shift_id = 1;

COMMIT;

SELECT COUNT(*) as saved_records_count 
FROM fact_production 
WHERE date_id = 20250310 AND shift_id = 1;




BEGIN;

INSERT INTO fact_production (
    production_id,
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
) VALUES 
    (2001, 20250310, 2, 1, 3, 1, 5, 1, 2, 72.30, 78.90, 6, 9.50, 108.70, 10.30, CURRENT_TIMESTAMP),
    (2002, 20250310, 2, 1, 3, 2, 6, 2, 3, 65.80, 70.20, 5, 8.70, 98.40, 9.50, CURRENT_TIMESTAMP),
    (2003, 20250310, 2, 1, 4, 3, 7, 6, 1, 83.60, 90.10, 7, 10.80, 132.50, 11.40, CURRENT_TIMESTAMP),
    (2004, 20250310, 2, 1, 4, 4, 8, 7, 2, 70.15, 75.80, 5, 9.00, 102.30, 9.90, CURRENT_TIMESTAMP),
    (2005, 20250310, 2, 1, 5, 5, 9, 8, 3, 67.45, 71.60, 5, 8.50, 95.70, 9.20, CURRENT_TIMESTAMP);


SELECT * FROM fact_production 
WHERE date_id = 20250310 AND shift_id = 2;



ROLLBACK;


SELECT COUNT(*) as rolled_back_records_count 
FROM fact_production 
WHERE date_id = 20250310 AND shift_id = 2;


SELECT 
    shift_id,
    COUNT(*) as records_count
FROM fact_production 
WHERE date_id = 20250310
GROUP BY shift_id;


SELECT 
    'После COMMIT' as status,
    shift_id,
    COUNT(*) as total_records,
    SUM(tons_mined) as total_tons_mined
FROM fact_production 
WHERE date_id = 20250310
GROUP BY shift_id
UNION ALL
SELECT 
    'После ROLLBACK',
    shift_id,
    COUNT(*),
    SUM(tons_mined)
FROM fact_production 
WHERE date_id = 20250310
GROUP BY shift_id;
```
### Результат
```
production_id|date_id |shift_id|mine_id|shaft_id|equipment_id|operator_id|location_id|ore_grade_id|tons_mined|tons_transported|trips_count|distance_km|fuel_consumed_l|operating_hours|loaded_at              |
-------------+--------+--------+-------+--------+------------+-----------+-----------+------------+----------+----------------+-----------+-----------+---------------+---------------+-----------------------+
         6652|20250310|       1|      1|       3|           1|          1|          1|           1|     96.26|           96.13|          7|       8.97|         123.87|          10.38|2026-03-18 11:45:41.511|
         6653|20250310|       1|      1|       3|           2|          2|          2|           3|     78.27|           74.70|          6|       9.45|         117.12|          11.45|2026-03-18 11:45:41.511|
         6654|20250310|       1|      1|       4|           3|         10|          6|           3|     61.86|           82.69|          5|      10.97|         123.68|          11.44|2026-03-18 11:45:41.511|
         6655|20250310|       1|      2|       7|           4|          5|         10|           2|     80.40|           82.18|          9|      10.21|         105.99|          10.39|2026-03-18 11:45:41.511|
         6656|20250310|       1|      2|       7|           6|          6|         11|           2|     79.36|           93.35|          9|       9.05|         121.58|          10.83|2026-03-18 11:45:41.511|
         6657|20250310|       1|      1|       3|           7|          3|          3|           3|    197.50|          202.43|          5|      14.66|         215.46|          10.28|2026-03-18 11:45:41.511|
         6658|20250310|       1|      1|       4|           8|          4|          8|           1|    166.32|          155.72|          4|      15.52|         221.69|          11.07|2026-03-18 11:45:41.511|
         6659|20250310|       1|      2|       7|          10|          7|         12|           2|    161.65|          195.81|          5|      13.73|         205.98|          10.26|2026-03-18 11:45:41.511|

saved_records_count|
-------------------+
                  8|

production_id|date_id |shift_id|mine_id|shaft_id|equipment_id|operator_id|location_id|ore_grade_id|tons_mined|tons_transported|trips_count|distance_km|fuel_consumed_l|operating_hours|loaded_at              |
-------------+--------+--------+-------+--------+------------+-----------+-----------+------------+----------+----------------+-----------+-----------+---------------+---------------+-----------------------+
         6660|20250310|       2|      1|       3|           1|          1|          1|           2|     73.44|           91.07|          6|       9.68|         130.90|          11.18|2026-03-18 11:45:41.511|
         6661|20250310|       2|      1|       3|           2|          2|          2|           1|     85.30|           89.67|          8|      10.49|         118.26|          10.24|2026-03-18 11:45:41.511|
         6662|20250310|       2|      1|       4|           3|         10|          6|           1|     66.13|           89.92|          7|      11.10|         109.32|          10.48|2026-03-18 11:45:41.511|
         6663|20250310|       2|      2|       7|           4|          5|         10|           2|     83.59|           88.62|          7|      10.09|         104.28|          11.49|2026-03-18 11:45:41.511|
         6664|20250310|       2|      2|       7|           6|          6|         11|           2|     95.68|           88.98|          7|       9.63|         116.56|          10.63|2026-03-18 11:45:41.511|
         6665|20250310|       2|      2|       7|          10|          7|         12|           2|    150.26|          180.45|          7|      14.14|         178.63|          11.38|2026-03-18 11:45:41.511|

rolled_back_records_count|
-------------------------+
                        6|

status        |shift_id|total_records|total_tons_mined|
--------------+--------+-------------+----------------+
После COMMIT  |       1|            8|          921.62|
После COMMIT  |       2|            6|          554.40|
После ROLLBACK|       1|            8|          921.62|
После ROLLBACK|       2|            6|          554.40|
```
## Задание 2
### Текст задания
Бизнес-задача: Загрузка данных за день: сначала добыча, потом качество, потом телеметрия. Если телеметрия не загрузится — добыча и качество должны сохраниться.

Требования:

Начните транзакцию
Вставьте запись в fact_production
Создайте SAVEPOINT sp_after_production
Вставьте запись в fact_ore_quality
Создайте SAVEPOINT sp_after_quality
Попробуйте вставить запись в fact_equipment_telemetry с заведомо некорректными данными (несуществующий sensor_id)
Выполните ROLLBACK TO sp_after_quality
Убедитесь, что production и quality записи сохранены
Зафиксируйте транзакцию
Проверьте итоговое состояние всех трёх таблиц
### Решение
```
BEGIN;

INSERT INTO fact_production (
    production_id,
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
) VALUES (
    3001,
    20250311,
    1,
    1,
    3,
    1,
    1,
    1,
    1,
    95.75,
    102.40,
    8,
    11.20,
    145.30,
    12.50,
    CURRENT_TIMESTAMP
);

SAVEPOINT sp_after_production;

INSERT INTO fact_ore_quality (
    quality_id,
    date_id,
    time_id,
    shift_id,
    mine_id,
    shaft_id,
    location_id,
    ore_grade_id,
    sample_number,
    fe_content,
    sio2_content,
    al2o3_content,
    moisture,
    density,
    sample_weight_kg,
    loaded_at
) VALUES (
    5001,
    20250311,
    820,
    1,
    1,
    3,
    1,
    1,
    'PRB-20250311-N480-1',
    64.28,
    17.45,
    1.98,
    4.87,
    4.012,
    1.75,
    CURRENT_TIMESTAMP
);

SAVEPOINT sp_after_quality;


INSERT INTO fact_equipment_telemetry (
    telemetry_id,
    date_id,
    time_id,
    equipment_id,
    sensor_id,
    location_id,
    sensor_value,
    is_alarm,
    quality_flag,
    loaded_at
) VALUES (
    10001,
    20250311,
    800,
    1,
    99999,
    1,
    88.45,
    FALSE,
    'OK',
    CURRENT_TIMESTAMP
);

ROLLBACK TO sp_after_quality;

SELECT 'После ROLLBACK TO sp_after_quality' as check_point;
SELECT COUNT(*) as production_exists FROM fact_production WHERE production_id = 3001;
SELECT COUNT(*) as quality_exists FROM fact_ore_quality WHERE quality_id = 5001;

COMMIT;

SELECT '=== ИТОГОВЫЕ РЕЗУЛЬТАТЫ ===' as result;

SELECT 
    production_id,
    date_id,
    shift_id,
    equipment_id,
    tons_mined,
    tons_transported
FROM fact_production 
WHERE production_id = 3001;

SELECT 
    quality_id,
    date_id,
    shift_id,
    location_id,
    ore_grade_id,
    fe_content,
    moisture
FROM fact_ore_quality 
WHERE quality_id = 5001;

SELECT 
    COUNT(*) as telemetry_records_count
FROM fact_equipment_telemetry 
WHERE telemetry_id = 10001;
```
### Результат
```
check_point                       |
----------------------------------+
После ROLLBACK TO sp_after_quality|

production_exists|
-----------------+
                2|

quality_exists|
--------------+
             2|

production_id|date_id |shift_id|equipment_id|tons_mined|tons_transported|
-------------+--------+--------+------------+----------+----------------+
         3001|20240714|       2|           2|     54.59|           38.77|
         3001|20250311|       1|           1|     95.75|          102.40|

quality_id|date_id |shift_id|location_id|ore_grade_id|fe_content|moisture|
----------+--------+--------+-----------+------------+----------+--------+
      5001|20250214|       2|          1|           2|     59.25|    4.78|
      5001|20250311|       1|          1|           1|     64.28|    4.87|

telemetry_records_count|
-----------------------+
                      1|
```
## Задание 3
### Текст задания
Бизнес-задача: Продемонстрировать атомарность — перевод тонн между двумя единицами оборудования.

Требования:

Подготовьте: создайте тестовую таблицу equipment_balance:
CREATE TABLE equipment_balance (
    equipment_id INT PRIMARY KEY,
    balance_tons NUMERIC DEFAULT 0,
    CHECK (balance_tons >= 0)
);
INSERT INTO equipment_balance VALUES (1, 1000), (2, 500);
Реализуйте «перевод» 200 тонн с оборудования 1 на оборудование 2:
Уменьшите баланс оборудования 1 на 200
Увеличьте баланс оборудования 2 на 200
Оба UPDATE в одной транзакции
Проверьте балансы после COMMIT
Попробуйте перевести 1500 тонн с оборудования 2 (нарушит CHECK) — что произойдёт?
Убедитесь, что после ошибки оба баланса остались неизменными (атомарность)

### Решение
```
CREATE TABLE equipment_balance (
    equipment_id INT PRIMARY KEY,
    balance_tons NUMERIC DEFAULT 0,
    CHECK (balance_tons >= 0) 
);


INSERT INTO equipment_balance VALUES (1, 1000), (2, 500);


SELECT * FROM equipment_balance ORDER BY equipment_id;


BEGIN;

UPDATE equipment_balance 
SET balance_tons = balance_tons - 200 
WHERE equipment_id = 1;

UPDATE equipment_balance 
SET balance_tons = balance_tons + 200 
WHERE equipment_id = 2;

SELECT 'Промежуточное состояние (внутри транзакции)' as status, * 
FROM equipment_balance 
ORDER BY equipment_id;


COMMIT;


SELECT 'Финальное состояние после успешного перевода' as status, * 
FROM equipment_balance 
ORDER BY equipment_id;



SELECT 'Состояние перед ошибочным переводом' as status, * 
FROM equipment_balance 
ORDER BY equipment_id;


BEGIN;


UPDATE equipment_balance 
SET balance_tons = balance_tons - 1500 
WHERE equipment_id = 2;


UPDATE equipment_balance 
SET balance_tons = balance_tons + 1500 
WHERE equipment_id = 1;


COMMIT;


SELECT 'Состояние ПОСЛЕ ошибочного перевода (должно быть неизменным)' as status, * 
FROM equipment_balance 
ORDER BY equipment_id;


DO $$
DECLARE
    v_balance_2 NUMERIC;
    v_error_message TEXT;
BEGIN
    SELECT balance_tons INTO v_balance_2 FROM equipment_balance WHERE equipment_id = 2;
    RAISE NOTICE 'Начальный баланс оборудования 2: % тонн', v_balance_2;
    RAISE NOTICE 'Пытаемся перевести 1500 тонн с оборудования 2 на оборудование 1...';
    BEGIN
    UPDATE equipment_balance 
    SET balance_tons = balance_tons - 1500 
    WHERE equipment_id = 2;
    
    UPDATE equipment_balance 
    SET balance_tons = balance_tons + 1500 
    WHERE equipment_id = 1;
    
    COMMIT;
    
    RAISE NOTICE 'Перевод успешно выполнен!';
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_error_message = MESSAGE_TEXT;
    RAISE NOTICE 'ОШИБКА: %', v_error_message;
    RAISE NOTICE 'Транзакция автоматически откачена. Балансы не изменились.';
    
    PERFORM * FROM equipment_balance WHERE equipment_id = 2 AND balance_tons = v_balance_2;
    IF FOUND THEN
        RAISE NOTICE 'Атомарность подтверждена: баланс оборудования 2 остался = % тонн', v_balance_2;
    END IF;
END $$;

SELECT 'Финальная проверка после всех операций' as status, * 
FROM equipment_balance 
ORDER BY equipment_id;
```

## Задание 4
### Текст задания

### Решение
```

```
### Результат
```

```
## Задание 5
### Текст задания
Бизнес-задача: Два оператора одновременно корректируют данные о добыче. Нужно обработать конфликт.

Требования:

Создайте функцию safe_update_production:
CREATE FUNCTION safe_update_production(
    p_production_id INT,
    p_new_tons NUMERIC,
    p_timeout_ms INT DEFAULT 5000
) RETURNS VARCHAR
Функция должна:
Установить lock_timeout на заданное время
Попытаться обновить запись с блокировкой (FOR UPDATE)
При успехе — обновить tons_mined и вернуть 'OK'
При lock_not_available — вернуть 'ЗАБЛОКИРОВАНО: попробуйте позже'
При deadlock_detected — вернуть 'DEADLOCK: повторите операцию'
Протестируйте:
В сессии A начните транзакцию и заблокируйте запись (SELECT ... FOR UPDATE)
В сессии B вызовите safe_update_production с timeout = 3000
Убедитесь, что функция корректно обрабатывает таймаут
### Решение
```
CREATE OR REPLACE FUNCTION safe_update_production(
    p_production_id INT,
    p_new_tons NUMERIC,
    p_timeout_ms INT DEFAULT 5000
) RETURNS VARCHAR AS $$
DECLARE
    v_current_tons NUMERIC;
    v_result VARCHAR;
BEGIN
    EXECUTE format('SET LOCAL lock_timeout = %s', p_timeout_ms);
    
    BEGIN

        SELECT tons_mined INTO v_current_tons
        FROM fact_production
        WHERE production_id = p_production_id
        FOR UPDATE;
        

        IF NOT FOUND THEN
            RETURN 'ОШИБКА: запись не найдена';
        END IF;
        
        UPDATE fact_production 
        SET tons_mined = p_new_tons,
            loaded_at = CURRENT_TIMESTAMP
        WHERE production_id = p_production_id;
        
        v_result := format('OK: tons_mined изменен с %s на %s', 
                          v_current_tons::TEXT, p_new_tons::TEXT);
        RETURN v_result;
        
    EXCEPTION 
        WHEN lock_not_available THEN
            RETURN format('ЗАБЛОКИРОВАНО: запись %s недоступна, попробуйте позже (таймаут %s мс)', 
                         p_production_id, p_timeout_ms);
        WHEN deadlock_detected THEN
            RETURN format('DEADLOCK: обнаружен взаимоблокировка при обновлении записи %s, повторите операцию', 
                         p_production_id);
        WHEN OTHERS THEN
            RETURN format('ОШИБКА: %s', SQLERRM);
    END;
END;
$$ LANGUAGE plpgsql;


INSERT INTO fact_production (
    production_id, date_id, shift_id, mine_id, shaft_id,
    equipment_id, operator_id, location_id, ore_grade_id,
    tons_mined, tons_transported, trips_count, distance_km,
    fuel_consumed_l, operating_hours, loaded_at
) VALUES (
    99999, 20250315, 1, 1, 3, 1, 1, 1, 1,
    100.50, 110.20, 7, 10.50, 135.60, 11.20, CURRENT_TIMESTAMP
);


SELECT production_id, tons_mined, loaded_at 
FROM fact_production 
WHERE production_id = 99999;


BEGIN;

SELECT production_id, tons_mined, loaded_at 
FROM fact_production 
WHERE production_id = 9999 
FOR UPDATE;


SELECT 'Запись 9999 заблокирована в сессии A' as status, 
       production_id, tons_mined 
FROM fact_production 
WHERE production_id = 9999;

SELECT pg_sleep(10);

COMMIT;

SELECT 'Сессия A: блокировка снята, транзакция зафиксирована' as status;


SELECT safe_update_production(99999, 150.75, 3000);
```

## Задание 6
### Текст задания

### Решение
```

```
### Результат
```

```
## Задание 7
### Текст задания

### Решение
```

```
### Результат
```

```
## Задание 8
### Текст задания

### Решение
```

```
### Результат
```

```
## Задание 9
### Текст задания

### Решение
```

```
### Результат
```

```
## Задание 10
### Текст задания

### Решение
```

```
### Результат
```

```