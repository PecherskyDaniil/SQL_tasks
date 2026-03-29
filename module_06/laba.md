## Задание 1
### Текст задания
Бизнес-задача: Лаборатория качества готовит отчёт по результатам анализов проб за 15 марта 2024 года. Содержание компонентов необходимо округлить до 1 десятичного знака.

Требования:

Выведите: номер пробы, содержание Fe, SiO2, Al2O3
Содержание Fe округлите до 1 знака (ROUND)
Содержание SiO2 округлите вверх (CEIL / CEILING)
Содержание Al2O3 округлите вниз (FLOOR)
Отсортируйте по содержанию Fe (убывание)
### Решение
```
EVALUATE
    SELECTCOLUMNS(
        FILTER(
            fact_ore_quality,
            fact_ore_quality[date_id] = 20240315
        ),
        "sample_number", fact_ore_quality[sample_number],
        "fe_round", ROUND(fact_ore_quality[fe_content], 1),
        "sio2_ceil", CEILING(fact_ore_quality[sio2_content], 1),
        "al2o3_floor", FLOOR(fact_ore_quality[al2o3_content], 1)
    )
ORDER BY [fe_round] DESC


SELECT sample_number, ROUND(fe_content, 1) AS fe_round, CEIL(sio2_content) AS sio2_ceil, FLOOR(al2o3_content) AS al2o3_floor
FROM fact_ore_quality WHERE date_id = 20240315 ORDER BY fe_round DESC;

```
### Результат
```
sample_number       |fe_round|sio2_ceil|al2o3_floor|
--------------------+--------+---------+-----------+
PRB-20240315-N480-N2|    59.3|       20|          4|
PRB-20240315-N480-N1|    59.3|       15|          5|
PRB-20240315-N620-3 |    58.4|       13|          2|
PRB-20240315-N620-1 |    58.4|       15|          2|
PRB-20240315-N620-2 |    58.4|       10|          3|
PRB-20240315-S420-2 |    51.5|        9|          6|
PRB-20240315-S420-1 |    51.5|       23|          7|
PRB-20240315-S420-3 |    51.5|       12|          2|
PRB-20240315-S420-N2|    47.6|       10|          3|
PRB-20240315-S420-N1|    47.6|       11|          2|
PRB-20240315-N480-2 |    46.6|       14|          5|
PRB-20240315-N480-1 |    46.6|       17|          7|
PRB-20240315-N480-3 |    46.6|       16|          2|

```

## Задание 2
### Текст задания
Бизнес-задача: Инженер качества хочет оценить, насколько пробы за март 2024 отклоняются от целевого содержания Fe = 60%. Нужно определить абсолютное отклонение, его направление и квадрат отклонения.

Требования:

