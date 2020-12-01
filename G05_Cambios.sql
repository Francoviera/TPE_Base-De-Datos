-------------------------------------------RESTRICCIONES-----------------------------------------------

--La fecha del primer comentario tiene que ser anterior a la fecha del último comentario si este no es nulo.

CREATE OR REPLACE FUNCTION FN_GR05_Date_Control()
    RETURNS TRIGGER AS $$
        declare
            fecha_primer_coment GR05_COMENTA.fecha_primer_com%type;
        BEGIN
            SELECT fecha_primer_com into fecha_primer_coment
                FROM GR05_COMENTA
                WHERE id_usuario = NEW.id_usuario
                AND id_juego = NEW.id_juego;
            IF (fecha_primer_coment > NEW.fecha_comentario) THEN
                raise exception 'La fecha de su ultimo comentario es anterior a su primer comentario';
            END IF;
        return NEW;
        end;
    $$language 'plpgsql';

CREATE TRIGGER TR_GR05_COMENTARIO_Date_Control BEFORE
    INSERT on GR05_COMENTARIO
    FOR EACH ROW
    execute procedure FN_GR05_Date_Control();

--DISPARADOR:

/*
INSERT INTO GR05_COMENTARIO(id_usuario,id_juego,id_comentario,fecha_comentario,comentario)
        VALUES (19,64,1,to_timestamp('15-11-2020', 'DD-MM-YYYY'),'Re dificil, no puedo pasar el nivel 2');

        INSERT INTO GR05_COMENTARIO(id_usuario,id_juego,id_comentario,fecha_comentario,comentario)
        VALUES (19,64,2,to_timestamp('10-11-2020', 'DD-MM-YYYY'),'Un buen juego');
*/



--Cada usuario sólo puede comentar una vez al día cada juego.

CREATE OR REPLACE FUNCTION FN_GR05_Date_Control_Day()
    RETURNS TRIGGER AS $$
        declare fecha_ult_coment GR05_COMENTA.fecha_ultimo_com%type;
        declare fecha_primer GR05_COMENTA.fecha_primer_com%type;
        BEGIN
            SELECT fecha_ultimo_com, fecha_primer_com into fecha_ult_coment, fecha_primer
                FROM GR05_COMENTA
                where new.id_usuario = id_usuario AND
                new.id_juego = id_juego AND
                date(fecha_primer_com) = date(new.fecha_comentario) OR
                date(fecha_ultimo_com) = date(new.fecha_comentario);
            IF (fecha_ult_coment is not null OR date(fecha_primer) = date(new.fecha_comentario)) THEN
                raise exception 'ya hiciste un comentario en el dia de hoy';
            END IF;
        return NEW;
        end
    $$language 'plpgsql';

CREATE TRIGGER TR_GR05_Date_Control_Day BEFORE
    INSERT on GR05_COMENTARIO
    FOR EACH ROW
    execute procedure FN_GR05_Date_Control_Day();

--DISPARADOR:

/*
        INSERT INTO GR05_COMENTARIO(id_usuario,id_juego,id_comentario,fecha_comentario,comentario)
        VALUES (36,51,3,to_timestamp('28-11-2020', 'DD-MM-YYYY'),'Este juego me encanto la verdad');

        INSERT INTO GR05_COMENTARIO(id_usuario,id_juego,id_comentario,fecha_comentario,comentario)
        VALUES (36,51,4,to_timestamp('28-11-2020', 'DD-MM-YYYY'),'Ahora que lo jugue un poco mas me di cuenta que el juego es malisimo');
*/

--Un usuario no puede recomendar un juego si no ha votado previamente dicho juego.

CREATE OR REPLACE FUNCTION FN_GR05_Vote_Control()
    RETURNS TRIGGER AS $$
        declare usuario GR05_VOTO.id_usuario%type;
        BEGIN
            SELECT id_usuario into usuario
                FROM GR05_VOTO v
                where new.id_usuario = v.id_usuario AND
                      new.id_juego = v.id_juego;

            IF (usuario is null) THEN
                raise exception 'No puedes recomendar sin antes votar el juego';
            END IF;
        RETURN NEW;
        end;
    $$language 'plpgsql';

