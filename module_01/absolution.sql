--- PRACTICE.MD ---

-- Показать все таблицы в схеме public
SELECT table_name, table_type
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
/*
table_name              |table_type|
------------------------+----------+
dim_date                |BASE TABLE|
dim_downtime_reason     |BASE TABLE|
dim_equipment           |BASE TABLE|
dim_equipment_type      |BASE TABLE|
dim_location            |BASE TABLE|
dim_mine                |BASE TABLE|
dim_operator            |BASE TABLE|
dim_ore_grade           |BASE TABLE|
dim_sensor              |BASE TABLE|
dim_sensor_type         |BASE TABLE|
dim_shaft               |BASE TABLE|
dim_shift               |BASE TABLE|
dim_time                |BASE TABLE|
fact_equipment_downtime |BASE TABLE|
fact_equipment_telemetry|BASE TABLE|
fact_ore_quality        |BASE TABLE|
fact_production         |BASE TABLE|
geography_columns       |VIEW      |
geometry_columns        |VIEW      |
spatial_ref_sys         |BASE TABLE|
*/
-- Посмотреть столбцы таблицы dim_mine
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'dim_mine'
ORDER BY ordinal_position;

/*
column_name   |data_type        |is_nullable|column_default                                 |
--------------+-----------------+-----------+-----------------------------------------------+
mine_id       |integer          |NO         |nextval('dim_mine_mine_id_seq'::regclass)      |
mine_key      |integer          |NO         |nextval('star.dim_mine_mine_key_seq'::regclass)|
mine_name     |character varying|NO         |                                               |
mine_id       |character varying|NO         |                                               |
mine_code     |character varying|NO         |                                               |
mine_name     |character varying|NO         |                                               |
region        |character varying|YES        |                                               |
region        |character varying|YES        |                                               |
max_depth_m   |integer          |YES        |                                               |
city          |character varying|YES        |                                               |
status        |character varying|YES        |                                               |
latitude      |numeric          |YES        |                                               |
opened_date   |date             |YES        |                                               |
longitude     |numeric          |YES        |                                               |
opened_date   |date             |YES        |                                               |
effective_from|date             |NO         |CURRENT_DATE                                   |
max_depth_m   |numeric          |YES        |                                               |
effective_to  |date             |NO         |'9999-12-31'::date                             |
status        |character varying|YES        |'active'::character varying                    |
is_current    |boolean          |NO         |true                                           |
*/

-- Комментарии к таблицам
SELECT
    c.relname AS table_name,
    pg_catalog.obj_description(c.oid) AS description
FROM pg_catalog.pg_class c
JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relkind = 'r'
  AND pg_catalog.obj_description(c.oid) IS NOT NULL
ORDER BY c.relname;
/*
table_name              |description                                                    |
------------------------+---------------------------------------------------------------+
dim_date                |Измерение даты — календарь                                     |
dim_downtime_reason     |Справочник причин простоев оборудования                        |
dim_equipment           |Справочник горного оборудования                                |
dim_equipment_type      |Справочник типов горного оборудования                          |
dim_location            |Подземные локации (зоны навигационной системы)                 |
dim_mine                |Справочник шахт (рудников) предприятия                         |
dim_operator            |Справочник операторов (машинистов) горного оборудования        |
dim_ore_grade           |Справочник сортов (марок) железной руды                        |
dim_sensor              |Справочник датчиков, установленных на оборудовании             |
dim_sensor_type         |Справочник типов датчиков оборудования                         |
dim_shaft               |Стволы и горизонты шахт                                        |
dim_shift               |Справочник рабочих смен                                        |
dim_time                |Измерение времени (с точностью до минуты)                      |
fact_equipment_downtime |Факт-таблица простоев оборудования                             |
fact_equipment_telemetry|Факт-таблица показаний датчиков оборудования                   |
fact_ore_quality        |Факт-таблица результатов лабораторного анализа качества руды   |
fact_production         |Факт-таблица добычи руды (одна запись — один оператор за смену)|
*/

SELECT mine_id, mine_name, mine_code, region, city, max_depth_m, status
FROM dim_mine
ORDER BY mine_id;
/*
mine_id|mine_name       |mine_code|region              |city           |max_depth_m|status|
-------+----------------+---------+--------------------+---------------+-----------+------+
      1|Шахта "Северная"|MINE_N   |Курская область     |г. Железногорск|     620.00|active|
      2|Шахта "Южная"   |MINE_S   |Белгородская область|г. Губкин      |     540.00|active|
*/

SELECT type_name, type_code, max_payload_tons, engine_power_kw, fuel_type
FROM dim_equipment_type
ORDER BY equipment_type_id;

/*
type_name                    |type_code|max_payload_tons|engine_power_kw|fuel_type                    |
-----------------------------+---------+----------------+---------------+-----------------------------+
Погрузочно-доставочная машина|LHD      |           14.00|         220.00|Дизельное топливо            |
Шахтный самосвал             |TRUCK    |           30.00|         350.00|Дизельное топливо            |
Вагонетка                    |CART     |            5.00|               |Электротяга (контактная сеть)|
Скиповой подъёмник           |SKIP     |           20.00|         500.00|Электропривод                |
*/

SELECT
    e.equipment_name,
    e.inventory_number,
    et.type_name AS equipment_type,
    m.mine_name,
    e.manufacturer,
    e.model,
    e.year_manufactured,
    e.status