Выведите: номер пробы, содержание Fe, отклонение (fe_content - 60)
Добавьте абсолютное отклонение (ABS)
Добавьте направление: «Выше нормы» / «В норме» / «Ниже нормы» (SIGN + CASE / SWITCH)
Добавьте квадрат отклонения (POWER)
Отсортируйте по абсолютному отклонению (убывание), первые 10
### Решение
```
SELECT sample_number,fe_content,
       (fe_content-60) as deviation,
       ABS(fe_content-60) as abs_deviation,
       case SIGN(fe_content-60) 
       		when 1 then 'Выше нормы'
       		when -1 then 'Ниже нормы'
       		else 'В норме'
       		end,
       	ROUND((fe_content-60)*(fe_content-60),2) as squared_dev
FROM fact_ore_quality where date_id>20240301 and date_id<20240401 order by abs_deviation desc limit 10;

EVALUATE
VAR march_data =
    SELECTCOLUMNS(
        FILTER(
            fact_ore_quality,
            fact_ore_quality[date_id] >= 20240301
                && fact_ore_quality[date_id] <= 20240331
        ),
        "sample_number", fact_ore_quality[sample_number],
        "fe_content", fact_ore_quality[fe_content],
        "deviation", ROUND(fact_ore_quality[fe_content] - 60, 2),
        "abs_deviation", ROUND(ABS(fact_ore_quality[fe_content] - 60), 2),
        "direction",
            SWITCH(
                TRUE(),
                fact_ore_quality[fe_content] > 60, "Выше нормы",
                fact_ore_quality[fe_content] = 60, "В норме",
                "Ниже нормы"
            ),
        "squared_dev", ROUND(POWER(fact_ore_quality[fe_content] - 60, 2), 2)
    )
RETURN
    TOPN(10, march_data, [abs_deviation], DESC)
ORDER BY [abs_deviation] DESC

```
### Результат
```
sample_number      |fe_content|deviation|abs_deviation|case      |squared_dev|
-------------------+----------+---------+-------------+----------+-----------+
PRB-20240304-S420-3|     42.73|   -17.27|        17.27|Ниже нормы|     298.25|
PRB-20240304-S420-2|     42.73|   -17.27|        17.27|Ниже нормы|     298.25|
PRB-20240304-S420-1|     42.73|   -17.27|        17.27|Ниже нормы|     298.25|
PRB-20240322-N620-3|     44.37|   -15.63|        15.63|Ниже нормы|     244.30|
PRB-20240322-N620-1|     44.37|   -15.63|        15.63|Ниже нормы|     244.30|
PRB-20240322-N620-2|     44.37|   -15.63|        15.63|Ниже нормы|     244.30|
PRB-20240320-S420-1|     44.58|   -15.42|        15.42|Ниже нормы|     237.78|
PRB-20240320-S420-2|     44.58|   -15.42|        15.42|Ниже нормы|     237.78|
PRB-20240320-S420-3|     44.58|   -15.42|        15.42|Ниже нормы|     237.78|
PRB-20240308-N620-3|     44.71|   -15.29|        15.29|Ниже нормы|     233.78|

```

## Задание 3
### Текст задания
Бизнес-задача: Начальник производства запросил сводку добычи за март 2024 с разбивкой по сменам: количество записей, суммарная добыча, средняя добыча, количество уникальных операторов.

Требования:

Группировка по shift_id
Используйте: COUNT(*), SUM, ROUND(AVG, 2), COUNT(DISTINCT operator_id)
Добавьте название смены через CASE (1='Утренняя', 2='Дневная', 3='Ночная')
Отсортируйте по shift_id
### Решение
```
SELECT
    shift_id,
    CASE shift_id WHEN 1 THEN 'Утренняя' when 2 then 'Дневная' when 3 then 'Ночная' END AS shift_name,
    COUNT(*) AS count_of_shifts,
    SUM(tons_mined) AS sum_of_tons,
    ROUND(AVG(tons_mined), 2) AS average_tons,
    COUNT(DISTINCT operator_id) AS count_of_operators
FROM fact_production
WHERE date_id BETWEEN 20240301 AND 20240331
GROUP BY shift_id
ORDER BY shift_id;

EVALUATE
    ADDCOLUMNS(
        SUMMARIZECOLUMNS(
            dim_shift[shift_id],
            FILTER(
                dim_date,
                dim_date[date_id] >= 20240301 && dim_date[date_id] <= 20240331
            ),
            "record_count", COUNTROWS(fact_production),
            "total_tons", SUM(fact_production[tons_mined]),
            "avg_tons", ROUND(AVERAGE(fact_production[tons_mined]), 2),
            "unique_operators", DISTINCTCOUNT(fact_production[operator_id])
        ),
        "shift_name",
            SWITCH(
                [shift_id],
                1, "Утренняя",
                2, "Дневная",
                3, "Ночная"
            )
    )
ORDER BY [shift_id]
```
### Результат
```
shift_id|shift_name|count_of_shifts|sum_of_tons|average_tons|count_of_operators|
--------+----------+---------------+-----------+------------+------------------+
       1|Утренняя  |            237|   23367.34|       98.60|                 8|
       2|Дневная   |            235|   22826.77|       97.14|                 8|

```

