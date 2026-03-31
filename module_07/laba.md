## Задача 1
### Текст задачи
Тема модуля: 7.3 -- Как PostgreSQL хранит данные

Бизнес-задача: Администратору БД предприятия «Руда+» необходимо провести аудит индексов аналитической базы: понять, какие индексы уже существуют, насколько они велики и как часто используются. Это первый шаг перед оптимизацией.

Требования:

Выведите список всех индексов для таблиц fact_production, fact_equipment_telemetry, fact_equipment_downtime и fact_ore_quality. Для каждого индекса покажите: имя таблицы, имя индекса, определение (indexdef).

Для таблицы fact_production выведите размер каждого индекса и статистику использования (количество сканирований, количество прочитанных кортежей).

Подсчитайте суммарный размер всех индексов для каждой факт-таблицы. Сравните с размером самих таблиц.

Подсказка: запрос для пункта 1
SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE tablename IN (
    'fact_production',
    'fact_equipment_telemetry',
    'fact_equipment_downtime',
    'fact_ore_quality'
)
ORDER BY tablename, indexname;
Подсказка: запрос для пункта 2
SELECT indexrelname AS index_name,
       pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
       idx_scan AS times_used,
       idx_tup_read AS tuples_read,
       idx_tup_fetch AS tuples_fetched
FROM pg_stat_user_indexes
WHERE relname = 'fact_production'
ORDER BY pg_relation_size(indexrelid) DESC;
Подсказка: запрос для пункта 3
SELECT relname AS table_name,
       pg_size_pretty(pg_table_size(relid)) AS table_size,
       pg_size_pretty(pg_indexes_size(relid)) AS indexes_size,
       pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
       ROUND(
           pg_indexes_size(relid)::numeric /
           NULLIF(pg_table_size(relid), 0) * 100, 1
       ) AS index_pct
FROM pg_stat_user_tables
WHERE relname IN (
    'fact_production',
    'fact_equipment_telemetry',
    'fact_equipment_downtime',
    'fact_ore_quality'
)
ORDER BY pg_total_relation_size(relid) DESC;
Ожидаемый результат: Таблица со всеми индексами, их размерами и статистикой использования. Вы должны увидеть индексы, созданные при развертывании схемы (idx_fact_production_date, idx_fact_production_shift и т.д.), и оценить долю индексов относительно данных.
### Решение
```
SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE tablename IN (
    'fact_production',
    'fact_equipment_telemetry',
    'fact_equipment_downtime',
    'fact_ore_quality'
)
ORDER BY tablename, indexname;

SELECT indexrelname AS index_name,
       pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
       idx_scan AS times_used,
       idx_tup_read AS tuples_read,
       idx_tup_fetch AS tuples_fetched
FROM pg_stat_user_indexes
WHERE relname = 'fact_production'
ORDER BY pg_relation_size(indexrelid) DESC;


SELECT relname AS table_name,
       pg_size_pretty(pg_table_size(relid)) AS table_size,
       pg_size_pretty(pg_indexes_size(relid)) AS indexes_size,
       pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
       ROUND(
           pg_indexes_size(relid)::numeric /
           NULLIF(pg_table_size(relid), 0) * 100, 1
       ) AS index_pct
FROM pg_stat_user_tables
WHERE relname IN (
    'fact_production',
    'fact_equipment_telemetry',
    'fact_equipment_downtime',
    'fact_ore_quality'
)
ORDER BY pg_total_relation_size(relid) DESC;
```
### Результат
```
tablename               |indexname                    |indexdef                                                                                                       |
------------------------+-----------------------------+---------------------------------------------------------------------------------------------------------------+
fact_equipment_downtime |fact_equipment_downtime_pkey |CREATE UNIQUE INDEX fact_equipment_downtime_pkey ON public.fact_equipment_downtime USING btree (downtime_id)   |
fact_equipment_downtime |idx_fact_downtime_date       |CREATE INDEX idx_fact_downtime_date ON public.fact_equipment_downtime USING btree (date_id)                    |
fact_equipment_downtime |idx_fact_downtime_equip      |CREATE INDEX idx_fact_downtime_equip ON public.fact_equipment_downtime USING btree (equipment_id)              |
fact_equipment_downtime |idx_fact_downtime_reason     |CREATE INDEX idx_fact_downtime_reason ON public.fact_equipment_downtime USING btree (reason_id)                |
fact_equipment_telemetry|fact_equipment_telemetry_pkey|CREATE UNIQUE INDEX fact_equipment_telemetry_pkey ON public.fact_equipment_telemetry USING btree (telemetry_id)|
fact_equipment_telemetry|idx_fact_telemetry_date      |CREATE INDEX idx_fact_telemetry_date ON public.fact_equipment_telemetry USING btree (date_id)                  |
fact_equipment_telemetry|idx_fact_telemetry_equip     |CREATE INDEX idx_fact_telemetry_equip ON public.fact_equipment_telemetry USING btree (equipment_id)            |
fact_equipment_telemetry|idx_fact_telemetry_sensor    |CREATE INDEX idx_fact_telemetry_sensor ON public.fact_equipment_telemetry USING btree (sensor_id)              |
fact_equipment_telemetry|idx_fact_telemetry_time      |CREATE INDEX idx_fact_telemetry_time ON public.fact_equipment_telemetry USING btree (time_id)                  |
fact_ore_quality        |fact_ore_quality_pkey        |CREATE UNIQUE INDEX fact_ore_quality_pkey ON public.fact_ore_quality USING btree (quality_id)                  |
fact_ore_quality        |fact_ore_quality_pkey        |CREATE UNIQUE INDEX fact_ore_quality_pkey ON star.fact_ore_quality USING btree (quality_key)                   |
fact_ore_quality        |idx_foq_mine                 |CREATE INDEX idx_foq_mine ON star.fact_ore_quality USING btree (mine_key)                                      |
fact_ore_quality        |idx_foq_time                 |CREATE INDEX idx_foq_time ON star.fact_ore_quality USING btree (time_key)                                      |
fact_production         |fact_production_pkey         |CREATE UNIQUE INDEX fact_production_pkey ON star.fact_production USING btree (production_key)                  |
fact_production         |fact_production_pkey         |CREATE UNIQUE INDEX fact_production_pkey ON public.fact_production USING btree (production_id)                 |
fact_production         |idx_fact_production_equip    |CREATE INDEX idx_fact_production_equip ON public.fact_production USING btree (equipment_id)                    |
fact_production         |idx_fact_production_mine     |CREATE INDEX idx_fact_production_mine ON public.fact_production USING btree (mine_id)                          |
fact_production         |idx_fact_production_operator |CREATE INDEX idx_fact_production_operator ON public.fact_production USING btree (operator_id)                  |
fact_production         |idx_fact_production_shift    |CREATE INDEX idx_fact_production_shift ON public.fact_production USING btree (shift_id)                        |
fact_production         |idx_fp_equipment             |CREATE INDEX idx_fp_equipment ON star.fact_production USING btree (equipment_key)                              |
fact_production         |idx_fp_mine                  |CREATE INDEX idx_fp_mine ON star.fact_production USING btree (mine_key)                                        |
fact_production         |idx_fp_operator              |CREATE INDEX idx_fp_operator ON star.fact_production USING btree (operator_key)                                |
fact_production         |idx_fp_time                  |CREATE INDEX idx_fp_time ON star.fact_production USING btree (time_key)                                        |
fact_production         |idx_prod_date_desc1          |CREATE INDEX idx_prod_date_desc1 ON public.fact_production USING btree (date_id DESC)                          |


index_name                  |index_size|times_used|tuples_read|tuples_fetched|
----------------------------+----------+----------+-----------+--------------+
fact_production_pkey        |200 kB    |        12|     100608|        100608|
idx_prod_date_desc1         |88 kB     |        53|       2184|          2184|
idx_fact_production_mine    |80 kB     |     16970|   75672531|      75647379|
idx_fact_production_equip   |80 kB     |     58908|   61773692|      61656316|
idx_fact_production_operator|80 kB     |        18|     134544|         41920|
idx_fact_production_shift   |80 kB     |         3|      25152|             0|
fact_production_pkey        |16 kB     |         0|          0|             0|
idx_fp_time                 |16 kB     |        17|       3060|          3060|
idx_fp_mine                 |16 kB     |         0|          0|             0|
idx_fp_equipment            |16 kB     |         0|          0|             0|
idx_fp_operator             |16 kB     |         0|          0|             0|

table_name              |table_size|indexes_size|total_size|index_pct|
------------------------+----------+------------+----------+---------+
fact_equipment_telemetry|1448 kB   |1088 kB     |2536 kB   |     75.1|
fact_production         |1056 kB   |608 kB      |1664 kB   |     57.6|
fact_ore_quality        |760 kB    |136 kB      |896 kB    |     17.9|
fact_equipment_downtime |256 kB    |184 kB      |440 kB    |     71.9|
fact_production         |48 kB     |80 kB       |128 kB    |    166.7|
fact_ore_quality        |8192 bytes|48 kB       |56 kB     |    600.0|
```
## Задача 2
### Текст задачи
Тема модуля: 7.1 -- Планы выполнения запросов