FROM dim_equipment e
JOIN dim_equipment_type et ON e.equipment_type_id = et.equipment_type_id
JOIN dim_mine m ON e.mine_id = m.mine_id
ORDER BY et.type_name, e.equipment_name;
/*
equipment_name|inventory_number|equipment_type               |mine_name       |manufacturer  |model |year_manufactured|status     |
--------------+----------------+-----------------------------+----------------+--------------+------+-----------------+-----------+
Вагонетка-001 |INV-CRT-001     |Вагонетка                    |Шахта "Северная"|НКМЗ          |ВГ-5.0|             2016|active     |
Вагонетка-002 |INV-CRT-002     |Вагонетка                    |Шахта "Северная"|НКМЗ          |ВГ-5.0|             2016|active     |
Вагонетка-003 |INV-CRT-003     |Вагонетка                    |Шахта "Южная"   |НКМЗ          |ВГ-5.0|             2017|active     |
Вагонетка-004 |INV-CRT-004     |Вагонетка                    |Шахта "Южная"   |НКМЗ          |ВГ-5.0|             2017|active     |
ПДМ-001       |INV-LHD-001     |Погрузочно-доставочная машина|Шахта "Северная"|Sandvik       |LH514 |             2019|active     |
ПДМ-002       |INV-LHD-002     |Погрузочно-доставочная машина|Шахта "Северная"|Sandvik       |LH514 |             2020|active     |
ПДМ-003       |INV-LHD-003     |Погрузочно-доставочная машина|Шахта "Северная"|Caterpillar   |R1700 |             2018|active     |
ПДМ-004       |INV-LHD-004     |Погрузочно-доставочная машина|Шахта "Южная"   |Sandvik       |LH517i|             2021|active     |
ПДМ-005       |INV-LHD-005     |Погрузочно-доставочная машина|Шахта "Южная"   |Caterpillar   |R1700 |             2017|maintenance|
ПДМ-006       |INV-LHD-006     |Погрузочно-доставочная машина|Шахта "Южная"   |Epiroc        |ST14  |             2022|active     |
Скип-001      |INV-SKP-001     |Скиповой подъёмник           |Шахта "Северная"|НКМЗ          |СН-20 |             2010|active     |
Скип-002      |INV-SKP-002     |Скиповой подъёмник           |Шахта "Северная"|Siemag Tecberg|BMR-20|             2015|active     |
Скип-003      |INV-SKP-003     |Скиповой подъёмник           |Шахта "Южная"   |НКМЗ          |СН-20 |             2012|active     |
Самосвал-001  |INV-TRK-001     |Шахтный самосвал             |Шахта "Северная"|Sandvik       |TH663i|             2020|active     |
Самосвал-002  |INV-TRK-002     |Шахтный самосвал             |Шахта "Северная"|Sandvik       |TH663i|             2020|active     |
Самосвал-003  |INV-TRK-003     |Шахтный самосвал             |Шахта "Северная"|Caterpillar   |AD30  |             2019|active     |
Самосвал-004  |INV-TRK-004     |Шахтный самосвал             |Шахта "Южная"   |Sandvik       |TH551i|             2021|active     |
Самосвал-005  |INV-TRK-005     |Шахтный самосвал             |Шахта "Южная"   |Caterpillar   |AD30  |             2018|active     |
*/

SELECT
    m.mine_name,
    et.type_name,
    COUNT(*) AS equipment_count
FROM dim_equipment e
JOIN dim_mine m ON e.mine_id = m.mine_id
JOIN dim_equipment_type et ON e.equipment_type_id = et.equipment_type_id
GROUP BY m.mine_name, et.type_name
ORDER BY m.mine_name, et.type_name;
/*
mine_name       |type_name                    |equipment_count|
----------------+-----------------------------+---------------+
Шахта "Северная"|Вагонетка                    |              2|
Шахта "Северная"|Погрузочно-доставочная машина|              3|
Шахта "Северная"|Скиповой подъёмник           |              2|
Шахта "Северная"|Шахтный самосвал             |              3|
Шахта "Южная"   |Вагонетка                    |              2|
Шахта "Южная"   |Погрузочно-доставочная машина|              3|
Шахта "Южная"   |Скиповой подъёмник           |              1|
Шахта "Южная"   |Шахтный самосвал             |              2|
*/

SELECT
    'fact_production' AS table_name, COUNT(*) AS row_count FROM fact_production
UNION ALL
SELECT
    'fact_equipment_telemetry', COUNT(*) FROM fact_equipment_telemetry
UNION ALL
SELECT
    'fact_equipment_downtime', COUNT(*) FROM fact_equipment_downtime
UNION ALL
SELECT
    'fact_ore_quality', COUNT(*) FROM fact_ore_quality
ORDER BY table_name;

/*
table_name              |row_count|
------------------------+---------+
fact_equipment_downtime |     1735|
fact_equipment_telemetry|    18864|
fact_ore_quality        |     5325|
fact_production         |     8384|
 */

SELECT
    fp.production_id,
    d.full_date,
    s.shift_name,
    m.mine_name,
    e.equipment_name,
    op.last_name || ' ' || op.first_name AS operator,
    fp.tons_mined,
    fp.trips_count,
    fp.operating_hours
