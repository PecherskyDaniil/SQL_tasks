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

### Решение
```


```
### Результат
```


```

## Задание 5
### Текст задания

### Решение
```


```
### Результат
```


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