Бизнес-задача: Начальник участка жалуется, что отчет по добыче за месяц с группировкой по оборудованию работает медленно. Необходимо проанализировать план выполнения запроса и выявить узкое место.

Требования:

Выполните запрос с EXPLAIN и изучите оценочный план (запрос НЕ выполняется):
EXPLAIN
SELECT e.equipment_name,
       SUM(p.tons_mined) AS total_tons,
       SUM(p.fuel_consumed_l) AS total_fuel,
       SUM(p.operating_hours) AS total_hours
FROM fact_production p
JOIN dim_equipment e ON p.equipment_id = e.equipment_id
WHERE p.date_id BETWEEN 20240301 AND 20240331
GROUP BY e.equipment_name
ORDER BY total_tons DESC;
Выполните тот же запрос с EXPLAIN ANALYZE и зафиксируйте реальное время:
EXPLAIN ANALYZE
SELECT e.equipment_name,
       SUM(p.tons_mined) AS total_tons,
       SUM(p.fuel_consumed_l) AS total_fuel,
       SUM(p.operating_hours) AS total_hours
FROM fact_production p
JOIN dim_equipment e ON p.equipment_id = e.equipment_id
WHERE p.date_id BETWEEN 20240301 AND 20240331
GROUP BY e.equipment_name
ORDER BY total_tons DESC;
Выполните тот же запрос с EXPLAIN (ANALYZE, BUFFERS) для анализа ввода/вывода:
EXPLAIN (ANALYZE, BUFFERS)
SELECT e.equipment_name,
       SUM(p.tons_mined) AS total_tons,
       SUM(p.fuel_consumed_l) AS total_fuel,
       SUM(p.operating_hours) AS total_hours
FROM fact_production p
JOIN dim_equipment e ON p.equipment_id = e.equipment_id
WHERE p.date_id BETWEEN 20240301 AND 20240331
GROUP BY e.equipment_name
ORDER BY total_tons DESC;
Определите узкое место запроса. Ответьте на вопросы:
Какой тип сканирования используется для fact_production?
Какой тип соединения (Join) выбран планировщиком?
Где тратится больше всего времени?
Сколько страниц (buffers) прочитано?
Подсказка: на что обращать внимание
Ожидаемый результат: Три варианта плана выполнения с нарастающей детализацией. Основное узкое место -- сканирование fact_production с фильтрацией по date_id.
### Решение
```
EXPLAIN
SELECT e.equipment_name,
       SUM(p.tons_mined) AS total_tons,
       SUM(p.fuel_consumed_l) AS total_fuel,
       SUM(p.operating_hours) AS total_hours
FROM fact_production p
JOIN dim_equipment e ON p.equipment_id = e.equipment_id
WHERE p.date_id BETWEEN 20240301 AND 20240331
GROUP BY e.equipment_name
ORDER BY total_tons DESC;

EXPLAIN ANALYZE
SELECT e.equipment_name,
       SUM(p.tons_mined) AS total_tons,
       SUM(p.fuel_consumed_l) AS total_fuel,
       SUM(p.operating_hours) AS total_hours
FROM fact_production p
JOIN dim_equipment e ON p.equipment_id = e.equipment_id
WHERE p.date_id BETWEEN 20240301 AND 20240331
GROUP BY e.equipment_name
ORDER BY total_tons DESC;

EXPLAIN (ANALYZE, BUFFERS)
SELECT e.equipment_name,
       SUM(p.tons_mined) AS total_tons,
       SUM(p.fuel_consumed_l) AS total_fuel,
       SUM(p.operating_hours) AS total_hours
FROM fact_production p
JOIN dim_equipment e ON p.equipment_id = e.equipment_id
WHERE p.date_id BETWEEN 20240301 AND 20240331
GROUP BY e.equipment_name
ORDER BY total_tons DESC;
```
### Результат
```
QUERY PLAN                                                                                                       |
-----------------------------------------------------------------------------------------------------------------+
Sort  (cost=39.71..39.88 rows=70 width=414)                                                                      |
  Sort Key: (sum(p.tons_mined)) DESC                                                                             |
  ->  HashAggregate  (cost=36.34..37.56 rows=70 width=414)                                                       |
        Group Key: e.equipment_name                                                                              |
        ->  Hash Join  (cost=11.86..31.62 rows=472 width=336)                                                    |
              Hash Cond: (p.equipment_id = e.equipment_id)                                                       |
              ->  Index Scan using idx_prod_date_desc1 on fact_production p  (cost=0.29..18.72 rows=472 width=22)|
                    Index Cond: ((date_id >= 20240301) AND (date_id <= 20240331))                                |
              ->  Hash  (cost=10.70..10.70 rows=70 width=322)                                                    |
                    ->  Seq Scan on dim_equipment e  (cost=0.00..10.70 rows=70 width=322)                        |

QUERY PLAN                                                                                                                                                   |
-------------------------------------------------------------------------------------------------------------------------------------------------------------+
Sort  (cost=39.71..39.88 rows=70 width=414) (actual time=0.449..0.451 rows=8 loops=1)                                                                        |
  Sort Key: (sum(p.tons_mined)) DESC                                                                                                                         |
  Sort Method: quicksort  Memory: 25kB                                                                                                                       |
  ->  HashAggregate  (cost=36.34..37.56 rows=70 width=414) (actual time=0.436..0.441 rows=8 loops=1)                                                         |
        Group Key: e.equipment_name                                                                                                                          |
        Batches: 1  Memory Usage: 32kB                                                                                                                       |
        ->  Hash Join  (cost=11.86..31.62 rows=472 width=336) (actual time=0.065..0.273 rows=472 loops=1)                                                    |
              Hash Cond: (p.equipment_id = e.equipment_id)                                                                                                   |
              ->  Index Scan using idx_prod_date_desc1 on fact_production p  (cost=0.29..18.72 rows=472 width=22) (actual time=0.041..0.131 rows=472 loops=1)|
                    Index Cond: ((date_id >= 20240301) AND (date_id <= 20240331))                                                                            |
              ->  Hash  (cost=10.70..10.70 rows=70 width=322) (actual time=0.017..0.018 rows=18 loops=1)                                                     |
                    Buckets: 1024  Batches: 1  Memory Usage: 9kB                                                                                             |
                    ->  Seq Scan on dim_equipment e  (cost=0.00..10.70 rows=70 width=322) (actual time=0.009..0.011 rows=18 loops=1)                         |
Planning Time: 0.279 ms                                                                                                                                      |
Execution Time: 0.507 ms          

QUERY PLAN                                                                                                                                                   |
-------------------------------------------------------------------------------------------------------------------------------------------------------------+
Sort  (cost=39.71..39.88 rows=70 width=414) (actual time=0.468..0.470 rows=8 loops=1)                                                                        |
  Sort Key: (sum(p.tons_mined)) DESC                                                                                                                         |
  Sort Method: quicksort  Memory: 25kB                                                                                                                       |
  Buffers: shared hit=25                                                                                                                                     |
  ->  HashAggregate  (cost=36.34..37.56 rows=70 width=414) (actual time=0.452..0.458 rows=8 loops=1)                                                         |
        Group Key: e.equipment_name                                                                                                                          |
        Batches: 1  Memory Usage: 32kB                                                                                                                       |
        Buffers: shared hit=25                                                                                                                               |
        ->  Hash Join  (cost=11.86..31.62 rows=472 width=336) (actual time=0.036..0.276 rows=472 loops=1)                                                    |
              Hash Cond: (p.equipment_id = e.equipment_id)                                                                                                   |
              Buffers: shared hit=25                                                                                                                         |
              ->  Index Scan using idx_prod_date_desc1 on fact_production p  (cost=0.29..18.72 rows=472 width=22) (actual time=0.014..0.102 rows=472 loops=1)|
                    Index Cond: ((date_id >= 20240301) AND (date_id <= 20240331))                                                                            |
                    Buffers: shared hit=24                                                                                                                   |
              ->  Hash  (cost=10.70..10.70 rows=70 width=322) (actual time=0.016..0.016 rows=18 loops=1)                                                     |
                    Buckets: 1024  Batches: 1  Memory Usage: 9kB                                                                                             |
                    Buffers: shared hit=1                                                                                                                    |
                    ->  Seq Scan on dim_equipment e  (cost=0.00..10.70 rows=70 width=322) (actual time=0.007..0.010 rows=18 loops=1)                         |
                          Buffers: shared hit=1                                                                                                              |
Planning:                                                                                                                                                    |
  Buffers: shared hit=8                                                                                                                                      |
Planning Time: 0.228 ms                                                                                                                                      |
Execution Time: 0.524 ms                                                                                                                                     |                                                                                                                           |
```

