-- =====================================================================
-- Base de datos del sistema de gestión de alertas de seguridad
-- Sector Tulipanes, Jamundí, Valle del Cauca
-- Trabajo de grado I - Ficha 841A - Grupo G18
-- Motor: MySQL 8.x / MariaDB 10.x (InnoDB, utf8mb4)
--
-- Cómo ejecutarlo (crea la base desde cero, es reproducible):
--   mysql -u root -p < base_datos_alertas_tulipanes.sql
-- Cómo exportarla de nuevo:
--   mysqldump -u root -p alertas_tulipanes > respaldo_alertas_tulipanes.sql
--
-- IMPORTANTE: todos los datos de este archivo son DATOS DE PRUEBA
-- inventados para el ejercicio académico. No hay personas reales.
-- Cambia las claves de los usuarios de la sección 5 antes de usarlo.
-- =====================================================================

-- 1. CREACIÓN DE LA BASE ------------------------------------------------
DROP DATABASE IF EXISTS alertas_tulipanes;
CREATE DATABASE alertas_tulipanes
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE alertas_tulipanes;

-- 2. TABLAS --------------------------------------------------------------
CREATE TABLE usuario (
  id_usuario          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre              VARCHAR(100) NOT NULL,
  correo              VARCHAR(120) NOT NULL,
  contrasena_cifrada  VARCHAR(255) NOT NULL,
  rol                 ENUM('residente','administrador') NOT NULL DEFAULT 'residente',
  fecha_registro      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_usuario),
  UNIQUE KEY uq_usuario_correo (correo)
) ENGINE=InnoDB;

CREATE TABLE tipo_incidente (
  id_tipo   TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre    VARCHAR(50) NOT NULL,
  PRIMARY KEY (id_tipo),
  UNIQUE KEY uq_tipo_nombre (nombre)
) ENGINE=InnoDB;

CREATE TABLE zona (
  id_zona      SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre       VARCHAR(80) NOT NULL,
  descripcion  VARCHAR(255) NULL,
  PRIMARY KEY (id_zona),
  UNIQUE KEY uq_zona_nombre (nombre)
) ENGINE=InnoDB;

