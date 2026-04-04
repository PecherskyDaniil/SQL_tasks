## Задание 1
### Текст задания
Бизнес-задача: Главный инженер хочет быстро получить сводку по основным показателям предприятия.

Требования:

Создайте анонимный блок DO $$ ... END $$, который:
Объявит переменные для: количества шахт, общей добычи за январь 2025, среднего содержания Fe, количества простоев
Заполнит переменные данными из соответствующих таблиц
Выведет форматированный отчёт через RAISE NOTICE
Формат вывода:
```
===== Сводка по предприятию «Руда+» =====
Количество шахт: N
Добыча за январь 2025: XXXXX т
Среднее содержание Fe: XX.X %
Количество простоев: N
==========================================
```
### Решение
```
DO $$ 
DECLARE
    v_mine_count int;
    v_total_production_jan_2025 numeric;
    v_avg_fe_percent numeric;
    v_downtime_count int;
BEGIN
    SELECT COUNT(*) INTO v_mine_count FROM dim_mine;
    SELECT COALESCE(SUM(fp.tons_mined), 0) INTO v_total_production_jan_2025
    FROM fact_production fp
    JOIN dim_date dd ON fp.date_id = dd.date_id
    WHERE dd.year = 2025 AND dd.month = 1;
    SELECT ROUND(AVG(fe_content), 1) INTO v_avg_fe_percent
    FROM fact_ore_quality foq
    JOIN dim_date dd ON foq.date_id = dd.date_id
    WHERE dd.year = 2025 AND dd.month = 1;
    SELECT COUNT(*) INTO v_downtime_count
    FROM fact_equipment_downtime fd
    JOIN dim_date dd ON fd.date_id = dd.date_id
    WHERE dd.year = 2025 AND dd.month = 1;
    RAISE NOTICE '===== Сводка по предприятию «Руда+» =====';
    RAISE NOTICE 'Количество шахт: %', v_mine_count;
    RAISE NOTICE 'Добыча за январь 2025: % т', v_total_production_jan_2025;
    RAISE NOTICE 'Среднее содержание Fe: %', v_avg_fe_percent;
    RAISE NOTICE 'Количество простоев: %', v_downtime_count;
    RAISE NOTICE '==========================================';
END $$;
```
### Результат
```
===== Сводка по предприятию «Руда+» =====
Количество шахт: 2
Добыча за январь 2025: 44891.66 т
Среднее содержание Fe: 53.7
Количество простоев: 117
==========================================
```

## Задание 2
### Текст задания
Бизнес-задача: Необходимо классифицировать оборудование по возрасту для планирования замены.

Требования:

Создайте анонимный блок, который для каждой единицы оборудования из dim_equipment:
Вычислит «возраст» оборудования (разница между текущей датой и commissioning_date в годах)
Классифицирует через IF/ELSIF:
< 2 лет — «Новое»
2-5 лет — «Рабочее»
5-10 лет — «Требует внимания»
10 лет — «На замену»

Выведет: название, тип, возраст, категорию
В конце выведите сводку: сколько оборудования в каждой категории
Подсказка: Если в dim_equipment нет столбца commissioning_date, используйте случайную генерацию даты: CURRENT_DATE - (random() * 4000)::INT для тестовых целей.
### Решение
```
DO $$ 
DECLARE
    v_rec RECORD;
    v_age_years INT;
    v_category TEXT;

    v_cnt_new INT := 0;
    v_cnt_working INT := 0;
    v_cnt_attention INT := 0;
    v_cnt_replace INT := 0;
BEGIN
    RAISE NOTICE '=== Отчет по классификации оборудования ===';
    RAISE NOTICE '% | % | % | %', 
        RPAD('Название', 20), RPAD('Тип', 15), RPAD('Возраст', 8), 'Категория';
    RAISE NOTICE '------------------------------------------------------------';
    FOR v_rec IN (
        SELECT 
            equipment_name, 
            COALESCE(commissioning_date, CURRENT_DATE - (random() * 4000)::INT) as c_date 
        FROM dim_equipment
    ) 
    LOOP
        v_age_years := EXTRACT(YEAR FROM AGE(CURRENT_DATE, v_rec.c_date));
        IF v_age_years < 2 THEN
            v_category := 'Новое';
            v_cnt_new := v_cnt_new + 1;
        ELSIF v_age_years BETWEEN 2 AND 5 THEN
            v_category := 'Рабочее';
            v_cnt_working := v_cnt_working + 1;
        ELSIF v_age_years > 5 AND v_age_years <= 10 THEN
            v_category := 'Требует внимания';
            v_cnt_attention := v_cnt_attention + 1;
        ELSE
            v_category := 'На замену';
            v_cnt_replace := v_cnt_replace + 1;
        END IF;
        RAISE NOTICE '% | % | % лет | %', 
            RPAD(v_rec.equipment_name, 20), 
            RPAD('Оборудование', 15), 
            LPAD(v_age_years::text, 7), 
            v_category;
    END LOOP;
    RAISE NOTICE '------------------------------------------------------------';
    RAISE NOTICE 'ИТОГОВАЯ СВОДКА:';
    RAISE NOTICE '- Новое: %', v_cnt_new;
```
### Результат
```
=== Отчет по классификации оборудования ===
Название             | Тип             | Возраст  | Категория
------------------------------------------------------------
ПДМ-001              | Оборудование    |       6 лет | Требует внимания
ПДМ-002              | Оборудование    |       6 лет | Требует внимания
ПДМ-003              | Оборудование    |       7 лет | Требует внимания
ПДМ-004              | Оборудование    |       4 лет | Рабочее
ПДМ-005              | Оборудование    |       8 лет | Требует внимания
ПДМ-006              | Оборудование    |       4 лет | Рабочее
Самосвал-001         | Оборудование    |       5 лет | Рабочее
Самосвал-002         | Оборудование    |       5 лет | Рабочее
Самосвал-003         | Оборудование    |       6 лет | Требует внимания
Самосвал-004         | Оборудование    |       4 лет | Рабочее
Самосвал-005         | Оборудование    |       7 лет | Требует внимания
Вагонетка-001        | Оборудование    |      10 лет | Требует внимания
Вагонетка-002        | Оборудование    |      10 лет | Требует внимания
Вагонетка-003        | Оборудование    |       8 лет | Требует внимания
Вагонетка-004        | Оборудование    |       8 лет | Требует внимания
Скип-001             | Оборудование    |      15 лет | На замену
Скип-002             | Оборудование    |      10 лет | Требует внимания
Скип-003             | Оборудование    |      13 лет | На замену
------------------------------------------------------------
ИТОГОВАЯ СВОДКА:
- Новое: 0
- Рабочее: 5
- Требует внимания: 11
- На замену: 2
============================================================

```

