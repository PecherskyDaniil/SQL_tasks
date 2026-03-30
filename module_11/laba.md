## Задача 1
### Текст задачи
Бизнес-задача: Аналитику MES-системы нужен удобный источник для ежедневных отчётов по добыче.

Требования:

Создайте представление v_daily_production_summary, которое выводит:
Дата (full_date из dim_date)
Название шахты
Название смены
Количество записей
Суммарная добыча (тонн)
Суммарный расход топлива (л)
Среднее количество рейсов
Проверьте представление запросом: данные за март 2024, шахта «Северная»
Добавьте фильтрацию по количеству записей > 5
Подсказка: CREATE OR REPLACE VIEW v_daily_production_summary AS SELECT ...
### Решение
```
CREATE OR REPLACE VIEW v_daily_production_summary AS 
select dd.full_date,dm.mine_name,ds.shift_name, COUNT(*), SUM(fp.tons_mined) as tonnage,SUM(fp.fuel_consumed_l) as fuel_consumed, ROUND(AVG(fp.trips_count),2) as avg_trips
from "public".fact_production fp
join "public".dim_date dd on fp.date_id=dd.date_id
join "public".dim_mine dm on fp.mine_id=dm.mine_id
join "public".dim_shift ds on fp.shift_id=ds.shift_id
group by dd.full_date,dm.mine_name,ds.shift_name;


select * from v_daily_production_summary where full_date>='2024-03-01' and full_date<='2024-03-31' and count>=5 and mine_name='Шахта "Северная"';

```
### Результат
```
full_date |mine_name       |shift_name   |count|tonnage|fuel_consumed|avg_trips|
----------+----------------+-------------+-----+-------+-------------+---------+
2024-03-01|Шахта "Северная"|Дневная смена|    5| 559.71|       804.33|     6.80|
2024-03-01|Шахта "Северная"|Ночная смена |    5| 551.83|       766.19|     6.00|
2024-03-02|Шахта "Северная"|Дневная смена|    5| 384.64|       740.80|     6.60|
2024-03-02|Шахта "Северная"|Ночная смена |    5| 320.50|       748.19|     5.60|
2024-03-03|Шахта "Северная"|Дневная смена|    5| 329.79|       751.53|     6.60|
2024-03-04|Шахта "Северная"|Дневная смена|    5| 547.74|       767.83|     6.60|
2024-03-04|Шахта "Северная"|Ночная смена |    5| 564.57|       764.88|     5.60|
2024-03-05|Шахта "Северная"|Дневная смена|    5| 605.06|       741.30|     6.40|
2024-03-05|Шахта "Северная"|Ночная смена |    5| 519.67|       782.07|     6.40|
2024-03-06|Шахта "Северная"|Дневная смена|    5| 597.67|       802.96|     7.20|
2024-03-07|Шахта "Северная"|Дневная смена|    5| 511.90|       764.35|     6.40|
2024-03-07|Шахта "Северная"|Ночная смена |    5| 563.12|       801.03|     6.60|
2024-03-08|Шахта "Северная"|Дневная смена|    5| 619.42|       761.97|     6.60|
2024-03-08|Шахта "Северная"|Ночная смена |    5| 513.46|       776.43|     6.00|
2024-03-09|Шахта "Северная"|Ночная смена |    5| 303.30|       772.98|     6.20|
2024-03-10|Шахта "Северная"|Ночная смена |    5| 336.70|       737.07|     7.00|
2024-03-11|Шахта "Северная"|Дневная смена|    5| 542.16|       806.32|     6.40|
2024-03-11|Шахта "Северная"|Ночная смена |    5| 557.07|       801.30|     6.60|
2024-03-12|Шахта "Северная"|Дневная смена|    5| 551.50|       806.79|     6.40|
2024-03-12|Шахта "Северная"|Ночная смена |    5| 631.71|       797.70|     6.40|
2024-03-13|Шахта "Северная"|Дневная смена|    5| 560.02|       798.82|     7.00|
2024-03-13|Шахта "Северная"|Ночная смена |    5| 573.81|       768.07|     6.60|
2024-03-14|Шахта "Северная"|Дневная смена|    5| 579.45|       801.66|     5.60|
2024-03-15|Шахта "Северная"|Ночная смена |    5| 566.31|       828.50|     6.00|
2024-03-16|Шахта "Северная"|Дневная смена|    5| 335.11|       784.01|     5.40|
2024-03-16|Шахта "Северная"|Ночная смена |    5| 335.74|       756.55|     5.80|
2024-03-18|Шахта "Северная"|Дневная смена|    5| 543.04|       785.99|     6.60|
2024-03-19|Шахта "Северная"|Дневная смена|    5| 529.03|       798.20|     6.80|
2024-03-19|Шахта "Северная"|Ночная смена |    5| 552.07|       795.15|     6.80|
2024-03-20|Шахта "Северная"|Дневная смена|    5| 509.51|       773.21|     6.40|
2024-03-20|Шахта "Северная"|Ночная смена |    5| 535.36|       763.06|     6.60|
2024-03-21|Шахта "Северная"|Дневная смена|    5| 547.28|       773.91|     6.00|
2024-03-22|Шахта "Северная"|Дневная смена|    5| 634.08|       772.62|     6.80|
2024-03-22|Шахта "Северная"|Ночная смена |    5| 545.02|       798.47|     6.00|
2024-03-23|Шахта "Северная"|Дневная смена|    5| 338.47|       795.79|     5.40|
2024-03-24|Шахта "Северная"|Дневная смена|    5| 323.25|       780.95|     6.40|
2024-03-25|Шахта "Северная"|Дневная смена|    5| 547.71|       779.74|     6.40|
2024-03-25|Шахта "Северная"|Ночная смена |    5| 575.55|       846.29|     6.40|
2024-03-26|Шахта "Северная"|Дневная смена|    5| 550.96|       832.04|     6.80|
2024-03-26|Шахта "Северная"|Ночная смена |    5| 588.77|       725.13|     6.40|
2024-03-27|Шахта "Северная"|Дневная смена|    5| 624.76|       805.44|     7.60|
2024-03-27|Шахта "Северная"|Ночная смена |    5| 594.53|       753.70|     5.60|
2024-03-28|Шахта "Северная"|Дневная смена|    5| 545.33|       715.15|     6.00|
2024-03-28|Шахта "Северная"|Ночная смена |    5| 596.29|       777.77|     6.80|
2024-03-29|Шахта "Северная"|Дневная смена|    5| 614.79|       760.64|     5.80|
2024-03-30|Шахта "Северная"|Ночная смена |    5| 327.00|       763.69|     5.60|
2024-03-31|Шахта "Северная"|Дневная смена|    5| 324.09|       788.48|     6.00|
2024-03-31|Шахта "Северная"|Ночная смена |    5| 318.88|       737.47|     7.00|
```