FROM fact_production fp
JOIN dim_date d ON fp.date_id = d.date_id
JOIN dim_shift s ON fp.shift_id = s.shift_id
JOIN dim_mine m ON fp.mine_id = m.mine_id
JOIN dim_equipment e ON fp.equipment_id = e.equipment_id
JOIN dim_operator op ON fp.operator_id = op.operator_id
ORDER BY d.full_date DESC, s.shift_name
LIMIT 10;

/*
production_id|full_date |shift_name   |mine_name       |equipment_name|operator        |tons_mined|trips_count|operating_hours|
-------------+----------+-------------+----------------+--------------+----------------+----------+-----------+---------------+
         8371|2025-06-30|Дневная смена|Шахта "Северная"|ПДМ-001       |Иванов Алексей  |     77.52|          8|          10.22|
         8372|2025-06-30|Дневная смена|Шахта "Северная"|ПДМ-002       |Петров Сергей   |    102.15|          9|          11.15|
         8373|2025-06-30|Дневная смена|Шахта "Северная"|ПДМ-003       |Кузнецов Игорь  |     77.95|          5|          10.11|
         8374|2025-06-30|Дневная смена|Шахта "Южная"   |ПДМ-004       |Новиков Михаил  |     90.68|         10|          10.79|
         8375|2025-06-30|Дневная смена|Шахта "Южная"   |ПДМ-006       |Морозов Владимир|    102.25|          9|          10.64|
         8376|2025-06-30|Дневная смена|Шахта "Южная"   |Самосвал-004  |Волков Николай  |    196.29|          5|          11.31|
         8377|2025-06-30|Ночная смена |Шахта "Северная"|ПДМ-001       |Иванов Алексей  |     97.82|          7|          10.13|
         8378|2025-06-30|Ночная смена |Шахта "Северная"|ПДМ-002       |Петров Сергей   |     72.45|          6|          10.09|
         8379|2025-06-30|Ночная смена |Шахта "Северная"|ПДМ-003       |Кузнецов Игорь  |     75.77|          6|          10.76|
         8380|2025-06-30|Ночная смена |Шахта "Южная"   |ПДМ-004       |Новиков Михаил  |    108.95|          9|          10.88|
 */


-- EXAMPLES.SQL
-- ============================================================
-- Модуль 1: Введение в язык SQL и СУБД PostgreSQL
-- Примеры SQL-запросов из презентации
-- СУБД: PostgreSQL (Yandex Managed Service for PostgreSQL)
-- База данных: ruda_plus (предприятие «Руда+»)
-- ============================================================

-- ============================================================
-- 1. EXPRESSION (ВЫРАЖЕНИЕ) — примеры
-- ============================================================

-- Литеральные выражения
SELECT
    42                    AS integer_literal,
    'Шахта Северная'      AS string_literal,
    TRUE                  AS boolean_literal,
    CURRENT_DATE          AS date_expression,
    CURRENT_TIMESTAMP     AS timestamp_expression;
/*
integer_literal|string_literal|boolean_literal|date_expression|timestamp_expression         |
---------------+--------------+---------------+---------------+-----------------------------+
             42|Шахта Северная|true           |     2026-03-27|2026-03-27 16:13:35.910 +0800|
 */
-- Арифметические выражения на данных «Руда+»
SELECT
    equipment_name,
    year_manufactured,
    EXTRACT(YEAR FROM CURRENT_DATE) - year_manufactured AS equipment_age_years
FROM dim_equipment
ORDER BY equipment_age_years DESC;
/*
equipment_name|year_manufactured|equipment_age_years|
--------------+-----------------+-------------------+
Скип-001      |             2010|                 16|
Скип-003      |             2012|                 14|
Скип-002      |             2015|                 11|
Вагонетка-002 |             2016|                 10|
Вагонетка-001 |             2016|                 10|
ПДМ-005       |             2017|                  9|
Вагонетка-004 |             2017|                  9|
Вагонетка-003 |             2017|                  9|
ПДМ-003       |             2018|                  8|
Самосвал-005  |             2018|                  8|
ПДМ-001       |             2019|                  7|
Самосвал-003  |             2019|                  7|
Самосвал-002  |             2020|                  6|
Самосвал-001  |             2020|                  6|
ПДМ-002       |             2020|                  6|
Самосвал-004  |             2021|                  5|
ПДМ-004       |             2021|                  5|
ПДМ-006       |             2022|                  4|
 */

-- Выражения с функциями
SELECT
    mine_name,
    max_depth_m,
    ROUND(max_depth_m * 3.281, 1) AS max_depth_ft,  -- перевод метров в футы
    UPPER(mine_code) AS mine_code_upper
FROM dim_mine;
/*
 mine_name       |max_depth_m|max_depth_ft|mine_code_upper|
----------------+-----------+------------+---------------+
Шахта "Северная"|     620.00|      2034.2|MINE_N         |
Шахта "Южная"   |     540.00|      1771.7|MINE_S         |
 */

-- Условное выражение CASE
SELECT
    equipment_name,
    status,
    CASE
        WHEN status = 'active'         THEN 'В работе'
        WHEN status = 'maintenance'    THEN 'На обслуживании'
        WHEN status = 'decommissioned' THEN 'Списано'
        ELSE 'Неизвестно'
    END AS status_rus
