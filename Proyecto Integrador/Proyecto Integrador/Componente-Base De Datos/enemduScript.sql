-- ------------------------------ Creación Usuario ------------------------------------
CREATE USER 'EnemduUser' IDENTIFIED BY 'mysql';
GRANT USAGE, SELECT
    ON enemdu.* TO 'EnemduUser';

FLUSH PRIVILEGES;


-- --------------------------------------- Esquema --------------------------------------
CREATE SCHEMA IF NOT EXISTS `ENEMDU` DEFAULT CHARACTER SET utf8;
USE `ENEMDU`;

USE ENEMDU;
SELECT *
FROM enemdu;

-- -------------------------------- Agregar la nueva columna ----------------------------
ALTER TABLE enemdu
    ADD ID INT AUTO_INCREMENT PRIMARY KEY;

-- -------------------------------- Normalización Ciudad --------------------------------
DROP TABLE IF EXISTS ciudad;
Create Table ciudad AS
Select distinct ciudad
from enemdu;

alter table ciudad
    add constraint ciudad_pk
        primary key (ciudad);

alter table ciudad
    add Nombre CHAR null;

ALTER TABLE Ciudad
    MODIFY COLUMN Nombre VARCHAR(255);

UPDATE Ciudad
    JOIN codigos_postales ON Ciudad.Ciudad = codigos_postales.codigo
SET Ciudad.Nombre = codigos_postales.parroquia_ciudad;

-- ------------------------------------------------------------------------------------

Create Table ciudad AS
Select distinct ciudad as codigoPostal
from enemdu;

alter table ciudad
    add constraint ciudad_pk
        primary key (codigoPostal);

alter table ciudad
    add Nombre VARCHAR(225) null;

UPDATE Ciudad
    JOIN codigos_postales ON Ciudad.ciudad = codigos_postales.codigo
SET Ciudad.Nombre = codigos_postales.parroquia_ciudad;

-- -------------------------------------------------------------------------------------------------------
ALTER TABLE ciudad
    ADD COLUMN Con_Analfabetismo   DECIMAL(10, 2),
    ADD COLUMN Sin_Analfabetismo   DECIMAL(10, 2),
    ADD COLUMN Nulos_Analfabetismo DECIMAL(10, 2);

INSERT INTO Ciudad (codigoPostal, Nombre, Con_Analfabetismo, Sin_Analfabetismo, Nulos_Analfabetismo)
SELECT datos.ciudad,
       '',
       SUM(CASE WHEN datos.analfabetismo = '2' THEN datos.percentage END),
       SUM(CASE WHEN datos.analfabetismo = '1' THEN datos.percentage END),
       COALESCE(100.0 - SUM(CASE WHEN datos.analfabetismo IN ('1', '2') THEN datos.percentage END),
           0.00)
FROM (SELECT ciudad,
             p11                                                         AS analfabetismo,
             COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY ciudad) AS percentage
      FROM persona
      GROUP BY ciudad, p11) AS datos
GROUP BY datos.ciudad
ON DUPLICATE KEY UPDATE Con_Analfabetismo   = VALUES(Con_Analfabetismo),
                        Sin_Analfabetismo   = VALUES(Sin_Analfabetismo),
                        Nulos_Analfabetismo = VALUES(Nulos_Analfabetismo);

-- -------------------------------------------------------------------------------------------------------


ALTER TABLE ciudad
    ADD COLUMN Posee_Titulo   DECIMAL(10, 2),
    ADD COLUMN NoPosee_Titulo DECIMAL(10, 2),
    ADD COLUMN Nulos_Titulo   DECIMAL(10, 2);

INSERT INTO Ciudad (codigoPostal, Nombre, NoPosee_Titulo, Posee_Titulo, Nulos_Titulo)
SELECT datos.ciudad,
       '',
       SUM(CASE WHEN datos.titulo = '2' THEN datos.percentage END),
       SUM(CASE WHEN datos.titulo = '1' THEN datos.percentage END),
       COALESCE(100.0 - SUM(CASE WHEN datos.titulo IN ('1', '2') THEN datos.percentage END), 0.00)