## Задача 3
### Текст задачи
Тема модуля: 7.2 -- Избирательность; 7.5 -- B-tree индекс

Бизнес-задача: Диспетчер хочет быстро находить смены с аномально высоким расходом топлива (более 80 литров) для расследования причин перерасхода. Такие смены составляют небольшую долю от общего числа.

Требования:

Зафиксируйте план запроса до создания индекса:
EXPLAIN ANALYZE
SELECT p.date_id, e.equipment_name, o.last_name, p.fuel_consumed_l
FROM fact_production p
JOIN dim_equipment e ON p.equipment_id = e.equipment_id
JOIN dim_operator o ON p.operator_id = o.operator_id
WHERE p.fuel_consumed_l > 80
ORDER BY p.fuel_consumed_l DESC;
Оцените избирательность (selectivity) условия fuel_consumed_l > 80:
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE fuel_consumed_l > 80) AS matching_rows,
    ROUND(
        COUNT(*) FILTER (WHERE fuel_consumed_l > 80)::numeric /
        COUNT(*) * 100, 2
    ) AS selectivity_pct
FROM fact_production;
Создайте B-tree индекс на столбец fuel_consumed_l.

Повторите запрос из п.1 с EXPLAIN ANALYZE и сравните планы.

Ответьте на вопрос: если избирательность составляет более 20-30%, почему PostgreSQL может продолжить использовать Seq Scan даже после создания индекса?
### Решение
```
EXPLAIN ANALYZE
SELECT p.date_id, e.equipment_name, o.last_name, p.fuel_consumed_l
FROM fact_production p
JOIN dim_equipment e ON p.equipment_id = e.equipment_id
JOIN dim_operator o ON p.operator_id = o.operator_id
WHERE p.fuel_consumed_l > 80
ORDER BY p.fuel_consumed_l DESC;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE fuel_consumed_l > 80) AS matching_rows,
    ROUND(
        COUNT(*) FILTER (WHERE fuel_consumed_l > 80)::numeric /
        COUNT(*) * 100, 2
    ) AS selectivity_pct
FROM fact_production;

create index fuel_index on "Pech".fact_production(fuel_consumed_l);

EXPLAIN ANALYZE
SELECT p.date_id, e.equipment_name, o.last_name, p.fuel_consumed_l
FROM "Pech".fact_production p
JOIN "Pech".dim_equipment e ON p.equipment_id = e.equipment_id
JOIN "Pech".dim_operator o ON p.operator_id = o.operator_id
WHERE p.fuel_consumed_l > 80
ORDER BY p.fuel_consumed_l DESC;
```
### Результат
```
QUERY PLAN                                                                                                                          |
------------------------------------------------------------------------------------------------------------------------------------+
Sort  (cost=2029.00..2049.96 rows=8384 width=546) (actual time=9.689..10.268 rows=8384 loops=1)                                     |
  Sort Key: p.fuel_consumed_l DESC                                                                                                  |
  Sort Method: quicksort  Memory: 933kB                                                                                             |
  ->  Hash Join  (cost=23.15..302.64 rows=8384 width=546) (actual time=0.040..5.132 rows=8384 loops=1)                              |
        Hash Cond: (p.operator_id = o.operator_id)                                                                                  |
        ->  Hash Join  (cost=11.57..267.72 rows=8384 width=332) (actual time=0.019..3.658 rows=8384 loops=1)                        |
              Hash Cond: (p.equipment_id = e.equipment_id)                                                                          |
              ->  Seq Scan on fact_production p  (cost=0.00..232.80 rows=8384 width=18) (actual time=0.006..2.131 rows=8384 loops=1)|
                    Filter: (fuel_consumed_l > '80'::numeric)                                                                       |
              ->  Hash  (cost=10.70..10.70 rows=70 width=322) (actual time=0.009..0.010 rows=18 loops=1)                            |
                    Buckets: 1024  Batches: 1  Memory Usage: 9kB                                                                    |
                    ->  Seq Scan on dim_equipment e  (cost=0.00..10.70 rows=70 width=322) (actual time=0.003..0.006 rows=18 loops=1)|
        ->  Hash  (cost=10.70..10.70 rows=70 width=222) (actual time=0.016..0.017 rows=10 loops=1)                                  |
              Buckets: 1024  Batches: 1  Memory Usage: 9kB                                                                          |
              ->  Seq Scan on dim_operator o  (cost=0.00..10.70 rows=70 width=222) (actual time=0.009..0.012 rows=10 loops=1)       |
Planning Time: 0.502 ms                                                                                                             |
Execution Time: 10.715 ms                                                                                                           |

total_rows|matching_rows|selectivity_pct|
----------+-------------+---------------+
      8384|         8384|         100.00|

QUERY PLAN                                                                                                                          |
------------------------------------------------------------------------------------------------------------------------------------+
Sort  (cost=2212.87..2233.83 rows=8384 width=546) (actual time=8.948..9.398 rows=8384 loops=1)                                      |
  Sort Key: p.fuel_consumed_l DESC                                                                                                  |
  Sort Method: quicksort  Memory: 933kB                                                                                             |
  ->  Hash Join  (cost=23.15..486.51 rows=8384 width=546) (actual time=0.038..4.756 rows=8384 loops=1)                              |
        Hash Cond: (p.operator_id = o.operator_id)                                                                                  |
        ->  Hash Join  (cost=11.57..359.66 rows=8384 width=332) (actual time=0.018..3.344 rows=8384 loops=1)                        |
              Hash Cond: (p.equipment_id = e.equipment_id)                                                                          |
              ->  Seq Scan on fact_production p  (cost=0.00..232.80 rows=8384 width=18) (actual time=0.004..1.863 rows=8384 loops=1)|
                    Filter: (fuel_consumed_l > '80'::numeric)                                                                       |
              ->  Hash  (cost=10.70..10.70 rows=70 width=322) (actual time=0.009..0.011 rows=18 loops=1)                            |
                    Buckets: 1024  Batches: 1  Memory Usage: 9kB                                                                    |
                    ->  Seq Scan on dim_equipment e  (cost=0.00..10.70 rows=70 width=322) (actual time=0.004..0.006 rows=18 loops=1)|
        ->  Hash  (cost=10.70..10.70 rows=70 width=222) (actual time=0.014..0.015 rows=10 loops=1)                                  |
              Buckets: 1024  Batches: 1  Memory Usage: 9kB                                                                          |
              ->  Seq Scan on dim_operator o  (cost=0.00..10.70 rows=70 width=222) (actual time=0.008..0.010 rows=10 loops=1)       |
Planning Time: 0.472 ms                                                                                                             |
Execution Time: 9.798 ms                                                                                                            |
```
## Задача 4
### Текст задачи
Тема модуля: 7.5 -- B-tree индекс (частичные индексы)

Бизнес-задача: Система мониторинга MES должна мгновенно показывать аварийные показания датчиков. Аварийные показания (is_alarm = TRUE) составляют менее 2% от всех данных телеметрии. Полный индекс будет неоправданно большим.

Требования:

Зафиксируйте план для запроса:
EXPLAIN ANALYZE
SELECT t.telemetry_id, t.date_id, t.equipment_id,
       t.sensor_id, t.sensor_value
FROM fact_equipment_telemetry t
WHERE t.date_id = 20240315
  AND t.is_alarm = TRUE;
Создайте частичный индекс (partial index), оптимальный для этого запроса.

Создайте полный индекс на те же столбцы (без WHERE) для сравнения.

Сравните размеры частичного и полного индексов:

SELECT indexrelname,
       pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_stat_user_indexes