FROM dim_equipment
ORDER BY equipment_name;
/*
equipment_name|status     |status_rus     |
--------------+-----------+---------------+
Вагонетка-001 |active     |В работе       |
Вагонетка-002 |active     |В работе       |
Вагонетка-003 |active     |В работе       |
Вагонетка-004 |active     |В работе       |
ПДМ-001       |active     |В работе       |
ПДМ-002       |active     |В работе       |
ПДМ-003       |active     |В работе       |
ПДМ-004       |active     |В работе       |
ПДМ-005       |maintenance|На обслуживании|
ПДМ-006       |active     |В работе       |
Самосвал-001  |active     |В работе       |
Самосвал-002  |active     |В работе       |
Самосвал-003  |active     |В работе       |
Самосвал-004  |active     |В работе       |
Самосвал-005  |active     |В работе       |
Скип-001      |active     |В работе       |
Скип-002      |active     |В работе       |
Скип-003      |active     |В работе       |
 */

-- ============================================================
-- 2. CLAUSE (ПРЕДЛОЖЕНИЕ) — каждое ключевое слово = секция
-- ============================================================

SELECT                                        -- Clause: SELECT (что выводить)
    m.mine_name,
    COUNT(e.equipment_id) AS equipment_count
FROM dim_mine m                               -- Clause: FROM (источник данных)
JOIN dim_equipment e                          -- Clause: JOIN (соединение)
    ON m.mine_id = e.mine_id                  -- Clause: ON (условие соединения)
WHERE m.status = 'active'                     -- Clause: WHERE (фильтрация строк)
GROUP BY m.mine_name                          -- Clause: GROUP BY (группировка)
HAVING COUNT(e.equipment_id) > 5              -- Clause: HAVING (фильтрация групп)
ORDER BY equipment_count DESC                 -- Clause: ORDER BY (сортировка)
LIMIT 10;                                     -- Clause: LIMIT (ограничение)
/*
mine_name       |equipment_count|
----------------+---------------+
Шахта "Северная"|             10|
Шахта "Южная"   |              8|
 */

-- ============================================================
-- 3. STATEMENT (ИНСТРУКЦИЯ) — полная конструкция для выполнения
-- ============================================================

-- Statement 1: выборка шахт
SELECT mine_name, max_depth_m
FROM dim_mine
WHERE status = 'active'
ORDER BY max_depth_m DESC;
/*
mine_name       |max_depth_m|
----------------+-----------+
Шахта "Северная"|     620.00|
Шахта "Южная"   |     540.00|
 */

-- Statement 2: подсчёт оборудования по типам
SELECT
    et.type_name,
    COUNT(*) AS total
FROM dim_equipment e
JOIN dim_equipment_type et ON e.equipment_type_id = et.equipment_type_id
GROUP BY et.type_name
ORDER BY total DESC;

/*
type_name                    |total|
-----------------------------+-----+
Погрузочно-доставочная машина|    6|
Шахтный самосвал             |    5|
Вагонетка                    |    4|
Скиповой подъёмник           |    3|
 */
-- ============================================================
-- 4. COMMAND (КОМАНДА) — тип действия
-- ============================================================

-- DDL-команда: создание временной таблицы (для демонстрации)
CREATE TEMP TABLE temp_demo (
    id    SERIAL PRIMARY KEY,
    label VARCHAR(50) NOT NULL
);

-- DML-команда: вставка данных
INSERT INTO temp_demo (label) VALUES ('Тестовая запись 1'), ('Тестовая запись 2');

-- DML-команда: выборка
SELECT * FROM temp_demo;
/*
id|label            |
--+-----------------+
 1|Тестовая запись 1|
 2|Тестовая запись 2|
 */

-- DML-команда: обновление
UPDATE temp_demo SET label = 'Обновлённая запись' WHERE id = 1;

-- DML-команда: удаление
DELETE FROM temp_demo WHERE id = 2;

-- DDL-команда: удаление таблицы
DROP TABLE temp_demo;


-- ============================================================
-- 5. BATCH (ПАКЕТ) — несколько инструкций в одной транзакции
-- ============================================================

-- Пример пакета: проверка данных в нескольких таблицах
BEGIN;
SELECT 'Шахты' AS entity, COUNT(*) AS cnt FROM dim_mine;
SELECT 'Оборудование' AS entity, COUNT(*) AS cnt FROM dim_equipment;
SELECT 'Датчики' AS entity, COUNT(*) AS cnt FROM dim_sensor;
SELECT 'Операторы' AS entity, COUNT(*) AS cnt FROM dim_operator;
COMMIT;
/*
entity|cnt|
------+---+
Шахты |  2|

entity      |cnt|
------------+---+
Оборудование| 18|

entity |cnt|
-------+---+
Датчики| 43|

entity   |cnt|
---------+---+
Операторы| 10|
 */

-- ============================================================
-- 6. ОБЗОР СТРУКТУРЫ БД — системные запросы
-- ============================================================

-- Список всех таблиц
SELECT table_name, table_type
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
/*
table_name              |table_type|
------------------------+----------+
dim_date                |BASE TABLE|
dim_downtime_reason     |BASE TABLE|
dim_equipment           |BASE TABLE|
dim_equipment_type      |BASE TABLE|
dim_location            |BASE TABLE|
dim_mine                |BASE TABLE|
dim_operator            |BASE TABLE|
dim_ore_grade           |BASE TABLE|
dim_sensor              |BASE TABLE|
dim_sensor_type         |BASE TABLE|
dim_shaft               |BASE TABLE|
dim_shift               |BASE TABLE|
dim_time                |BASE TABLE|
fact_equipment_downtime |BASE TABLE|
fact_equipment_telemetry|BASE TABLE|
fact_ore_quality        |BASE TABLE|
fact_production         |BASE TABLE|
geography_columns       |VIEW      |
geometry_columns        |VIEW      |
spatial_ref_sys         |BASE TABLE|
 */