## Задание 4
### Текст задания
Бизнес-задача: Механик хочет увидеть для каждого оборудования все причины простоев за март 2024, объединённые в одну строку, и суммарную длительность.

Требования:

Группировка по equipment_name
Используйте STRING_AGG (SQL) / CONCATENATEX (DAX) для объединения уникальных причин простоев через «; »
Добавьте суммарную длительность простоев (SUM duration_min)
Добавьте количество инцидентов простоев
Отсортируйте по суммарной длительности (убывание)
### Решение
```
EVALUATE
VAR march_downtime =
    SUMMARIZE(
        FILTER(
            fact_equipment_downtime,
            fact_equipment_downtime[date_id] >= 20240301
                && fact_equipment_downtime[date_id] <= 20240331
        ),
        dim_equipment[equipment_name]
    )
RETURN
    ADDCOLUMNS(
        march_downtime,
        "reasons",
            CONCATENATEX(
                VALUES(dim_downtime_reason[reason_name]),
                dim_downtime_reason[reason_name],
                "; ",
                dim_downtime_reason[reason_name], ASC
            ),
        "total_min", SUM(fact_equipment_downtime[duration_min]),
        "incidents", COUNTROWS(fact_equipment_downtime)
    )
ORDER BY [total_min] DESC

SELECT
    e.equipment_name,
    STRING_AGG(DISTINCT dr.reason_name, '; ' ORDER BY dr.reason_name) AS reasons,
    SUM(fd.duration_min) AS total_min,
    COUNT(*) AS incidents
FROM fact_equipment_downtime fd
JOIN dim_equipment e ON fd.equipment_id = e.equipment_id
JOIN dim_downtime_reason dr ON fd.reason_id = dr.reason_id
WHERE fd.date_id BETWEEN 20240301 AND 20240331
GROUP BY e.equipment_name
ORDER BY total_min DESC;

```
### Результат
```
equipment_name|reasons                                                                                                            |total_min|incidents|
--------------+-------------------------------------------------------------------------------------------------------------------+---------+---------+
ПДМ-004       |Аварийный ремонт; Заправка топливом; Ожидание транспорта; Плановое техническое обслуживание                        |  1514.90|       15|
ПДМ-001       |Заправка топливом; Ожидание транспорта; Отсутствие оператора; Перегрев двигателя; Плановое техническое обслуживание|  1289.56|       14|
ПДМ-002       |Заправка топливом; Ожидание транспорта; Плановое техническое обслуживание                                          |  1217.46|       14|
Самосвал-001  |Заправка топливом; Ожидание погрузки; Отсутствие оператора; Плановое техническое обслуживание                      |  1033.94|       12|
Самосвал-004  |Заправка топливом; Плановое техническое обслуживание                                                               |   750.00|       10|
ПДМ-003       |Заправка топливом; Плановое техническое обслуживание                                                               |   750.00|       10|
ПДМ-006       |Заправка топливом; Плановое техническое обслуживание                                                               |   750.00|       10|
Самосвал-002  |Заправка топливом; Плановое техническое обслуживание                                                               |   750.00|       10|

```

## Задание 5
### Текст задания
Бизнес-задача: Для ежедневного отчёта необходимо преобразовать суррогатный ключ date_id (INTEGER) в читаемый формат даты и отформатировать числовые значения.

Требования:

Преобразуйте date_id в дату (TO_DATE / DATEVALUE)
Отформатируйте дату как «DD.MM.YYYY» (TO_CHAR / FORMAT)
Суммарную добычу отформатируйте как строку с разделителем тысяч (TO_CHAR / FORMAT)
Группировка по date_id, фильтр: первая неделя марта 2024 (20240301-20240307)
### Решение
```
EVALUATE
    ADDCOLUMNS(
        SUMMARIZECOLUMNS(
            dim_date[date_id],
			FILTER(
            dim_date,
            dim_date[date_id] >= 20240301
                && dim_date[date_id] <= 20240331
       		),
			"total_tons",SUM(fact_production[tons_mined])
		),
		"formated_date_id",FORMAT(DATEVALUE( LEFT([date_id], 4) & "-" & MID([date_id], 5, 2) & "-" & RIGHT([date_id], 2) ),"DD.MM.YYYY"),
		"formated_tons",FORMAT([total_tons],"Standard")
	)
ORDER BY [date_id]

```
### Результат
```
dim_date[date_id]	[total_tons]	[formated_date_id]	[formated_tons]
20240301	1529.07	01.03.2024	1 529,07
20240302	1114.24	02.03.2024	1 114,24
20240303	933.2	03.03.2024	933,20
20240304	1815.09	04.03.2024	1 815,09
20240305	1801.91	05.03.2024	1 801,91
20240306	1692.82	06.03.2024	1 692,82
20240307	1688.65	07.03.2024	1 688,65
20240308	1794.3	08.03.2024	1 794,30
20240309	1038.6	09.03.2024	1 038,60
20240310	949.04	10.03.2024	949,04
20240311	1758.81	11.03.2024	1 758,81
20240312	1790.81	12.03.2024	1 790,81
20240313	1783.4	13.03.2024	1 783,40
20240314	1601.14	14.03.2024	1 601,14
20240315	1682.48	15.03.2024	1 682,48
20240316	1074.7	16.03.2024	1 074,70
20240317	947.43	17.03.2024	947,43
20240318	1671.82	18.03.2024	1 671,82
20240319	1755.51	19.03.2024	1 755,51
20240320	1582.64	20.03.2024	1 582,64
20240321	1612.26	21.03.2024	1 612,26
20240322	1889.08	22.03.2024	1 889,08
20240323	995.77	23.03.2024	995,77
20240324	1025.89	24.03.2024	1 025,89
20240325	1722.02	25.03.2024	1 722,02
20240326	1805.4	26.03.2024	1 805,40
20240327	1748.37	27.03.2024	1 748,37
20240328	1760.29	28.03.2024	1 760,29
20240329	1634.23	29.03.2024	1 634,23
20240330	964.44	30.03.2024	964,44
20240331	1030.7	31.03.2024	1 030,70

```

## Задание 6
### Текст задания
Бизнес-задача: Инженер качества готовит ежедневный отчёт за март 2024: количество проб по категориям качества и процент «хороших» проб (Fe >= 60%).

Требования:

Группировка по дате (full_date из dim_date)
Для каждой даты подсчитайте:
Количество проб с Fe >= 65 (богатая руда)
Количество проб с 55 <= Fe < 65 (средняя руда)
Количество проб с Fe < 55 (бедная руда)
Общее количество проб
Процент хороших проб (Fe >= 60), используя NULLIF для защиты от деления на 0
Отсортируйте по дате
Подсказка SQL:

SUM(CASE WHEN fe_content >= 65 THEN 1 ELSE 0 END) AS rich_ore,
ROUND(100.0 * SUM(CASE WHEN fe_content >= 60 THEN 1 ELSE 0 END)
    / NULLIF(COUNT(*), 0), 1) AS good_pct
