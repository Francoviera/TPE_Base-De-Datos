--La fecha del primer comentario tiene que ser anterior a la fecha del último comentario si este no es nulo.

ALTER TABLE GR05_COMENTARIO ADD CONSTRAINT CK_GR05_FECHA_COMENTARIO
CHECK( NOT EXIST (
            SELECT x
            FROM GR05_COMENTA
            WHERE fecha_comentario > fecha_primer_com;))

--Cada usuario sólo puede comentar una vez al día cada juego.

ALTER TABLE GR05_COMENTARIO ADD CONSTRAINT CK_GR05_COMENTARIO_DIARIO
CHECK( NOT EXIST (
            SELECT x
            FROM GR05_COMENTA c
            WHERE id_usuario = NEW.id_usuario
              AND id_juego = NEW.id_juego AND
              (EXTRACT('DAY' FROM fecha_ult_coment) = EXTRACT('DAY' FROM NEW.fecha_comentario) AND
                 EXTRACT('MONTH' FROM fecha_ult_coment) = EXTRACT('MONTH' FROM NEW.fecha_comentario) AND
                 EXTRACT('YEAR' FROM fecha_ult_coment) = EXTRACT('YEAR' FROM NEW.fecha_comentario);))

--Un usuario no puede recomendar un juego si no ha votado previamente dicho juego.



--Un usuario no puede comentar un juego que no ha jugado.