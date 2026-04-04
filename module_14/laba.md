## Задание 1
### Текст задания
Бизнес-задача: Начальник участка хочет получить сменный рапорт по добыче за 15 января 2024 с подитогами по шахтам и общим итогом.

Требования:

Используя GROUP BY ROLLUP(mine_name, shift_name), сформируйте отчёт:
Название шахты
Название смены
Суммарная добыча (тонн)
Количество единиц оборудования
Замените NULL в подитоговых строках на понятные подписи с помощью CASE WHEN GROUPING(...) = 1
Отсортируйте так, чтобы подитоги шли после детализации, общий итог — в конце
Ожидаемый результат: Таблица с детализацией, подитогами по шахтам и общим итогом.
### Решение
```
select CASE WHEN grouping(dm.mine_name)=1 then 'Общая' else dm.mine_name end, CASE WHEN grouping(ds.shift_name)=1 then '-' else ds.shift_name end, SUM(fp.tons_mined ), COUNT(distinct fp.equipment_id )
from fact_production fp 
join dim_mine dm on fp.mine_id=dm.mine_id 
join dim_shift ds on fp.shift_id =ds.shift_id 
where fp.date_id =20240115
GROUP BY ROLLUP(dm.mine_name, ds.shift_name)
order by dm.mine_name, ds.shift_name;
```
### Результат
```
mine_name       |shift_name   |sum    |count|
----------------+-------------+-------+-----+
Шахта "Северная"|Дневная смена| 498.10|    5|
Шахта "Северная"|Ночная смена | 547.04|    5|
Шахта "Северная"|-            |1045.14|    5|
Шахта "Южная"   |Дневная смена| 300.92|    3|
Шахта "Южная"   |Ночная смена | 276.22|    3|
Шахта "Южная"   |-            | 577.14|    3|
Общая           |-            |1622.28|    8|
```

## Задание 2
### Текст задания
Бизнес-задача: Главный инженер хочет видеть добычу по всем комбинациям «шахта / тип оборудования» с итогами по строкам и столбцам.

Требования:

Используя GROUP BY CUBE(mine_name, type_name), сформируйте отчёт за I квартал 2024:
Шахта (или «ВСЕ ШАХТЫ» для подитога)
Тип оборудования (или «ВСЕ ТИПЫ» для подитога)
Суммарная добыча
Средняя добыча на единицу оборудования
Добавьте столбец grouping_level с помощью GROUPING(mine_name, type_name)
Отсортируйте по уровню группировки, шахте и типу
Вопрос: Сколько строк вернёт CUBE для 3 шахт и 4 типов оборудования? (Ответ: 3x4 + 3 + 4 + 1 = 20.)
### Решение
```
select CASE WHEN grouping(dm.mine_name)=1 then 'Все шахты' else dm.mine_name end,
	   CASE WHEN grouping(det.type_name)=1 then 'Все типы' else det.type_name end,
	   SUM(fp.tons_mined ) as sum_tons, 
	   ROUND(SUM(fp.tons_mined )/COUNT(distinct fp.equipment_id),1) as avg_per_equipment,
	   GROUPING(mine_name, type_name) as grouping_level
from fact_production fp 
join dim_mine dm on dm.mine_id=fp.mine_id 
join dim_equipment de on de.equipment_id=fp.equipment_id
join dim_equipment_type det on de.equipment_type_id=det.equipment_type_id 
where fp.date_id between 20240101 and 20240331
GROUP BY CUBE(dm.mine_name, det.type_name)
order by grouping_level,mine_name, type_name;
```
### Результат
```
mine_name       |type_name                    |sum_tons |avg_per_equipment|grouping_level|
----------------+-----------------------------+---------+-----------------+--------------+
Шахта "Северная"|Погрузочно-доставочная машина| 34188.29|          11396.1|             0|
Шахта "Северная"|Шахтный самосвал             | 49620.47|          24810.2|             0|
Шахта "Южная"   |Погрузочно-доставочная машина| 24696.58|          12348.3|             0|
Шахта "Южная"   |Шахтный самосвал             | 23303.48|          23303.5|             0|
Шахта "Северная"|Все типы                     | 83808.76|          16761.8|             1|
Шахта "Южная"   |Все типы                     | 48000.06|          16000.0|             1|
Все шахты       |Погрузочно-доставочная машина| 58884.87|          11777.0|             2|
Все шахты       |Шахтный самосвал             | 72923.95|          24308.0|             2|
Все шахты       |Все типы                     |131808.82|          16476.1|             3|
```