-- Столбцы конкретной таблицы
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'dim_equipment'
ORDER BY ordinal_position;
/*
column_name       |data_type        |is_nullable|column_default                                           |
------------------+-----------------+-----------+---------------------------------------------------------+
equipment_id      |integer          |NO         |nextval('dim_equipment_equipment_id_seq'::regclass)      |
equipment_key     |integer          |NO         |nextval('star.dim_equipment_equipment_key_seq'::regclass)|
equipment_id      |character varying|NO         |                                                         |
equipment_type_id |integer          |NO         |                                                         |
equipment_name    |character varying|NO         |                                                         |
mine_id           |integer          |NO         |                                                         |
equipment_name    |character varying|NO         |                                                         |
type_name         |character varying|YES        |                                                         |
inventory_number  |character varying|NO         |                                                         |
type_code         |character varying|YES        |                                                         |
manufacturer      |character varying|YES        |                                                         |
manufacturer      |character varying|YES        |                                                         |
model             |character varying|YES        |                                                         |
model             |character varying|YES        |                                                         |
year_manufactured |integer          |YES        |                                                         |
year_manufactured |integer          |YES        |                                                         |
max_payload_tons  |numeric          |YES        |                                                         |
commissioning_date|date             |YES        |                                                         |
status            |character varying|YES        |'active'::character varying                              |
mine_name         |character varying|YES        |                                                         |
has_video_recorder|boolean          |YES        |false                                                    |
mine_region       |character varying|YES        |                                                         |
has_navigation    |boolean          |YES        |false                                                    |
effective_from    |date             |NO         |CURRENT_DATE                                             |
effective_to      |date             |NO         |'9999-12-31'::date                                       |
is_current        |boolean          |NO         |true                                                     |
 */
-- Комментарии к таблицам
SELECT
    c.relname AS table_name,
    pg_catalog.obj_description(c.oid) AS description
FROM pg_catalog.pg_class c
JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relkind = 'r'
  AND pg_catalog.obj_description(c.oid) IS NOT NULL
ORDER BY c.relname;
/*
table_name              |description                                                    |
------------------------+---------------------------------------------------------------+
dim_date                |Измерение даты — календарь                                     |
dim_downtime_reason     |Справочник причин простоев оборудования                        |
dim_equipment           |Справочник горного оборудования                                |
dim_equipment_type      |Справочник типов горного оборудования                          |
dim_location            |Подземные локации (зоны навигационной системы)                 |
dim_mine                |Справочник шахт (рудников) предприятия                         |
dim_operator            |Справочник операторов (машинистов) горного оборудования        |
dim_ore_grade           |Справочник сортов (марок) железной руды                        |
dim_sensor              |Справочник датчиков, установленных на оборудовании             |
dim_sensor_type         |Справочник типов датчиков оборудования                         |
dim_shaft               |Стволы и горизонты шахт                                        |
dim_shift               |Справочник рабочих смен                                        |
dim_time                |Измерение времени (с точностью до минуты)                      |
fact_equipment_downtime |Факт-таблица простоев оборудования                             |
fact_equipment_telemetry|Факт-таблица показаний датчиков оборудования                   |
fact_ore_quality        |Факт-таблица результатов лабораторного анализа качества руды   |
fact_production         |Факт-таблица добычи руды (одна запись — один оператор за смену)|
 */

-- ============================================================
-- 7. ПЕРВЫЕ ЗАПРОСЫ К ДАННЫМ «РУДА+»
-- ============================================================

-- Какие шахты есть в системе?
SELECT mine_name, region, city, max_depth_m, status
FROM dim_mine;
/*
mine_name       |region              |city           |max_depth_m|status|
----------------+--------------------+---------------+-----------+------+
Шахта "Северная"|Курская область     |г. Железногорск|     620.00|active|
Шахта "Южная"   |Белгородская область|г. Губкин      |     540.00|active|
 */
-- Сколько оборудования на каждой шахте по типам?
SELECT
    m.mine_name,
    et.type_name,
    COUNT(*) AS equipment_count
FROM dim_equipment e
JOIN dim_mine m ON e.mine_id = m.mine_id
JOIN dim_equipment_type et ON e.equipment_type_id = et.equipment_type_id
GROUP BY m.mine_name, et.type_name
ORDER BY m.mine_name, et.type_name;
/*
mine_name       |type_name                    |equipment_count|
----------------+-----------------------------+---------------+
Шахта "Северная"|Вагонетка                    |              2|
Шахта "Северная"|Погрузочно-доставочная машина|              3|
Шахта "Северная"|Скиповой подъёмник           |              2|
Шахта "Северная"|Шахтный самосвал             |              3|
Шахта "Южная"   |Вагонетка                    |              2|
Шахта "Южная"   |Погрузочно-доставочная машина|              3|
Шахта "Южная"   |Скиповой подъёмник           |              1|
Шахта "Южная"   |Шахтный самосвал             |              2|
 */