WHERE indexrelname IN ('idx_telemetry_alarm_partial', 'idx_telemetry_alarm_full')
ORDER BY pg_relation_size(indexrelid);
Повторите запрос из п.1 и убедитесь, что используется частичный индекс.
### Решение
```
EXPLAIN ANALYZE
SELECT t.telemetry_id, t.date_id, t.equipment_id,
       t.sensor_id, t.sensor_value
FROM "Pech".fact_equipment_telemetry t
WHERE t.date_id = 20240315
  AND t.is_alarm = TRUE;

CREATE INDEX telemetry_part_index
ON "Pech".fact_equipment_telemetry(date_id)
WHERE is_alarm = TRUE;

CREATE INDEX telemetry_full_index
ON "Pech".fact_equipment_telemetry(date_id, is_alarm);

SELECT indexrelname,
       pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_stat_user_indexes
WHERE indexrelname IN ('telemetry_part_index', 'telemetry_full_index')
ORDER BY pg_relation_size(indexrelid);

EXPLAIN ANALYZE
SELECT t.telemetry_id, t.date_id, t.equipment_id,
       t.sensor_id, t.sensor_value
FROM "Pech".fact_equipment_telemetry t
WHERE t.date_id = 20240315
  AND t.is_alarm = TRUE;
```
### Результат
```
QUERY PLAN                                                                                                           |
---------------------------------------------------------------------------------------------------------------------+
Seq Scan on fact_equipment_telemetry t  (cost=0.00..412.80 rows=1 width=26) (actual time=1.424..1.424 rows=0 loops=1)|
  Filter: (is_alarm AND (date_id = 20240315))                                                                        |
  Rows Removed by Filter: 18864                                                                                      |
Planning Time: 0.319 ms                                                                                              |
Execution Time: 1.455 ms                                                                                             |


indexrelname        |size  |
--------------------+------+
telemetry_part_index|16 kB |
telemetry_full_index|152 kB|

QUERY PLAN                                                                                                                                      |
------------------------------------------------------------------------------------------------------------------------------------------------+
Index Scan using telemetry_part_index on fact_equipment_telemetry t  (cost=0.14..2.16 rows=1 width=26) (actual time=0.018..0.019 rows=0 loops=1)|
  Index Cond: (date_id = 20240315)                                                                                                              |
Planning Time: 0.318 ms                                                                                                                         |
Execution Time: 0.045 ms                                                                                                                        |
```
## Задача 5
### Текст задачи
Тема модуля: 7.5 -- B-tree индекс (композитные индексы, правило левого префикса)

Бизнес-задача: Начальник участка ежедневно запрашивает данные о добыче конкретного оборудования за определенный период. Запрос фильтрует по equipment_id (равенство) и date_id (диапазон).

Требования:

Зафиксируйте план для запроса:
EXPLAIN ANALYZE
SELECT date_id, tons_mined, tons_transported,
       trips_count, operating_hours
FROM fact_production
WHERE equipment_id = 5
  AND date_id BETWEEN 20240301 AND 20240331;
Создайте композитный индекс (equipment_id, date_id):
CREATE INDEX idx_prod_equip_date
ON fact_production(equipment_id, date_id);
Создайте композитный индекс с обратным порядком (date_id, equipment_id):
CREATE INDEX idx_prod_date_equip
ON fact_production(date_id, equipment_id);
Выполните запрос из п.1 и определите, какой индекс PostgreSQL выбирает.

Проверьте, будет ли индекс (equipment_id, date_id) использован для запроса, фильтрующего только по date_id:

EXPLAIN ANALYZE
SELECT * FROM fact_production
WHERE date_id = 20240315;
Объясните правило левого префикса и удалите менее эффективный индекс.
### Решение
```
EXPLAIN ANALYZE
SELECT date_id, tons_mined, tons_transported,
       trips_count, operating_hours
FROM "Pech".fact_production
WHERE equipment_id = 5
  AND date_id BETWEEN 20240301 AND 20240331;

CREATE INDEX idx_prod_equip_date
ON "Pech".fact_production(equipment_id, date_id);

CREATE INDEX idx_prod_date_equip
ON "Pech".fact_production(date_id, equipment_id);

EXPLAIN ANALYZE
SELECT date_id, tons_mined, tons_transported,
       trips_count, operating_hours
FROM "Pech".fact_production
WHERE equipment_id = 5
  AND date_id BETWEEN 20240301 AND 20240331;

EXPLAIN ANALYZE
SELECT * FROM fact_production
WHERE date_id = 20240315;
```
### Результат
```
QUERY PLAN                                                                                                |
----------------------------------------------------------------------------------------------------------+
Seq Scan on fact_production  (cost=0.00..274.72 rows=1 width=26) (actual time=0.678..0.679 rows=0 loops=1)|
  Filter: ((date_id >= 20240301) AND (date_id <= 20240331) AND (equipment_id = 5))                        |
  Rows Removed by Filter: 8384                                                                            |
Planning Time: 0.226 ms                                                                                   |
Execution Time: 0.709 ms                                                                                  |


QUERY PLAN                                                                                                                          |
------------------------------------------------------------------------------------------------------------------------------------+
Index Scan using idx_prod_equip_date on fact_production  (cost=0.29..2.31 rows=1 width=26) (actual time=0.036..0.036 rows=0 loops=1)|
  Index Cond: ((equipment_id = 5) AND (date_id >= 20240301) AND (date_id <= 20240331))                                              |
Planning Time: 0.425 ms                                                                                                             |
Execution Time: 0.071 ms                                                                                                            |

QUERY PLAN                                                                                                                            |
--------------------------------------------------------------------------------------------------------------------------------------+
Index Scan using idx_prod_date_equip on fact_production  (cost=0.29..8.22 rows=14 width=82) (actual time=0.063..0.067 rows=14 loops=1)|
  Index Cond: (date_id = 20240315)                                                                                                    |
Planning Time: 0.248 ms                                                                                                               |
Execution Time: 0.098 ms                                                                                                              |
```
## Задача 6
### Текст задачи
Бизнес-задача: Кадровая служба ищет операторов по фамилии. Пользователи вводят фамилии в произвольном регистре (например, «петров», «ПЕТРОВ», «Петров»). Поиск должен быть нечувствителен к регистру.

Требования:

Выполните запрос и зафиксируйте план:
EXPLAIN ANALYZE
SELECT operator_id, last_name, first_name,
       middle_name, position, qualification
FROM dim_operator
WHERE LOWER(last_name) = 'петров';
Создайте индекс по выражению LOWER(last_name).

Повторите запрос и убедитесь, что индекс используется.

Проверьте: будет ли индекс использован для запроса без LOWER?

EXPLAIN ANALYZE
SELECT operator_id, last_name, first_name
FROM dim_operator
WHERE last_name = 'Петров';
Проверьте: будет ли индекс использован для запроса с UPPER?
EXPLAIN ANALYZE
SELECT operator_id, last_name, first_name
FROM dim_operator
WHERE UPPER(last_name) = 'ПЕТРОВ';
Подсказка: создание индекса
CREATE INDEX idx_operator_lower_lastname
ON dim_operator (LOWER(last_name));
Подсказка: ответы на вопросы п.4 и п.5
Ожидаемый результат: Индекс по выражению используется строго при совпадении выражения в запросе и в определении индекса. Запросы без LOWER или с UPPER его не задействуют.
### Решение
```
EXPLAIN ANALYZE
SELECT operator_id, last_name, first_name,
       middle_name, position, qualification
FROM "Pech".dim_operator
WHERE LOWER(last_name) = 'петров';

CREATE INDEX idx_operator_lower_lastname
ON "Pech".dim_operator (LOWER(last_name));

EXPLAIN ANALYZE
SELECT operator_id, last_name, first_name,
       middle_name, position, qualification
FROM "Pech".dim_operator
WHERE LOWER(last_name) = 'петров';

EXPLAIN ANALYZE
SELECT operator_id, last_name, first_name
FROM "Pech".dim_operator
WHERE last_name = 'Петров';

EXPLAIN ANALYZE
SELECT operator_id, last_name, first_name
FROM dim_operator
WHERE UPPER(last_name) = 'ПЕТРОВ';
```
### Результат
```
QUERY PLAN                                                                                            |
------------------------------------------------------------------------------------------------------+
Seq Scan on dim_operator  (cost=0.00..1.15 rows=1 width=994) (actual time=0.020..0.027 rows=1 loops=1)|
  Filter: (lower((last_name)::text) = 'петров'::text)                                                 |
  Rows Removed by Filter: 9                                                                           |
Planning Time: 0.147 ms                                                                               |
Execution Time: 0.053 ms                                                                              |

QUERY PLAN                                                                                            |
------------------------------------------------------------------------------------------------------+
Seq Scan on dim_operator  (cost=0.00..1.15 rows=1 width=994) (actual time=0.018..0.025 rows=1 loops=1)|
  Filter: (lower((last_name)::text) = 'петров'::text)                                                 |
  Rows Removed by Filter: 9                                                                           |
Planning Time: 0.264 ms                                                                               |
Execution Time: 0.052 ms                                                                              |

QUERY PLAN                                                                                            |
------------------------------------------------------------------------------------------------------+
Seq Scan on dim_operator  (cost=0.00..1.12 rows=1 width=440) (actual time=0.013..0.014 rows=1 loops=1)|
  Filter: ((last_name)::text = 'Петров'::text)                                                        |
  Rows Removed by Filter: 9                                                                           |
Planning Time: 0.123 ms                                                                               |
Execution Time: 0.044 ms                                                                              |

QUERY PLAN                                                                                            |
------------------------------------------------------------------------------------------------------+
Seq Scan on dim_operator  (cost=0.00..1.15 rows=1 width=440) (actual time=0.018..0.026 rows=1 loops=1)|
  Filter: (upper((last_name)::text) = 'ПЕТРОВ'::text)                                                 |
  Rows Removed by Filter: 9                                                                           |
Planning Time: 0.066 ms                                                                               |
Execution Time: 0.045 ms                                                                              |
```
## Задача 7
### Текст задачи
Тема модуля: 7.5 -- B-tree индекс (покрывающие индексы, INCLUDE)