## Задание 3
### Текст задания
Бизнес-задача: Построить подневной анализ добычи за первые 2 недели января 2025 с нарастающим итогом.

Требования:

Используйте цикл FOR i IN 1..14 для перебора дней
Для каждого дня:
Получите суммарную добычу (SUM(tons_mined))
Вычислите нарастающий итог
Определите, является ли день «рекордным» (добыча выше средней за предыдущие дни)
Выведите таблицу:
День 01: 1234.5 т | Нарастающий: 1234.5 т | РЕКОРД
День 02: 987.3 т  | Нарастающий: 2221.8 т |
...
В конце выведите: общий итог, средняя добыча в день, лучший день
### Решение
```
DO $$ 
DECLARE
    v_day INT:=0;
    v_total_tons numeric;
    v_cumulative_tons numeric:=0.0;
	v_avg_prev_tons numeric;
	v_ach TEXT;
	v_best_day INT;
	v_best_prod numeric:=0;
	v_rec RECORD;
begin
	RAISE NOTICE '=============================================';
	for v_rec in (
		select 
			fp.date_id,SUM(tons_mined) as total_tons,
			AVG(SUM(tons_mined)) over (ORDER BY fp.date_id ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) as avg_prev
			from fact_production fp
			where fp.date_id between 20240101 and 20240114
			group by fp.date_id
			order by fp.date_id
	) loop
		v_day:=v_day+1;
		v_total_tons:=v_rec.total_tons;
		v_cumulative_tons:=v_cumulative_tons+v_total_tons;
		v_avg_prev_tons:=v_rec.avg_prev;
		if v_total_tons > v_rec.avg_prev then 
			v_ach:='РЕКОРД';
		else
			v_ach:='';
		end if; 
		if v_total_tons>v_best_prod then
			v_best_prod=v_total_tons;
			v_best_day=v_day;
		end if;
		RAISE NOTICE 'День %: % т.| Нарастающий: % т. |%', 
            v_day,
			v_total_tons,
			v_cumulative_tons,
			v_ach;
	end loop;
	RAISE NOTICE 'ИТОГО % т.| СРЕДНЕЕ В ДЕНЬ % т. |ЛУЧШИЙ ДЕНЬ - %',
			v_cumulative_tons,
			ROUND(v_avg_prev_tons,2),
			v_best_day;
end $$;
```
### Результат
```
=============================================
День 1: 1637.73 т.| Нарастающий: 1637.73 т. |
День 2: 1564.57 т.| Нарастающий: 3202.30 т. |
День 3: 1521.55 т.| Нарастающий: 4723.85 т. |
День 4: 1570.59 т.| Нарастающий: 6294.44 т. |
День 5: 1407.01 т.| Нарастающий: 7701.45 т. |
День 6: 958.50 т.| Нарастающий: 8659.95 т. |
День 7: 943.90 т.| Нарастающий: 9603.85 т. |
День 8: 1431.53 т.| Нарастающий: 11035.38 т. |РЕКОРД
День 9: 1620.49 т.| Нарастающий: 12655.87 т. |РЕКОРД
День 10: 1665.62 т.| Нарастающий: 14321.49 т. |РЕКОРД
День 11: 1555.50 т.| Нарастающий: 15876.99 т. |РЕКОРД
День 12: 1726.35 т.| Нарастающий: 17603.34 т. |РЕКОРД
День 13: 861.18 т.| Нарастающий: 18464.52 т. |
День 14: 972.16 т.| Нарастающий: 19436.68 т. |
ИТОГО 19436.68 т.| СРЕДНЕЕ В ДЕНЬ 1420.35 т. |ЛУЧШИЙ ДЕНЬ - 12
```

## Задание 4
### Текст задания
Бизнес-задача: Определить, к какому дню января суммарные простои превысили критический порог.

Требования:

Задайте порог: v_threshold := 500 (часов суммарных простоев)
Используйте цикл WHILE, начиная с 20250101
На каждой итерации:
Получите суммарные простои за текущий день (из fact_equipment_downtime)
Добавьте к накопленному итогу
Если порог достигнут — выведите дату и выйдите из цикла (EXIT)
Если порог не достигнут — используйте CONTINUE для перехода к следующему дню
Если порог не достигнут до конца месяца, выведите сообщение об этом
### Решение
```
DO $$ 
DECLARE
    v_threshold numeric := 500.0;
    v_current_date date := '2025-01-01';
    v_end_date date := '2025-01-31';
    v_daily_hours numeric := 0;
    v_cumulative_hours numeric := 0;
    v_date_id int;
    v_threshold_reached boolean := false;
BEGIN
    RAISE NOTICE '=== Анализ критического порога простоев (Порог: % ч.) ===', v_threshold;

    WHILE v_current_date <= v_end_date LOOP

        v_date_id := to_char(v_current_date, 'YYYYMMDD')::int;

        SELECT COALESCE(SUM(duration_min), 0) / 60.0 INTO v_daily_hours
        FROM fact_equipment_downtime
        WHERE date_id = v_date_id;

        v_cumulative_hours := v_cumulative_hours + v_daily_hours;

        IF v_cumulative_hours >= v_threshold THEN
            RAISE NOTICE 'КРИТИЧЕСКИЙ ПОРОГ ДОСТИГНУТ!';
            RAISE NOTICE 'Дата: % | Накоплено: % ч.', v_current_date, ROUND(v_cumulative_hours, 1);
            v_threshold_reached := true;
            EXIT;
        END IF;

        v_current_date := v_current_date + 1;
        CONTINUE; 
    END LOOP;

    IF NOT v_threshold_reached THEN
        RAISE NOTICE 'За январь порог в % ч. достигнут не был. Итог: % ч.', 
                     v_threshold, ROUND(v_cumulative_hours, 1);
    END IF;

END $$;

```
### Результат
```
=== Анализ критического порога простоев (Порог: 500.0 ч.) ===
За январь порог в 500.0 ч. достигнут не был. Итог: 153.9 ч.
```

## Задание 5
### Текст задания
Бизнес-задача: Для каждого типа датчика определить количество показаний и статус работы.

Требования:

Получите массив уникальных sensor_type_id из dim_sensor_type
Используйте FOREACH для перебора типов датчиков
Для каждого типа:
Подсчитайте количество датчиков этого типа
Подсчитайте количество показаний телеметрии за январь 2025
Определите статус через CASE:
Показаний на датчик > 1000 — «Активно работает»
Показаний на датчик 100-1000 — «Нормальная работа»
Показаний на датчик 1-99 — «Редкие показания»
0 показаний — «Нет данных»
Выведите результат в формате
### Решение
```
DO $$ 
DECLARE
    v_type_ids int[];
    v_current_id int;
    v_type_name text;
    v_sensor_count int;
    v_telemetry_count int;
    v_avg_readings numeric;
    v_status text;
BEGIN
    SELECT array_agg(sensor_type_id) INTO v_type_ids FROM dim_sensor_type;

    RAISE NOTICE '=== Отчет по активности типов датчиков (Январь 2025) ===';
    FOREACH v_current_id IN ARRAY v_type_ids LOOP
        
        SELECT type_name INTO v_type_name FROM dim_sensor_type WHERE sensor_type_id = v_current_id;
        SELECT COUNT(*) INTO v_sensor_count FROM dim_sensor WHERE sensor_type_id = v_current_id;

        SELECT COUNT(*) INTO v_telemetry_count
        FROM fact_equipment_telemetry fet
        JOIN dim_sensor ds ON fet.sensor_id = ds.sensor_id
        JOIN dim_date dd ON fet.date_id = dd.date_id
        WHERE ds.sensor_type_id = v_current_id 
          AND dd.year = 2025 AND dd.month = 1;
        v_avg_readings := v_telemetry_count / NULLIF(v_sensor_count, 0);
        v_status := CASE 
            WHEN v_telemetry_count = 0 THEN 'Нет данных'
            WHEN v_avg_readings > 1000 THEN 'Активно работает'
            WHEN v_avg_readings BETWEEN 100 AND 1000 THEN 'Нормальная работа'
            ELSE 'Редкие показания'
        END;
        RAISE NOTICE 'Тип: % | Датчиков: % | Показаний: % | Статус: %', 
            RPAD(v_type_name, 15), 
            LPAD(v_sensor_count::text, 3), 
            LPAD(v_telemetry_count::text, 7), 
            v_status;
    END LOOP;
    RAISE NOTICE '=======================================================';
END $$;
```
### Результат
```
=== Отчет по активности типов датчиков (Январь 2025) ===
Тип: Датчик температ | Датчиков:   9 | Показаний:       0 | Статус: Нет данных
Тип: Датчик температ | Датчиков:   0 | Показаний:       0 | Статус: Нет данных
Тип: Датчик вибрации | Датчиков:   9 | Показаний:       0 | Статус: Нет данных
Тип: Датчик скорости | Датчиков:   6 | Показаний:       0 | Статус: Нет данных
Тип: Датчик массы гр | Датчиков:   9 | Показаний:       0 | Статус: Нет данных
Тип: Датчик уровня т | Датчиков:   6 | Показаний:       0 | Статус: Нет данных
Тип: GPS-координаты  | Датчиков:   0 | Показаний:       0 | Статус: Нет данных
Тип: GPS-координаты  | Датчиков:   0 | Показаний:       0 | Статус: Нет данных
Тип: Датчик давления | Датчиков:   1 | Показаний:       0 | Статус: Нет данных
Тип: Датчик оборотов | Датчиков:   3 | Показаний:       0 | Статус: Нет данных
=======================================================
```

