UPDATE records_staging AS rs
SET rs.province = (
    CASE
        WHEN rs.province REGEXP '^[0-9]+$' THEN rs.province
        WHEN EXISTS (SELECT 1
                     FROM province_dim AS pd
                     WHERE rs.province LIKE CONCAT('%', pd.name_vi, '%')
                        OR rs.province LIKE CONCAT('%', pd.name_en, '%')
                        OR rs.province LIKE CONCAT('%', TRIM(pd.name_en), '%')
                        OR rs.province LIKE CONCAT('%', TRIM(pd.name_vi), '%')
                        OR rs.province LIKE CONCAT('%', SUBSTRING_INDEX(pd.name_vi, ' ', -1), '%')
                        OR rs.province LIKE CONCAT('%', SUBSTRING_INDEX(pd.name_en, ' ', -1), '%')) THEN (SELECT pd.id
                                                                                                          FROM province_dim AS pd
                                                                                                          WHERE rs.province LIKE CONCAT('%', pd.name_vi, '%')
                                                                                                             OR rs.province LIKE CONCAT('%', pd.name_en, '%')
                                                                                                             OR rs.province LIKE CONCAT('%', TRIM(pd.name_en), '%')
                                                                                                             OR rs.province LIKE CONCAT('%', TRIM(pd.name_vi), '%')
                                                                                                             OR rs.province LIKE
                                                                                                                CONCAT('%', SUBSTRING_INDEX(pd.name_vi, ' ', -1), '%')
                                                                                                             OR rs.province LIKE
                                                                                                                CONCAT('%', SUBSTRING_INDEX(pd.name_en, ' ', -1), '%')
                                                                                                          LIMIT 1)
        ELSE (SELECT NULL)
        END
    );

DELETE
FROM records_staging
WHERE province IS NULL
   OR province = '';

UPDATE records_staging
SET time_record = IF(time_record IS NULL OR time_record = '', TIME_FORMAT(NOW(), '%H:%i:%s'), time_record)
WHERE time_record IS NULL
   OR time_record = '';

UPDATE records_staging
SET date_record = IF(date_record IS NULL OR date_record = '', DATE_FORMAT(NOW(), '%d-%m-%Y'), date_record)
WHERE date_record IS NULL
   OR date_record = '';

UPDATE records_staging AS rs
    JOIN date_dim AS dd ON
        CASE
            WHEN rs.date_record REGEXP '^[0-9]+$' THEN rs.date_record = dd.date_key
            ELSE dd.full_date = STR_TO_DATE(rs.date_record, '%d-%m-%Y') END
SET rs.date_record = dd.date_key;


DELETE
FROM records_staging
WHERE time_forcast IS NULL
   OR time_forcast = '';

DELETE
FROM records_staging
WHERE date_forcast IS NULL
   OR date_forcast = '';

UPDATE records_staging AS rs
    JOIN date_dim AS dd ON
        CASE
            WHEN rs.date_forcast REGEXP '^[0-9]+$' THEN rs.date_forcast = dd.date_key
            ELSE dd.full_date = STR_TO_DATE(rs.date_forcast, '%d-%m-%Y') END
SET rs.date_forcast = dd.date_key;

UPDATE records_staging r1
    JOIN records_staging r2 ON r1.id = r2.id - 1
    JOIN records_staging r3 ON r1.id = r3.id + 1
SET r1.temperature = IF(r1.temperature IS NULL OR r1.temperature = '',
                        IF(r2.temperature IS NULL OR r2.temperature = '',
                           r3.temperature,
                           IF(r3.temperature IS NULL OR r3.temperature = '',
                              r2.temperature,
                              ROUND((r2.temperature + r3.temperature) / 2)
                           )
                        ),
                        r1.temperature
                     )
WHERE r1.temperature IS NULL
   OR r1.temperature = '';
UPDATE records_staging r1
SET temperature = (SELECT temperature FROM records_staging r2 WHERE r2.id = r1.id - 1)
WHERE (r1.temperature IS NULL OR r1.temperature = '')
  AND r1.id = (SELECT MAX(id) FROM records_staging);

UPDATE records_staging r1
    JOIN records_staging r2 ON r1.id = r2.id - 1
    JOIN records_staging r3 ON r1.id = r3.id + 1
SET r1.feel_like = IF(r1.feel_like IS NULL OR r1.feel_like = '',
                      IF(r2.feel_like IS NULL OR r2.feel_like = '',
                         r3.feel_like,
                         IF(r3.feel_like IS NULL OR r3.feel_like = '',
                            r2.feel_like,
                            ROUND((r2.feel_like + r3.feel_like) / 2)
                         )
                      ),
                      r1.feel_like
                   )
WHERE r1.feel_like IS NULL
   OR r1.feel_like = '';
UPDATE records_staging r1
SET feel_like = (SELECT feel_like FROM records_staging r2 WHERE r2.id = r1.id - 1)
WHERE (r1.feel_like IS NULL OR r1.feel_like = '')
  AND r1.id = (SELECT MAX(id) FROM records_staging);


INSERT INTO description_dim (name_en)
SELECT DISTINCT description
FROM records_staging
WHERE NOT EXISTS (SELECT *
                  FROM description_dim
                  WHERE name_en = records_staging.description
                     OR id = records_staging.description);

UPDATE records_staging AS rs
SET rs.description = (
    CASE
        WHEN EXISTS (SELECT 1
                     FROM description_dim AS dd
                     WHERE rs.description = dd.name_vi
                        OR rs.description = dd.name_en) THEN (SELECT dd.id
                                                              FROM description_dim AS dd
                                                              WHERE rs.description = dd.name_vi
                                                                 OR rs.description = dd.name_en
                                                              LIMIT 1)
        ELSE (SELECT description
              FROM records_staging
              WHERE description LIKE rs.description
              LIMIT 1)
        END
    );