Бизнес-задача: На дашборде MES-системы отображается сводка добычи за дату: дата, оборудование, тоннаж. Этот запрос выполняется каждые 30 секунд и должен работать максимально быстро. Цель -- добиться Index Only Scan, когда данные читаются только из индекса, без обращения к таблице.

Требования:

Зафиксируйте план для запроса:
EXPLAIN ANALYZE
SELECT date_id, equipment_id, tons_mined
FROM fact_production
WHERE date_id = 20240315;
Создайте покрывающий индекс (с INCLUDE), чтобы запрос выполнялся через Index Only Scan:
CREATE INDEX idx_prod_date_cover
ON fact_production(date_id)
INCLUDE (equipment_id, tons_mined);
Выполните VACUUM fact_production; (для обновления карты видимости -- Visibility Map).

Повторите запрос и убедитесь в Index Only Scan.

Добавьте в SELECT столбец fuel_consumed_l и проверьте -- сохранится ли Index Only Scan?

EXPLAIN ANALYZE
SELECT date_id, equipment_id, tons_mined, fuel_consumed_l
FROM fact_production
WHERE date_id = 20240315;
Создайте расширенный покрывающий индекс и проверьте снова.
### Решение
```
EXPLAIN ANALYZE
SELECT date_id, equipment_id, tons_mined
FROM "Pech".fact_production
WHERE date_id = 20240315;

CREATE INDEX idx_prod_date_cover
ON "Pech".fact_production(date_id)
INCLUDE (equipment_id, tons_mined);

VACUUM "Pech".fact_production;

EXPLAIN ANALYZE
SELECT date_id, equipment_id, tons_mined
FROM "Pech".fact_production
WHERE date_id = 20240315;

EXPLAIN ANALYZE
SELECT date_id, equipment_id, tons_mined, fuel_consumed_l
FROM fact_production
WHERE date_id = 20240315;

CREATE INDEX idx_prod_date_cover_dop
ON "Pech".fact_production(date_id)
INCLUDE (equipment_id, tons_mined, fuel_consumed_l);

EXPLAIN ANALYZE
SELECT date_id, equipment_id, tons_mined, fuel_consumed_l
FROM fact_production
WHERE date_id = 20240315;

```
### Результат
```
QUERY PLAN                                                                                                                            |
--------------------------------------------------------------------------------------------------------------------------------------+
Index Scan using idx_prod_date_equip on fact_production  (cost=0.29..8.22 rows=14 width=14) (actual time=0.012..0.017 rows=14 loops=1)|
  Index Cond: (date_id = 20240315)                                                                                                    |
Planning Time: 0.110 ms                                                                                                               |
Execution Time: 0.042 ms                                                                                                              |


QUERY PLAN                                                                                                                                 |
-------------------------------------------------------------------------------------------------------------------------------------------+
Index Only Scan using idx_prod_date_cover on fact_production  (cost=0.29..1.53 rows=14 width=14) (actual time=0.084..0.088 rows=14 loops=1)|
  Index Cond: (date_id = 20240315)                                                                                                         |
  Heap Fetches: 0                                                                                                                          |
Planning Time: 0.157 ms                                                                                                                    |
Execution Time: 0.118 ms                                                                                                                   |

QUERY PLAN                                                                                                                            |
--------------------------------------------------------------------------------------------------------------------------------------+
Index Scan using idx_prod_date_cover on fact_production  (cost=0.29..2.53 rows=14 width=20) (actual time=0.014..0.018 rows=14 loops=1)|
  Index Cond: (date_id = 20240315)                                                                                                    |
Planning Time: 0.146 ms                                                                                                               |
Execution Time: 0.055 ms                                                                                                              |

QUERY PLAN                                                                                                                                     |
-----------------------------------------------------------------------------------------------------------------------------------------------+
Index Only Scan using idx_prod_date_cover_dop on fact_production  (cost=0.29..1.53 rows=14 width=20) (actual time=0.045..0.047 rows=14 loops=1)|
  Index Cond: (date_id = 20240315)                                                                                                             |
  Heap Fetches: 0                                                                                                                              |
Planning Time: 0.311 ms                                                                                                                        |
Execution Time: 0.074 ms                                                                                                                       |
```
## Задача 8
### Текст задачи
Тема модуля: 7.4 -- Типы индексов в PostgreSQL

Бизнес-задача: Таблица телеметрии содержит большой объем данных. Данные вставляются последовательно по датам (физический порядок коррелирует с date_id). Нужен компактный индекс для фильтрации по диапазону дат, который занимает минимум места.

Требования:

Проверьте размер существующего B-tree индекса idx_fact_telemetry_date:
SELECT indexrelname,
       pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_stat_user_indexes
WHERE indexrelname = 'idx_fact_telemetry_date';
Создайте BRIN-индекс на столбец date_id:
CREATE INDEX idx_telemetry_date_brin
ON fact_equipment_telemetry USING brin (date_id)
WITH (pages_per_range = 128);
Сравните размеры B-tree и BRIN индексов:
SELECT indexrelname,
       pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_stat_user_indexes
WHERE indexrelname IN ('idx_fact_telemetry_date', 'idx_telemetry_date_brin')
ORDER BY pg_relation_size(indexrelid) DESC;
Сравните производительность B-tree и BRIN на запросе с диапазоном дат:
-- Тест с B-tree (отключаем Bitmap Scan для чистоты эксперимента)
SET enable_bitmapscan = off;
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM fact_equipment_telemetry
WHERE date_id BETWEEN 20240301 AND 20240331;
RESET enable_bitmapscan;

-- Тест с BRIN (отключаем Index Scan)
SET enable_indexscan = off;
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM fact_equipment_telemetry
WHERE date_id BETWEEN 20240301 AND 20240331;
RESET enable_indexscan;
Заполните таблицу сравнения:
Характеристика	        B-tree	BRIN
Размер индекса	        152 kB	24 kB
Время выполнения (мс)	0.120   0.038
Buffers прочитано	    29   	5
Тип сканирования	    Index Scan	Bitmap Heap Scan
### Решение
```
SELECT indexrelname,
       pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_stat_user_indexes
WHERE indexrelname = 'idx_fact_telemetry_date';

CREATE INDEX idx_telemetry_date_brin
ON "Pech".fact_equipment_telemetry USING brin (date_id)
WITH (pages_per_range = 128);

SELECT indexrelname,
       pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_stat_user_indexes
WHERE indexrelname IN ('idx_fact_telemetry_date', 'idx_telemetry_date_brin')
ORDER BY pg_relation_size(indexrelid) DESC;

SET enable_bitmapscan = off;
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM fact_equipment_telemetry
WHERE date_id BETWEEN 20240301 AND 20240331;
RESET enable_bitmapscan;

-- Тест с BRIN (отключаем Index Scan)
SET enable_bitmapscan = on;
SET enable_indexscan = off;
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM fact_equipment_telemetry
WHERE date_id BETWEEN 20240301 AND 20240331;
RESET enable_indexscan;
```
### Результат
```
indexrelname           |size  |
-----------------------+------+
idx_fact_telemetry_date|152 kB|

indexrelname           |size  |
-----------------------+------+
idx_fact_telemetry_date|152 kB|
idx_telemetry_date_brin|24 kB |

QUERY PLAN                                                                                                                                    |
----------------------------------------------------------------------------------------------------------------------------------------------+
Index Scan using telemetry_full_index on fact_equipment_telemetry  (cost=0.29..2.31 rows=1 width=46) (actual time=0.083..0.084 rows=0 loops=1)|
  Index Cond: ((date_id >= 20240301) AND (date_id <= 20240331))                                                                               |
  Buffers: shared read=2                                                                                                                      |
  I/O Timings: shared read=0.051                                                                                                              |
Planning:                                                                                                                                     |
  Buffers: shared hit=29                                                                                                                      |
Planning Time: 0.190 ms                                                                                                                       |
Execution Time: 0.120 ms                                                                                                                      |

QUERY PLAN                                                                                                                 |
---------------------------------------------------------------------------------------------------------------------------+
Bitmap Heap Scan on fact_equipment_telemetry  (cost=1.30..2.31 rows=1 width=46) (actual time=0.008..0.008 rows=0 loops=1)  |
  Recheck Cond: ((date_id >= 20240301) AND (date_id <= 20240331))                                                          |
  Buffers: shared hit=2                                                                                                    |
  ->  Bitmap Index Scan on telemetry_full_index  (cost=0.00..1.30 rows=1 width=0) (actual time=0.006..0.007 rows=0 loops=1)|
        Index Cond: ((date_id >= 20240301) AND (date_id <= 20240331))                                                      |
        Buffers: shared hit=2                                                                                              |
Planning:                                                                                                                  |
  Buffers: shared hit=5                                                                                                    |
Planning Time: 0.124 ms                                                                                                    |
Execution Time: 0.038 ms                                                                                                   |
```
## Задача 9
### Текст задачи
Тема модуля: 7.6 -- Влияние индексов на INSERT/UPDATE/DELETE