## Задание 6
### Текст задания
Бизнес-задача: Создать процедуру заполнения таблицы отчётов по сменам.

Требования:

Создайте таблицу report_shift_summary:
CREATE TABLE report_shift_summary (
    report_date    DATE,
    shift_name     VARCHAR(50),
    mine_name      VARCHAR(100),
    total_tons     NUMERIC(12,2),
    equipment_used INT,
    efficiency     NUMERIC(5,1),
    created_at     TIMESTAMP DEFAULT NOW()
);
Создайте анонимный блок с курсором, который:
Перебирает все даты из dim_date за 01-15 января 2025
Для каждой даты вставляет агрегированные данные по каждой комбинации смена+шахта
Рассчитывает эффективность: (operating_hours / (equipment_count * 8)) * 100
Использует GET DIAGNOSTICS для отслеживания количества вставленных строк
Выведите прогресс выполнения через RAISE NOTICE
Проверьте результат: SELECT * FROM report_shift_summary ORDER BY report_date, shift_name, mine_name
### Решение
```
DO $$ 
DECLARE
    cur_dates CURSOR FOR 
        SELECT full_date, date_id 
        FROM dim_date 
        WHERE full_date BETWEEN '2025-01-01' AND '2025-01-15'
        ORDER BY full_date;

    v_date_rec RECORD;
    v_inserted_rows INT := 0;
    v_total_inserted INT := 0;
BEGIN
    RAISE NOTICE '=== Начало формирования отчетов по сменам ===';

    FOR v_date_rec IN cur_dates LOOP

        INSERT INTO "Pechersky".report_shift_summary (
            report_date, shift_name, mine_name, total_tons, equipment_used, efficiency
        )
        SELECT 
            v_date_rec.full_date,
            ds.shift_name,
            dm.mine_name,
            SUM(fp.tons_mined) as total_tons,
            COUNT(DISTINCT fp.equipment_id) as equipment_used,
            ROUND(
                (SUM(fp.operating_hours) / NULLIF(COUNT(DISTINCT fp.equipment_id) * 8, 0)) * 100, 
                1
            ) as efficiency
        FROM fact_production fp
        JOIN dim_mine dm ON fp.mine_id = dm.mine_id
		join dim_shift ds on fp.shift_id=ds.shift_id
        WHERE fp.date_id = v_date_rec.date_id
        GROUP BY ds.shift_name, dm.mine_name;

        GET DIAGNOSTICS v_inserted_rows = ROW_COUNT;
        v_total_inserted := v_total_inserted + v_inserted_rows;

        RAISE NOTICE 'Дата % обработана. Добавлено записей: %', v_date_rec.full_date, v_inserted_rows;
    END LOOP;

    RAISE NOTICE '=== Завершено. Всего создано строк: % ===', v_total_inserted;
END $$;

SELECT * FROM "Pechersky".report_shift_summary ORDER BY report_date, shift_name, mine_name;
```
### Результат
```
=== Начало формирования отчетов по сменам ===
Дата 2025-01-01 обработана. Добавлено записей: 4
Дата 2025-01-02 обработана. Добавлено записей: 4
Дата 2025-01-03 обработана. Добавлено записей: 4
Дата 2025-01-04 обработана. Добавлено записей: 4
Дата 2025-01-05 обработана. Добавлено записей: 4
Дата 2025-01-06 обработана. Добавлено записей: 4
Дата 2025-01-07 обработана. Добавлено записей: 4
Дата 2025-01-08 обработана. Добавлено записей: 4
Дата 2025-01-09 обработана. Добавлено записей: 4
Дата 2025-01-10 обработана. Добавлено записей: 4
Дата 2025-01-11 обработана. Добавлено записей: 4
Дата 2025-01-12 обработана. Добавлено записей: 4
Дата 2025-01-13 обработана. Добавлено записей: 4
Дата 2025-01-14 обработана. Добавлено записей: 4
Дата 2025-01-15 обработана. Добавлено записей: 4
=== Завершено. Всего создано строк: 60 ===

report_date|shift_name   |mine_name       |total_tons|equipment_used|efficiency|created_at             |
-----------+-------------+----------------+----------+--------------+----------+-----------------------+
 2025-01-01|Дневная смена|Шахта "Северная"|    510.54|             5|     137.3|2026-04-04 10:40:53.056|
 2025-01-01|Дневная смена|Шахта "Южная"   |    274.64|             3|     135.5|2026-04-04 10:40:53.056|
 2025-01-01|Ночная смена |Шахта "Северная"|    470.27|             4|     135.2|2026-04-04 10:40:53.056|
 2025-01-01|Ночная смена |Шахта "Южная"   |    209.71|             2|     134.1|2026-04-04 10:40:53.056|
 2025-01-02|Дневная смена|Шахта "Северная"|    373.27|             4|     135.2|2026-04-04 10:40:53.056|
 2025-01-02|Дневная смена|Шахта "Южная"   |    324.33|             3|     137.8|2026-04-04 10:40:53.056|
 2025-01-02|Ночная смена |Шахта "Северная"|    463.62|             5|     135.2|2026-04-04 10:40:53.056|
 2025-01-02|Ночная смена |Шахта "Южная"   |    309.23|             3|     131.5|2026-04-04 10:40:53.056|
 2025-01-03|Дневная смена|Шахта "Северная"|    499.94|             5|     134.0|2026-04-04 10:40:53.056|
 2025-01-03|Дневная смена|Шахта "Южная"   |    304.69|             3|     134.8|2026-04-04 10:40:53.056|
 2025-01-03|Ночная смена |Шахта "Северная"|    531.32|             5|     133.4|2026-04-04 10:40:53.056|
 2025-01-03|Ночная смена |Шахта "Южная"   |    299.25|             3|     134.4|2026-04-04 10:40:53.056|
 2025-01-04|Дневная смена|Шахта "Северная"|    309.76|             5|     135.7|2026-04-04 10:40:53.056|
 2025-01-04|Дневная смена|Шахта "Южная"   |    177.87|             3|     132.3|2026-04-04 10:40:53.056|
 2025-01-04|Ночная смена |Шахта "Северная"|    269.42|             5|     136.8|2026-04-04 10:40:53.056|
 2025-01-04|Ночная смена |Шахта "Южная"   |    170.06|             3|     128.6|2026-04-04 10:40:53.056|
 2025-01-05|Дневная смена|Шахта "Северная"|    271.98|             4|     137.3|2026-04-04 10:40:53.056|
 2025-01-05|Дневная смена|Шахта "Южная"   |    162.08|             3|     132.3|2026-04-04 10:40:53.056|
 2025-01-05|Ночная смена |Шахта "Северная"|    288.62|             5|     134.9|2026-04-04 10:40:53.056|
 2025-01-05|Ночная смена |Шахта "Южная"   |    159.45|             3|     138.6|2026-04-04 10:40:53.056|
 2025-01-06|Дневная смена|Шахта "Северная"|    457.59|             4|     132.4|2026-04-04 10:40:53.056|
 2025-01-06|Дневная смена|Шахта "Южная"   |    266.32|             3|     129.3|2026-04-04 10:40:53.056|
 2025-01-06|Ночная смена |Шахта "Северная"|    438.23|             4|     131.9|2026-04-04 10:40:53.056|
 2025-01-06|Ночная смена |Шахта "Южная"   |    293.72|             3|     132.8|2026-04-04 10:40:53.056|
 2025-01-07|Дневная смена|Шахта "Северная"|    502.08|             5|     128.7|2026-04-04 10:40:53.056|
 2025-01-07|Дневная смена|Шахта "Южная"   |    343.06|             3|     134.4|2026-04-04 10:40:53.056|
 2025-01-07|Ночная смена |Шахта "Северная"|    506.06|             5|     133.4|2026-04-04 10:40:53.056|
 2025-01-07|Ночная смена |Шахта "Южная"   |    294.35|             3|     134.2|2026-04-04 10:40:53.056|
 2025-01-08|Дневная смена|Шахта "Северная"|    537.82|             5|     134.1|2026-04-04 10:40:53.056|
 2025-01-08|Дневная смена|Шахта "Южная"   |    315.35|             3|     136.8|2026-04-04 10:40:53.056|
 2025-01-08|Ночная смена |Шахта "Северная"|    517.71|             5|     132.3|2026-04-04 10:40:53.056|
 2025-01-08|Ночная смена |Шахта "Южная"   |    320.50|             3|     135.7|2026-04-04 10:40:53.056|
 2025-01-09|Дневная смена|Шахта "Северная"|    514.04|             5|     131.4|2026-04-04 10:40:53.056|
 2025-01-09|Дневная смена|Шахта "Южная"   |    290.17|             3|     140.3|2026-04-04 10:40:53.056|
 2025-01-09|Ночная смена |Шахта "Северная"|    490.51|             5|     133.5|2026-04-04 10:40:53.056|
 2025-01-09|Ночная смена |Шахта "Южная"   |    308.92|             3|     132.1|2026-04-04 10:40:53.056|
 2025-01-10|Дневная смена|Шахта "Северная"|    568.97|             5|     133.9|2026-04-04 10:40:53.056|
 2025-01-10|Дневная смена|Шахта "Южная"   |    300.80|             3|     135.9|2026-04-04 10:40:53.056|
 2025-01-10|Ночная смена |Шахта "Северная"|    507.07|             5|     136.9|2026-04-04 10:40:53.056|
 2025-01-10|Ночная смена |Шахта "Южная"   |    326.78|             3|     134.9|2026-04-04 10:40:53.056|
 2025-01-11|Дневная смена|Шахта "Северная"|    280.69|             5|     135.2|2026-04-04 10:40:53.056|
 2025-01-11|Дневная смена|Шахта "Южная"   |    177.28|             3|     132.2|2026-04-04 10:40:53.056|
 2025-01-11|Ночная смена |Шахта "Северная"|    310.93|             5|     133.0|2026-04-04 10:40:53.056|
 2025-01-11|Ночная смена |Шахта "Южная"   |    176.27|             3|     135.5|2026-04-04 10:40:53.056|
 2025-01-12|Дневная смена|Шахта "Северная"|    314.00|             5|     129.1|2026-04-04 10:40:53.056|
 2025-01-12|Дневная смена|Шахта "Южная"   |    174.73|             3|     137.6|2026-04-04 10:40:53.056|
 2025-01-12|Ночная смена |Шахта "Северная"|    317.18|             5|     131.6|2026-04-04 10:40:53.056|
 2025-01-12|Ночная смена |Шахта "Южная"   |    201.13|             3|     137.8|2026-04-04 10:40:53.056|
 2025-01-13|Дневная смена|Шахта "Северная"|    550.65|             5|     131.8|2026-04-04 10:40:53.056|
 2025-01-13|Дневная смена|Шахта "Южная"   |    320.60|             3|     128.8|2026-04-04 10:40:53.056|
 2025-01-13|Ночная смена |Шахта "Северная"|    514.14|             5|     138.0|2026-04-04 10:40:53.056|
 2025-01-13|Ночная смена |Шахта "Южная"   |    305.29|             3|     134.8|2026-04-04 10:40:53.056|
 2025-01-14|Дневная смена|Шахта "Северная"|    374.07|             4|     139.4|2026-04-04 10:40:53.056|
 2025-01-14|Дневная смена|Шахта "Южная"   |    278.49|             3|     136.6|2026-04-04 10:40:53.056|
 2025-01-14|Ночная смена |Шахта "Северная"|    543.44|             5|     136.0|2026-04-04 10:40:53.056|
 2025-01-14|Ночная смена |Шахта "Южная"   |    297.95|             3|     137.0|2026-04-04 10:40:53.056|
 2025-01-15|Дневная смена|Шахта "Северная"|    935.00|             5|     130.7|2026-04-04 10:40:53.056|
 2025-01-15|Дневная смена|Шахта "Южная"   |    299.43|             3|     134.5|2026-04-04 10:40:53.056|
 2025-01-15|Ночная смена |Шахта "Северная"|    913.32|             5|     130.9|2026-04-04 10:40:53.056|
 2025-01-15|Ночная смена |Шахта "Южная"   |    285.01|             3|     129.2|2026-04-04 10:40:53.056|
```

