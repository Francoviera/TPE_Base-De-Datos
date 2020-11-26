--1- Se debe mantener sincronizadas las tablas COMENTA y COMENTARIO en los siguientes aspectos:
--a) La primera vez que se inserta un comentario de un usuario para un juego se debe hacer el insert conjunto en ambas tablas, colocando la fecha del primer comentario y última fecha comentario en nulo.
--b) Los posteriores comentarios sólo deben modificar la fecha de último comentario e insertar en COMENTARIO

CREATE TRIGGER TR_GR05_SYNCHRONIZATION_COMENT
    AFTER INSERT OR UPDATE OF id_usuario, id_juego, fecha_comentario
    ON GR05_COMENTARIO
    FOR EACH ROW
    execute procedure FN_GR05_SYNCHRONIZATION_COMENT();

CREATE OR REPLACE FUNCTION FN_GR05_SYNCHRONIZATION_COMENT() RETURNS Trigger AS
$$
DECLARE
    --fecha_primer_coment GR05_COMENTA.fecha_primer_com%type;
    usuario GR05_COMENTARIO.id_usuario%type;
    juego GR05_COMENTARIO.id_juego%type;

BEGIN
    SELECT id_usuario, id_juego into usuario, juego
    FROM GR05_COMENTA
    WHERE id_usuario = NEW.id_usuario
      AND id_juego = NEW.id_juego;

    --IF NOT(usuario AND juego) THEN
    IF (NEW.id_usuario <> usuario AND NEW.id_juego <> juego) THEN
        INSERT INTO GR05_COMENTA (id_usuario, id_juego, fecha_primer_com, fecha_ultimo_com) VALUES (NEW.id_usuario,NEW.id_juego,NEW.fecha_comentario, null);
    ELSE
        UPDATE GR05_COMENTA SET fecha_ultimo_com = NEW.fecha_comentario WHERE id_juego = NEW.id_juego AND id_usuario = NEW.id_usuario;
    END IF;
    RETURN NEW;
END
$$
    LANGUAGE 'plpgsql';

-- 2- Dado un patrón de búsqueda devolver todos los datos de el o los usuarios junto con la cantidad de
-- juegos que ha jugado y la cantidad de votos que ha realizado

CREATE OR REPLACE FUNCTION FN_G03_PATRON_BUSQUEDA_APELLIDO(pattern varchar)
RETURNS TABLE (
        id GR05_USUARIO.id_usuario%type,
        surname GR05_USUARIO.apellido%type,
        name GR05_USUARIO.nombre%type,
        mail GR05_USUARIO.email%type,
        id_user_type GR05_USUARIO.id_tipo_usuario%type,
        password GR05_USUARIO.password%type,
        cant_games_played INT,
        cant_votes  INT
)
AS $$
BEGIN
    RETURN QUERY SELECT
       id_usuario, apellido, nombre, email, id_tipo_usuario, password, coalesce(cant_games_played,0) as cant_games_played, coalesce(cant_votes,0) as cant_votes
    FROM
        GR05_USUARIO u left join (
            SELECT id_usuario, COUNT(*) as cant_games_played
                FROM GR05_JUEGA
                GROUP BY id_usuario) as Play on (u.id_usuario = Play.id_usuario)
            left join  (SELECT id_usuario, COUNT(*) as cant_votes
                        FROM GR05_VOTO
                        GROUP BY id_usuario) as Vote on (u.id_usuario = Vote.id_usuario)
    WHERE
        u.email ILIKE '%'||pattern||'%';

END; $$
LANGUAGE 'plpgsql';