--Listar todos los comentarios realizados durante el último mes descartando aquellos
-- juegos de la Categoría “Sin Categorías”

CREATE VIEW GR05_LAST_COMENT_MONTH AS
SELECT comentario, fecha_comentario
FROM GR05_COMENTARIO g
WHERE g.id_juego IN (SELECT j.id_juego
                        FROM GR05_juego j
                            WHERE id_categoria IN (SELECT id_categoria
                                FROM GR05_CATEGORIA
                                WHERE descripcion <> 'Sin Categoria'))
  AND fecha_comentario >=  NOW() - '1 month'::interval;
    --DATEADD(MONTH, -1, GETDATE())

-- Listar aquellos usuarios que han comentado TODOS los juegos durante el
-- último año, teniendo en cuenta que sólo pueden comentar aquellos juegos que han jugado.

CREATE VIEW GR05_LIST_USER_LAST_YEAR AS
SELECT *
FROM GR05_USUARIO
WHERE id_usuario IN (SELECT id_usuario
                     FROM GR05_COMENTA
                     WHERE id_usuario IN (
                         SELECT id_usuario
                         FROM GR05_COMENTARIO
                         WHERE fecha_comentario
                                   BETWEEN NOW() - '1 year'::interval AND NOW()
                         HAVING COUNT(id_juego) = (SELECT COUNT(id_juego) FROM GR05_JUEGO)));

-- Realizar el ranking de los 20 juegos mejor puntuados por los Usuarios.
-- El ranking debe ser generado considerando el promedio del valor puntuado por los usuarios y que el
-- juego hubiera sido calificado más de 5 veces

CREATE VIEW GR05_MOST_20_GAMES AS
SELECT *
FROM GR05_JUEGO
WHERE id_juego IN (SELECT id_juego
   FROM GR05_VOTO v
    GROUP BY v.id_juego
    HAVING count(*) > 5
    ORDER BY AVG(v.valor_voto) DESC
    LIMIT 20);

/* LOS_10_JUEGOS_MAS_JUGADOS: Generar una vista con los 10 juegos más jugados. */

CREATE VIEW GR05_MOST_10_GAME AS
SELECT *
FROM GR05_JUEGO
WHERE id_juego IN (SELECT id_juego
    FROM GR05_JUEGA j
    GROUP BY j.id_juego
    ORDER BY COUNT(j.id_juego) DESC
    LIMIT 10);