-- Причины простоев по категориям
SELECT reason_name, category
FROM dim_downtime_reason
ORDER BY category, reason_name;
/*
reason_name                      |category       |
---------------------------------+---------------+
Аварийный ремонт                 |внеплановый    |
Обрушение породы                 |внеплановый    |
Перегрев двигателя               |внеплановый    |
Электроснабжение                 |внеплановый    |
Ожидание погрузки                |организационный|
Ожидание транспорта              |организационный|
Отсутствие оператора             |организационный|
Диагностика и калибровка         |плановый       |
Замена шин / гусениц             |плановый       |
Заправка топливом                |плановый       |
Плановое техническое обслуживание|плановый       |
Проветривание забоя              |плановый       |
 */

-- ============================================================
-- 8. EXPLAIN — просмотр плана выполнения запроса
-- ============================================================

EXPLAIN
SELECT
    m.mine_name,
    COUNT(e.equipment_id) AS cnt
FROM dim_mine m
JOIN dim_equipment e ON m.mine_id = e.mine_id
WHERE m.status = 'active'
GROUP BY m.mine_name;
/*
QUERY PLAN                                                                         |
-----------------------------------------------------------------------------------+
GroupAggregate  (cost=21.92..21.94 rows=1 width=326)                               |
  Group Key: m.mine_name                                                           |
  ->  Sort  (cost=21.92..21.92 rows=1 width=322)                                   |
        Sort Key: m.mine_name                                                      |
        ->  Hash Join  (cost=11.01..21.91 rows=1 width=322)                        |
              Hash Cond: (e.mine_id = m.mine_id)                                   |
              ->  Seq Scan on dim_equipment e  (cost=0.00..10.70 rows=70 width=8)  |
              ->  Hash  (cost=11.00..11.00 rows=1 width=322)                       |
                    ->  Seq Scan on dim_mine m  (cost=0.00..11.00 rows=1 width=322)|
                          Filter: ((status)::text = 'active'::text)                |
 */
-- С подробной статистикой (ANALYZE выполняет запрос!)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT
    m.mine_name,
    COUNT(e.equipment_id) AS cnt
FROM dim_mine m
JOIN dim_equipment e ON m.mine_id = e.mine_id
WHERE m.status = 'active'
GROUP BY m.mine_name;
/*
QUERY PLAN                                                                                                                   |
-----------------------------------------------------------------------------------------------------------------------------+
GroupAggregate  (cost=21.92..21.94 rows=1 width=326) (actual time=0.085..0.090 rows=2 loops=1)                               |
  Group Key: m.mine_name                                                                                                     |
  Buffers: shared hit=2                                                                                                      |
  ->  Sort  (cost=21.92..21.92 rows=1 width=322) (actual time=0.076..0.079 rows=18 loops=1)                                  |
        Sort Key: m.mine_name                                                                                                |
        Sort Method: quicksort  Memory: 26kB                                                                                 |
        Buffers: shared hit=2                                                                                                |
        ->  Hash Join  (cost=11.01..21.91 rows=1 width=322) (actual time=0.029..0.040 rows=18 loops=1)                       |
              Hash Cond: (e.mine_id = m.mine_id)                                                                             |
              Buffers: shared hit=2                                                                                          |
              ->  Seq Scan on dim_equipment e  (cost=0.00..10.70 rows=70 width=8) (actual time=0.007..0.009 rows=18 loops=1) |
                    Buffers: shared hit=1                                                                                    |
              ->  Hash  (cost=11.00..11.00 rows=1 width=322) (actual time=0.013..0.014 rows=2 loops=1)                       |
                    Buckets: 1024  Batches: 1  Memory Usage: 9kB                                                             |
                    Buffers: shared hit=1                                                                                    |
                    ->  Seq Scan on dim_mine m  (cost=0.00..11.00 rows=1 width=322) (actual time=0.008..0.009 rows=2 loops=1)|
                          Filter: ((status)::text = 'active'::text)                                                          |
                          Buffers: shared hit=1                                                                              |
Planning:                                                                                                                    |
  Buffers: shared hit=8                                                                                                      |
Planning Time: 0.222 ms                                                                                                      |
Execution Time: 0.148 ms                                                                                                     |
 */

-- ============================================================
-- 9. СРАВНЕНИЕ SQL и DAX — подсчёт оборудования
-- ============================================================

-- SQL: подсчёт оборудования по шахтам
SELECT
    m.mine_name,
    COUNT(*) AS total_equipment
FROM dim_equipment e
JOIN dim_mine m ON e.mine_id = m.mine_id
GROUP BY m.mine_name;
/*
mine_name       |total_equipment|
----------------+---------------+
Шахта "Южная"   |              8|
Шахта "Северная"|             10|
 */
-- Аналог в DAX (для справки, выполняется в Power BI / DAX Studio):
--
-- Total Equipment =
-- COUNTROWS(dim_equipment)
--
-- Equipment By Mine =
-- SUMMARIZE(
--     dim_equipment,
--     dim_mine[mine_name],
--     "Total Equipment", COUNTROWS(dim_equipment)
-- )


-- ============================================================
-- 10. ОБЪЁМ ДАННЫХ В ФАКТ-ТАБЛИЦАХ
-- ============================================================

SELECT
    'fact_production' AS table_name, COUNT(*) AS row_count FROM fact_production
UNION ALL
SELECT
    'fact_equipment_telemetry', COUNT(*) FROM fact_equipment_telemetry