## Задача 2
### Текст задачи
Требования:

Создайте представление v_unplanned_downtime на основе fact_equipment_downtime с условием WHERE is_planned = FALSE
Добавьте WITH CHECK OPTION
Выполните SELECT COUNT(*) из представления и из базовой таблицы — убедитесь, что представление содержит только подмножество данных
Объясните в комментарии: что произойдёт при попытке выполнить INSERT INTO v_unplanned_downtime (..., is_planned, ...) VALUES (..., TRUE, ...)?
### Решение
"Объясните в комментарии: что произойдёт при попытке выполнить INSERT INTO v_unplanned_downtime (..., is_planned, ...) VALUES (..., TRUE, ...)?"
Не получится добавить новую запись
```
CREATE OR REPLACE VIEW v_unplanned_downtime AS 
select * 
from "public".fact_equipment_downtime 
WHERE is_planned = false
with check option;

select 'from source',COUNT(*) from "public".fact_equipment_downtime
union all
select 'from view',COUNT(*) from v_unplanned_downtime;
```
### Результат
```
?column?   |count|
-----------+-----+
from source| 1735|
from view  |  335|
```

## Задача 3
### Текст задачи
Бизнес-задача: Отчёт по качеству руды по шахтам и месяцам — тяжёлый запрос. Нужно его кэшировать.