CREATE TABLE incidente (
  id_incidente  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_usuario    INT UNSIGNED NOT NULL,
  id_tipo       TINYINT UNSIGNED NOT NULL,
  id_zona       SMALLINT UNSIGNED NOT NULL,
  descripcion   VARCHAR(500) NOT NULL,
  fecha_hora    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  latitud       DECIMAL(9,6) NOT NULL,
  longitud      DECIMAL(9,6) NOT NULL,
  estado        ENUM('pendiente','validado','descartado') NOT NULL DEFAULT 'pendiente',
  PRIMARY KEY (id_incidente),
  CONSTRAINT fk_incidente_usuario FOREIGN KEY (id_usuario)
    REFERENCES usuario (id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_incidente_tipo FOREIGN KEY (id_tipo)
    REFERENCES tipo_incidente (id_tipo) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_incidente_zona FOREIGN KEY (id_zona)
    REFERENCES zona (id_zona) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT ck_incidente_latitud  CHECK (latitud  BETWEEN -90  AND 90),
  CONSTRAINT ck_incidente_longitud CHECK (longitud BETWEEN -180 AND 180),
  INDEX idx_incidente_zona_tipo (id_zona, id_tipo),   -- consultas de HU-05
  INDEX idx_incidente_estado_fecha (estado, fecha_hora) -- listado y mapa (HU-03, HU-04)
) ENGINE=InnoDB;

-- 3. PERMISOS (principio de menor privilegio) ----------------------------
-- La aplicación no puede borrar registros ni cambiar la estructura.
CREATE USER IF NOT EXISTS 'app_residente'@'localhost' IDENTIFIED BY 'CambiarClave_Residente1';
CREATE USER IF NOT EXISTS 'app_admin'@'localhost'     IDENTIFIED BY 'CambiarClave_Admin1';

GRANT SELECT, INSERT ON alertas_tulipanes.usuario        TO 'app_residente'@'localhost';
GRANT SELECT         ON alertas_tulipanes.tipo_incidente TO 'app_residente'@'localhost';
GRANT SELECT         ON alertas_tulipanes.zona           TO 'app_residente'@'localhost';
GRANT SELECT, INSERT ON alertas_tulipanes.incidente      TO 'app_residente'@'localhost';

GRANT SELECT, INSERT, UPDATE ON alertas_tulipanes.usuario        TO 'app_admin'@'localhost';
GRANT SELECT, INSERT, UPDATE ON alertas_tulipanes.tipo_incidente TO 'app_admin'@'localhost';
GRANT SELECT, INSERT, UPDATE ON alertas_tulipanes.zona           TO 'app_admin'@'localhost';
GRANT SELECT, INSERT, UPDATE ON alertas_tulipanes.incidente      TO 'app_admin'@'localhost';

-- 4. DATOS DE CATÁLOGO ---------------------------------------------------
INSERT INTO tipo_incidente (nombre) VALUES
  ('Hurto'), ('Riña'), ('Amenaza'), ('Otro');

INSERT INTO zona (nombre, descripcion) VALUES
  ('Zona Norte',   'Zona de prueba definida para el ejercicio académico'),
  ('Zona Centro',  'Zona de prueba definida para el ejercicio académico'),
  ('Zona Sur',     'Zona de prueba definida para el ejercicio académico'),
  ('Zona Oriente', 'Zona de prueba definida para el ejercicio académico');

-- 5. DATOS DE PRUEBA -----------------------------------------------------
-- Las contraseñas son marcadores de posición: la aplicación debe guardar
-- aquí el resultado de cifrar la clave con bcrypt, nunca la clave en texto.
INSERT INTO usuario (nombre, correo, contrasena_cifrada, rol, fecha_registro) VALUES
  ('Administrador de prueba', 'admin.prueba@example.com',    '$2b$10$DATO.DE.PRUEBA.ADMIN.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', 'administrador', '2026-10-01 08:00:00'),
  ('Residente de prueba 1',   'residente1.prueba@example.com','$2b$10$DATO.DE.PRUEBA.RES1.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', 'residente',     '2026-10-02 09:15:00'),
  ('Residente de prueba 2',   'residente2.prueba@example.com','$2b$10$DATO.DE.PRUEBA.RES2.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', 'residente',     '2026-10-02 10:40:00'),
  ('Residente de prueba 3',   'residente3.prueba@example.com','$2b$10$DATO.DE.PRUEBA.RES3.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', 'residente',     '2026-10-03 18:05:00');

-- Coordenadas aproximadas alrededor de Jamundí (datos inventados para pruebas)
INSERT INTO incidente (id_usuario, id_tipo, id_zona, descripcion, fecha_hora, latitud, longitud, estado) VALUES
  (2, 1, 1, 'Hurto de celular en la vía principal al caer la tarde', '2026-10-05 18:20:00', 3.262100, -76.541200, 'validado'),
  (2, 1, 2, 'Hurto a una persona cerca del paradero',                '2026-10-06 19:05:00', 3.260400, -76.539800, 'validado'),
  (3, 2, 2, 'Riña entre jóvenes en el parque',                       '2026-10-08 21:30:00', 3.259900, -76.538900, 'validado'),
  (3, 3, 3, 'Amenaza entre vecinos por ruido',                       '2026-10-09 20:10:00', 3.257800, -76.540500, 'pendiente'),
  (4, 1, 1, 'Intento de hurto a una motocicleta',                    '2026-10-10 07:45:00', 3.263000, -76.542000, 'validado'),
  (4, 2, 4, 'Riña a la salida de un establecimiento',                '2026-10-11 23:15:00', 3.261500, -76.536700, 'pendiente'),
  (2, 3, 4, 'Amenaza a un comerciante',                              '2026-10-12 16:50:00', 3.262800, -76.537200, 'validado'),
  (3, 1, 3, 'Hurto en una tienda del barrio',                        '2026-10-13 12:25:00', 3.256900, -76.541800, 'descartado'),
  (4, 4, 2, 'Ruido excesivo y consumo en espacio público',           '2026-10-14 22:00:00', 3.260100, -76.540100, 'pendiente'),
  (2, 1, 1, 'Hurto de bicicleta frente a una vivienda',              '2026-10-15 06:40:00', 3.263500, -76.540900, 'validado'),
  (3, 2, 1, 'Riña en la cancha del sector',                          '2026-10-16 17:35:00', 3.262400, -76.543000, 'pendiente'),
  (4, 3, 2, 'Amenaza por mensaje a una residente',                   '2026-10-17 14:20:00', 3.259500, -76.539300, 'validado');

-- 6. CONSULTAS DE COMPROBACIÓN -------------------------------------------
-- C1 (HU-03) Listado de incidentes validados: fecha, tipo y zona (sin nombres)
SELECT i.fecha_hora, t.nombre AS tipo, z.nombre AS zona
FROM incidente i
JOIN tipo_incidente t ON t.id_tipo = i.id_tipo
JOIN zona z ON z.id_zona = i.id_zona
WHERE i.estado = 'validado'
ORDER BY i.fecha_hora DESC;

-- C2 (HU-04) Puntos para el mapa: incidentes validados con coordenadas
SELECT i.id_incidente, t.nombre AS tipo, i.latitud, i.longitud
FROM incidente i
JOIN tipo_incidente t ON t.id_tipo = i.id_tipo
WHERE i.estado = 'validado';

-- C3 (HU-05) Cantidad de incidentes por zona
SELECT z.nombre AS zona, COUNT(*) AS total
FROM incidente i
JOIN zona z ON z.id_zona = i.id_zona
WHERE i.estado <> 'descartado'
GROUP BY z.nombre
ORDER BY total DESC;

-- C4 (HU-05) Cantidad de incidentes por zona y por tipo
SELECT z.nombre AS zona, t.nombre AS tipo, COUNT(*) AS total
FROM incidente i
JOIN zona z ON z.id_zona = i.id_zona
JOIN tipo_incidente t ON t.id_tipo = i.id_tipo
WHERE i.estado <> 'descartado'
GROUP BY z.nombre, t.nombre
ORDER BY z.nombre, total DESC;

-- C5 (HU-06) Validar un reporte pendiente y comprobar el cambio de estado
UPDATE incidente SET estado = 'validado' WHERE id_incidente = 4;
SELECT id_incidente, estado FROM incidente WHERE id_incidente = 4;

-- C6 (integridad) No debe haber incidentes sin usuario, tipo o zona (resultado: 0)
SELECT COUNT(*) AS incidentes_huerfanos
FROM incidente i
LEFT JOIN usuario u ON u.id_usuario = i.id_usuario
LEFT JOIN tipo_incidente t ON t.id_tipo = i.id_tipo
LEFT JOIN zona z ON z.id_zona = i.id_zona
WHERE u.id_usuario IS NULL OR t.id_tipo IS NULL OR z.id_zona IS NULL;

-- C7 (RNF-02) Una prueba de restricción: este INSERT debe FALLAR por correo repetido.
-- Quita los dos guiones de la línea para probarlo:
-- INSERT INTO usuario (nombre, correo, contrasena_cifrada) VALUES ('Repetido', 'admin.prueba@example.com', 'x');
