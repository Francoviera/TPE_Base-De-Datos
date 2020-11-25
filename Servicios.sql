--1- Se debe mantener sincronizadas las tablas COMENTA y COMENTARIO en los siguientes aspectos:
--a) La primera vez que se inserta un comentario de un usuario para un juego se debe hacer el insert conjunto en ambas tablas, colocando la fecha del primer comentario y última fecha comentario en nulo.
--b) Los posteriores comentarios sólo deben modificar la fecha de último comentario e insertar en COMENTARIO

CREATE TRIGGER CONTROL_COMENT_JUEGO AFTER INSERT
    ON G05_COMENTARIO
    FOR EACH ROW
    execute procedure FN_Sincronizacion_Comenta_Comentario();

CREATE OR REPLACE FUNCTION FN_Sincronizacion_Comenta_Comentario() RETURNS Trigger AS
$$
DECLARE
    fecha_primer_coment G05_COMENTA.fecha_primer_com%type;
BEGIN
    SELECT fecha_primer_com into fecha_primer_coment
    FROM G05_COMENTA
    WHERE id_usuario = NEW.id_usuario
      AND id_juego = NEW.id_juego;
    IF NOT EXISTS(fecha_primer_coment) THEN
        INSERT INTO G05_COMENTA (id_usuario, id_juego, fecha_primer_com, fecha_ultimo_com) VALUES (NEW.id_usuario,NEW.id_juego,NEW.fecha_comentario, null);
    ELSE
        UPDATE G05_COMENTA SET fecha_ultimo_com = NEW.fecha_comentario WHERE id_juego = NEW.id_juego AND id_usuario = NEW.id_usuario;
    END IF;
    RETURN NEW;
END
$$
    LANGUAGE 'plpgsql';

-- 2- Dado un patrón de búsqueda devolver todos los datos de el o los usuarios junto con la cantidad de
-- juegos que ha jugado y la cantidad de votos que ha realizado

CREATE VIEW Patron_Busqueda AS
    SELECT
       id_usuario, apellido, nombre, email, id_tipo_usuario, password
        FROM G05_USUARIO
                        ;