UNION ALL
SELECT
    'fact_equipment_downtime', COUNT(*) FROM fact_equipment_downtime
UNION ALL
SELECT
    'fact_ore_quality', COUNT(*) FROM fact_ore_quality
ORDER BY table_name;
/*
table_name              |row_count|
------------------------+---------+
fact_equipment_downtime |     1735|
fact_equipment_telemetry|    18864|
fact_ore_quality        |     5325|
fact_production         |     8384|
*/

-- Lab.md --

select type_name,type_code,unit_of_measure,min_value,max_value from dim_sensor_type order by type_name;
/*
type_name                    |type_code  |unit_of_measure|min_value|max_value |
-----------------------------+-----------+---------------+---------+----------+
GPS-координаты (X)           |NAV_X      |м              |   0.0000|10000.0000|
GPS-координаты (Y)           |NAV_Y      |м              |   0.0000|10000.0000|
Датчик вибрации              |VIBRATION  |мм/с           |   0.0000|   50.0000|
Датчик давления масла        |OIL_PRESS  |бар            |   0.0000|   10.0000|
Датчик массы груза           |LOAD_WEIGHT|т              |   0.0000|   35.0000|
Датчик оборотов двигателя    |RPM        |об/мин         |   0.0000| 3000.0000|
Датчик скорости движения     |SPEED      |км/ч           |   0.0000|   40.0000|
Датчик температуры гидравлики|TEMP_HYDR  |°C             | -20.0000|  120.0000|
Датчик температуры двигателя |TEMP_ENGINE|°C             | -40.0000|  150.0000|
Датчик уровня топлива        |FUEL_LEVEL |%              |   0.0000|  100.0000|
*/


select t.first_name, t.middle_name, t.last_name,t.position,dm.mine_name  from dim_operator t join dim_mine dm on t.mine_id=dm.mine_id where t.status='active' order by dm.mine_name, t.last_name;
/*
first_name|middle_name  |last_name|position          |mine_name       |
----------+-------------+---------+------------------+----------------+
Алексей   |Петрович     |Иванов   |Машинист ПДМ      |Шахта "Северная"|
Андрей    |Викторович   |Козлов   |Машинист самосвала|Шахта "Северная"|
Игорь     |Олегович     |Кузнецов |Машинист ПДМ      |Шахта "Северная"|
Сергей    |Николаевич   |Петров   |Машинист ПДМ      |Шахта "Северная"|
Дмитрий   |Александрович|Сидоров  |Машинист самосвала|Шахта "Северная"|
Павел     |Андреевич    |Соловьёв |Оператор подъёма  |Шахта "Северная"|
Николай   |Дмитриевич   |Волков   |Машинист самосвала|Шахта "Южная"   |
Евгений   |Михайлович   |Лебедев  |Оператор подъёма  |Шахта "Южная"   |
Владимир  |Иванович     |Морозов  |Машинист ПДМ      |Шахта "Южная"   |
Михаил    |Сергеевич    |Новиков  |Машинист ПДМ      |Шахта "Южная"   |
 */

SELECT
    e.equipment_name,
    et.type_name,
    COUNT(s.sensor_id) AS sensor_count
FROM dim_equipment e
JOIN dim_equipment_type et ON e.equipment_type_id = et.equipment_type_id
JOIN dim_sensor s ON s.equipment_id = e.equipment_id
GROUP BY e.equipment_name, et.type_name
ORDER BY sensor_count DESC;
/*
equipment_name|type_name                    |sensor_count|
--------------+-----------------------------+------------+
Самосвал-001  |Шахтный самосвал             |           7|
ПДМ-002       |Погрузочно-доставочная машина|           5|
Самосвал-004  |Шахтный самосвал             |           5|
ПДМ-004       |Погрузочно-доставочная машина|           5|
Самосвал-002  |Шахтный самосвал             |           5|
ПДМ-001       |Погрузочно-доставочная машина|           5|
Скип-001      |Скиповой подъёмник           |           4|
ПДМ-003       |Погрузочно-доставочная машина|           4|
Скип-003      |Скиповой подъёмник           |           3|
 */

SELECT
    m.mine_name,
    sh.shaft_name,
    sh.shaft_type,
    loc.location_name,
    loc.location_type,
    loc.level_m
FROM dim_mine m
JOIN dim_shaft sh ON m.mine_id = sh.mine_id
JOIN dim_location loc ON sh.shaft_id = loc.shaft_id
ORDER BY m.mine_name, sh.shaft_name, loc.level_m;

/*
mine_name       |shaft_name     |shaft_type|location_name      |location_type      |level_m|
----------------+---------------+----------+-------------------+-------------------+-------+
Шахта "Северная"|Горизонт -480 м|горизонт  |Забой 1-С          |забой              |-480.00|
Шахта "Северная"|Горизонт -480 м|горизонт  |Забой 2-С          |забой              |-480.00|
Шахта "Северная"|Горизонт -480 м|горизонт  |Штрек транспортный |штрек              |-480.00|
Шахта "Северная"|Горизонт -480 м|горизонт  |Рудоспуск №1       |рудоспуск          |-480.00|
Шахта "Северная"|Горизонт -480 м|горизонт  |Околоствольный двор|околоствольный двор|-480.00|
Шахта "Северная"|Горизонт -620 м|горизонт  |Забой 3-С          |забой              |-620.00|
Шахта "Северная"|Горизонт -620 м|горизонт  |Забой 4-С          |забой              |-620.00|
Шахта "Северная"|Горизонт -620 м|горизонт  |Штрек откаточный   |штрек              |-620.00|
Шахта "Северная"|Горизонт -620 м|горизонт  |Рудоспуск №2       |рудоспуск          |-620.00|
Шахта "Южная"   |Горизонт -420 м|горизонт  |Забой 1-Ю          |забой              |-420.00|
Шахта "Южная"   |Горизонт -420 м|горизонт  |Забой 2-Ю          |забой              |-420.00|
Шахта "Южная"   |Горизонт -420 м|горизонт  |Штрек магистральный|штрек              |-420.00|
Шахта "Южная"   |Горизонт -420 м|горизонт  |Рудоспуск №1 Южный |рудоспуск          |-420.00|
Шахта "Южная"   |Горизонт -420 м|горизонт  |Камера ожидания    |камера             |-420.00|
 */

