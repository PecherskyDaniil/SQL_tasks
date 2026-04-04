## Задание 1
### Текст задания
Бизнес-задача: Диспетчер хочет видеть единую хронологию событий оборудования за 15 марта 2024: записи о добыче и простоях.

Требования:

Объедините с помощью UNION ALL данные из fact_production и fact_equipment_downtime за date_id = 20240315
Для каждой записи выведите:
Тип события ('Добыча' / 'Простой')
Название оборудования
Числовое значение (тонн добычи или минут простоя)
Единица измерения ('тонн' / 'мин.')
Отсортируйте по названию оборудования и типу события
Ожидаемый результат: единая таблица с чередующимися записями добычи и простоев.
### Решение
```
select 'Добыча' as event_type,de.equipment_name ,fp.tons_mined as value, 'тонны' as unit
from fact_production fp 
join dim_equipment de on fp.equipment_id =de.equipment_id 
where fp.date_id=20240315
union all
select 'Простой' as event_type,de1.equipment_name ,fed.duration_min  as value, 'мин' as unit
from fact_equipment_downtime fed  
join dim_equipment de1 on fed.equipment_id =de1.equipment_id 
where fed.date_id=20240315;
```
### Результат
```
event_type|equipment_name|value |unit |
----------+--------------+------+-----+
Добыча    |ПДМ-001       | 79.25|тонны|
Добыча    |ПДМ-002       | 69.58|тонны|
Добыча    |ПДМ-002       | 74.97|тонны|
Добыча    |ПДМ-003       | 79.01|тонны|
Добыча    |ПДМ-003       | 68.13|тонны|
Добыча    |ПДМ-004       | 85.76|тонны|
Добыча    |ПДМ-004       | 79.63|тонны|
Добыча    |ПДМ-006       | 99.25|тонны|
Добыча    |Самосвал-001  |176.02|тонны|
Добыча    |Самосвал-001  |158.60|тонны|
Добыча    |Самосвал-002  |191.76|тонны|
Добыча    |Самосвал-002  |185.36|тонны|
Добыча    |Самосвал-004  |161.92|тонны|
Добыча    |Самосвал-004  |173.24|тонны|
Простой   |ПДМ-001       |480.00|мин  |
Простой   |ПДМ-001       |240.00|мин  |
Простой   |ПДМ-002       |480.00|мин  |
Простой   |ПДМ-003       |480.00|мин  |
Простой   |ПДМ-004       |480.00|мин  |
Простой   |ПДМ-006       |480.00|мин  |
Простой   |Самосвал-001  |480.00|мин  |
Простой   |Самосвал-002  |480.00|мин  |
Простой   |Самосвал-004  |480.00|мин  |
```

## Задание 2
### Текст задания
Бизнес-задача: Определить все шахты, в которых была хоть какая-то активность (добыча ИЛИ простои) за I квартал 2024.

Требования:

Используя UNION (без ALL), объедините:
mine_id из fact_production (через dim_mine)
mine_id из fact_equipment_downtime (через dim_equipment → dim_mine)
Присоедините dim_mine для получения названий
Подсчитайте количество уникальных шахт
Вопрос: Если заменить UNION на UNION ALL, изменится ли количество строк? Почему?
### Решение
```
with all_events as (
select fp.mine_id as mine_id
from fact_production fp 
union
select de.mine_id as mine_id
from fact_equipment_downtime fed 
join dim_equipment de on fed.equipment_id=de.equipment_id 
where fed.date_id between 20240101 and 20240331
)
select count(distinct dm.mine_name) from all_events join dim_mine dm on all_events.mine_id=dm.mine_id;
```
### Результат
```
count|
-----+
    2|
```

## Задание 3
### Текст задания
Бизнес-задача: Найти оборудование, у которого есть записи о добыче, но нет связанных данных о качестве руды за I квартал 2024.

Требования:

Используя EXCEPT, найдите equipment_id:
Первый набор: уникальные equipment_id из fact_production за Q1 2024
Второй набор: уникальные equipment_id из fact_ore_quality (через fact_production, связывая по mine_id, shaft_id, date_id)
Расшифруйте результат — выведите название оборудования и тип
Перепишите этот же запрос с NOT EXISTS и сравните результаты
### Решение
```
with unique_equipment as (select distinct equipment_id
from fact_production fp 
where fp.date_id between 20240101 and 20240331
except
select distinct equipment_id
from fact_ore_quality foq 
left join fact_production fp on foq.mine_id=fp.mine_id and foq.shaft_id=fp.shaft_id and foq.date_id=fp.date_id
where foq.date_id between 20240101 and 20240331)
select equipment_name,type_name
from unique_equipment ue
join dim_equipment de on ue.equipment_id=de.equipment_id 
join dim_equipment_type det on de.equipment_type_id =det.equipment_type_id ;
```

## Задание 4
### Текст задания
Бизнес-задача: Найти операторов-универсалов, которые работали и на ПДМ, и на самосвалах.

Требования:

Используя INTERSECT, найдите operator_id:
Набор 1: операторы, работавшие на оборудовании типа LHD (ПДМ)
Набор 2: операторы, работавшие на оборудовании типа TRUCK (самосвал)
Расшифруйте: выведите ФИО, должность, квалификацию
Подсчитайте, сколько процентов от общего числа операторов являются универсалами
### Решение
```
WITH MultiSkillOps AS (
    SELECT fp.operator_id
    FROM fact_production fp
    JOIN dim_equipment e ON fp.equipment_id = e.equipment_id
    JOIN dim_equipment_type et ON e.equipment_type_id = et.equipment_type_id
    WHERE et.type_code = 'LHD'
    INTERSECT
    SELECT fp.operator_id
    FROM fact_production fp
    JOIN dim_equipment e ON fp.equipment_id = e.equipment_id
    JOIN dim_equipment_type et ON e.equipment_type_id = et.equipment_type_id
    WHERE et.type_code = 'TRUCK'
)
SELECT 
    d_o.last_name || ' ' || LEFT(d_o.first_name, 1) || '.' AS fio,
    d_o.position,
    d_o.qualification,
    COUNT(*) OVER() AS universal_count,
    (SELECT COUNT(DISTINCT operator_id) FROM dim_operator) AS total_operators,
    ROUND(
        (COUNT(*) OVER() * 100.0 / (SELECT COUNT(DISTINCT operator_id) FROM dim_operator))::numeric, 
        2
    ) AS pct_of_all
FROM dim_operator d_o
JOIN MultiSkillOps mso ON d_o.operator_id = mso.operator_id;
```

## Задание 5
### Текст задания
Бизнес-задача: Классифицировать операторов по типу оборудования: только ПДМ, только самосвалы, оба типа.

Требования:

Используя комбинацию UNION ALL, INTERSECT и EXCEPT, постройте отчёт:
«Оба типа» — количество операторов (INTERSECT)
«Только ПДМ» — количество операторов (EXCEPT)
«Только самосвал» — количество (EXCEPT в другом порядке)
Выведите: категория, количество, процент от общего числа
Убедитесь, что суммы сходятся
### Решение
```
WITH MultiSkillOps AS (
    SELECT fp.operator_id
    FROM fact_production fp
    JOIN dim_equipment e ON fp.equipment_id = e.equipment_id
    JOIN dim_equipment_type et ON e.equipment_type_id = et.equipment_type_id
    WHERE et.type_code = 'LHD'
    INTERSECT
    SELECT fp.operator_id
    FROM fact_production fp
    JOIN dim_equipment e ON fp.equipment_id = e.equipment_id
    JOIN dim_equipment_type et ON e.equipment_type_id = et.equipment_type_id
    WHERE et.type_code = 'TRUCK'
),
OnlyLHD AS (
    SELECT fp.operator_id
    FROM fact_production fp
    JOIN dim_equipment e ON fp.equipment_id = e.equipment_id
    JOIN dim_equipment_type et ON e.equipment_type_id = et.equipment_type_id
    WHERE et.type_code = 'LHD'
    EXCEPT
    SELECT fp.operator_id
    FROM fact_production fp
    JOIN dim_equipment e ON fp.equipment_id = e.equipment_id
    JOIN dim_equipment_type et ON e.equipment_type_id = et.equipment_type_id
    WHERE et.type_code = 'TRUCK'
),
OnlyTruck as (
	SELECT fp.operator_id
    FROM fact_production fp
    JOIN dim_equipment e ON fp.equipment_id = e.equipment_id
    JOIN dim_equipment_type et ON e.equipment_type_id = et.equipment_type_id
    WHERE et.type_code = 'TRUCK'
    EXCEPT
	SELECT fp.operator_id
    FROM fact_production fp
    JOIN dim_equipment e ON fp.equipment_id = e.equipment_id
    JOIN dim_equipment_type et ON e.equipment_type_id = et.equipment_type_id
    WHERE et.type_code = 'LHD'
),
otchet as (
select operator_id, 'Оба типа' as operator_type
from MultiSkillOps
union all 
select operator_id, 'Только ПДМ' as operator_type
from OnlyLHD
union all 
select operator_id, 'Только самосвал' as operator_type
from OnlyTruck
)
select operator_type,COUNT(*), ROUND(100*COUNT(*)/(select count(*) from otchet),1) from otchet group by operator_type;
```
### Результат
```
operator_type  |count|round|
---------------+-----+-----+
Только самосвал|    3| 37.0|
Только ПДМ     |    5| 62.0|
```