FROM (SELECT ciudad,
             p12a                                                        AS titulo,
             COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY ciudad) AS percentage
      FROM persona
      GROUP BY ciudad, p12a) AS datos
GROUP BY datos.ciudad
ON DUPLICATE KEY UPDATE NoPosee_Titulo = VALUES(NoPosee_Titulo),
                        Posee_Titulo   = VALUES(Posee_Titulo),
                        Nulos_Titulo   = VALUES(Nulos_Titulo);

-- -------------------------------------------------------------------------------------------------------


ALTER TABLE ciudad
    ADD COLUMN Vivienda_Trabajo    DECIMAL(10, 2),
    ADD COLUMN No_Vivienda_Trabajo DECIMAL(10, 2),
    ADD COLUMN Nulos_Vivienda      DECIMAL(10, 2);

INSERT INTO Ciudad (codigoPostal, Nombre, No_Vivienda_Trabajo, Vivienda_Trabajo, Nulos_Vivienda)
SELECT datos.ciudad,
       '',
       SUM(CASE WHEN datos.trabajo = '2' THEN datos.percentage END),
       SUM(CASE WHEN datos.trabajo = '1' THEN datos.percentage END),
       COALESCE(100.0 - SUM(CASE WHEN datos.trabajo IN ('1', '2') THEN datos.percentage END), 0.00)
FROM (SELECT ciudad,
             p12a                                                        AS trabajo,
             COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY ciudad) AS percentage
      FROM persona
      GROUP BY ciudad, p12a) AS datos
GROUP BY datos.ciudad
ON DUPLICATE KEY UPDATE No_Vivienda_Trabajo = VALUES(No_Vivienda_Trabajo),
                        Vivienda_Trabajo    = VALUES(Vivienda_Trabajo),
                        Nulos_Vivienda      = VALUES(Nulos_Vivienda);

-- -------------------------------------------------------------------------------------------------------

Select Distinct p15aa
from persona;

ALTER TABLE ciudad
    ADD COLUMN Nativo      DECIMAL(10, 2),
    ADD COLUMN Ecuatoriano DECIMAL(10, 2),
    ADD COLUMN Extranjero  DECIMAL(10, 2);


INSERT INTO Ciudad (codigoPostal, Nombre, Nativo, Ecuatoriano, Extranjero)
SELECT datos.ciudad,
       '',
       SUM(CASE WHEN datos.residente = '1' THEN datos.percentage END),
       SUM(CASE WHEN datos.residente = '2' THEN datos.percentage END),
       COALESCE(100.0 - SUM(CASE WHEN datos.residente IN ('1', '2') THEN datos.percentage END), 0.00)
FROM (SELECT ciudad,
             p15aa                                                       AS residente,
             COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY ciudad) AS percentage
      FROM persona
      GROUP BY ciudad, p15aa) AS datos
WHERE datos.residente IN ('1', '2', '3')
GROUP BY datos.ciudad
ON DUPLICATE KEY UPDATE Nativo      = VALUES(Nativo),
                        Ecuatoriano = VALUES(Ecuatoriano),
                        Extranjero  = VALUES(Extranjero);


-- -------------------------------- Normalización Vivienda --------------------------------
DROP TABLE IF EXISTS vivienda;
CREATE TABLE vivienda
AS
SELECT id_vivienda  as idVivienda,
       id_hogar     as idHogar,
       vivienda     as numeroVivienda,
       hogar        as numeroHogar,
       vi02         as tipoVivienda,
       vi144        as relacion_parentesco,
       vi01         as viaAcceso,
       area         as area,
       ciudad as codigoPostal

FROM enemdu e
         INNER JOIN ciudad c
                    ON e.ciudad = c.codigoPostal;