Бизнес-задача: ETL-процесс загружает данные о добыче каждую смену. Администратор хочет понять, как количество индексов влияет на скорость загрузки данных, чтобы оптимизировать окно ETL.

Требования:

Подсчитайте текущее количество индексов на таблице fact_production:
SELECT COUNT(*) AS index_count
FROM pg_indexes
WHERE tablename = 'fact_production';
Замерьте время INSERT с текущими индексами:
EXPLAIN ANALYZE
INSERT INTO fact_production
    (date_id, shift_id, mine_id, shaft_id, equipment_id,
     operator_id, location_id, ore_grade_id,
     tons_mined, tons_transported, trips_count,
     distance_km, fuel_consumed_l, operating_hours)
VALUES
    (20240401, 1, 1, 1, 1, 1, 1, 1,
     120.50, 115.00, 8, 12.5, 45.2, 7.5);
Создайте 3 дополнительных индекса на fact_production:
CREATE INDEX idx_test_1 ON fact_production(tons_mined);
CREATE INDEX idx_test_2 ON fact_production(fuel_consumed_l, operating_hours);
CREATE INDEX idx_test_3 ON fact_production(date_id, shift_id, mine_id);
Подсчитайте новое количество индексов и повторите INSERT:
SELECT COUNT(*) AS index_count
FROM pg_indexes
WHERE tablename = 'fact_production';

EXPLAIN ANALYZE
INSERT INTO fact_production
    (date_id, shift_id, mine_id, shaft_id, equipment_id,
     operator_id, location_id, ore_grade_id,
     tons_mined, tons_transported, trips_count,
     distance_km, fuel_consumed_l, operating_hours)
VALUES
    (20240401, 1, 1, 1, 1, 1, 1, 1,
     130.00, 125.00, 9, 14.0, 50.1, 8.0);
Сравните время выполнения INSERT и заполните таблицу:
Метрика	До (N индексов)	После (N+3 индекса)
Кол-во индексов	5	8
Время INSERT (мс)	0.412	0.418

Ответьте на вопрос: как бы вы организовали массовую загрузку 10 000+ строк для минимизации времени?
### Решение
```
SELECT COUNT(*) AS index_count
FROM pg_indexes
WHERE tablename = 'fact_production' and schemaname='Pech';

EXPLAIN ANALYZE
INSERT INTO "Pech".fact_production
    (date_id, shift_id, mine_id, shaft_id, equipment_id,
     operator_id, location_id, ore_grade_id,
     tons_mined, tons_transported, trips_count,
     distance_km, fuel_consumed_l, operating_hours)
VALUES
    (20240401, 1, 1, 1, 1, 1, 1, 1,
     120.50, 115.00, 8, 12.5, 45.2, 7.5);

CREATE INDEX idx_test_1 ON "Pech".fact_production(tons_mined);
CREATE INDEX idx_test_2 ON "Pech".fact_production(fuel_consumed_l, operating_hours);
CREATE INDEX idx_test_3 ON "Pech".fact_production(date_id, shift_id, mine_id);

SELECT COUNT(*) AS index_count
FROM pg_indexes
WHERE tablename = 'fact_production' and schemaname='Pech';

EXPLAIN ANALYZE
INSERT INTO "Pech".fact_production
    (date_id, shift_id, mine_id, shaft_id, equipment_id,
     operator_id, location_id, ore_grade_id,
     tons_mined, tons_transported, trips_count,
     distance_km, fuel_consumed_l, operating_hours)
VALUES
    (20240401, 1, 1, 1, 1, 1, 1, 1,
     130.00, 125.00, 9, 14.0, 50.1, 8.0);
```
### Результат
```
index_count|
-----------+
          5|

QUERY PLAN                                                                                           |
-----------------------------------------------------------------------------------------------------+
Insert on fact_production  (cost=0.00..0.01 rows=0 width=0) (actual time=0.379..0.379 rows=0 loops=1)|
  ->  Result  (cost=0.00..0.01 rows=1 width=126) (actual time=0.099..0.100 rows=1 loops=1)           |
Planning Time: 0.070 ms                                                                              |
Execution Time: 0.412 ms                                                                             |



index_count|
-----------+
          8|

QUERY PLAN                                                                                           |
-----------------------------------------------------------------------------------------------------+
Insert on fact_production  (cost=0.00..0.01 rows=0 width=0) (actual time=0.378..0.379 rows=0 loops=1)|
  ->  Result  (cost=0.00..0.01 rows=1 width=126) (actual time=0.008..0.009 rows=1 loops=1)           |
Planning Time: 0.057 ms                                                                              |
Execution Time: 0.418 ms                                                                             |
```
## Задача 10
### Текст задачи
Тема модуля: все темы модуля 7

Бизнес-задача: Вам поручено оптимизировать пять наиболее частых запросов аналитической системы «Руда+». Необходимо предложить стратегию индексирования -- не более 7 новых индексов на все 5 запросов. Каждый индекс должен быть обоснован.

Запросы:

Запрос 1. Суммарная добыча по шахте за месяц:

SELECT m.mine_name,
       SUM(p.tons_mined) AS total_tons,
       SUM(p.operating_hours) AS total_hours
FROM fact_production p
JOIN dim_mine m ON p.mine_id = m.mine_id
WHERE p.date_id BETWEEN 20240301 AND 20240331
GROUP BY m.mine_name;
Запрос 2. Средний показатель качества руды по сорту за квартал:

SELECT g.grade_name,
       AVG(q.fe_content) AS avg_fe,
       AVG(q.sio2_content) AS avg_sio2,
       COUNT(*) AS samples
FROM fact_ore_quality q
JOIN dim_ore_grade g ON q.ore_grade_id = g.ore_grade_id
WHERE q.date_id BETWEEN 20240101 AND 20240331
GROUP BY g.grade_name;
Запрос 3. Топ-5 оборудования по длительности внеплановых простоев:

SELECT e.equipment_name,
       SUM(dt.duration_min) AS total_downtime_min,
       COUNT(*) AS incidents
FROM fact_equipment_downtime dt
JOIN dim_equipment e ON dt.equipment_id = e.equipment_id
WHERE dt.is_planned = FALSE
  AND dt.date_id BETWEEN 20240301 AND 20240331
GROUP BY e.equipment_name
ORDER BY total_downtime_min DESC
LIMIT 5;
Запрос 4. Последние аварийные показания по оборудованию:

SELECT t.date_id, t.time_id, t.sensor_id,
       t.sensor_value, t.quality_flag
FROM fact_equipment_telemetry t
WHERE t.equipment_id = 5
  AND t.is_alarm = TRUE
ORDER BY t.date_id DESC, t.time_id DESC
LIMIT 20;
Запрос 5. Добыча конкретного оператора за неделю:

SELECT p.date_id, e.equipment_name,
       p.tons_mined, p.trips_count, p.operating_hours
FROM fact_production p
JOIN dim_equipment e ON p.equipment_id = e.equipment_id
WHERE p.operator_id = 3
  AND p.date_id BETWEEN 20240311 AND 20240317
ORDER BY p.date_id;
Требования:

Для каждого запроса зафиксируйте текущий план выполнения (EXPLAIN ANALYZE).

Предложите индексы (не более 7 новых индексов на все 5 запросов). Для каждого индекса укажите:

Какой запрос (или запросы) он ускоряет
Тип индекса (B-tree, частичный, покрывающий и т.д.)
Обоснование выбора столбцов и их порядка
Создайте предложенные индексы.