## Задание 6
### Текст задания
Бизнес-задача: Для каждой шахты показать 5 самых длительных внеплановых простоев за I квартал 2024.

Требования:

Используя CROSS JOIN LATERAL, для каждой активной шахты (dim_mine.status = 'active') выберите 5 самых длительных внеплановых простоев
Выведите:
Название шахты
Дата (full_date)
Название оборудования
Причина простоя
Длительность (минуты и часы)
Отсортируйте по шахте, затем по длительности убыванию
### Решение
```
SELECT m.mine_name, top5.*
FROM dim_mine m
CROSS JOIN LATERAL (
    SELECT dd.full_date, e.equipment_name, ddr.reason_name, fd.duration_min, ROUND(fd.duration_min/60,0) as duration_hours
    FROM fact_equipment_downtime fd
    JOIN dim_equipment e on fd.equipment_id =e.equipment_id 
    join dim_date dd on fd.date_id=dd.date_id
    join dim_downtime_reason ddr on fd.reason_id=ddr.reason_id 
    WHERE e.mine_id = m.mine_id 
      AND fd.is_planned = FALSE
      AND fd.date_id BETWEEN 20240101 AND 20240331
    ORDER BY fd.duration_min DESC
    LIMIT 5
) top5
WHERE m.status = 'active'
order by m.mine_name,top5.duration_min;
```
### Результат
```
mine_name       |full_date |equipment_name|reason_name         |duration_min|duration_hours|
----------------+----------+--------------+--------------------+------------+--------------+
Шахта "Северная"|2024-03-07|ПДМ-001       |Отсутствие оператора|      173.11|             3|
Шахта "Северная"|2024-01-03|Самосвал-001  |Ожидание транспорта |      173.18|             3|
Шахта "Северная"|2024-03-15|ПДМ-001       |Перегрев двигателя  |      240.00|             4|
Шахта "Северная"|2024-01-22|ПДМ-002       |Аварийный ремонт    |      240.00|             4|
Шахта "Северная"|2024-02-08|ПДМ-001       |Аварийный ремонт    |      480.00|             8|
Шахта "Южная"   |2024-02-16|ПДМ-004       |Ожидание транспорта |      152.55|             3|
Шахта "Южная"   |2024-01-29|Самосвал-004  |Ожидание транспорта |      173.69|             3|
Шахта "Южная"   |2024-02-20|ПДМ-004       |Ожидание транспорта |      174.51|             3|
Шахта "Южная"   |2024-03-28|ПДМ-004       |Ожидание транспорта |      179.97|             3|
Шахта "Южная"   |2024-03-05|ПДМ-004       |Аварийный ремонт    |      240.00|             4|
```

## Задание 7
### Текст задания
Бизнес-задача: Для каждого активного датчика показать его последнее показание.

Требования:

Используя LEFT JOIN LATERAL, для каждого датчика из dim_sensor (где status = 'active') найдите последнюю запись из fact_equipment_telemetry
Выведите:
Код датчика
Тип датчика
Оборудование
Дата и время последнего показания
Значение показания
Признак тревоги
Отсортируйте по дате последнего показания (самые «застывшие» датчики сверху)
Вопрос: Почему LEFT JOIN LATERAL предпочтительнее CROSS JOIN LATERAL в этом случае?
### Решение
```
select ds.sensor_code,
	   dst.type_name,
	   de.equipment_name,
	   last_sensor_value.full_date,
	   last_sensor_value.time_id,
	   last_sensor_value.sensor_value,
	   last_sensor_value.is_alarm
from dim_sensor ds
join dim_sensor_type dst on ds.sensor_type_id=dst.sensor_type_id 
join dim_equipment de on de.equipment_id=ds.equipment_id
left join lateral (
			select dd.full_date,fet.time_id,fet.sensor_value,fet.is_alarm 
			from fact_equipment_telemetry fet 
			join dim_date dd on fet.date_id=dd.date_id 
			where fet.sensor_id=ds.sensor_id
			order by fet.date_id desc
			limit 1
		) last_sensor_value on true
order by last_sensor_value.full_date,last_sensor_value.time_id;
```
### Результат
```
sensor_code  |type_name                   |equipment_name|full_date |time_id|sensor_value|is_alarm|
-------------+----------------------------+--------------+----------+-------+------------+--------+
S-TRK001-RPM |Датчик оборотов двигателя   |Самосвал-001  |2024-07-07|    815|   1241.0000|true    |
S-TRK001-TEMP|Датчик температуры двигателя|Самосвал-001  |2024-07-07|    815|    102.4400|true    |
S-LHD004-LOAD|Датчик массы груза          |ПДМ-004       |2024-07-07|    845|      1.4300|true    |
S-LHD001-VIB |Датчик вибрации             |ПДМ-001       |2024-07-07|    900|     15.7700|true    |
S-LHD001-LOAD|Датчик массы груза          |ПДМ-001       |2024-07-07|    930|      3.3800|true    |
S-TRK001-LOAD|Датчик массы груза          |Самосвал-001  |2024-07-07|    945|      8.5400|true    |
S-TRK004-LOAD|Датчик массы груза          |Самосвал-004  |2024-07-07|    945|     20.6700|true    |
S-LHD004-VIB |Датчик вибрации             |ПДМ-004       |2024-07-07|   1145|     15.4700|true    |
S-TRK004-TEMP|Датчик температуры двигателя|Самосвал-004  |2024-07-07|   1200|     97.5500|true    |
S-LHD004-TEMP|Датчик температуры двигателя|ПДМ-004       |2024-07-07|   1200|     95.9100|true    |
S-TRK004-RPM |Датчик оборотов двигателя   |Самосвал-004  |2024-07-07|   1215|   1262.0000|true    |
S-LHD001-FUEL|Датчик уровня топлива       |ПДМ-001       |2024-07-07|   1230|     65.8500|true    |
S-TRK001-OIL |Датчик давления масла       |Самосвал-001  |2024-07-07|   1345|      2.7100|true    |
S-TRK001-FUEL|Датчик уровня топлива       |Самосвал-001  |2024-07-07|   1345|     61.1700|true    |
S-TRK004-VIB |Датчик вибрации             |Самосвал-004  |2024-07-07|   1545|     11.8800|true    |
S-LHD001-SPD |Датчик скорости движения    |ПДМ-001       |2024-07-07|   1600|     10.6100|true    |
S-TRK004-SPD |Датчик скорости движения    |Самосвал-004  |2024-07-07|   1645|      0.2400|true    |
S-TRK001-VIB |Датчик вибрации             |Самосвал-001  |2024-07-07|   1730|      5.6400|true    |
S-LHD004-FUEL|Датчик уровня топлива       |ПДМ-004       |2024-07-07|   1730|     44.3400|true    |
S-TRK001-SPD |Датчик скорости движения    |Самосвал-001  |2024-07-07|   1845|      3.6600|false   |
S-LHD001-TEMP|Датчик температуры двигателя|ПДМ-001       |2024-07-07|   1900|     91.1200|false   |
S-LHD004-SPD |Датчик скорости движения    |ПДМ-004       |2024-07-07|   1915|      1.8900|true    |
S-LHD002-SPD |Датчик скорости движения    |ПДМ-002       |          |       |            |        |
S-SKP003-TEMP|Датчик температуры двигателя|Скип-003      |          |       |            |        |
S-SKP003-LOAD|Датчик массы груза          |Скип-003      |          |       |            |        |
S-SKP001-LOAD|Датчик массы груза          |Скип-001      |          |       |            |        |
S-TRK002-SPD |Датчик скорости движения    |Самосвал-002  |          |       |            |        |
S-TRK002-LOAD|Датчик массы груза          |Самосвал-002  |          |       |            |        |
S-LHD002-VIB |Датчик вибрации             |ПДМ-002       |          |       |            |        |
S-LHD003-VIB |Датчик вибрации             |ПДМ-003       |          |       |            |        |
S-LHD003-LOAD|Датчик массы груза          |ПДМ-003       |          |       |            |        |
S-LHD002-LOAD|Датчик массы груза          |ПДМ-002       |          |       |            |        |
S-TRK002-VIB |Датчик вибрации             |Самосвал-002  |          |       |            |        |
S-TRK002-FUEL|Датчик уровня топлива       |Самосвал-002  |          |       |            |        |
S-SKP001-VIB |Датчик вибрации             |Скип-001      |          |       |            |        |
S-SKP003-VIB |Датчик вибрации             |Скип-003      |          |       |            |        |
S-LHD003-FUEL|Датчик уровня топлива       |ПДМ-003       |          |       |            |        |
S-LHD002-FUEL|Датчик уровня топлива       |ПДМ-002       |          |       |            |        |
S-LHD002-TEMP|Датчик температуры двигателя|ПДМ-002       |          |       |            |        |
S-LHD003-TEMP|Датчик температуры двигателя|ПДМ-003       |          |       |            |        |
S-SKP001-RPM |Датчик оборотов двигателя   |Скип-001      |          |       |            |        |
S-TRK002-TEMP|Датчик температуры двигателя|Самосвал-002  |          |       |            |        |
S-SKP001-TEMP|Датчик температуры двигателя|Скип-001      |          |       |            |        |
```