## Задание 7
### Текст задания
Бизнес-задача: Создать процедуру заполнения таблицы отчётов по сменам.

Требования:

Создайте таблицу report_shift_summary:
CREATE TABLE report_shift_summary (
    report_date    DATE,
    shift_name     VARCHAR(50),
    mine_name      VARCHAR(100),
    total_tons     NUMERIC(12,2),
    equipment_used INT,
    efficiency     NUMERIC(5,1),
    created_at     TIMESTAMP DEFAULT NOW()
);
Создайте анонимный блок с курсором, который:
Перебирает все даты из dim_date за 01-15 января 2025
Для каждой даты вставляет агрегированные данные по каждой комбинации смена+шахта
Рассчитывает эффективность: (operating_hours / (equipment_count * 8)) * 100
Использует GET DIAGNOSTICS для отслеживания количества вставленных строк
Выведите прогресс выполнения через RAISE NOTICE
Проверьте результат: SELECT * FROM report_shift_summary ORDER BY report_date, shift_name, mine_name
Задание 7. RETURN NEXT — функция генерации отчёта (сложное)
Бизнес-задача: Создать функцию, которая генерирует помесячный отчёт по качеству руды с нарастающим средним.

Требования:

Создайте функцию:
CREATE FUNCTION get_quality_trend(p_year INT, p_mine_id INT DEFAULT NULL)
RETURNS TABLE (
    month_num      INT,
    month_name     VARCHAR,
    samples_count  BIGINT,
    avg_fe         NUMERIC,
    min_fe         NUMERIC,
    max_fe         NUMERIC,
    running_avg_fe NUMERIC,
    trend          VARCHAR
)
Функция должна:
Перебирать месяцы 1..12 через цикл FOR
Для каждого месяца рассчитывать статистику из fact_ore_quality
Вести нарастающее среднее (running average) по Fe
Определять тренд: «Улучшение» / «Ухудшение» / «Стабильно» (сравнение с предыдущим месяцем)
Использовать RETURN NEXT для возврата каждой строки
Параметр p_mine_id — необязательный (если NULL — по всем шахтам)