## Задание 3
### Текст задания
Бизнес-задача: Для ежемесячного совещания подготовить сводку по добыче за январь 2024 в разрезе: по шахтам, по сменам, по типам оборудования, общий итог.

Требования:

Используя GROUPING SETS, в одном запросе получите 4 среза:
(mine_name) — итого по шахтам
(shift_name) — итого по сменам
(type_name) — итого по типам оборудования
() — общий итог
Добавьте столбец dimension с названием среза: «Шахта», «Смена», «Тип оборудования», «ИТОГО»
Выведите: dimension, dimension_value, total_tons, total_trips, avg_tons_per_trip
### Решение
```
SELECT
    CASE
        WHEN GROUPING(m.mine_name) = 0 THEN 'Шахта'
        WHEN GROUPING(s.shift_name) = 0 THEN 'Смена'
        WHEN GROUPING(et.type_name) = 0 THEN 'Тип оборудования'
        ELSE 'ИТОГО'
    END AS dimension,
    COALESCE(m.mine_name, s.shift_name, et.type_name, 'Все') AS dimension_value,
    SUM(fp.tons_mined) as total_tons,
    sum(fp.trips_count) as total_trips,
    ROUND(SUM(fp.tons_mined)/sum(fp.trips_count),2) as avg_tons_per_trip
from fact_production fp 
join dim_mine m on fp.mine_id=m.mine_id 
join dim_shift s on fp.shift_id=s.shift_id 
join dim_equipment de on fp.equipment_id=de.equipment_id 
join dim_equipment_type et on de.equipment_type_id=et.equipment_type_id 
where fp.date_id between 20240101 and 20240131
group by grouping sets (
	(m.mine_name),
	(s.shift_name),
	(et.type_name),
	()
)
order by dimension,dimension_value
```
### Результат
```
dimension       |dimension_value              |total_tons|total_trips|avg_tons_per_trip|
----------------+-----------------------------+----------+-----------+-----------------+
ИТОГО           |Все                          |  43252.34|       3216|            13.45|
Смена           |Дневная смена                |  21778.18|       1603|            13.59|
Смена           |Ночная смена                 |  21474.16|       1613|            13.31|
Тип оборудования|Погрузочно-доставочная машина|  19559.13|       2273|             8.60|
Тип оборудования|Шахтный самосвал             |  23693.21|        943|            25.13|
Шахта           |Шахта "Северная"             |  27398.61|       1965|            13.94|
Шахта           |Шахта "Южная"                |  15853.73|       1251|            12.67|
```

## Задание 4
### Текст задания
Бизнес-задача: Построить таблицу «Качество руды по шахтам и месяцам» в формате Excel-сводной таблицы.

Требования:

С помощью условной агрегации (CASE WHEN) разверните данные fact_ore_quality за I полугодие 2024:
Строки: mine_name
Столбцы: месяцы (Янв, Фев, ..., Июн)
Значения: среднее содержание Fe (%), округлённое до 2 знаков
Добавьте столбец «Среднее за период»
Добавьте строку «ИТОГО» с помощью GROUPING SETS или UNION ALL
### Решение
```
SELECT 
    CASE 
        WHEN GROUPING(dm.mine_name) = 1 THEN 'ИТОГО' 
        ELSE dm.mine_name 
    END AS mine_name,
    ROUND(AVG(CASE WHEN EXTRACT(MONTH FROM dd.full_date) = 1 THEN foq.fe_content END), 2) AS "Янв",
    ROUND(AVG(CASE WHEN EXTRACT(MONTH FROM dd.full_date) = 2 THEN foq.fe_content END), 2) AS "Фев",
    ROUND(AVG(CASE WHEN EXTRACT(MONTH FROM dd.full_date) = 3 THEN foq.fe_content END), 2) AS "Мар",
    ROUND(AVG(CASE WHEN EXTRACT(MONTH FROM dd.full_date) = 4 THEN foq.fe_content END), 2) AS "Апр",
    ROUND(AVG(CASE WHEN EXTRACT(MONTH FROM dd.full_date) = 5 THEN foq.fe_content END), 2) AS "Май",
    ROUND(AVG(CASE WHEN EXTRACT(MONTH FROM dd.full_date) = 6 THEN foq.fe_content END), 2) AS "Июн",
    ROUND(AVG(foq.fe_content), 2) AS "Среднее за период"
FROM fact_ore_quality foq
JOIN dim_mine dm ON foq.mine_id = dm.mine_id
JOIN dim_date dd ON foq.date_id = dd.date_id
WHERE dd.full_date >= '2024-01-01' AND dd.full_date <= '2024-06-30'
GROUP BY GROUPING SETS (
    (dm.mine_name), 
    ()
)
ORDER BY GROUPING(dm.mine_name), dm.mine_name;
```
### Результат
```
mine_name       |Янв  |Фев  |Мар  |Апр  |Май  |Июн  |Среднее за период|
----------------+-----+-----+-----+-----+-----+-----+-----------------+
Шахта "Северная"|56.03|56.13|55.48|55.92|58.05|59.27|            56.81|
Шахта "Южная"   |50.68|49.52|51.98|50.90|53.14|52.79|            51.50|
ИТОГО           |53.96|53.57|54.12|53.97|56.17|56.79|            54.76|
```