## Задание 8
### Текст задания
Требования:

С помощью UNION ALL объедините 4 запроса, каждый из которых возвращает: mine_name, kpi_name, kpi_value
Суммарная добыча (тонн) — из fact_production
Суммарные простои (часы) — из fact_equipment_downtime
Среднее содержание Fe (%) — из fact_ore_quality
Количество тревожных показаний — из fact_equipment_telemetry
Отсортируйте по шахте и названию KPI
Дополнительно: разверните результат в «широкую» таблицу (с помощью условной агрегации или crosstab):
### Решение
```
with kpi_stats as (
	select dm.mine_name,'Добыча (тонн)' as kpi_name, SUM(fp.tons_mined) as kpi_value
	from fact_production fp 
	join dim_mine dm on dm.mine_id=fp.mine_id
	group by dm.mine_name
	union all
	select dm.mine_name,'Простои (часы)' as kpi_name, SUM(ROUND(fed.duration_min/60,0)) as kpi_value
	from fact_equipment_downtime fed
	join dim_equipment de on fed.equipment_id=de.equipment_id
	join dim_mine dm on dm.mine_id=de.mine_id
	group by dm.mine_name
	union all
	select dm.mine_name,'Cодержание Fe (%) ' as kpi_name, ROUND(AVG(foq.fe_content),2) as kpi_value
	from fact_ore_quality foq 
	join dim_mine dm on dm.mine_id=foq.mine_id
	group by dm.mine_name
	union all
	select dm.mine_name,'Количество тревожных показаний ' as kpi_name, COUNT(*) as kpi_value
	from fact_equipment_telemetry fet
	join dim_equipment de on fet.equipment_id=de.equipment_id 
	join dim_mine dm on dm.mine_id=de.mine_id
	where fet.is_alarm=true
	group by dm.mine_name
)
select *
from kpi_stats
order by mine_name,kpi_name;
```
### Результат
```
mine_name       |kpi_name                       |kpi_value|
----------------+-------------------------------+---------+
Шахта "Северная"|Cодержание Fe (%)              |    56.86|
Шахта "Северная"|Добыча (тонн)                  |549486.25|
Шахта "Северная"|Количество тревожных показаний |      118|
Шахта "Северная"|Простои (часы)                 |     1922|
Шахта "Южная"   |Cодержание Fe (%)              |    51.35|
Шахта "Южная"   |Добыча (тонн)                  |317302.56|
Шахта "Южная"   |Количество тревожных показаний |       95|
Шахта "Южная"   |Простои (часы)                 |     1174|
```