### Решение
```
CREATE OR REPLACE FUNCTION get_quality_trend(p_year INT, p_mine_id INT DEFAULT NULL)
RETURNS TABLE (
    month_num      INT,
    month_name     VARCHAR,
    samples_count  BIGINT,
    avg_fe         NUMERIC,
    min_fe         NUMERIC,
    max_fe         NUMERIC,
    running_avg_fe NUMERIC,
    trend          VARCHAR
) AS $$
DECLARE
    v_total_sum_fe NUMERIC := 0;
    v_total_samples BIGINT := 0;
    v_prev_avg_fe  NUMERIC := NULL;
BEGIN
    FOR i IN 1..12 LOOP
        month_num := i;
        month_name := to_char(to_date(i::text, 'MM'), 'TMMonth');
        SELECT 
            COUNT(foq.fe_content),
            AVG(foq.fe_content),
            MIN(foq.fe_content),
            MAX(foq.fe_content)
        INTO 
            samples_count,
            avg_fe,
            min_fe,
            max_fe
        FROM "public".fact_ore_quality foq
        JOIN "public".dim_date dd ON foq.date_id = dd.date_id
        WHERE dd.year = p_year 
          AND dd.month = i
          AND (p_mine_id IS NULL OR foq.mine_id = p_mine_id);
        avg_fe := ROUND(avg_fe, 2);
        min_fe := ROUND(min_fe, 2);
        max_fe := ROUND(max_fe, 2);
        IF samples_count > 0 THEN
            v_total_sum_fe := v_total_sum_fe + (avg_fe * samples_count);
            v_total_samples := v_total_samples + samples_count;
            running_avg_fe := ROUND(v_total_sum_fe / v_total_samples, 2);
        ELSE
            running_avg_fe := v_prev_avg_fe;
        END IF;

        trend := CASE 
            WHEN v_prev_avg_fe IS NULL OR avg_fe IS NULL THEN 'Стабильно'
            WHEN avg_fe > v_prev_avg_fe + 0.1 THEN 'Улучшение'
            WHEN avg_fe < v_prev_avg_fe - 0.1 THEN 'Ухудшение'
            ELSE 'Стабильно'
        END;

        IF avg_fe IS NOT NULL THEN
            v_prev_avg_fe := avg_fe;
        END IF;

        RETURN NEXT;
    END LOOP;
END;
$$ LANGUAGE plpgsql;


SELECT * FROM get_quality_trend(2025);

SELECT * FROM get_quality_trend(2025, 1);
```
### Результат
```
month_num|month_name|samples_count|avg_fe|min_fe|max_fe|running_avg_fe|trend    |
---------+----------+-------------+------+------+------+--------------+---------+
        1|January   |          309| 53.74| 41.15| 65.80|         53.74|Стабильно|
        2|February  |          265| 53.94| 41.64| 65.04|         53.83|Улучшение|
        3|March     |          300| 53.03| 41.34| 65.83|         53.56|Ухудшение|
        4|April     |          298| 53.59| 41.17| 64.41|         53.57|Улучшение|
        5|May       |          291| 56.65| 44.04| 68.91|         54.18|Улучшение|
        6|June      |          287| 55.11| 44.34| 67.43|         54.33|Ухудшение|
        7|July      |            0|      |      |      |         55.11|Стабильно|
        8|August    |            0|      |      |      |         55.11|Стабильно|
        9|September |            0|      |      |      |         55.11|Стабильно|
       10|October   |            0|      |      |      |         55.11|Стабильно|
       11|November  |            0|      |      |      |         55.11|Стабильно|
       12|December  |            0|      |      |      |         55.11|Стабильно|



month_num|month_name|samples_count|avg_fe|min_fe|max_fe|running_avg_fe|trend    |
---------+----------+-------------+------+------+------+--------------+---------+
        1|January   |          189| 55.89| 44.24| 65.80|         55.89|Стабильно|
        2|February  |          168| 56.08| 44.42| 65.04|         55.98|Улучшение|
        3|March     |          189| 54.99| 44.50| 65.83|         55.64|Ухудшение|
        4|April     |          183| 54.99| 44.73| 64.41|         55.47|Стабильно|
        5|May       |          184| 58.46| 47.04| 68.91|         56.08|Улучшение|
        6|June      |          179| 56.91| 47.11| 67.43|         56.21|Ухудшение|
        7|July      |            0|      |      |      |         56.91|Стабильно|
        8|August    |            0|      |      |      |         56.91|Стабильно|
        9|September |            0|      |      |      |         56.91|Стабильно|
       10|October   |            0|      |      |      |         56.91|Стабильно|
       11|November  |            0|      |      |      |         56.91|Стабильно|
       12|December  |            0|      |      |      |         56.91|Стабильно|
```