CREATE TRIGGER TR_GR05_Vote_Control AFTER
    INSERT or UPDATE of id_usuario, id_juego on GR05_RECOMENDACION
    FOR EACH ROW
    execute procedure FN_GR05_Vote_Control();

--DISPARADOR:

/*
        INSERT INTO GR05_RECOMENDACION(id_recomendacion,email_recomendado,id_usuario,id_juego) VALUES (102,'juanma04@testing.com.ar',49,55);
*/

--Un usuario no puede comentar un juego que no ha jugado.

CREATE OR REPLACE FUNCTION FN_G05_CONTROL_GAME_COMENT() RETURNS Trigger AS
$$
DECLARE
    usuario GR05_JUEGA.id_usuario%type;

BEGIN
    SELECT id_usuario into usuario
    FROM GR05_JUEGA
    WHERE id_usuario = NEW.id_usuario
      AND id_juego = NEW.id_juego;
        IF (usuario is null)THEN
        RAISE EXCEPTION 'No puedes Comentar un juego que no has jugado';
    END IF;
    RETURN NEW;
END
$$
    LANGUAGE 'plpgsql';

CREATE TRIGGER TR_GR05_CONTROL_GAME_COMENT BEFORE INSERT
    ON GR05_COMENTARIO
    FOR EACH ROW
    execute procedure FN_G05_CONTROL_GAME_COMENT();

--DISPARADOR:

/*
        INSERT INTO GR05_COMENTARIO(id_usuario,id_juego,id_comentario,fecha_comentario,comentario)
        VALUES (15,59,5,to_timestamp('21-9-2020', 'DD-MM-YYYY'),'Ya lo estoy descargando, mañana mismo lo arranco a jugar');
*/


--------------------------------------------------SERVICIOS------------------------------------------------------

--1- Se debe mantener sincronizadas las tablas COMENTA y COMENTARIO en los siguientes aspectos:
--a) La primera vez que se inserta un comentario de un usuario para un juego se debe hacer el insert conjunto en ambas tablas, colocando la fecha del primer comentario y última fecha comentario en nulo.
--b) Los posteriores comentarios sólo deben modificar la fecha de último comentario e insertar en COMENTARIO

CREATE OR REPLACE FUNCTION FN_GR05_SYNCHRONIZATION_COMENT() RETURNS Trigger AS
$$
DECLARE
    usuario GR05_COMENTARIO.id_usuario%type;
BEGIN
    SELECT id_usuario into usuario
    FROM GR05_COMENTA
    WHERE id_usuario = NEW.id_usuario
      AND id_juego = NEW.id_juego;

    IF (usuario is null) THEN
        INSERT INTO GR05_COMENTA (id_usuario, id_juego, fecha_primer_com, fecha_ultimo_com) VALUES (NEW.id_usuario,NEW.id_juego,NEW.fecha_comentario, null);
    ELSE
        UPDATE GR05_COMENTA SET fecha_ultimo_com = NEW.fecha_comentario WHERE id_juego = NEW.id_juego AND id_usuario = NEW.id_usuario;
    END IF;

    RETURN NEW;
END;
$$
    LANGUAGE 'plpgsql';


CREATE TRIGGER TR_GR05_SYNCHRONIZATION_COMENT
    BEFORE INSERT OR UPDATE OF id_usuario, id_juego, fecha_comentario
    ON GR05_COMENTARIO
    FOR EACH ROW
    execute procedure FN_GR05_SYNCHRONIZATION_COMENT();


CREATE OR REPLACE FUNCTION FN_GR05_SYNCHRONIZATION_COMENT_DELETE() RETURNS Trigger AS
$$
DECLARE
    fecha_coment GR05_COMENTARIO.fecha_comentario%type;

