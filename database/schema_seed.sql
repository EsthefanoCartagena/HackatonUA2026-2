-- ==========================================
-- 1. CREACIÓN DE TABLAS (POSTGRES / SUPABASE)
-- ==========================================

CREATE TABLE IF NOT EXISTS usuario (
    id_usuario SERIAL PRIMARY KEY,
    dni VARCHAR(15) UNIQUE NOT NULL,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    telefono VARCHAR(20),
    rol VARCHAR(20) DEFAULT 'CIUDADANO', -- 'CIUDADANO' | 'ADMIN'
    perfil_accesibilidad VARCHAR(30) DEFAULT 'ESTANDAR', -- 'VISUAL' | 'AUDITIVA' | 'HABLA' | 'ADULTO_MAYOR' | 'ESTANDAR'
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tipo_tramite (
    id_tipo SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion_simple TEXT NOT NULL,
    icono VARCHAR(50),
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS tramite (
    id_tramite SERIAL PRIMARY KEY,
    codigo_seguimiento VARCHAR(20) UNIQUE NOT NULL,
    id_usuario INT NOT NULL REFERENCES usuario(id_usuario),
    id_tipo INT NOT NULL REFERENCES tipo_tramite(id_tipo),
    datos_adicionales TEXT,
    estado_actual VARCHAR(25) DEFAULT 'PENDIENTE', -- 'PENDIENTE' | 'EN_PROCESO' | 'APROBADO' | 'OBSERVADO'
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS historial_estado (
    id_historial SERIAL PRIMARY KEY,
    id_tramite INT NOT NULL REFERENCES tramite(id_tramite),
    estado_anterior VARCHAR(25),
    estado_nuevo VARCHAR(25) NOT NULL,
    comentario TEXT,
    fecha_cambio TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS incidencia (
    id_incidencia SERIAL PRIMARY KEY,
    id_usuario INT REFERENCES usuario(id_usuario),
    id_tramite INT REFERENCES tramite(id_tramite),
    tipo_incidencia VARCHAR(50) NOT NULL, -- 'BARRERA_ACCESIBILIDAD' | 'ERROR_DATOS' | 'SOPORTE_ASISTIDO'
    descripcion TEXT NOT NULL,
    estado VARCHAR(20) DEFAULT 'ABIERTA', -- 'ABIERTA' | 'EN_REVISION' | 'RESUELTA'
    fecha_reporte TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS documento_tramite (
    id_documento SERIAL PRIMARY KEY,
    id_tramite INT NOT NULL REFERENCES tramite(id_tramite),
    id_incidencia INT REFERENCES incidencia(id_incidencia),
    tipo_documento VARCHAR(30) NOT NULL, -- 'ADJUNTADO_CIUDADANO' | 'EMITIDO_SISTEMA' | 'CONSTANCIA'
    object_key VARCHAR(255) UNIQUE NOT NULL,
    nombre_original VARCHAR(150) NOT NULL,
    mime_type VARCHAR(80) NOT NULL,
    tamano_bytes BIGINT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS chat_token (
    id_token SERIAL PRIMARY KEY,
    token_hash VARCHAR(128) UNIQUE NOT NULL,
    id_tramite INT REFERENCES tramite(id_tramite),
    id_incidencia INT REFERENCES incidencia(id_incidencia),
    destinatario_tipo VARCHAR(25) NOT NULL, -- 'CIUDADANO' | 'OPERADOR' | 'SOPORTE'
    alcance VARCHAR(25) DEFAULT 'CHAT_ESCRITURA', -- 'SOLO_LECTURA' | 'CHAT_ESCRITURA'
    expira_en TIMESTAMP NOT NULL,
    revocado BOOLEAN DEFAULT FALSE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS mensaje_chat (
    id_mensaje SERIAL PRIMARY KEY,
    id_token INT NOT NULL REFERENCES chat_token(id_token),
    remitente_rol VARCHAR(25) NOT NULL, -- 'CIUDADANO' | 'ADMIN' | 'SISTEMA'
    contenido TEXT NOT NULL,
    metadatos_json TEXT,
    enviado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- 2. DATA SEMILLA (SEED DATA PARA DEMO)
-- ==========================================

INSERT INTO usuario (dni, nombres, apellidos, telefono, rol, perfil_accesibilidad) VALUES
('08451234', 'Rosa María', 'Quispe Mamani', '987654321', 'CIUDADANO', 'ADULTO_MAYOR'),
('45129876', 'Carlos Alberto', 'Mendoza Ríos', '912345678', 'CIUDADANO', 'VISUAL'),
('72348901', 'Lucía Fernanda', 'Huamán Torres', '945678123', 'CIUDADANO', 'AUDITIVA'),
('41982345', 'Jorge Luis', 'Paredes Salazar', '998877665', 'CIUDADANO', 'HABLA'),
('70112233', 'María Elena', 'Vargas Soto', '955443322', 'ADMIN', 'ESTANDAR'),
('70445566', 'Diego Andrés', 'Castillo Peña', '966778899', 'ADMIN', 'ESTANDAR');

INSERT INTO tipo_tramite (nombre, descripcion_simple, icono, activo) VALUES
('Cita Médica Prioritaria', 'Reserva tu atención médica en el centro de salud más cercano en 3 pasos.', 'hospital', TRUE),
('Certificado Domiciliario', 'Solicita tu constancia oficial de domicilio sin hacer filas presenciales.', 'home', TRUE),
('Pensión y Apoyo Adulto Mayor', 'Inscripción y actualización de datos para bonos y asistencia social.', 'heart', TRUE),
('Carnet de Discapacidad (CONADIS)', 'Solicitud de emisión o duplicado del carnet de inscripción.', 'accessibility', TRUE),
('Exoneración de Arbitrios', 'Trámite de descuento municipal para adultos mayores y personas con discapacidad.', 'file-check', TRUE);

INSERT INTO tramite (codigo_seguimiento, id_usuario, id_tipo, datos_adicionales, estado_actual) VALUES
('TRM-2026-001', 1, 1, 'Especialidad: Cardiología. Preferencia turno mañana. Solicita lectura por voz.', 'EN_PROCESO'),
('TRM-2026-002', 2, 4, 'Duplicado por pérdida. Usuario navega con lector de pantalla y comandos de voz.', 'PENDIENTE'),
('TRM-2026-003', 3, 2, 'Dirección: Av. Central 450, Villa El Salvador. Comunicación 100% escrita/visual.', 'APROBADO'),
('TRM-2026-004', 4, 5, 'Predio único familiar. Requiere confirmación por mensaje de texto.', 'OBSERVADO'),
('TRM-2026-005', 1, 3, 'Actualización de cuenta de cobro asistida por familiar.', 'PENDIENTE');

INSERT INTO historial_estado (id_tramite, estado_anterior, estado_nuevo, comentario) VALUES
(1, 'PENDIENTE', 'EN_PROCESO', 'Asignado a operador de salud. Verificando disponibilidad en posta local.'),
(3, 'PENDIENTE', 'EN_PROCESO', 'Documentos revisados correctamente.'),
(3, 'EN_PROCESO', 'APROBADO', 'Certificado emitido y subido al repositorio S3.');

INSERT INTO incidencia (id_usuario, id_tramite, tipo_incidencia, descripcion, estado) VALUES
(1, 1, 'SOPORTE_ASISTIDO', 'La ciudadana indica que el texto del comprobante era muy pequeño en su celular.', 'RESUELTA'),
(2, 2, 'BARRERA_ACCESIBILIDAD', 'El botón de adjuntar DNI no tenía etiqueta ARIA descriptiva para lector de pantalla.', 'EN_REVISION'),
(4, 4, 'ERROR_DATOS', 'Falta adjuntar copia simple del recibo de luz para validar dirección.', 'ABIERTA');

INSERT INTO documento_tramite (id_tramite, id_incidencia, tipo_documento, object_key, nombre_original, mime_type, tamano_bytes) VALUES
(1, NULL, 'ADJUNTADO_CIUDADANO', 'tramites/TRM-2026-001/adjuntos/dni-rosa-quispe.pdf', 'dni-rosa-quispe.pdf', 'application/pdf', 245120),
(3, NULL, 'EMITIDO_SISTEMA', 'tramites/TRM-2026-003/emitidos/constancia-TRM-2026-003.pdf', 'constancia-domiciliaria.pdf', 'application/pdf', 189400),
(4, 3, 'ADJUNTADO_CIUDADANO', 'tramites/TRM-2026-004/adjuntos/recibo-luz.jpg', 'recibo-luz.jpg', 'image/jpeg', 512000);

INSERT INTO chat_token (token_hash, id_tramite, id_incidencia, destinatario_tipo, alcance, expira_en, revocado) VALUES
('tok_demo_trm001_ciudadano', 1, NULL, 'CIUDADANO', 'CHAT_ESCRITURA', NOW() + INTERVAL '7 days', FALSE),
('tok_demo_trm004_incidencia', 4, 3, 'CIUDADANO', 'CHAT_ESCRITURA', NOW() + INTERVAL '7 days', FALSE);

INSERT INTO mensaje_chat (id_token, remitente_rol, contenido, metadatos_json) VALUES
(1, 'SISTEMA', 'Hola Rosa María, tu trámite TRM-2026-001 está en proceso. Puedes responder por aquí o dictar tu mensaje.', '{"voz_habilitada": true}'),
(1, 'ADMIN', 'Buen día Sra. Rosa, ya reservamos su cupo para este jueves a las 9:00 AM.', '{"operador": "María Elena"}'),
(2, 'ADMIN', 'Hola Jorge Luis, por favor sube una foto más nítida de tu recibo de luz usando este enlace.', '{"modo": "solo_texto"}');