Требования:

Создайте MATERIALIZED VIEW mv_monthly_ore_quality со следующими столбцами:
Название шахты
Год-месяц (year_month)
Количество проб
Среднее содержание Fe (округлённое до 2 знаков)
Мин. и макс. содержание Fe
Среднее содержание SiO2
Среднее содержание влажности
Создайте индекс по mine_name и year_month
Выполните EXPLAIN ANALYZE для запроса к материализованному представлению и сравните с аналогичным запросом напрямую к таблицам
Выполните REFRESH MATERIALIZED VIEW
Вопрос: Какой индекс нужен для REFRESH ... CONCURRENTLY?
### Решение
```
CREATE MATERIALIZED VIEW mv_monthly_ore_quality as
select dm.mine_name,dd.year_month, COUNT(*) as count_prob, ROUND(AVG (foq.fe_content),2) as avg_fe_content, MIN(foq.fe_content) as min_fe_content,MAX(foq.fe_content) as max_fe_content,ROUND(AVG(sio2_content),2) as avg_sio2_content ,ROUND(AVG(moisture),2) as avg_moisture
from "public".fact_ore_quality foq
join "public".dim_mine dm on foq.mine_id=dm.mine_id
join "public".dim_date dd on foq.date_id=dd.date_id
group by dm.mine_name,dd.year_month;

CREATE INDEX mine_index ON mv_monthly_ore_quality(mine_name);
CREATE INDEX year_month_index ON mv_monthly_ore_quality(year_month);

REFRESH MATERIALIZED view mv_monthly_ore_quality;

EXPLAIN analyze 
select * from mv_monthly_ore_quality;

EXPLAIN analyze 
select dm.mine_name,dd.year_month, COUNT(*) as count_prob, ROUND(AVG (foq.fe_content),2) as avg_fe_content, MIN(foq.fe_content) as min_fe_content,MAX(foq.fe_content) as max_fe_content,ROUND(AVG(sio2_content),2) as avg_sio2_content ,ROUND(AVG(moisture),2) as avg_moisture
from "public".fact_ore_quality foq
join "public".dim_mine dm on foq.mine_id=dm.mine_id
join "public".dim_date dd on foq.date_id=dd.date_id
group by dm.mine_name,dd.year_month;
```
### Результат
```
QUERY PLAN                                                                                                        |
------------------------------------------------------------------------------------------------------------------+
Seq Scan on mv_monthly_ore_quality  (cost=0.00..1.36 rows=36 width=518) (actual time=0.006..0.009 rows=36 loops=1)|
Planning Time: 0.218 ms                                                                                           |
Execution Time: 0.033 ms          


QUERY PLAN                                                                                                                             |
---------------------------------------------------------------------------------------------------------------------------------------+
HashAggregate  (cost=320.78..368.78 rows=1920 width=494) (actual time=5.442..5.501 rows=36 loops=1)                                    |
  Group Key: dm.mine_name, dd.year_month                                                                                               |
  Batches: 1  Memory Usage: 177kB                                                                                                      |
  ->  Hash Join  (cost=41.25..214.28 rows=5325 width=344) (actual time=0.356..2.969 rows=5325 loops=1)                                 |
        Hash Cond: (foq.date_id = dd.date_id)                                                                                          |
        ->  Hash Join  (cost=11.80..170.77 rows=5325 width=340) (actual time=0.025..1.726 rows=5325 loops=1)                           |
              Hash Cond: (foq.mine_id = dm.mine_id)                                                                                    |
              ->  Seq Scan on fact_ore_quality foq  (cost=0.00..144.25 rows=5325 width=26) (actual time=0.006..0.412 rows=5325 loops=1)|
              ->  Hash  (cost=10.80..10.80 rows=80 width=322) (actual time=0.013..0.014 rows=2 loops=1)                                |
                    Buckets: 1024  Batches: 1  Memory Usage: 9kB                                                                       |
                    ->  Seq Scan on dim_mine dm  (cost=0.00..10.80 rows=80 width=322) (actual time=0.005..0.006 rows=2 loops=1)        |
        ->  Hash  (cost=20.31..20.31 rows=731 width=12) (actual time=0.321..0.322 rows=731 loops=1)                                    |
              Buckets: 1024  Batches: 1  Memory Usage: 40kB                                                                            |
              ->  Seq Scan on dim_date dd  (cost=0.00..20.31 rows=731 width=12) (actual time=0.004..0.171 rows=731 loops=1)            |
Planning Time: 0.276 ms                                                                                                                |
Execution Time: 5.605 ms                                                                                                               |                                                                                |
```