Подсказка DAX: Используйте CALCULATE(COUNTROWS(...), фильтр) и DIVIDE.
### Решение
```
EVALUATE
    ADDCOLUMNS(
        SUMMARIZECOLUMNS(
            dim_date[full_date],
            FILTER(
                dim_date,
                dim_date[date_id] >= 20240301 && dim_date[date_id] <= 20240331
            )
        ),
        "rich_ore",
            CALCULATE(
                COUNTROWS(fact_ore_quality),
                fact_ore_quality[fe_content] >= 65
            ),
        "medium_ore",
            CALCULATE(
                COUNTROWS(fact_ore_quality),
                fact_ore_quality[fe_content] >= 55
                    && fact_ore_quality[fe_content] < 65
            ),
        "poor_ore",
            CALCULATE(
                COUNTROWS(fact_ore_quality),
                fact_ore_quality[fe_content] < 55
            ),
        "total", COUNTROWS(fact_ore_quality),
        "good_pct",
            ROUND(
                DIVIDE(
                    CALCULATE(
                        COUNTROWS(fact_ore_quality),
                        fact_ore_quality[fe_content] >= 60
                    ),
                    COUNTROWS(fact_ore_quality),
                    0
                ) * 100,
                1
            )
    )
ORDER BY [full_date]

```
### Результат
```
dim_date[full_date]	[rich_ore]	[medium_ore]	[poor_ore]	[total]	[good_pct]
Fri, 01 Mar 2024 00:00:00		2	11	5325	
Sat, 02 Mar 2024 00:00:00			9	5325	
Sun, 03 Mar 2024 00:00:00				5325	
Mon, 04 Mar 2024 00:00:00		7	5	5325	0.1
Tue, 05 Mar 2024 00:00:00		5	6	5325	
Wed, 06 Mar 2024 00:00:00		7	5	5325	0.1
Thu, 07 Mar 2024 00:00:00		7	5	5325	0.1
Fri, 08 Mar 2024 00:00:00		8	5	5325	0.1
Sat, 09 Mar 2024 00:00:00		6	3	5325	0.1
Sun, 10 Mar 2024 00:00:00				5325	
Mon, 11 Mar 2024 00:00:00		5	7	5325	
Tue, 12 Mar 2024 00:00:00		4	8	5325	
Wed, 13 Mar 2024 00:00:00		8	4	5325	
Thu, 14 Mar 2024 00:00:00		8	4	5325	0.1
Fri, 15 Mar 2024 00:00:00		5	8	5325	
Sat, 16 Mar 2024 00:00:00		2	6	5325	
Sun, 17 Mar 2024 00:00:00				5325	
Mon, 18 Mar 2024 00:00:00		4	8	5325	
Tue, 19 Mar 2024 00:00:00		4	8	5325	0.1
Wed, 20 Mar 2024 00:00:00		5	8	5325	
Thu, 21 Mar 2024 00:00:00		10	2	5325	
Fri, 22 Mar 2024 00:00:00		5	8	5325	0.1
Sat, 23 Mar 2024 00:00:00		6	3	5325	0.1
Sun, 24 Mar 2024 00:00:00				5325	
Mon, 25 Mar 2024 00:00:00		5	8	5325	
Tue, 26 Mar 2024 00:00:00	2	8	2	5325	0
Wed, 27 Mar 2024 00:00:00		6	5	5325	0
Thu, 28 Mar 2024 00:00:00		2	11	5325	
Fri, 29 Mar 2024 00:00:00		8	5	5325	0.1
Sat, 30 Mar 2024 00:00:00		7		5325	0.1
Sun, 31 Mar 2024 00:00:00				5325	

```

## Задание 7
### Текст задания
Бизнес-задача: Для каждого оператора за март 2024 рассчитать производственные KPI с защитой от NULL и деления на ноль.

Требования:

Группировка по оператору (last_name, first_name)
Рассчитайте:
Суммарная добыча (тонн)
Суммарный расход топлива (литров), подставляя 0 вместо NULL через COALESCE
Производительность: тонн / рейс — через NULLIF для защиты от деления на 0
Расход топлива на тонну — через NULLIF или DIVIDE
Максимальная эффективность: GREATEST между производительностью за смену 1 и смену 2
Все KPI округлите до 2 знаков (ROUND)
Отсортируйте по производительности (убывание)
Подсказка SQL:
### Решение
```
EVALUATE
ADDCOLUMNS(
    SUMMARIZECOLUMNS(
        dim_operator[last_name],
        dim_operator[first_name],
        FILTER(
            dim_date,
            dim_date[date_id] >= 20240301 && dim_date[date_id] <= 20240331
        )
    ),
    "Суммарная добыча (тонн)", 
        ROUND(
            CALCULATE(SUM(fact_production[tons_mined])),
            2
        ),
    
    "Суммарный расход топлива (литров)", 
        ROUND(
            COALESCE(
                CALCULATE(SUM(fact_production[fuel_consumed_l])),
                0
            ),
            2
        ),
    
    "Количество рейсов", 
        CALCULATE(COUNTROWS(fact_production)),
    
    "Производительность (тонн/рейс)", 
        ROUND(
            DIVIDE(
                CALCULATE(SUM(fact_production[tons_mined])),
                CALCULATE(COUNTROWS(fact_production)),
                0
            ),
            2
        ),
    
    "Расход топлива на тонну (л/т)", 
        VAR TotalFuel = COALESCE(CALCULATE(SUM(fact_production[fuel_consumed_l])), 0)
        VAR TotalTonnage = CALCULATE(SUM(fact_production[tons_mined]))
        RETURN
            ROUND(
                IF(
                    TotalTonnage = 0 || ISBLANK(TotalTonnage),
                    0,
                    TotalFuel / TotalTonnage
                ),
                2
            ),
    
    "Производительность смена 1", 
        ROUND(
            DIVIDE(
                CALCULATE(
                    SUM(fact_production[tons_mined]),
                    fact_production[shift_id] = 1
                ),
                CALCULATE(
                    COUNTROWS(fact_production),
                    fact_production[shift_id] = 1
                ),
                0
            ),
            2
        ),
    
    "Производительность смена 2", 
        ROUND(
            DIVIDE(
                CALCULATE(
                    SUM(fact_production[tons_mined]),
                    fact_production[shift_id] = 2
                ),
                CALCULATE(
                    COUNTROWS(fact_production),
                    fact_production[shift_id] = 2
                ),
                0
            ),
            2
        ),
    
    "Максимальная эффективность (тонн/рейс)", 
        VAR Shift1Perf =
            DIVIDE(
                CALCULATE(
                    SUM(fact_production[tons_mined]),
                    fact_production[shift_id] = 1
                ),
                CALCULATE(
                    COUNTROWS(fact_production),
                    fact_production[shift_id] = 1
                ),
                0
            )
        VAR Shift2Perf =
            DIVIDE(
                CALCULATE(
                    SUM(fact_production[tons_mined]),
                    fact_production[shift_id] = 2
                ),
                CALCULATE(
                    COUNTROWS(fact_production),
                    fact_production[shift_id] = 2
                ),
                0
            )
        RETURN
            ROUND(
                IF(Shift1Perf >= Shift2Perf, Shift1Perf, Shift2Perf),
                2
            )
)
ORDER BY 
    [Производительность (тонн/рейс)] DESC

```
### Результат
```
dim_operator[last_name]	dim_operator[first_name]	[Суммарная добыча (тонн)]	[Суммарный расход топлива (литров)]	[Количество рейсов]	[Производительность (тонн/рейс)]	[Расход топлива на тонну (л/т)]	[Производительность смена 1]	[Производительность смена 2]	[Максимальная эффективность (тонн/рейс)]
Морозов	Владимир	866408.31	1251838.94	8384	103.34	1.44	103.48	103.2	103.48
Петров	Сергей	866408.31	1251838.94	8384	103.34	1.44	103.48	103.2	103.48
Сидоров	Дмитрий	866408.31	1251838.94	8384	103.34	1.44	103.48	103.2	103.48
Козлов	Андрей	866408.31	1251838.94	8384	103.34	1.44	103.48	103.2	103.48
Новиков	Михаил	866408.31	1251838.94	8384	103.34	1.44	103.48	103.2	103.48
Иванов	Алексей	866408.31	1251838.94	8384	103.34	1.44	103.48	103.2	103.48
Волков	Николай	866408.31	1251838.94	8384	103.34	1.44	103.48	103.2	103.48
Соловьёв	Павел	866408.31	1251838.94	8384	103.34	1.44	103.48	103.2	103.48
Лебедев	Евгений	866408.31	1251838.94	8384	103.34	1.44	103.48	103.2	103.48
Кузнецов	Игорь	866408.31	1251838.94	8384	103.34	1.44	103.48	103.2	103.48

```