alter table vivienda
    add constraint vivienda_pk
        primary key (idVivienda, idHogar, numeroVivienda, numeroHogar),
    add constraint vivienda_fk
        foreign key (codigoPostal) references ciudad (codigoPostal);

-- -------------------------------- Normalización Hogar --------------------------------
DROP TABLE IF EXISTS hogar;
CREATE TABLE hogar
AS
SELECT ID             as id_unico_hogar,
       idVivienda     as idVivienda,
       idHogar        as idHogar,
       numeroVivienda as numeroVivienda,
       numeroHogar    as numeroHogar,
       vi06           as nroCuartos,
       vi07           as nroDormitorios,
       vi07a          as nroCuartosNegocio,
       vi07b          as cocina,
       vi08           as combustibleCocina
FROM enemdu e
         INNER JOIN vivienda v
                    ON e.id_vivienda = v.idVivienda
                        AND e.id_hogar = v.idHogar
                        AND e.vivienda = v.numeroVivienda
                        AND e.hogar = v.numeroHogar;

alter table hogar
    add constraint hogar_pk
        primary key (id_unico_hogar),
    add constraint hogar_fk
        foreign key (idVivienda, idHogar, numeroVivienda, numeroHogar)
            references vivienda (idVivienda, idHogar, numeroVivienda, numeroHogar);

-- -------------------------------- Normalización  Servicios Higienicos --------------------------------

CREATE TABLE servicios_higienico
AS
SELECT ID             as id_unico_higienico,
       id_unico_hogar as id_unico_hogar,
       vi09           as tipoServicioHigienico,
       vi09a          as sinServicioHigienico,
       vi09b          as instalacionSanitaria
FROM enemdu e
         INNER JOIN hogar h
                    ON e.ID = h.id_unico_hogar;

alter table servicios_higienico
    add constraint servicios_higienico_pk
        primary key (id_unico_higienico),
    add constraint servicios_higienico_fk
        foreign key (id_unico_hogar) references hogar (id_unico_hogar);

-- -------------------------------- Normalización Servicios Basicos--------------------------------

DROP TABLE IF EXISTS servicios_basicos;
CREATE TABLE servicios_basicos
AS
SELECT idVivienda     as idVivienda,
       idHogar        as idHogar,
       numeroVivienda as numeroVivienda,
       numeroHogar    as numeroHogar,
       vi10           as obtencionAgua,
       vi101          as medidorAgua,
       vi102          as juntaAgua,
       vi10a          as aguaRecibida,
       vi11           as servicioDucha,
       vi12           as tipoAlumbrado,
       vi13           as eliminacionBasura
FROM enemdu e
         INNER JOIN vivienda v
                    ON e.id_vivienda = v.idVivienda
                        AND e.id_hogar = v.idHogar
                        AND e.vivienda = v.numeroVivienda
                        AND e.hogar = v.numeroHogar;

alter table servicios_basicos
    add constraint servicios_basicos_pk
        primary key (idVivienda, idHogar, numeroVivienda, numeroHogar),
    add constraint servicios_basicos_pk
        foreign key (idVivienda, idHogar, numeroVivienda, numeroHogar)
            references vivienda (idVivienda, idHogar, numeroVivienda, numeroHogar);
-- -------------------------------- Normalización Medio Transporte --------------------------------

CREATE TABLE medio_transporte
AS
SELECT ID             as id_unico_medio_transporte,
       idVivienda     as idVivienda,
       idHogar        as idHogar,
       numeroVivienda as numeroVivienda,
       numeroHogar    as numeroHogar,
       vi1511         as vehiculoHogar,
       vi1521         as cantidadVehiculos,
       vi1512         as motosHogar,
       vi1522         as cantidadMotos
FROM enemdu e
         INNER JOIN vivienda v
                    ON e.id_vivienda = v.idVivienda
                        AND e.id_hogar = v.idHogar
                        AND e.vivienda = v.numeroVivienda
                        AND e.hogar = v.numeroHogar;