## Задание 5
### Текст задания
Бизнес-задача: Сформировать таблицу простоев: строки — оборудование, столбцы — причины простоев, значения — суммарная длительность (часы).

Требования:

Установите расширение: CREATE EXTENSION IF NOT EXISTS tablefunc;
С помощью crosstab() постройте сводную таблицу за I квартал 2024:
Строки: equipment_name
Столбцы: top-5 причин простоев (по общей длительности)
Значения: суммарная длительность в часах, округлённая до 1 знака
Определите структуру результата в AS ct(...) вручную
### Решение
```
SELECT * FROM crosstab(
    $$
    SELECT 
        de.equipment_name,
        dr.reason_name,
        ROUND(SUM(fd.duration_min) / 60.0, 1) as duration_hours
    FROM fact_equipment_downtime fd
    JOIN dim_equipment de ON fd.equipment_id = de.equipment_id
    JOIN dim_downtime_reason dr ON fd.reason_id = dr.reason_id
    WHERE fd.date_id BETWEEN 20240101 AND 20240331
    GROUP BY 1, 2
    ORDER BY 1, 2
    $$,
    $$
    SELECT dr.reason_name 
    FROM fact_equipment_downtime fd
    JOIN dim_downtime_reason dr ON fd.reason_id = dr.reason_id
    WHERE fd.date_id BETWEEN 20240101 AND 20240331
    GROUP BY dr.reason_name
    ORDER BY SUM(fd.duration_min) DESC
    LIMIT 5
    $$
) AS ct (
    "Оборудование" TEXT,
    "Плановое техническое обслуживание" numeric,
	"Заправка топливом" numeric,
	"Ожидание транспорта" numeric,
	"Отсутствие оператора" numeric,
	"Ожидание погрузки" numeric        
);
```
### Результат
```
Оборудование|Плановое техническое обслуживани|Заправка топливом|Ожидание транспорта|Отсутствие оператора|Ожидание погрузки|
------------+--------------------------------+-----------------+-------------------+--------------------+-----------------+
ПДМ-001     |                            24.0|             13.0|                6.9|                 7.1|              5.3|
ПДМ-002     |                            24.0|             13.0|               15.1|                 5.7|              3.8|
ПДМ-003     |                            24.0|             13.0|                   |                    |                 |
ПДМ-004     |                            24.0|             13.0|               23.2|                    |              2.3|
ПДМ-006     |                            24.0|             13.0|                   |                    |                 |
Самосвал-001|                            24.0|             13.0|                7.2|                 6.3|              4.9|
Самосвал-002|                            24.0|             13.0|                   |                    |                 |
Самосвал-004|                            24.0|             13.0|                5.6|                 4.9|              3.5|
```

## Задание 6
### Текст задания
Бизнес-задача: Подготовить квартальный производственный отчёт для руководства: по каждой шахте — добыча по месяцам, подитоги по кварталу, общий итог по компании.

Требования:

Сформируйте «широкую» таблицу:
Строки: шахта (с подитогом «ИТОГО» через ROLLUP)
Столбцы: Январь, Февраль, Март, Q1 Итого (через условную агрегацию)
Значения: добыча (тонн)
Добавьте столбцы:
Изменение Фев vs Янв (%)
Изменение Мар vs Фев (%)
Тренд: «рост» / «снижение» / «стабильно» (если изменение < 5%)
Сформируйте вторую часть отчёта с простоями (UNION ALL):
Те же строки и столбцы
Значения: простои (часы)
Отсортируйте: детализация → подитог
### Решение
```
WITH RawReport AS (
    SELECT 
        m.mine_name,
        'Добыча (тонн)' AS metric,
        SUM(CASE WHEN d.month = 1 THEN fp.tons_mined ELSE 0 END) AS jan,
        SUM(CASE WHEN d.month = 2 THEN fp.tons_mined ELSE 0 END) AS feb,
        SUM(CASE WHEN d.month = 3 THEN fp.tons_mined ELSE 0 END) AS mar,
        SUM(fp.tons_mined) AS q1_total,
        GROUPING(m.mine_name) AS is_total
    FROM fact_production fp
    JOIN dim_mine m ON fp.mine_id = m.mine_id
    JOIN dim_date d ON fp.date_id = d.date_id
    WHERE d.year = 2024 AND d.quarter = 1
    GROUP BY ROLLUP(m.mine_name)
    UNION ALL
    SELECT 
        m.mine_name,
        'Простои (час)' AS metric,
        SUM(CASE WHEN d.month = 1 THEN fd.duration_min ELSE 0 END) / 60.0 AS jan,
        SUM(CASE WHEN d.month = 2 THEN fd.duration_min ELSE 0 END) / 60.0 AS feb,
        SUM(CASE WHEN d.month = 3 THEN fd.duration_min ELSE 0 END) / 60.0 AS mar,
        SUM(fd.duration_min) / 60.0 AS q1_total,
        GROUPING(m.mine_name) AS is_total
    FROM fact_equipment_downtime fd
    JOIN dim_equipment de on fd.equipment_id=de.equipment_id
    JOIN dim_mine m ON de.mine_id = m.mine_id
    JOIN dim_date d ON fd.date_id = d.date_id
    WHERE d.year = 2024 AND d.quarter = 1
    GROUP BY ROLLUP(m.mine_name)
)
SELECT 
    CASE WHEN is_total = 1 THEN 'ИТОГО' ELSE mine_name END AS "Шахта",
    metric AS "Метрика",
    ROUND(jan, 1) AS "Янв",
    ROUND(feb, 1) AS "Фев",
    ROUND(mar, 1) AS "Мар",
    ROUND(q1_total, 1) AS "Q1 Итого",
    CASE WHEN jan > 0 
         THEN ROUND(((feb - jan) / jan) * 100, 1) 
         ELSE 0 END AS "diff_feb_jan_%",
    CASE WHEN feb > 0 
         THEN ROUND(((mar - feb) / feb) * 100, 1) 
         ELSE 0 END AS "diff_mar_feb_%",
    CASE 
        WHEN feb = 0 THEN 'нет данных'
        WHEN ((mar - feb) / feb) * 100 > 5 THEN 'рост'
        WHEN ((mar - feb) / feb) * 100 < -5 THEN 'снижение'
        ELSE 'стабильно'
    END AS "Тренд"
FROM RawReport
ORDER BY metric, is_total, mine_name;
```
### Результат
```
Шахта           |Метрика      |Янв    |Фев    |Мар    |Q1 Итого|diff_feb_jan_%|diff_mar_feb_%|Тренд    |
----------------+-------------+-------+-------+-------+--------+--------------+--------------+---------+
Шахта "Северная"|Добыча (тонн)|27398.6|27067.9|29342.2| 83808.8|          -1.2|           8.4|рост     |
Шахта "Южная"   |Добыча (тонн)|15853.7|15294.5|16851.9| 48000.1|          -3.5|          10.2|рост     |
ИТОГО           |Добыча (тонн)|43252.3|42362.4|46194.1|131808.8|          -2.1|           9.0|рост     |
Шахта "Северная"|Простои (час)|   92.7|   86.6|   84.0|   263.4|          -6.5|          -3.0|стабильно|
Шахта "Южная"   |Простои (час)|   53.6|   50.6|   50.2|   154.5|          -5.6|          -0.7|стабильно|
ИТОГО           |Простои (час)|  146.3|  137.3|  134.3|   417.8|          -6.2|          -2.2|стабильно|
```