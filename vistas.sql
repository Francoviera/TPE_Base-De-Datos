SELECT *
FROM GR05_JUEGO
WHERE id_juego IN (SELECT id_juego
    FROM GR05_JUEGA j
    GROUP BY j.id_juego
    ORDER BY COUNT(j.id_juego) DESC
    LIMIT 10);

select FN_G03_PATRON_BUSQUEDA_APELLIDO('Mckenzie');

CREATE OR REPLACE FUNCTION FN_G03_PATRON_BUSQUEDA_APELLIDO(patron varchar)
RETURNS TABLE (
        id_usuario gr05_usuario.id_usuario%type,
        apellido gr05_usuario.apellido%type,
        nombre gr05_usuario.nombre%type,
        email gr05_usuario.email%type,
        id_tipo_usuario gr05_usuario.id_tipo_usuario%type,
        password gr05_usuario.password%type,
        cant_juegos_jugados INT,
        cant_votos  INT
)
AS $$
BEGIN
    RETURN QUERY SELECT
       u.id_usuario, apellido, nombre, email, id_tipo_usuario, password, coalesce(cant_juegos_jugados,0) as cant_juegos_jugados, coalesce(cant_votos,0) as cant_votos
    FROM
        gr05_usuario u left join (SELECT id_usuario, COUNT(*) as cant_juegos_jugados
                        FROM gr05_juega
                        GROUP BY id_usuario) as juega on (u.id_usuario = juega.id_usuario)
            left join  (SELECT id_usuario, COUNT(*) as cant_votos
                        FROM gr05_voto
                        GROUP BY id_usuario) as voto on (u.id_usuario = voto.id_usuario)
    WHERE
        u.apellido ILIKE '%'||patron||'%';

END; $$
LANGUAGE 'plpgsql';


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

select * from GR05_LAST_COMENT_MONTH;

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
--actualizable
CREATE VIEW GR05_MOST_20_PLAYED_GAMES AS
    SELECT *
        FROM GR05_JUEGO
        WHERE id_juego IN (SELECT id_juego
            FROM GR05_VOTO v
            GROUP BY v.id_juego
            HAVING count(*) > 5
            ORDER BY AVG(v.valor_voto) DESC
            LIMIT 20);

--no actualizable
CREATE VIEW GR05_MOST_20_PLAYED_GAMES AS
    SELECT j.id_juego, j.nombre_juego, j.descripcion_juego, j.id_categoria
        FROM GR05_JUEGO j JOIN GR05_VOTO v ON (j.id_juego = v.id_juego)
        GROUP BY v.id_juego
        HAVING count(*) > 5
        ORDER BY AVG(v.valor_voto) DESC
        LIMIT 20;

/* LOS_10_JUEGOS_MAS_JUGADOS: Generar una vista con los 10 juegos más jugados. */

--actualizable
CREATE VIEW GR05_MOST_10_GAME AS
SELECT *
FROM GR05_JUEGO
WHERE id_juego IN (SELECT id_juego
    FROM GR05_JUEGA j
    GROUP BY j.id_juego
    ORDER BY COUNT(j.id_juego) DESC
    LIMIT 10);

--no actualizable
CREATE VIEW GR05_MOST_10_GAME AS
SELECT jo.id_juego, jo.nombre_juego, jo.descripcion_juego, jo.id_categoria
FROM GR05_JUEGO jo JOIN gr05_juega ja on (jo.id_juego = ja.id_juego)
    GROUP BY jo.id_juego
    ORDER BY COUNT(jo.id_juego) DESC
    LIMIT 10;