## Задание 8
### Текст задания
Бизнес-задача: Создать функцию комплексной проверки качества данных MES-системы.

Требования:

Создайте функцию:
CREATE FUNCTION validate_mes_data(
    p_date_from INT,
    p_date_to   INT
)
RETURNS TABLE (
    check_id      INT,
    check_name    VARCHAR,
    severity      VARCHAR,  -- 'ОШИБКА', 'ПРЕДУПРЕЖДЕНИЕ', 'ИНФО'
    affected_rows BIGINT,
    details       TEXT,
    recommendation TEXT
)
Реализуйте минимум 8 проверок:
Отрицательные значения добычи
Добыча свыше 500 т за одну запись (аномалия)
Нулевые рабочие часы при ненулевой добыче
Рабочие дни без записей о добыче
Содержание Fe вне диапазона 0-100%
Простои длительностью > 24 часов (1440 минут)
Оборудование без единой записи о телеметрии за период
Дублирование записей (одно оборудование, одна смена, одна дата — более 1 записи)
Для каждой проверки:
Присвойте check_id (номер проверки)
Определите серьёзность через IF/CASE
Подсчитайте количество затронутых строк
Сформируйте описание и рекомендацию
Используйте RETURN NEXT
Протестируйте:
SELECT * FROM validate_mes_data(20250101, 20250131)
ORDER BY severity DESC, affected_rows DESC;
Найдите и зафиксируйте все обнаруженные проблемы с данными
### Решение
```
CREATE OR REPLACE FUNCTION validate_mes_data(p_date_from INT, p_date_to INT)
RETURNS TABLE (
    check_id      INT,
    check_name    VARCHAR,
    severity      VARCHAR,
    affected_rows BIGINT,
    details       TEXT,
    recommendation TEXT
) AS $$
BEGIN
    check_id := 1; check_name := 'Отрицательная добыча'; severity := 'ОШИБКА';
    SELECT COUNT(*), 'Найдено записей с tons_mined < 0' 
    INTO affected_rows, details FROM "public".fact_production 
    WHERE date_id BETWEEN p_date_from AND p_date_to AND tons_mined < 0;
    recommendation := 'Проверить датчики весоизмерителей и логику загрузки из CSV/API.';
    IF affected_rows > 0 THEN RETURN NEXT; END IF;
    check_id := 2; check_name := 'Аномалия веса (>500т)'; severity := 'ПРЕДУПРЕЖДЕНИЕ';

    SELECT COUNT(*), 'Записи превышают технический предел кузова/конвейера' 
    INTO affected_rows, details FROM "public".fact_production 
    WHERE date_id BETWEEN p_date_from AND p_date_to AND tons_mined > 500;
    recommendation := 'Перепроверить ручной ввод или откалибровать весы.';
    IF affected_rows > 0 THEN RETURN NEXT; END IF;

    check_id := 3; check_name := 'Добыча без моточасов'; severity := 'ОШИБКА';
    SELECT COUNT(*), 'tons_mined > 0 при operating_hours = 0' 
    INTO affected_rows, details FROM "public".fact_production 
    WHERE date_id BETWEEN p_date_from AND p_date_to AND tons_mined > 0 AND operating_hours = 0;
    recommendation := 'Сбой системы учета времени работы двигателя (CAN-шина).';
    IF affected_rows > 0 THEN RETURN NEXT; END IF;

    check_id := 4; check_name := 'Простой предприятия'; severity := 'ИНФО';
    SELECT COUNT(*), 'Даты без единой записи о добыче в рабочем календаре' 
    INTO affected_rows, details FROM "public".dim_date dd
    LEFT JOIN "public".fact_production fp ON dd.date_id = fp.date_id
    WHERE dd.date_id BETWEEN p_date_from AND p_date_to AND dd.is_weekend = false and dd.is_holiday=false AND fp.date_id IS NULL;
    recommendation := 'Убедиться, что в эти дни не было плановой остановки всего рудника.';
    IF affected_rows > 0 THEN RETURN NEXT; END IF;

    check_id := 5; check_name := 'Fe вне диапазона 0-100%'; severity := 'ОШИБКА';
    SELECT COUNT(*), 'Химический состав не может быть отрицательным или > 100%' 
    INTO affected_rows, details FROM "public".fact_ore_quality 
    WHERE date_id BETWEEN p_date_from AND p_date_to AND (fe_content < 0 OR fe_content > 100);
    recommendation := 'Ошибка интеграции с ЛИС (лабораторной системой).';
    IF affected_rows > 0 THEN RETURN NEXT; END IF;

    check_id := 6; check_name := 'Длительный простой (>24ч)'; severity := 'ПРЕДУПРЕЖДЕНИЕ';
    SELECT COUNT(*), 'Простой одной записью более 1440 минут' 
    INTO affected_rows, details FROM "public".fact_equipment_downtime 
    WHERE date_id BETWEEN p_date_from AND p_date_to AND duration_min > 1440;
    recommendation := 'Разбить простои по сменам или проверить закрытие карточки ремонта.';
    IF affected_rows > 0 THEN RETURN NEXT; END IF;

    check_id := 7; check_name := '«Слепое» оборудование'; severity := 'ПРЕДУПРЕЖДЕНИЕ';
    SELECT COUNT(*), 'Активное оборудование без записей в fact_equipment_telemetry' 
    INTO affected_rows, details FROM "public".dim_equipment de
    WHERE NOT EXISTS (SELECT 1 FROM "public".fact_equipment_telemetry fet WHERE fet.equipment_id = de.equipment_id AND fet.date_id BETWEEN p_date_from AND p_date_to);
    recommendation := 'Проверить работоспособность GPS/GSM модемов на технике.';
    IF affected_rows > 0 THEN RETURN NEXT; END IF;

    check_id := 8; check_name := 'Дублирование сменных рапортов'; severity := 'ОШИБКА';
    SELECT COUNT(*), 'Найдено несколько записей на одну связку: Дата+Смена+Оборудование' 
    INTO affected_rows, details FROM (
        SELECT date_id, shift_name, equipment_id FROM "public".fact_production fp join dim_shift ds on fp.shift_id=ds.shift_id
        WHERE date_id BETWEEN p_date_from AND p_date_to
        GROUP BY date_id, shift_name, equipment_id HAVING COUNT(*) > 1
    ) AS dup;
    recommendation := 'Удалить дубликаты и настроить UNIQUE CONSTRAINT в базе.';
    IF affected_rows > 0 THEN RETURN NEXT; END IF;

END;
$$ LANGUAGE plpgsql;


SELECT * FROM validate_mes_data(20250101, 20250131)
ORDER BY severity DESC, affected_rows DESC;
```
### Результат
```
check_id|check_name           |severity      |affected_rows|details                                                     |recommendation                                         |
--------+---------------------+--------------+-------------+------------------------------------------------------------+-------------------------------------------------------+
       7|«Слепое» оборудование|ПРЕДУПРЕЖДЕНИЕ|           18|Активное оборудование без записей в fact_equipment_telemetry|Проверить работоспособность GPS/GSM модемов на технике.|
```