BEGIN
    SELECT fecha_comentario into fecha_coment
        FROM GR05_COMENTARIO
        ORDER BY fecha_comentario DESC
        LIMIT 1;

    IF (fecha_coment IS NULL) THEN
        DELETE FROM GR05_COMENTA WHERE id_usuario = OLD.id_usuario AND id_juego = OLD.id_juego;
    ELSIF (date(fecha_coment) = (select date(fecha_primer_com) from gr05_comenta where id_usuario = old.id_usuario and id_juego = old.id_juego)) THEN
        UPDATE GR05_COMENTA SET fecha_ultimo_com = null WHERE id_juego = OLD.id_juego AND id_usuario = OLD.id_usuario;
    ELSIF (fecha_coment < old.fecha_comentario) THEN
        UPDATE GR05_COMENTA SET fecha_ultimo_com = fecha_coment WHERE id_juego = OLD.id_juego AND id_usuario = OLD.id_usuario;
    end if;
    RETURN OLD;
    END;
$$
    LANGUAGE 'plpgsql';

CREATE TRIGGER TR_GR05_SYNCHRONIZATION_COMENT_DELETE
    AFTER DELETE
    ON GR05_COMENTARIO
    FOR EACH ROW
    execute procedure FN_GR05_SYNCHRONIZATION_COMENT_DELETE();

-- 2- Dado un patrón de búsqueda devolver todos los datos de el o los usuarios junto con la cantidad de
-- juegos que ha jugado y la cantidad de votos que ha realizado

CREATE OR REPLACE FUNCTION FN_G05_MAIL_PATTERN(pattern varchar)
RETURNS TABLE (
        id GR05_USUARIO.id_usuario%type,
        surname GR05_USUARIO.apellido%type,
        name GR05_USUARIO.nombre%type,
        mail GR05_USUARIO.email%type,
        id_user_type GR05_USUARIO.id_tipo_usuario%type,
        password GR05_USUARIO.password%type,
        games_played int,
        votes  int
)
AS $$
BEGIN
    RETURN QUERY SELECT
       u.id_usuario, u.apellido, u.nombre, u.email, u.id_tipo_usuario, u.password, coalesce(cant_games_played,0)::integer as games_played, coalesce(cant_votes,0)::integer as votes
    FROM
        GR05_USUARIO u left join (
            SELECT id_usuario, COUNT(*) as cant_games_played
                FROM GR05_JUEGA
                GROUP BY id_usuario) as Play on (u.id_usuario = Play.id_usuario)
            left join  (SELECT id_usuario, COUNT(*) as cant_votes
                        FROM GR05_VOTO
                        GROUP BY id_usuario) as Vote on (u.id_usuario = Vote.id_usuario)
    WHERE
        u.email LIKE '%'||pattern||'%';

END; $$
LANGUAGE 'plpgsql';



-----------------------------------------------VISTAS------------------------------------------

--Listar todos los comentarios realizados durante el último mes descartando aquellos
-- juegos de la Categoría “Sin Categorías”

CREATE VIEW GR05_LAST_COMENT_MONTH AS
SELECT *
FROM GR05_COMENTARIO g
WHERE g.id_juego IN (SELECT j.id_juego
                        FROM GR05_juego j
                            WHERE id_categoria IN (SELECT id_categoria
                                FROM GR05_CATEGORIA
                                WHERE descripcion <> 'Sin Categoria'))
  AND fecha_comentario >=  NOW() - '1 month'::interval;



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
                         GROUP BY (id_usuario)
                         HAVING COUNT(id_juego) = (SELECT COUNT(id_juego) FROM GR05_JUEGO)));

-- Realizar el ranking de los 20 juegos mejor puntuados por los Usuarios.
-- El ranking debe ser generado considerando el promedio del valor puntuado por los usuarios y que el
-- juego hubiera sido calificado más de 5 veces


CREATE VIEW GR05_MOST_20_VOTED_GAMES AS
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