## Задание 8
### Текст задания
Бизнес-задача: Администратор данных хочет оценить полноту данных в таблице fact_ore_quality за март 2024: в каких столбцах больше всего пропусков?

Требования:

Подсчитайте для каждого столбца (sio2_content, al2o3_content, moisture, density, sample_weight_kg):
Количество NOT NULL значений
Количество NULL значений
Процент заполненности
Выведите результат в одну строку (один запрос)
Фильтр: date_id BETWEEN 20240301 AND 20240331
### Решение
```

EVALUATE
ROW(
    "total_rows",
        CALCULATE(
            COUNTROWS(fact_ore_quality),
            fact_ore_quality[date_id] >= 20240301,
            fact_ore_quality[date_id] <= 20240331
        ),
    "sio2_filled",
        CALCULATE(
            COUNT(fact_ore_quality[sio2_content]),
            fact_ore_quality[date_id] >= 20240301,
            fact_ore_quality[date_id] <= 20240331
        ),
    "sio2_null",
        CALCULATE(
            COUNTROWS(fact_ore_quality),
            fact_ore_quality[date_id] >= 20240301,
            fact_ore_quality[date_id] <= 20240331
        )
        - CALCULATE(
            COUNT(fact_ore_quality[sio2_content]),
            fact_ore_quality[date_id] >= 20240301,
            fact_ore_quality[date_id] <= 20240331
        ),
    "al2o3_filled",
        CALCULATE(
            COUNT(fact_ore_quality[al2o3_content]),
            fact_ore_quality[date_id] >= 20240301,
            fact_ore_quality[date_id] <= 20240331
        ),
    "moisture_filled",
        CALCULATE(
            COUNT(fact_ore_quality[moisture]),
            fact_ore_quality[date_id] >= 20240301,
            fact_ore_quality[date_id] <= 20240331
        )
)
```
### Результат
```
[total_rows]	[sio2_filled]	[sio2_null]	[al2o3_filled]	[moisture_filled]
300	300	0	300	300

```

## Задание 9
### Текст задания
Бизнес-задача: Подготовить комплексный KPI-отчёт по каждому оборудованию за март 2024 для совещания у директора.

Требования:

Группировка по оборудованию (equipment_name) и типу (type_name)
Рассчитайте:
Количество отработанных смен
Суммарная добыча (тонн), округлить до 1 знака
Суммарные часы работы, округлить до 1 знака
Производительность (тонн/час) — с NULLIF / DIVIDE, округлить до 2 знаков
Коэффициент использования (%) = часы / (смены * 8) * 100, округлить до 1 знака
Расход топлива на тонну — с COALESCE + NULLIF / DIVIDE, округлить до 3 знаков
Категория эффективности: «Высокая» (> 20 т/ч), «Средняя» (> 12 т/ч), «Низкая»
Статус данных: «Полные» если все fuel_consumed_l заполнены, иначе «Неполные»
Отсортируйте по производительности (убывание)
Подсказка SQL: Это объединяет все функции модуля — ROUND, NULLIF, COALESCE, CASE WHEN, SUM, COUNT.