alter table medio_transporte
    add constraint medio_transporte_pk
        primary key (id_unico_medio_transporte),
    add constraint medio_transporte_fk
        foreign key (idVivienda, idHogar, numeroVivienda, numeroHogar)
            references vivienda (idVivienda, idHogar, numeroVivienda, numeroHogar);

-- -------------------------------- Normalización Arriendo --------------------------------

CREATE TABLE arriendo
AS
SELECT idVivienda     as idVivienda,
       idHogar        as idHogar,
       numeroVivienda as numeroVivienda,
       numeroHogar    as numeroHogar,
       vi14           as tipoArriendo,
       vi141          as montoPagar,
       vi142          as incluirAgua,
       vi143          as incluirLuz
FROM enemdu e
         INNER JOIN vivienda v
                    ON e.id_vivienda = v.idVivienda
                        AND e.id_hogar = v.idHogar
                        AND e.vivienda = v.numeroVivienda
                        AND e.hogar = v.numeroHogar;

alter table arriendo
    add constraint arriendo_pk
        primary key (idVivienda, idHogar, numeroVivienda, numeroHogar),
    add constraint arriendo_fk
        foreign key (idVivienda, idHogar, numeroVivienda, numeroHogar)
            references vivienda (idVivienda, idHogar, numeroVivienda, numeroHogar);

-- -------------------------------- Normalización Cubierta --------------------------------

DROP TABLE IF EXISTS cubierta;
CREATE TABLE cubierta
AS
SELECT idVivienda     as idVivienda,
       idHogar        as idHogar,
       numeroVivienda as numeroVivienda,
       numeroHogar    as numeroHogar,
       vi03a          as materialTecho,
       vi03b          as estadoTecho
FROM enemdu e
         INNER JOIN vivienda v
                    ON e.id_vivienda = v.idVivienda
                        AND e.id_hogar = v.idHogar
                        AND e.vivienda = v.numeroVivienda
                        AND e.hogar = v.numeroHogar;

alter table cubierta
    add constraint cubierta_pk
        primary key (idVivienda, idHogar, numeroVivienda, numeroHogar),
    add constraint cubierta_fk
        foreign key (idVivienda, idHogar, numeroVivienda, numeroHogar)
            references vivienda (idVivienda, idHogar, numeroVivienda, numeroHogar);


-- -------------------------------- Normalización Suelos --------------------------------
DROP TABLE IF EXISTS suelos;
CREATE TABLE suelos
AS
SELECT idVivienda     as idVivienda,
       idHogar        as idHogar,
       numeroVivienda as numeroVivienda,
       numeroHogar    as numeroHogar,
       vi04a          as materialPiso,
       vi04b          as estadoPiso
FROM enemdu e
         INNER JOIN vivienda v
                    ON e.id_vivienda = v.idVivienda
                        AND e.id_hogar = v.idHogar
                        AND e.vivienda = v.numeroVivienda
                        AND e.hogar = v.numeroHogar;

alter table suelos
    add constraint suelos_pk
        primary key (idVivienda, idHogar, numeroVivienda, numeroHogar),
    add constraint suelos_fk
        foreign key (idVivienda, idHogar, numeroVivienda, numeroHogar)
            references vivienda (idVivienda, idHogar, numeroVivienda, numeroHogar);

-- -------------------------------- Normalización Muros --------------------------------
DROP TABLE IF EXISTS muros;
CREATE TABLE muros
AS
select idVivienda     as idVivienda,
       idHogar        as idHogar,
       numeroVivienda as numeroVivienda,
       numeroHogar    as numeroHogar,
       vi05a          as materialParedes,
       vi05b          as estadoParedes
FROM enemdu e
         INNER JOIN vivienda v
                    ON e.id_vivienda = v.idVivienda
                        AND e.id_hogar = v.idHogar
                        AND e.vivienda = v.numeroVivienda
                        AND e.hogar = v.numeroHogar;