## Задача 4
### Текст задачи
Бизнес-задача: Определить лучшего оператора каждой смены за I квартал 2024.

Требования:

Используя производную таблицу (подзапрос в FROM), напишите запрос, который:
Рассчитывает суммарную добычу для каждого оператора в каждой смене
Присваивает ранг (ROW_NUMBER) в разрезе смен
Во внешнем запросе отбирает только ранг = 1
Выведите: название смены, ФИО оператора, суммарную добычу
Отсортируйте по названию смены
Подсказка: SELECT * FROM (SELECT ..., ROW_NUMBER() OVER (PARTITION BY shift_id ORDER BY ...) AS rn ...) sub WHERE rn = 1
### Решение
```
SELECT 
    shift_name,
    operator_name,
    total_production
FROM (
    SELECT 
        s.shift_name AS shift_name,
        CONCAT(o.last_name, ' ', o.first_name, ' ', COALESCE(o.middle_name, '')) AS operator_name,
        SUM(f.tons_mined) AS total_production,
        ROW_NUMBER() OVER (
            PARTITION BY s.shift_id 
            ORDER BY SUM(f.tons_mined) DESC
        ) AS rn
    FROM fact_production f
    INNER JOIN dim_operator o ON f.operator_id = o.operator_id
    INNER JOIN dim_shift s ON f.shift_id = s.shift_id
    INNER JOIN dim_date d ON f.date_id = d.date_id
    WHERE d.full_date BETWEEN '2024-01-01' AND '2024-03-31'
    GROUP BY s.shift_id, s.shift_name, o.operator_id, o.last_name, o.first_name, o.middle_name
) sub
WHERE rn = 1
ORDER BY shift_name;
```
### Результат
```
shift_name   |operator_name                |total_production|
-------------+-----------------------------+----------------+
Дневная смена|Сидоров Дмитрий Александрович|        12854.85|
Ночная смена |Сидоров Дмитрий Александрович|        12783.16|
```

## Задача 5
### Текст задачи
Бизнес-задача: Сформировать отчёт «Доступность оборудования по шахтам» за I квартал 2024.

Требования:

Напишите запрос с двумя CTE:
production_cte: суммарные рабочие часы и добыча по mine_id
downtime_cte: суммарные часы простоев по mine_id (через dim_equipment)
В основном запросе:
Соедините CTE с dim_mine
Рассчитайте доступность = рабочие часы / (рабочие часы + простои) × 100
Выведите: название шахты, рабочие часы, простои (часы), добычу, доступность (%)
Отсортируйте по доступности по возрастанию (худшие шахты сверху)
### Решение
```
with production_cte as (
select mine_id,SUM(operating_hours) as sum_operating_hours, SUM(tons_mined) as sum_tones_mined
from fact_production fp
group by mine_id
), downtime_cte as (
select de.mine_id,ROUND(SUM(fed.duration_min)/60,1) as sum_downtime_hours
from fact_equipment_downtime fed
join dim_equipment de on fed.equipment_id=de.equipment_id
group by de.mine_id
)
select dm.mine_name, p_cte.sum_operating_hours, d_cte.sum_downtime_hours, p_cte.sum_tones_mined, round(100*p_cte.sum_operating_hours/d_cte.sum_downtime_hours,1) as "availbility%"
from downtime_cte d_cte
join production_cte p_cte on d_cte.mine_id=p_cte.mine_id
join dim_mine dm on d_cte.mine_id=dm.mine_id
order by "availbility%"
;
```
### Результат
```
mine_name       |sum_operating_hours|sum_downtime_hours|sum_tones_mined|availbility%|
----------------+-------------------+------------------+---------------+------------+
Шахта "Южная"   |           33802.77|             935.4|      317302.56|      3613.7|
Шахта "Северная"|           56333.31|            1522.1|      549105.75|      3701.0|
```

