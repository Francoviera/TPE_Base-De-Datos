--Listar todos los comentarios realizados durante el último mes descartando aquellos
-- juegos de la Categoría “Sin Categorías”

CREATE VIEW Comentarios_ult_mes AS
SELECT comentario, fecha_comentario
FROM G05_COMENTARIO
WHERE id_juego NOT EXIST (SELECT 1
                        FROM g03_juego
                            WHERE id_categoria = null)
  AND fecha_comentario >=  EXTRACT('MONTH' FROM NOW()) - 1 ;

-- Listar aquellos usuarios que han comentado TODOS los juegos durante el
-- último año, teniendo en cuenta que sólo pueden comentar aquellos juegos que han jugado.

CREATE VIEW Lista_userComents_ult_año AS
SELECT *
FROM G05_USUARIO
WHERE id_usuario IN (SELECT id_usuario
                     FROM G05_COMENTA
                     WHERE id_usuario IN (
                         SELECT id_usuario
                         FROM G05_COMENTARIO
                         WHERE fecha_comentario
                                   BETWEEN NOW() - interval '1 year' AND NOW()
                         HAVING COUNT(id_juego) = (SELECT COUNT(id_juego) FROM G05_JUEGO)));

-- Realizar el ranking de los 20 juegos mejor puntuados por los Usuarios.
-- El ranking debe ser generado considerando el promedio del valor puntuado por los usuarios y que el
-- juego hubiera sido calificado más de 5 veces

CREATE VIEW _20_Juegos_mas_punteados AS
SELECT *
FROM G05_JUEGO
WHERE id_juego IN (SELECT id_juego
   FROM G05_VOTO
   HAVING count(*) > 5
   ORDER BY AVG(valor_voto) ASC
   LIMIT 20);

/* LOS_10_JUEGOS_MAS_JUGADOS: Generar una vista con los 10 juegos más jugados. */

CREATE VIEW Diez_Juegos_Mas_Jugados AS
SELECT *
FROM G05_JUEGO
WHERE id_juego IN (SELECT id_juego
   FROM G05_JUEGO
   ORDER BY COUNT(id_juego) ASC
   LIMIT 10);