Повторите запросы и зафиксируйте улучшение.
### Решение
```
EXPLAIN ANALYZE
SELECT m.mine_name,
       SUM(p.tons_mined) AS total_tons,
       SUM(p.operating_hours) AS total_hours
FROM "Pech".fact_production p
JOIN "Pech".dim_mine m ON p.mine_id = m.mine_id
WHERE p.date_id BETWEEN 20240301 AND 20240331
GROUP BY m.mine_name;

EXPLAIN ANALYZE
SELECT g.grade_name,
       AVG(q.fe_content) AS avg_fe,
       AVG(q.sio2_content) AS avg_sio2,
       COUNT(*) AS samples
FROM "Pech".fact_ore_quality q
JOIN "Pech".dim_ore_grade g ON q.ore_grade_id = g.ore_grade_id
WHERE q.date_id BETWEEN 20240101 AND 20240331
GROUP BY g.grade_name;

EXPLAIN ANALYZE
SELECT e.equipment_name,
       SUM(dt.duration_min) AS total_downtime_min,
       COUNT(*) AS incidents
FROM "Pech".fact_equipment_downtime dt
JOIN "Pech".dim_equipment e ON dt.equipment_id = e.equipment_id
WHERE dt.is_planned = FALSE
  AND dt.date_id BETWEEN 20240301 AND 20240331
GROUP BY e.equipment_name
ORDER BY total_downtime_min DESC
LIMIT 5;

EXPLAIN ANALYZE
SELECT t.date_id, t.time_id, t.sensor_id,
       t.sensor_value, t.quality_flag
FROM "Pech".fact_equipment_telemetry t
WHERE t.equipment_id = 5
  AND t.is_alarm = TRUE
ORDER BY t.date_id DESC, t.time_id DESC
LIMIT 20;

EXPLAIN ANALYZE
SELECT p.date_id, e.equipment_name,
       p.tons_mined, p.trips_count, p.operating_hours
FROM "Pech".fact_production p
JOIN "Pech".dim_equipment e ON p.equipment_id = e.equipment_id
WHERE p.operator_id = 3
  AND p.date_id BETWEEN 20240311 AND 20240317
ORDER BY p.date_id;

CREATE INDEX idx_fact_production_date_mine_operator 
ON "Pech".fact_production(date_id, mine_id, operator_id) 
INCLUDE (tons_mined, operating_hours, equipment_id);

CREATE INDEX idx_fact_ore_quality_date_grade 
ON "Pech".fact_ore_quality(date_id, ore_grade_id) 
INCLUDE (fe_content, sio2_content);

CREATE INDEX idx_downtime_unplanned 
ON "Pech".fact_equipment_downtime(date_id, equipment_id) 
INCLUDE (duration_min) 
WHERE is_planned = FALSE;

CREATE INDEX idx_fact_telemetry_equipment_alarm 
ON "Pech".fact_equipment_telemetry(equipment_id, is_alarm, date_id DESC, time_id DESC);

CREATE INDEX idx_dim_equipment_id_name 
ON "Pech".dim_equipment(equipment_id) 
INCLUDE (equipment_name);

CREATE INDEX idx_dim_mine_name 
ON "Pech".dim_mine(mine_name);

CREATE INDEX idx_dim_ore_grade_name 
ON "Pech".dim_ore_grade(grade_name);
```
### Результат
```
QUERY PLAN                                                                                                                                             |
-------------------------------------------------------------------------------------------------------------------------------------------------------+
HashAggregate  (cost=41.55..42.75 rows=80 width=382) (actual time=0.438..0.441 rows=2 loops=1)                                                         |
  Group Key: m.mine_name                                                                                                                               |
  Batches: 1  Memory Usage: 24kB                                                                                                                       |
  ->  Hash Join  (cost=12.09..38.02 rows=472 width=330) (actual time=0.032..0.258 rows=472 loops=1)                                                    |
        Hash Cond: (p.mine_id = m.mine_id)                                                                                                             |
        ->  Index Scan using idx_prod_date_cover on fact_production p  (cost=0.29..19.72 rows=472 width=16) (actual time=0.015..0.110 rows=472 loops=1)|
              Index Cond: ((date_id >= 20240301) AND (date_id <= 20240331))                                                                            |
        ->  Hash  (cost=10.80..10.80 rows=80 width=322) (actual time=0.011..0.011 rows=2 loops=1)                                                      |
              Buckets: 1024  Batches: 1  Memory Usage: 9kB                                                                                             |
              ->  Seq Scan on dim_mine m  (cost=0.00..10.80 rows=80 width=322) (actual time=0.007..0.008 rows=2 loops=1)                               |
Planning Time: 0.240 ms                                                                                                                                |
Execution Time: 0.497 ms                                                                                                                               |

QUERY PLAN                                                                                                                    |
------------------------------------------------------------------------------------------------------------------------------+
HashAggregate  (cost=257.46..260.46 rows=200 width=190) (actual time=1.034..1.038 rows=3 loops=1)                             |
  Group Key: g.grade_name                                                                                                     |
  Batches: 1  Memory Usage: 40kB                                                                                              |
  ->  Hash Join  (cost=17.43..242.59 rows=1487 width=130) (actual time=0.015..0.778 rows=901 loops=1)                         |
        Hash Cond: (q.ore_grade_id = g.ore_grade_id)                                                                          |
        ->  Seq Scan on fact_ore_quality q  (cost=0.00..170.88 rows=901 width=16) (actual time=0.005..0.537 rows=901 loops=1) |
              Filter: ((date_id >= 20240101) AND (date_id <= 20240331))                                                       |
              Rows Removed by Filter: 4424                                                                                    |
        ->  Hash  (cost=13.30..13.30 rows=330 width=122) (actual time=0.007..0.007 rows=4 loops=1)                            |
              Buckets: 1024  Batches: 1  Memory Usage: 9kB                                                                    |
              ->  Seq Scan on dim_ore_grade g  (cost=0.00..13.30 rows=330 width=122) (actual time=0.003..0.005 rows=4 loops=1)|
Planning Time: 0.109 ms                                                                                                       |
Execution Time: 1.077 ms                                                                                                      |


QUERY PLAN                                                                                                                                         |
---------------------------------------------------------------------------------------------------------------------------------------------------+
Limit  (cost=65.93..65.94 rows=5 width=358) (actual time=0.247..0.249 rows=4 loops=1)                                                              |
  ->  Sort  (cost=65.93..65.97 rows=18 width=358) (actual time=0.247..0.248 rows=4 loops=1)                                                        |
        Sort Key: (sum(dt.duration_min)) DESC                                                                                                      |
        Sort Method: quicksort  Memory: 25kB                                                                                                       |
        ->  GroupAggregate  (cost=65.22..65.63 rows=18 width=358) (actual time=0.236..0.242 rows=4 loops=1)                                        |
              Group Key: e.equipment_name                                                                                                          |
              ->  Sort  (cost=65.22..65.27 rows=18 width=323) (actual time=0.230..0.231 rows=15 loops=1)                                           |
                    Sort Key: e.equipment_name                                                                                                     |
                    Sort Method: quicksort  Memory: 25kB                                                                                           |
                    ->  Hash Join  (cost=11.57..64.85 rows=18 width=323) (actual time=0.049..0.197 rows=15 loops=1)                                |
                          Hash Cond: (dt.equipment_id = e.equipment_id)                                                                            |
                          ->  Seq Scan on fact_equipment_downtime dt  (cost=0.00..53.02 rows=18 width=9) (actual time=0.034..0.178 rows=15 loops=1)|
                                Filter: ((NOT is_planned) AND (date_id >= 20240301) AND (date_id <= 20240331))                                     |
                                Rows Removed by Filter: 1720                                                                                       |
                          ->  Hash  (cost=10.70..10.70 rows=70 width=322) (actual time=0.011..0.011 rows=18 loops=1)                               |
                                Buckets: 1024  Batches: 1  Memory Usage: 9kB                                                                       |
                                ->  Seq Scan on dim_equipment e  (cost=0.00..10.70 rows=70 width=322) (actual time=0.004..0.006 rows=18 loops=1)   |
Planning Time: 0.124 ms                                                                                                                            |
Execution Time: 0.280 ms                                                                                                                           |


QUERY PLAN                                                                                                                                                           |
---------------------------------------------------------------------------------------------------------------------------------------------------------------------+
Limit  (cost=7.88..7.93 rows=2 width=21) (actual time=0.111..0.111 rows=0 loops=1)                                                                                   |
  ->  Incremental Sort  (cost=7.88..7.93 rows=2 width=21) (actual time=0.110..0.111 rows=0 loops=1)                                                                  |
        Sort Key: date_id DESC, time_id DESC                                                                                                                         |
        Presorted Key: date_id                                                                                                                                       |
        Full-sort Groups: 1  Sort Method: quicksort  Average Memory: 25kB  Peak Memory: 25kB                                                                         |
        ->  Index Scan Backward using telemetry_part_index on fact_equipment_telemetry t  (cost=0.14..7.87 rows=1 width=21) (actual time=0.107..0.107 rows=0 loops=1)|
              Filter: (equipment_id = 5)                                                                                                                             |
              Rows Removed by Filter: 213                                                                                                                            |
Planning Time: 0.090 ms                                                                                                                                              |
Execution Time: 0.127 ms                                                                                                                                             |

QUERY PLAN                                                                                                                                              |
--------------------------------------------------------------------------------------------------------------------------------------------------------+
Sort  (cost=17.66..17.70 rows=13 width=338) (actual time=0.068..0.069 rows=13 loops=1)                                                                  |
  Sort Key: p.date_id                                                                                                                                   |
  Sort Method: quicksort  Memory: 25kB                                                                                                                  |
  ->  Hash Join  (cost=11.86..17.42 rows=13 width=338) (actual time=0.042..0.062 rows=13 loops=1)                                                       |
        Hash Cond: (p.equipment_id = e.equipment_id)                                                                                                    |
        ->  Index Scan using idx_prod_date_cover_dop on fact_production p  (cost=0.29..5.67 rows=13 width=24) (actual time=0.027..0.044 rows=13 loops=1)|
              Index Cond: ((date_id >= 20240311) AND (date_id <= 20240317))                                                                             |
              Filter: (operator_id = 3)                                                                                                                 |
              Rows Removed by Filter: 93                                                                                                                |
        ->  Hash  (cost=10.70..10.70 rows=70 width=322) (actual time=0.009..0.010 rows=18 loops=1)                                                      |
              Buckets: 1024  Batches: 1  Memory Usage: 9kB                                                                                              |
              ->  Seq Scan on dim_equipment e  (cost=0.00..10.70 rows=70 width=322) (actual time=0.003..0.005 rows=18 loops=1)                          |
Planning Time: 0.158 ms                                                                                                                                 |
Execution Time: 0.093 ms                                                                                                                                |



QUERY PLAN                                                                                                                                                                     |
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
HashAggregate  (cost=24.80..24.83 rows=2 width=382) (actual time=0.377..0.379 rows=2 loops=1)                                                                                  |
  Group Key: m.mine_name                                                                                                                                                       |
  Batches: 1  Memory Usage: 24kB                                                                                                                                               |
  ->  Hash Join  (cost=1.33..21.26 rows=472 width=330) (actual time=0.063..0.236 rows=472 loops=1)                                                                             |
        Hash Cond: (p.mine_id = m.mine_id)                                                                                                                                     |
        ->  Index Only Scan using idx_fact_production_date_mine_operator on fact_production p  (cost=0.29..13.72 rows=472 width=16) (actual time=0.045..0.139 rows=472 loops=1)|
              Index Cond: ((date_id >= 20240301) AND (date_id <= 20240331))                                                                                                    |
              Heap Fetches: 0                                                                                                                                                  |
        ->  Hash  (cost=1.02..1.02 rows=2 width=322) (actual time=0.011..0.011 rows=2 loops=1)                                                                                 |
              Buckets: 1024  Batches: 1  Memory Usage: 9kB                                                                                                                     |
              ->  Seq Scan on dim_mine m  (cost=0.00..1.02 rows=2 width=322) (actual time=0.007..0.007 rows=2 loops=1)                                                         |
Planning Time: 0.464 ms                                                                                                                                                        |
Execution Time: 0.433 ms                                                                                                                                                       |

QUERY PLAN                                                                                                                                                               |
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
HashAggregate  (cost=45.79..45.85 rows=4 width=190) (actual time=0.668..0.671 rows=3 loops=1)                                                                            |
  Group Key: g.grade_name                                                                                                                                                |
  Batches: 1  Memory Usage: 24kB                                                                                                                                         |
  ->  Hash Join  (cost=1.37..36.78 rows=901 width=130) (actual time=0.055..0.376 rows=901 loops=1)                                                                       |
        Hash Cond: (q.ore_grade_id = g.ore_grade_id)                                                                                                                     |
        ->  Index Only Scan using idx_fact_ore_quality_date_grade on fact_ore_quality q  (cost=0.28..23.30 rows=901 width=16) (actual time=0.044..0.205 rows=901 loops=1)|
              Index Cond: ((date_id >= 20240101) AND (date_id <= 20240331))                                                                                              |
              Heap Fetches: 0                                                                                                                                            |
        ->  Hash  (cost=1.04..1.04 rows=4 width=122) (actual time=0.007..0.008 rows=4 loops=1)                                                                           |
              Buckets: 1024  Batches: 1  Memory Usage: 9kB                                                                                                               |
              ->  Seq Scan on dim_ore_grade g  (cost=0.00..1.04 rows=4 width=122) (actual time=0.004..0.005 rows=4 loops=1)                                              |
Planning Time: 0.265 ms                                                                                                                                                  |
Execution Time: 0.708 ms                                                                                                                                                 |

QUERY PLAN                                                                                                                                                                      |
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
Limit  (cost=3.94..3.96 rows=5 width=358) (actual time=0.139..0.142 rows=4 loops=1)                                                                                             |
  ->  Sort  (cost=3.94..3.99 rows=18 width=358) (actual time=0.138..0.140 rows=4 loops=1)                                                                                       |
        Sort Key: (sum(dt.duration_min)) DESC                                                                                                                                   |
        Sort Method: quicksort  Memory: 25kB                                                                                                                                    |
        ->  HashAggregate  (cost=3.42..3.64 rows=18 width=358) (actual time=0.126..0.129 rows=4 loops=1)                                                                        |
              Group Key: e.equipment_name                                                                                                                                       |
              Batches: 1  Memory Usage: 24kB                                                                                                                                    |
              ->  Hash Join  (cost=1.68..3.28 rows=18 width=323) (actual time=0.104..0.112 rows=15 loops=1)                                                                     |
                    Hash Cond: (dt.equipment_id = e.equipment_id)                                                                                                               |
                    ->  Index Only Scan using idx_downtime_unplanned on fact_equipment_downtime dt  (cost=0.27..1.63 rows=18 width=9) (actual time=0.055..0.058 rows=15 loops=1)|
                          Index Cond: ((date_id >= 20240301) AND (date_id <= 20240331))                                                                                         |
                          Heap Fetches: 0                                                                                                                                       |
                    ->  Hash  (cost=1.18..1.18 rows=18 width=322) (actual time=0.042..0.043 rows=18 loops=1)                                                                    |
                          Buckets: 1024  Batches: 1  Memory Usage: 9kB                                                                                                          |
                          ->  Seq Scan on dim_equipment e  (cost=0.00..1.18 rows=18 width=322) (actual time=0.006..0.010 rows=18 loops=1)                                       |
Planning Time: 0.373 ms                                                                                                                                                         |
Execution Time: 0.195 ms                                                                                                                                                        |

QUERY PLAN                                                                                                                                                          |
--------------------------------------------------------------------------------------------------------------------------------------------------------------------+
Limit  (cost=0.29..2.31 rows=1 width=21) (actual time=0.029..0.029 rows=0 loops=1)                                                                                  |
  ->  Index Scan using idx_fact_telemetry_equipment_alarm on fact_equipment_telemetry t  (cost=0.29..2.31 rows=1 width=21) (actual time=0.028..0.028 rows=0 loops=1)|
        Index Cond: ((equipment_id = 5) AND (is_alarm = true))                                                                                                      |
Planning Time: 0.187 ms                                                                                                                                             |
Execution Time: 0.045 ms                                                                                                                                            |

QUERY PLAN                                                                                                                                              |
--------------------------------------------------------------------------------------------------------------------------------------------------------+
Sort  (cost=7.49..7.53 rows=13 width=338) (actual time=0.054..0.056 rows=13 loops=1)                                                                    |
  Sort Key: p.date_id                                                                                                                                   |
  Sort Method: quicksort  Memory: 25kB                                                                                                                  |
  ->  Hash Join  (cost=1.69..7.25 rows=13 width=338) (actual time=0.028..0.048 rows=13 loops=1)                                                         |
        Hash Cond: (p.equipment_id = e.equipment_id)                                                                                                    |
        ->  Index Scan using idx_prod_date_cover_dop on fact_production p  (cost=0.29..5.67 rows=13 width=24) (actual time=0.014..0.031 rows=13 loops=1)|
              Index Cond: ((date_id >= 20240311) AND (date_id <= 20240317))                                                                             |
              Filter: (operator_id = 3)                                                                                                                 |
              Rows Removed by Filter: 93                                                                                                                |
        ->  Hash  (cost=1.18..1.18 rows=18 width=322) (actual time=0.010..0.010 rows=18 loops=1)                                                        |
              Buckets: 1024  Batches: 1  Memory Usage: 9kB                                                                                              |
              ->  Seq Scan on dim_equipment e  (cost=0.00..1.18 rows=18 width=322) (actual time=0.003..0.005 rows=18 loops=1)                           |
Planning Time: 0.199 ms                                                                                                                                 |
Execution Time: 0.079 ms                                                                                                                                |
```
