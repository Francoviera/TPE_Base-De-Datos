--La fecha del primer comentario tiene que ser anterior a la fecha del último comentario si este no es nulo.

/*
--ALTER TABLE GR05_COMENTA ADD CONSTRAINT CK_GR05_DATE_CONTROL
--CHECK ( NOT EXIST (
    SELECT fecha_primer_com
        FROM GR05_COMENTA
        WHERE fecha_primer_com > fecha_ultimo_com;))
 */

CREATE TRIGGER TR_GR05_COMENTARIO_Date_Control BEFORE
    INSERT on GR05_COMENTARIO
    FOR EACH ROW
    execute procedure FN_GR05_Date_Control();

CREATE OR REPLACE FUNCTION FN_GR05_Date_Control()
    RETURNS TRIGGER AS $$
        declare
            fecha_primer_coment GR05_COMENTA.fecha_primer_com%type;
            fecha_ult_coment GR05_COMENTA.fecha_ultimo_com%type;
        BEGIN
            SELECT fecha_primer_com, fecha_ultimo_com into fecha_primer_coment, fecha_ult_coment
                FROM GR05_COMENTA
                WHERE id_usuario = NEW.id_usuario
                AND id_juego = NEW.id_juego;
            IF (fecha_ult_coment is not null AND fecha_primer_coment > NEW.fecha_comentario) THEN
                raise exception 'La fecha de su ultimo comentario es anterior a su primer comentario';
            END IF;
        return NEW;
        end;
    $$language 'plpgsql';

--Cada usuario sólo puede comentar una vez al día cada juego.

/*
ALTER TABLE GR05_COMENTARIO ADD CONSTRAINT CK_GR05_DATE_CONTROL_DAY
        CHECK (NOT EXISTS(
                SELECT 1
                FROM GR05_COMENTARIO
                group by fecha_comentario
                --group by extract('DAY' FROM fecha_comentario), extract('MONTH' FROM fecha_comentario), extract('YEAR' FROM fecha_comentario)
                having COUNT(*)>1
            ));
*/

CREATE TRIGGER TR_GR05_Date_Control_Day BEFORE
    INSERT on GR05_COMENTARIO
    FOR EACH ROW
    execute procedure FN_GR05_Date_Control_Day();

CREATE OR REPLACE FUNCTION FN_GR05_Date_Control_Day()
    RETURNS TRIGGER AS $$
        declare fecha_ult_coment GR05_COMENTA.fecha_ultimo_com%type;
        BEGIN
            SELECT fecha_ultimo_com into fecha_ult_coment
                FROM GR05_COMENTA
                where new.id_usuario = id_usuario AND
                new.id_juego = id_juego AND
                fecha_ultimo_com = new.fecha_comentario;
                --(EXTRACT('DAY' FROM fecha_ult_coment) = EXTRACT('DAY' FROM NEW.fecha_comentario) AND
                 --EXTRACT('MONTH' FROM fecha_ult_coment) = EXTRACT('MONTH' FROM NEW.fecha_comentario) AND
                 --EXTRACT('YEAR' FROM fecha_ult_coment) = EXTRACT('YEAR' FROM NEW.fecha_comentario));
            IF (fecha_ult_coment is not null) THEN
                raise exception 'ya hiciste un comentario en el dia de hoy';
            END IF;
        return NEW;
        end
    $$language 'plpgsql';

--Un usuario no puede recomendar un juego si no ha votado previamente dicho juego.

/*
ALTER TABLE g03_comentario
    ADD CONSTRAINT CK_GR05_VOTE_CONTROL
        CHECK (NOT EXISTS(
            SELECT 1
            FROM GR05_RECOMENDACION
            WHERE id_usuario, id_juego NOT EXIST (
                SELECT id_usuario, id_juego
                    FROM GR05_VOTO )
        ));
*/

CREATE TRIGGER TR_GR05_Vote_Control AFTER
    INSERT or UPDATE of id_usuario, id_juego on GR05_RECOMENDACION
    FOR EACH ROW
    execute procedure FN_GR05_Vote_Control();

CREATE OR REPLACE FUNCTION FN_GR05_Vote_Control()
    RETURNS TRIGGER AS $$
        declare usuario GR05_VOTO.id_usuario%type;
        --declare juego GR05_VOTO.id_juego%type;
        BEGIN
            SELECT id_usuario into usuario
                FROM GR05_VOTO v
                where new.id_usuario = v.id_usuario AND
                      new.id_juego = v.id_juego;

            IF (usuario is null) THEN
            --IF NOT (usuario AND juego) THEN
                raise exception 'No puedes recomendar sin antes votar el juego';
            END IF;
        RETURN NEW;
        end;
    $$language 'plpgsql';

--Un usuario no puede comentar un juego que no ha jugado.

/*
ALTER TABLE g03_comentario
    ADD CONSTRAINT CK_GR05_GAME_COMENT
        CHECK (NOT EXISTS(
            SELECT 1
            FROM GR05_COMENTARIO
            WHERE id_usuario, id_juego NOT EXIST (
                SELECT id_usuario, id_juego
                    FROM GR05_JUEGA )
        ));
*/

CREATE TRIGGER TR_GR05_CONTROL_GAME_COMENT BEFORE INSERT
    ON GR05_COMENTARIO
    FOR EACH ROW
    execute procedure FN_G05_CONTROL_GAME_COMENT();

CREATE OR REPLACE FUNCTION FN_G05_CONTROL_GAME_COMENT() RETURNS Trigger AS
$$
DECLARE
    usuario GR05_JUEGA.id_usuario%type;
    --juego GR05_JUEGA.id_juego%type;
BEGIN
    SELECT id_usuario into usuario
    FROM GR05_JUEGA
    WHERE id_usuario = NEW.id_usuario
      AND id_juego = NEW.id_juego;
        IF (usuario is null)THEN
       --IF NOT (usuario AND juego) THEN
        RAISE EXCEPTION 'No puedes Comentar un juego que no has jugado';
    END IF;
    RETURN NEW;
END
$$
    LANGUAGE 'plpgsql';