Подсказка DAX: Используйте SUMMARIZE + ADDCOLUMNS + DIVIDE + SWITCH(TRUE(), ...) + ROUND.
### Решение
```
EVALUATE
    ADDCOLUMNS(
        SUMMARIZECOLUMNS(
            dim_equipment[equipment_name],
            dim_equipment_type[type_name],
            FILTER(
                dim_date,
                dim_date[date_id] >= 20240301 && dim_date[date_id] <= 20240331
            ),
            "shift_count", COUNTROWS(fact_production),
            "total_tons", ROUND(SUM(fact_production[tons_mined]), 1),
            "total_hours", ROUND(SUM(fact_production[operating_hours]), 1),
            "productivity",
                ROUND(
                    DIVIDE(
                        SUM(fact_production[tons_mined]),
                        SUM(fact_production[operating_hours]),
                        0
                    ),
                    2
                ),
            "utilization",
                ROUND(
                    DIVIDE(
                        SUM(fact_production[operating_hours]),
                        COUNTROWS(fact_production) * 8,
                        0
                    ) * 100,
                    1
                ),
            "fuel_per_ton",
                ROUND(
                    DIVIDE(
                        SUM(fact_production[fuel_consumed_l]),
                        SUM(fact_production[tons_mined]),
                        0
                    ),
                    3
                )
        ),
        "efficiency_category",
            SWITCH(
                TRUE(),
                [productivity] > 20, "Высокая",
                [productivity] > 12, "Средняя",
                "Низкая"
            )
    )
ORDER BY [productivity] DESC

```
### Результат
```
dim_equipment[equipment_name]	dim_equipment_type[type_name]	[shift_count]	[total_tons]	[total_hours]	[productivity]	[utilization]	[fuel_per_ton]	[efficiency_category]
Самосвал-001	Шахтный самосвал	59	8796.2	640.2	13.74	135.6	1.358	Средняя
Самосвал-002	Шахтный самосвал	60	8744.1	644.3	13.57	134.2	1.45	Средняя
Самосвал-004	Шахтный самосвал	58	8203.2	628.4	13.05	135.4	1.37	Средняя
ПДМ-004	Погрузочно-доставочная машина	59	4270.3	626.7	6.81	132.8	1.547	Низкая
ПДМ-006	Погрузочно-доставочная машина	60	4378.4	645.8	6.78	134.5	1.591	Низкая
ПДМ-001	Погрузочно-доставочная машина	57	3909	615.3	6.35	134.9	1.763	Низкая
ПДМ-002	Погрузочно-доставочная машина	60	4069.7	645.2	6.31	134.4	1.708	Низкая
ПДМ-003	Погрузочно-доставочная машина	59	3823.2	630.9	6.06	133.7	1.917	Низкая

```

## Задание 10
### Текст задания

### Решение
```
WITH categorized AS (
    SELECT
        de.equipment_name,
        COALESCE(fd.duration_min, 0) AS duration_safe,
        CASE
            WHEN COALESCE(fd.duration_min, 0) > 480 THEN 'Критический'
            WHEN COALESCE(fd.duration_min, 0) between 120 and 480 THEN 'Длительный'
            WHEN COALESCE(fd.duration_min, 0) between 30 and 120 THEN 'Средний'
            WHEN COALESCE(fd.duration_min, 0) < 30 THEN 'Короткий'
        END AS category,
        case fd.is_planned 
        	when true then 'Плановый'
        	when false then 'Неплановый'
        end as planned,
        case 
        	when fd.end_time is null then 'Незавершен'
        	else 'Завершен'
        end as ended
    FROM fact_equipment_downtime fd join dim_equipment de on fd.equipment_id=de.equipment_id
)
SELECT category, COUNT(*),SUM(duration_safe) as total_minutes, ROUND(SUM(duration_safe) / 60.0, 1) AS total_hours, ROUND(100*SUM(duration_safe)/(select SUM(duration_safe) from categorized),2) as percent
FROM categorized GROUP BY category order by total_minutes desc;

```
### Результат
```
category   |count|total_minutes|total_hours|percent|
-----------+-----+-------------+-----------+-------+
Длительный |  292|     93891.53|     1564.9|  63.68|
Средний    | 1440|     51425.47|      857.1|  34.88|
Критический|    3|      2130.00|       35.5|   1.44|

```