UPDATE records_staging r1
SET wind_direction = (SELECT wind_direction
                      FROM records_staging r2
                      WHERE r2.id = r1.id - 1)
WHERE (r1.wind_direction IS NULL OR r1.wind_direction = '')
  AND r1.id <= (SELECT MAX(id) FROM records_staging);

UPDATE records_staging AS rs
SET rs.wind_direction = (
    CASE
        WHEN rs.wind_direction REGEXP '^[0-9]+$' THEN rs.wind_direction
        WHEN EXISTS (SELECT 1
                     FROM wind_direction_dim AS wdd
                     WHERE rs.wind_direction LIKE CONCAT('%', wdd.name_vi, '%')
                        OR rs.wind_direction LIKE CONCAT('%', wdd.name_en, '%'))
            THEN (SELECT wdd.id
                  FROM wind_direction_dim AS wdd
                  WHERE rs.wind_direction LIKE CONCAT('%', wdd.name_vi, '%')
                     OR rs.wind_direction LIKE CONCAT('%', wdd.name_en, '%')
                  LIMIT 1)
        ELSE (SELECT NULL)
        END
    );


UPDATE records_staging r1
    JOIN records_staging r2 ON r1.id = r2.id - 1
SET r1.wind_speed= IF(r1.wind_speed IS NULL OR r1.wind_speed = '', r2.wind_speed, r1.wind_speed)
WHERE r1.wind_speed IS NULL
   OR r1.wind_speed = ''
    AND r1.id <= (SELECT MAX(id) FROM records_staging);

UPDATE records_staging r1
    JOIN records_staging r2 ON r1.id = r2.id - 1
    JOIN records_staging r3 ON r1.id = r3.id + 1
SET r1.humidity= IF(r1.humidity IS NULL OR r1.humidity = '',
                    IF(r2.humidity IS NULL OR r2.humidity = '',
                       r3.humidity,
                       IF(r3.humidity IS NULL OR r3.humidity = '',
                          r2.humidity,
                          ROUND((r2.humidity + r3.humidity) / 2)
                       )
                    ),
                    r1.humidity
                 )
WHERE r1.humidity IS NULL
   OR r1.humidity = '';

UPDATE records_staging r1
SET humidity = (SELECT humidity FROM records_staging r2 WHERE r2.id = r1.id - 1)
WHERE (r1.humidity IS NULL OR r1.humidity = '')
  AND r1.id = (SELECT MAX(id) FROM records_staging);

UPDATE records_staging r1
    JOIN records_staging r2 ON r1.id = r2.id - 1
    JOIN records_staging r3 ON r1.id = r3.id + 1
SET r1.uv_index= IF(r1.uv_index IS NULL OR r1.uv_index = '',
                    IF(r2.uv_index IS NULL OR r2.uv_index = '',
                       r3.uv_index,
                       IF(r3.uv_index IS NULL OR r3.uv_index = '',
                          r2.uv_index,
                          ROUND((r2.uv_index + r3.uv_index) / 2)
                       )
                    ),
                    r1.uv_index
                 )
WHERE r1.uv_index IS NULL
   OR r1.uv_index = '';

UPDATE records_staging r1
SET uv_index = (SELECT uv_index FROM records_staging r2 WHERE r2.id = r1.id - 1)
WHERE (r1.uv_index IS NULL OR r1.uv_index = '')
  AND r1.id = (SELECT MAX(id) FROM records_staging);

UPDATE records_staging
SET uv_index =11
WHERE uv_index > 11;

UPDATE records_staging r1
    JOIN records_staging r2 ON r1.id = r2.id - 1
    JOIN records_staging r3 ON r1.id = r3.id + 1
SET r1.cloud_cover= IF(r1.cloud_cover IS NULL OR r1.cloud_cover = '',
                       IF(r2.cloud_cover IS NULL OR r2.cloud_cover = '',
                          r3.cloud_cover,
                          IF(r3.cloud_cover IS NULL OR r3.cloud_cover = '',
                             r2.cloud_cover,
                             ROUND((r2.cloud_cover + r3.cloud_cover) / 2)
                          )
                       ),
                       r1.cloud_cover
                    )
WHERE r1.cloud_cover IS NULL
   OR r1.cloud_cover = '';

UPDATE records_staging r1
SET cloud_cover = (SELECT cloud_cover FROM records_staging r2 WHERE r2.id = r1.id - 1)
WHERE (r1.cloud_cover IS NULL OR r1.cloud_cover = '')
  AND r1.id = (SELECT MAX(id) FROM records_staging);

UPDATE records_staging r1
    JOIN records_staging r2 ON r1.id = r2.id - 1
    JOIN records_staging r3 ON r1.id = r3.id + 1
SET r1.precipitation= IF(r1.precipitation IS NULL OR r1.precipitation = '',
                         IF(r2.precipitation IS NULL OR r2.precipitation = '',
                            r3.precipitation,
                            IF(r3.precipitation IS NULL OR r3.precipitation = '',
                               r2.precipitation,
                               ROUND((r2.precipitation + r3.precipitation) / 2)
                            )
                         ),
                         r1.precipitation
                      )
WHERE r1.precipitation IS NULL
   OR r1.precipitation = '';

UPDATE records_staging r1
SET precipitation = (SELECT precipitation FROM records_staging r2 WHERE r2.id = r1.id - 1)
WHERE (r1.precipitation IS NULL OR r1.precipitation = '')
  AND r1.id = (SELECT MAX(id) FROM records_staging);

UPDATE records_staging
SET accumulation=0
WHERE accumulation IS NULL
   OR accumulation = '';