alter table muros
    add constraint muros_pk
        primary key (idVivienda, idHogar, numeroVivienda, numeroHogar),
    add constraint muros_fk
        foreign key (idVivienda, idHogar, numeroVivienda, numeroHogar)
            references vivienda (idVivienda, idHogar, numeroVivienda, numeroHogar);

-- -------------------------------- Normalización Combustible --------------------------------

DROP TABLE if exists combustible;
CREATE TABLE combustible
AS
SELECT ID     as id_unico_combustible,
       vi1531 as super,
       vi1541 as gasto_super,
       vi1532 as extra,
       vi1542 as gasto_extra,
       vi1533 as diesel,
       vi1543 as gasto_diesel,
       vi1534 as ecopais,
       vi1544 as gasto_ecopais,
       vi1535 as electricidad,
       vi1545 as gasto_electricidad,
       vi1536 as gas,
       vi1546 as gasto_gas
FROM enemdu;

alter table combustible
    add constraint combustible_pk
        primary key (id_unico_combustible);

-- ----------------------------- Normalización Transporte Combustible ---------------------

DROP TABLE IF EXISTS trasnporte_combustible;

CREATE TABLE trasnporte_combustible
AS
SELECT id_unico_combustible      as id_unico_combustible,
       id_unico_medio_transporte as id_unico_medio_transporte
FROM combustible c
         INNER JOIN medio_transporte mt
                    ON c.id_unico_combustible = mt.id_unico_medio_transporte;


alter table trasnporte_combustible
    add constraint trasnporte_combustible_fk
        foreign key (id_unico_combustible) references combustible (id_unico_combustible),
    add constraint trasnporte_combustible2_fk
        foreign key (id_unico_medio_transporte) references medio_transporte (id_unico_medio_transporte);

-- ----------------------------------- Conversion a CSV ----------------------------------


SELECT 'codigoPostal',
       'Nombre',
       'Con_Analfabetismo',
       'Sin_Analfabetismo',
       'Nulos_Analfabetismo',
       'Posee_Titulo',
       'NoPosee_Titulo',
       'Nulos_Titulo',
       'Vivienda_Trabajo',
       'No_Vivienda_Trabajo',
       'Nulos_Vivienda',
       'Nativo',
       'Ecuatoriano',
       'Extranjero',
       'idVivienda',
       'idHogar',
       'numeroHogar',
       'numeroVivienda',
       'tipoVivienda',
       'relacion_parentesco',
       'viaAcceso',
       'area',
       'id_unico_hogar',
       'nroCuartos',
       'nroCuartosNegocio',
       'cocina',
       'combustibleCocina',
       'id_unico_higienico',
       'tipoServicioHigienico',
       'sinServicioHigienico',
       'instalacionSanitaria',
       'obtencionAgua',
       'medidorAgua',
       'juntaAgua',
       'aguaRecibida',
       'servicioDucha',
       'tipoAlumbrado',
       'eliminacionBasura',
       'id_unico_medio_transporte',
       'vehiculoHogar',
       'cantidadVehiculos',
       'motosHogar',
       'cantidadMotos',
       'tipoArriendo',
       'montoPagar',
       'incluirAgua',
       'incluirLuz',
       'materialTecho',
       'estadoTecho',
       'materialPiso',
       'estadoPiso',
       'materialParedes',
       'estadoParedes',
       'id_unico_combustible',
       'super',
       'gasto_super',
       'extra',
       'gasto_extra',
       'diesel',
       'gasto_diesel',
       'ecopais',
       'gasto_ecopais',
       'electricidad',
       'gasto_electricidad',
       'gas',
       'gasto_gas'

UNION

