--La fecha del primer comentario tiene que ser anterior a la fecha del último comentario si este no es nulo.

CREATE TRIGGER Control_of_Date BEFORE
    INSERT on G05_COMENTARIO
    FOR EACH ROW
    WHEN (NEW.comentario <> null)
    execute procedure FN_Date_Message();

CREATE OR REPLACE FUNCTION FN_Date_Message()
    RETURNS TRIGGER AS $$
        declare
        fecha_primer_coment timestamp;
        BEGIN
            SELECT fecha_comentario into fecha_primer_coment
                FROM G05_COMENTARIO
                WHERE id_comentario = NEW.id_comentario
                AND id_juego = NEW.id_juego;
            IF (fecha_primer_coment > NEW.fecha_comentario) THEN
                raise exception 'La fecha de su ultimo comentario es anterior a su primer comentario';
            END IF;
        return NEW;
        end;
    $$language 'plpgsql';

--Cada usuario sólo puede comentar una vez al día cada juego.
CREATE TRIGGER Control_Date_Day BEFORE
    INSERT on G05_COMENTA
    FOR EACH ROW
    execute procedure FN_Date_Day();

CREATE OR REPLACE FUNCTION FN_Date_Day()
    RETURNS TRIGGER AS $$
        declare fecha_ult_coment timestamp;
        BEGIN
            SELECT fecha_comentario into fecha_ult_coment
                FROM G05_COMENTARIO
                where new.id_usuario = id_usuario AND
                new.id_juego = id_juego AND
                (fecha_comentario = NEW.fecha_comentario);
            IF (fecha_ult_coment) THEN
                raise exception 'ya hiciste un comentario en el dia de hoy';
            END IF;
        return NEW;
        end;
    $$language 'plpgsql';

--Un usuario no puede recomendar un juego si no ha votado previamente dicho juego.

CREATE TRIGGER Control_Vote AFTER
    INSERT or UPDATE of id_usuario, id_juego on G05_RECOMENDACION
    FOR EACH ROW
    execute procedure FN_Date_Day();

CREATE OR REPLACE FUNCTION FN_Control_Vote()
    RETURNS TRIGGER AS $$
        declare usuario int;
        declare juego int;
        BEGIN
            SELECT id_usuario, id_juego into usuario, juego
                FROM G05_VOTO v
                where new.id_usuario = v.id_usuario;

            IF (usuario = new.id_usuario AND juego = new.id_juego) THEN
                raise exception 'No puedes recomendar sin antes votar el juego';
            END IF;
        end;
    $$language 'plpgsql';

--Un usuario no puede comentar un juego que no ha jugado.

CREATE TRIGGER CONTROL_COMENT_JUEGO BEFORE INSERT
    ON G05_COMENTARIO
    FOR EACH ROW
    execute procedure FN_CONTROL_COMENT_JUEGO();

CREATE OR REPLACE FUNCTION FN_G03_COMENTAR_JUEGO() RETURNS Trigger AS
$$
DECLARE
    usuario G05_JUEGA.id_usuario%type;
    juego G05_JUEGA.id_juego%type;
BEGIN
    SELECT id_usuario, id_juego into usuario, juego
    FROM G05_JUEGA
    WHERE id_usuario = NEW.id_usuario
      AND id_juego = NEW.id_juego;
    IF (usuario <> NEW.id_usuario
        AND juego <> NEW.id_juego) THEN
        RAISE EXCEPTION 'No puedes votar un juego que no has jugado';
    END IF;
    RETURN NEW;
END
$$
    LANGUAGE 'plpgsql';