## Задача 6
### Текст задачи
Бизнес-задача: Диспетчеру нужна функция для быстрого получения простоев оборудования за указанный период.

Требования:

Создайте функцию fn_equipment_downtime_report(p_equipment_id INT, p_date_from INT, p_date_to INT), которая возвращает таблицу:
Дата (full_date)
Причина простоя
Категория причины
Длительность (минуты)
Длительность (часы, округлённая до 1 знака)
Признак планового простоя
Комментарий
Вызовите функцию для equipment_id = 3 за январь 2024
Вызовите функцию через LATERAL JOIN для всех единиц оборудования шахты mine_id = 1
Подсказка: Используйте LANGUAGE sql для инлайн-оптимизации.
### Решение
```
CREATE OR REPLACE FUNCTION fn_equipment_downtime_report(p_equipment_id INT, p_date_from INT, p_date_to INT)
RETURNS TABLE(full_date date, reason_name varchar(200),category varchar(50), duration_min numeric,duration_hour numeric,is_planned bool, comment text) AS $$
begin
	return QUERY
		select dd.full_date, ddr.reason_name, ddr.category, fed.duration_min, ROUND(fed.duration_min/60,1) as duration_hours,fed.is_planned,fed.comment
		from fact_equipment_downtime fed
		join dim_date dd on fed.date_id=dd.date_id
		join dim_downtime_reason ddr on fed.reason_id=ddr.reason_id
		where fed.equipment_id=p_equipment_id
		and fed.date_id>=p_date_from
		and fed.date_id<=p_date_to
	;
end;
$$ LANGUAGE plpgsql;

select * from fn_equipment_downtime_report(3,20240101,20240131);

select de.equipment_name,fned.* from dim_equipment de cross join LATERAL (select * from fn_equipment_downtime_report(de.equipment_id,20000101,21000101)) as fned where de.mine_id=1;
```
### Результат
```
equipment_name|full_date |reason_name                      |category|duration_min|duration_hour|is_planned|comment                  |
--------------+----------+---------------------------------+--------+------------+-------------+----------+-------------------------+
ПДМ-001       |2024-01-15|Плановое техническое обслуживание|плановый|      480.00|          8.0|true      |Плановое ТО по регламенту|
ПДМ-001       |2024-02-15|Плановое техническое обслуживание|плановый|      480.00|          8.0|true      |Плановое ТО по регламенту|
ПДМ-001       |2024-03-15|Плановое техническое обслуживание|плановый|      480.00|          8.0|true      |Плановое ТО по регламенту|
ПДМ-001       |2024-04-15|Плановое техническое обслуживание|плановый|      480.00|          8.0|true      |Плановое ТО по регламенту|
ПДМ-001       |2024-05-15|Плановое техническое обслуживание|плановый|      480.00|          8.0|true      |Плановое ТО по регламенту|
```

## Задача 7
### Текст задачи
Бизнес-задача: Отобразить дерево подземных локаций с полным путём от корня.

Предварительные действия: Убедитесь, что таблица dim_location_hierarchy создана и заполнена (скрипт из практической работы модуля 11).

Требования:

Напишите рекурсивный CTE, который:
Начинает с корневых элементов (parent_id IS NULL)
Рекурсивно обходит все дочерние записи
Формирует полный путь (Шахта → Ствол → Горизонт → Штрек → Забой)
Формирует отступ для визуализации иерархии
Выведите:
Иерархию с отступами (пробелами)
Тип локации
Полный путь
Глубину вложенности
Отсортируйте по полному пути
### Решение
```
WITH RECURSIVE mine_tree AS (
    -- 1. Базовая часть (Anchor)
    SELECT location_id,LPAD(location_name,LENGTH(location_name) +depth_level,'  ') as hierarchy,location_type,depth_level,cast(location_name as text) as full_path 
    from dim_location_hierarchy dlh
    WHERE parent_id IS NULL
    UNION ALL
    -- 2. Рекурсивная часть (Recursive step)
    SELECT child.location_id,LPAD(location_name,LENGTH(location_name) +child.depth_level,'  ') as hierarchy,child.location_type,child.depth_level,concat(parent.full_path,'->',location_name) as full_path
    FROM dim_location_hierarchy child
    INNER JOIN mine_tree parent ON child.parent_id = parent.location_id
)
select * from mine_tree order by full_path;
```
### Результат
```
location_id|hierarchy             |location_type|depth_level|full_path                                                                     |
-----------+----------------------+-------------+-----------+------------------------------------------------------------------------------+
          1|Шахта Северная        |шахта        |          0|Шахта Северная                                                                |
          3| Ствол Вентиляционный |ствол        |          1|Шахта Северная->Ствол Вентиляционный                                          |
          6|  Горизонт -300м (В)  |горизонт     |          2|Шахта Северная->Ствол Вентиляционный->Горизонт -300м (В)                      |
          2| Ствол Главный        |ствол        |          1|Шахта Северная->Ствол Главный                                                 |
          4|  Горизонт -300м      |горизонт     |          2|Шахта Северная->Ствол Главный->Горизонт -300м                                 |
          7|   Штрек 3-Северный   |штрек        |          3|Шахта Северная->Ствол Главный->Горизонт -300м->Штрек 3-Северный               |
         10|    Забой 3С-1        |забой        |          4|Шахта Северная->Ствол Главный->Горизонт -300м->Штрек 3-Северный->Забой 3С-1   |
         11|    Забой 3С-2        |забой        |          4|Шахта Северная->Ствол Главный->Горизонт -300м->Штрек 3-Северный->Забой 3С-2   |
          8|   Штрек 3-Южный      |штрек        |          3|Шахта Северная->Ствол Главный->Горизонт -300м->Штрек 3-Южный                  |
         12|    Забой 3Ю-1        |забой        |          4|Шахта Северная->Ствол Главный->Горизонт -300м->Штрек 3-Южный->Забой 3Ю-1      |
          5|  Горизонт -450м      |горизонт     |          2|Шахта Северная->Ствол Главный->Горизонт -450м                                 |
          9|   Штрек 4-Центральный|штрек        |          3|Шахта Северная->Ствол Главный->Горизонт -450м->Штрек 4-Центральный            |
         13|    Забой 4Ц-1        |забой        |          4|Шахта Северная->Ствол Главный->Горизонт -450м->Штрек 4-Центральный->Забой 4Ц-1|
         14|    Забой 4Ц-2        |забой        |          4|Шахта Северная->Ствол Главный->Горизонт -450м->Штрек 4-Центральный->Забой 4Ц-2|
         15|Шахта Южная           |шахта        |          0|Шахта Южная                                                                   |
         16| Ствол Основной       |ствол        |          1|Шахта Южная->Ствол Основной                                                   |
         17|  Горизонт -200м      |горизонт     |          2|Шахта Южная->Ствол Основной->Горизонт -200м                                   |
         18|   Штрек 1-Западный   |штрек        |          3|Шахта Южная->Ствол Основной->Горизонт -200м->Штрек 1-Западный                 |
         19|    Забой 1З-1        |забой        |          4|Шахта Южная->Ствол Основной->Горизонт -200м->Штрек 1-Западный->Забой 1З-1     |
         20|    Забой 1З-2        |забой        |          4|Шахта Южная->Ствол Основной->Горизонт -200м->Штрек 1-Западный->Забой 1З-2     |
```

## Задача 8
### Текст задачи

### Решение
```

```
### Результат
```

```
## Задача 9
### Текст задачи

### Решение
```

```
### Результат
```

```

## Задача 10
### Текст задачи

### Решение
```

```
### Результат
```

```