SELECT c.codigoPostal,
       c.Nombre,
       c.Con_Analfabetismo,
       c.Sin_Analfabetismo,
       c.Nulos_Analfabetismo,
       c.Posee_Titulo,
       c.NoPosee_Titulo,
       c.Nulos_Titulo,
       c.Vivienda_Trabajo,
       c.No_Vivienda_Trabajo,
       c.Nulos_Vivienda,
       c.Nativo,
       c.Ecuatoriano,
       c.Extranjero,
       v.idVivienda,
       v.idHogar,
       v.numeroHogar,
       v.numeroVivienda,
       v.tipoVivienda,
       v.relacion_parentesco,
       v.viaAcceso,
       v.area,
       h.id_unico_hogar,
       h.nroCuartos,
       h.nroCuartosNegocio,
       h.cocina,
       h.combustibleCocina,
       sh.id_unico_higienico,
       sh.tipoServicioHigienico,
       sh.sinServicioHigienico,
       sh.instalacionSanitaria,
       sb.obtencionAgua,
       sb.medidorAgua,
       sb.juntaAgua,
       sb.aguaRecibida,
       sb.servicioDucha,
       sb.tipoAlumbrado,
       sb.eliminacionBasura,
       mt.id_unico_medio_transporte,
       mt.vehiculoHogar,
       mt.cantidadVehiculos,
       mt.motosHogar,
       mt.cantidadMotos,
       a.tipoArriendo,
       a.montoPagar,
       a.incluirAgua,
       a.incluirLuz,
       cu.materialTecho,
       cu.estadoTecho,
       su.materialPiso,
       su.estadoPiso,
       mu.materialParedes,
       mu.estadoParedes,
       cos.id_unico_combustible,
       cos.super,
       cos.gasto_super,
       cos.extra,
       cos.gasto_extra,
       cos.diesel,
       cos.gasto_diesel,
       cos.ecopais,
       cos.gasto_ecopais,
       cos.electricidad,
       cos.gasto_electricidad,
       cos.gas,
       cos.gasto_gas

FROM ciudad c
         INNER JOIN vivienda v ON c.codigoPostal = v.codigoPostal
         JOIN hogar h ON h.idVivienda = v.idVivienda
    AND h.idHogar = v.idHogar
    AND h.numeroVivienda = v.numeroVivienda
    AND h.numeroHogar = v.numeroHogar
         JOIN servicios_higienico sh ON h.id_unico_hogar = sh.id_unico_hogar
         JOIN servicios_basicos sb ON sb.idVivienda = v.idVivienda
    AND sb.idHogar = v.idHogar
    AND sb.numeroVivienda = v.numeroVivienda
    AND sb.numeroHogar = v.numeroHogar
         JOIN medio_transporte mt ON mt.idVivienda = v.idVivienda
    AND mt.idHogar = v.idHogar
    AND mt.numeroVivienda = v.numeroVivienda
    AND mt.numeroHogar = v.numeroHogar
         JOIN arriendo a ON a.idVivienda = v.idVivienda
    AND a.idHogar = v.idHogar
    AND a.numeroVivienda = v.numeroVivienda
    AND a.numeroHogar = v.numeroHogar
         JOIN cubierta cu ON cu.idVivienda = v.idVivienda
    AND cu.idHogar = v.idHogar
    AND cu.numeroVivienda = v.numeroVivienda
    AND cu.numeroHogar = v.numeroHogar
         JOIN suelos su ON su.idVivienda = v.idVivienda
    AND su.idHogar = v.idHogar
    AND su.numeroVivienda = v.numeroVivienda
    AND su.numeroHogar = v.numeroHogar
         JOIN muros mu ON mu.idVivienda = v.idVivienda
    AND mu.idHogar = v.idHogar
    AND mu.numeroVivienda = v.numeroVivienda
    AND mu.numeroHogar = v.numeroHogar
         JOIN trasnporte_combustible tc ON mt.id_unico_medio_transporte = tc.id_unico_medio_transporte
         JOIN combustible cos ON tc.id_unico_combustible = cos.id_unico_combustible

INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Final.csv'
    FIELDS TERMINATED BY ','
    ENCLOSED BY '"'
    LINES TERMINATED BY '\n';