SELECT
    category,
    COUNT(*) AS reason_count
FROM dim_downtime_reason
GROUP BY category
ORDER BY category;
/*
category       |reason_count|
---------------+------------+
внеплановый    |           4|
организационный|           3|
плановый       |           5|
*/

-- Основной запрос
SELECT
    e.equipment_name,
    et.type_name,
    m.mine_name,
    e.manufacturer,
    e.model
FROM dim_equipment e
JOIN dim_equipment_type et ON e.equipment_type_id = et.equipment_type_id
JOIN dim_mine m ON e.mine_id = m.mine_id
WHERE e.has_video_recorder = TRUE
  AND e.has_navigation = TRUE
ORDER BY et.type_name, e.equipment_name;
/*
equipment_name|type_name                    |mine_name       |manufacturer|model |
--------------+-----------------------------+----------------+------------+------+
ПДМ-001       |Погрузочно-доставочная машина|Шахта "Северная"|Sandvik     |LH514 |
ПДМ-002       |Погрузочно-доставочная машина|Шахта "Северная"|Sandvik     |LH514 |
ПДМ-003       |Погрузочно-доставочная машина|Шахта "Северная"|Caterpillar |R1700 |
ПДМ-004       |Погрузочно-доставочная машина|Шахта "Южная"   |Sandvik     |LH517i|
ПДМ-005       |Погрузочно-доставочная машина|Шахта "Южная"   |Caterpillar |R1700 |
ПДМ-006       |Погрузочно-доставочная машина|Шахта "Южная"   |Epiroc      |ST14  |
Самосвал-001  |Шахтный самосвал             |Шахта "Северная"|Sandvik     |TH663i|
Самосвал-002  |Шахтный самосвал             |Шахта "Северная"|Sandvik     |TH663i|
Самосвал-003  |Шахтный самосвал             |Шахта "Северная"|Caterpillar |AD30  |
Самосвал-004  |Шахтный самосвал             |Шахта "Южная"   |Sandvik     |TH551i|
 */
-- Процент от общего парка
SELECT
    COUNT(*) FILTER (WHERE has_video_recorder AND has_navigation) AS equipped_count,
    COUNT(*) AS total_count,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE has_video_recorder AND has_navigation)
        / COUNT(*), 1
    ) AS percent_equipped
FROM dim_equipment;
/*
equipped_count|total_count|percent_equipped|
--------------+-----------+----------------+
            10|         18|            55.6|
 */

SELECT
    t.table_name,
    COUNT(c.column_name) AS column_count,
    pg_catalog.obj_description(
        (SELECT oid FROM pg_catalog.pg_class WHERE relname = t.table_name limit 1),
        'pg_class'
    ) AS table_comment
FROM information_schema.tables t
JOIN information_schema.columns c
    ON t.table_name = c.table_name
   AND t.table_schema = c.table_schema
WHERE t.table_schema = 'public'
  AND t.table_type = 'BASE TABLE'
GROUP BY t.table_name
ORDER BY t.table_name;
/*
table_name              |column_count|table_comment                                                  |
------------------------+------------+---------------------------------------------------------------+
dim_date                |          18|Измерение даты — календарь                                     |
dim_downtime_reason     |           5|Справочник причин простоев оборудования                        |
dim_equipment           |          12|Справочник горного оборудования                                |
dim_equipment_type      |           8|Справочник типов горного оборудования                          |
dim_location            |           9|Подземные локации (зоны навигационной системы)                 |
dim_mine                |          10|Справочник шахт (рудников) предприятия                         |
dim_operator            |          10|Справочник операторов (машинистов) горного оборудования        |
dim_ore_grade           |           6|Справочник сортов (марок) железной руды                        |
dim_sensor              |           7|Справочник датчиков, установленных на оборудовании             |
dim_sensor_type         |           7|Справочник типов датчиков оборудования                         |
dim_shaft               |           7|Стволы и горизонты шахт                                        |
dim_shift               |           6|Справочник рабочих смен                                        |
dim_time                |           7|Измерение времени (с точностью до минуты)                      |
fact_equipment_downtime |          13|Факт-таблица простоев оборудования                             |
fact_equipment_telemetry|          10|Факт-таблица показаний датчиков оборудования                   |
fact_ore_quality        |          16|Факт-таблица результатов лабораторного анализа качества руды   |
fact_production         |          16|Факт-таблица добычи руды (одна запись — один оператор за смену)|
spatial_ref_sys         |           5|                                                               |
 */
*/