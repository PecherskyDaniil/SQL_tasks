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