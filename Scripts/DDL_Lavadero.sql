/* ============================================================================
   AUTORES ........... Juan Camilo Vargas - Pablo Ganboa Riquet - Juan David Delgado
 
   OBJETIVO
   --------
   Crear la estructura completa de la base de datos del lavadero: nueve
   tablas, una secuencia, indices de apoyo para las claves foraneas y la
   documentacion de tablas y columnas en el diccionario de datos de Oracle.

   CONTENIDO
   ---------
   1. Verificacion previa (no debe existir ninguna de las tablas).
   2. Creacion de las 9 tablas en orden de dependencia:
      EMPRESA, CLIENTE, EMPLEADO, SERVICIO, VEHICULO, ORDEN_LAVADO,
      DETALLE_ORDEN, FACTURA, PAGO.
   3. Secuencia SEQ_PAGO (identificadores de nuevos pagos).
   4. Indices sobre claves foraneas.
   5. Comentarios de tablas y columnas (COMMENT ON).
   6. Consultas de verificacion y mensaje final de resultado.

   ORDEN DE EJECUCION DE LOS CUATRO SCRIPTS DEL PROYECTO
   -----------------------------------------------------
   1. DDL_Lavadero.sql          (este archivo)
   2. DML_Lavadero.sql          (datos de prueba)
   3. Consultas_Reportes.sql    (reportes)
   4. PL_SQL_Lavadero.sql       (funcion, procedimiento y trigger)

   COMO EJECUTAR
   -------------
   1. Conectarse en SQL Developer al esquema del proyecto (con permisos
      CREATE TABLE, CREATE SEQUENCE y CREATE INDEX).
   2. Abrir este archivo (Archivo > Abrir) y verificar que la conexion
      seleccionada arriba a la derecha de la hoja es la correcta.
   3. Presionar F5 (Ejecutar script). Revisar la pestana "Salida de script".
   4. El resultado esperado es la fila final "DDL CORRECTO ...".

   REEJECUCION
   -----------
   El script no contiene DROP ni DELETE, por lo que no elimina nada. Si se
   ejecuta por segunda vez en el mismo esquema, Oracle responde ORA-00955
   (el nombre ya esta en uso). Ejecutarlo una sola vez en un esquema limpio.

   MODELO: NUEVE ENTIDADES (DECISIONES DE DISENO RESPECTO AL ER Y AL MR)
   ---------------------------------------------------------------------
   El diagrama ER y el modelo relacional originales tienen ocho entidades.
   Este DDL tiene nueve y corrige defectos del modelo original. Cada
   diferencia esta justificada:

   D1. FACTURA (entidad nueva). Se conserva como novena tabla para
       representar formalmente la facturacion: numero, fecha de emision,
       subtotal, impuestos, total y estado. Permite varios pagos por
       factura y calcular saldos pendientes. Una orden genera cero o una
       factura; una factura recibe cero o varios pagos. Es una ampliacion
       respecto al modelo original y debe reflejarse en el modelo final.
   D2. Se elimina la tabla intermedia Relation_6 (relacion N:M directa entre
       CLIENTE y EMPLEADO). La atencion se consulta por la ruta
       CLIENTE -> VEHICULO -> ORDEN_LAVADO -> EMPLEADO.
   D3. Se elimina la referencia circular ORDEN_LAVADO <-> PAGO del modelo
       original (ORDEN_LAVADO.pago_pago_ID y PAGO.Ordenlavado_ID_orden).
       Ahora la ruta es PAGO -> FACTURA -> ORDEN_LAVADO, sin ciclos.
   D4. Se elimina el empleado redundante de ORDEN_LAVADO: el modelo original
       tenia dos columnas (ID_Empleado_Asignado y empleado_ID_Empleado).
       Queda solo ID_EMPLEADO_ASIGNADO.
   D5. Se agrega la relacion VEHICULO (1) - ORDEN_LAVADO (N). En el modelo
       original, Placa era un atributo suelto de la orden y VEHICULO no
       tenia clave. Ahora VEHICULO tiene PK tecnica ID_VEHICULO, PLACA es
       UNIQUE y NOT NULL, y la orden referencia ID_VEHICULO.
   D6. La PK de SERVICIO es ID_SERVICIO (en el modelo original era
       ID_Empleado, un error evidente).
   D7. DETALLE_ORDEN tiene PK propia ID_DETALLE (la PK original ID_orden
       solo permitia un detalle por orden). Se agrega UNIQUE (ID_ORDEN,
       ID_SERVICIO): un servicio aparece una sola vez por orden. Si en el
       futuro se desea registrar varias unidades del mismo servicio, se
       debera incorporar una columna CANTIDAD y revisar esta restriccion.
   D8. Coherencia de sucursal. Mediante claves foraneas compuestas, el
       empleado asignado y los servicios de una orden deben pertenecer a la
       misma empresa (sucursal) que la orden.
   D9. Tipos de datos. IDs: VARCHAR2 en el MR, NUMBER(10) aqui. Telefonos:
       NUMBER en el MR, VARCHAR2(20) aqui (conserva ceros y prefijos).
       TIEMPO_ESTIMADO: DATE en el MR, TIEMPO_ESTIMADO_MIN NUMBER(5) aqui
       (una duracion en minutos, no una fecha). FECHA_HORA_INGRESO:
       VARCHAR2 en el MR, TIMESTAMP aqui. PRECIO_APLICADO: VARCHAR2 en el
       MR, NUMBER(12,2) aqui. CIUDAD: tipo indefinido en el MR, VARCHAR2(80).
       ESTADO de la orden: VARCHAR2(10) en el MR, VARCHAR2(20) con CHECK.
       TIPO_VEHICULO: VARCHAR2(25) en el MR, VARCHAR2(30) aqui.
       METODO_PAGO: VARCHAR2(15) en el MR, VARCHAR2(30) con CHECK.
       Valores monetarios: NUMBER(12,2).
   D10. Opcionalidad (obligatorio u opcional) frente al ER original:
        - ORDEN_LAVADO.FECHA_HORA_SALIDA: obligatorio en el ER, OPCIONAL
          aqui. La salida no existe mientras el vehiculo sigue en el lavadero.
        - ORDEN_LAVADO.ID_EMPLEADO_ASIGNADO: obligatorio en el ER, OPCIONAL
          aqui. Una orden puede recibirse antes de asignar a un empleado.
        - EMPLEADO.NOMBRE y EMPLEADO.CARGO: opcionales en el ER,
          OBLIGATORIOS aqui. Un empleado sin nombre ni cargo no es util.
        - DETALLE_ORDEN.PRECIO_APLICADO: opcional en el ER, OBLIGATORIO
          aqui. Sin precio no se puede facturar.
        - PAGO.METODO_PAGO: opcional en el ER, OBLIGATORIO aqui, con CHECK.
        - DETALLE_ORDEN.DETALLE: obligatorio en el ER y aqui (coincide).
        - Los demas atributos conservan la opcionalidad del ER.
   D11. SEQ_PAGO inicia en 19 porque los datos de prueba usan los
        identificadores de pago 1 a 18. La usa el procedimiento que registra
        pagos. Es NOCACHE y NOCYCLE; si una transaccion se revierte, el
        numero consumido no se reutiliza (pueden quedar huecos).
   D12. CK_PAGO_METODO admite solo 'Efectivo', 'Tarjeta' y 'Transferencia',
        escritos exactamente asi (distingue mayusculas y minusculas).
   D13. Indices: Oracle no crea indices automaticamente sobre claves
        foraneas. Se crean solo los que no estan ya cubiertos por una
        restriccion UNIQUE o PRIMARY KEY.

   REGLAS QUE ESTE DDL NO PUEDE EXPRESAR CON CHECK Y SE CONTROLAN EN OTRO LUGAR
   ----------------------------------------------------------------------------
   - Que FACTURA.SUBTOTAL coincida con la suma de los detalles de la orden.
   - Que FACTURA.ESTADO sea coherente con la suma de pagos.
   - Que la suma de pagos no supere el total de la factura.
   - Que la fecha de un pago no sea anterior a la emision de la factura.
   Estas reglas se controlan con los datos de prueba (DML), el procedimiento
   de registro de pagos y el trigger de PL_SQL_Lavadero.sql.
   ============================================================================ */

SET DEFINE OFF

/* ---------------------------------------------------------------------------
   0. VERIFICACION PREVIA
   Debe devolver 0. Si devuelve un numero mayor, el esquema ya contiene alguna
   de las tablas del proyecto: no continuar sin revisar el esquema.
   --------------------------------------------------------------------------- */
SELECT COUNT(*) AS TABLAS_EXISTENTES_ANTES_DE_CREAR
FROM user_tables
WHERE table_name IN ('EMPRESA', 'CLIENTE', 'EMPLEADO', 'SERVICIO', 'VEHICULO',
                     'ORDEN_LAVADO', 'DETALLE_ORDEN', 'FACTURA', 'PAGO');

/* ---------------------------------------------------------------------------
   1. EMPRESA
   Cada registro es una sede o sucursal del lavadero. Una empresa tiene
   empleados, servicios y ordenes.
   --------------------------------------------------------------------------- */
CREATE TABLE EMPRESA (
    ID_EMPRESA       NUMBER(10)       NOT NULL,
    NOMBRE_SUCURSAL  VARCHAR2(100)    NOT NULL,
    DIRECCION        VARCHAR2(200),
    TELEFONO         VARCHAR2(20),
    CIUDAD           VARCHAR2(80)     NOT NULL,
    CONSTRAINT PK_EMPRESA PRIMARY KEY (ID_EMPRESA)
);

/* ---------------------------------------------------------------------------
   2. CLIENTE
   Personas que usan los servicios. El correo es opcional, pero si se informa
   no puede repetirse (Oracle permite varios NULL en una columna UNIQUE).
   --------------------------------------------------------------------------- */
CREATE TABLE CLIENTE (
    ID_CLIENTE  NUMBER(10)       NOT NULL,
    NOMBRE      VARCHAR2(120)    NOT NULL,
    TELEFONO    VARCHAR2(20),
    CORREO      VARCHAR2(150),
    CONSTRAINT PK_CLIENTE PRIMARY KEY (ID_CLIENTE),
    CONSTRAINT UQ_CLIENTE_CORREO UNIQUE (CORREO)
);

/* ---------------------------------------------------------------------------
   3. EMPLEADO
   Personal de una sede. UQ_EMPLEADO_EMPRESA_ID es la clave candidata
   compuesta que permite validar, desde ORDEN_LAVADO, que el empleado
   asignado pertenece a la misma sede de la orden.
   --------------------------------------------------------------------------- */
CREATE TABLE EMPLEADO (
    ID_EMPLEADO  NUMBER(10)       NOT NULL,
    ID_EMPRESA   NUMBER(10)       NOT NULL,
    NOMBRE       VARCHAR2(120)    NOT NULL,
    CARGO        VARCHAR2(60)     NOT NULL,
    TELEFONO     VARCHAR2(20),
    CONSTRAINT PK_EMPLEADO PRIMARY KEY (ID_EMPLEADO),
    CONSTRAINT UQ_EMPLEADO_EMPRESA_ID UNIQUE (ID_EMPRESA, ID_EMPLEADO),
    CONSTRAINT FK_EMPLEADO_EMPRESA
        FOREIGN KEY (ID_EMPRESA)
        REFERENCES EMPRESA (ID_EMPRESA)
);

/* ---------------------------------------------------------------------------
   4. SERVICIO
   Catalogo de servicios de cada sede. El nombre no se repite dentro de una
   misma sede. TIEMPO_ESTIMADO_MIN es una duracion en minutos.
   UQ_SERVICIO_EMPRESA_ID permite validar la sede desde DETALLE_ORDEN.
   --------------------------------------------------------------------------- */
CREATE TABLE SERVICIO (
    ID_SERVICIO          NUMBER(10)       NOT NULL,
    ID_EMPRESA           NUMBER(10)       NOT NULL,
    NOMBRE_SERVICIO      VARCHAR2(100)    NOT NULL,
    DESCRIPCION          VARCHAR2(500),
    PRECIO_BASE          NUMBER(12,2)     NOT NULL,
    TIEMPO_ESTIMADO_MIN  NUMBER(5)        NOT NULL,
    CONSTRAINT PK_SERVICIO PRIMARY KEY (ID_SERVICIO),
    CONSTRAINT FK_SERVICIO_EMPRESA
        FOREIGN KEY (ID_EMPRESA)
        REFERENCES EMPRESA (ID_EMPRESA),
    CONSTRAINT CK_SERVICIO_PRECIO CHECK (PRECIO_BASE >= 0),
    CONSTRAINT CK_SERVICIO_TIEMPO CHECK (TIEMPO_ESTIMADO_MIN > 0),
    CONSTRAINT UQ_SERVICIO_SEDE_NOMBRE UNIQUE (ID_EMPRESA, NOMBRE_SERVICIO),
    CONSTRAINT UQ_SERVICIO_EMPRESA_ID UNIQUE (ID_EMPRESA, ID_SERVICIO)
);

/* ---------------------------------------------------------------------------
   5. VEHICULO
   Cada vehiculo pertenece a un cliente. ID_VEHICULO es la PK tecnica y PLACA
   es unica y obligatoria. Un cliente puede tener varios vehiculos.
   --------------------------------------------------------------------------- */
CREATE TABLE VEHICULO (
    ID_VEHICULO    NUMBER(10)       NOT NULL,
    ID_CLIENTE     NUMBER(10)       NOT NULL,
    PLACA          VARCHAR2(10)     NOT NULL,
    MARCA          VARCHAR2(50)     NOT NULL,
    COLOR          VARCHAR2(30),
    MODELO         VARCHAR2(50),
    TIPO_VEHICULO  VARCHAR2(30)     NOT NULL,
    CONSTRAINT PK_VEHICULO PRIMARY KEY (ID_VEHICULO),
    CONSTRAINT UQ_VEHICULO_PLACA UNIQUE (PLACA),
    CONSTRAINT FK_VEHICULO_CLIENTE
        FOREIGN KEY (ID_CLIENTE)
        REFERENCES CLIENTE (ID_CLIENTE)
);

/* ---------------------------------------------------------------------------
   6. ORDEN_LAVADO
   Ingreso de un vehiculo a una sede. La salida y el empleado asignado son
   opcionales (todavia pueden no existir). La FK compuesta a EMPLEADO obliga
   a que el empleado sea de la misma sede; si ID_EMPLEADO_ASIGNADO es NULL,
   Oracle no evalua esa clave foranea.
   --------------------------------------------------------------------------- */
CREATE TABLE ORDEN_LAVADO (
    ID_ORDEN              NUMBER(10)       NOT NULL,
    ID_EMPRESA            NUMBER(10)       NOT NULL,
    ID_VEHICULO           NUMBER(10)       NOT NULL,
    ID_EMPLEADO_ASIGNADO  NUMBER(10),
    FECHA_HORA_INGRESO    TIMESTAMP        DEFAULT SYSTIMESTAMP NOT NULL,
    FECHA_HORA_SALIDA     TIMESTAMP,
    ESTADO                VARCHAR2(20)     DEFAULT 'RECIBIDA' NOT NULL,
    CONSTRAINT PK_ORDEN_LAVADO PRIMARY KEY (ID_ORDEN),
    CONSTRAINT UQ_ORDEN_EMPRESA_ID UNIQUE (ID_EMPRESA, ID_ORDEN),
    CONSTRAINT FK_ORDEN_EMPRESA
        FOREIGN KEY (ID_EMPRESA)
        REFERENCES EMPRESA (ID_EMPRESA),
    CONSTRAINT FK_ORDEN_VEHICULO
        FOREIGN KEY (ID_VEHICULO)
        REFERENCES VEHICULO (ID_VEHICULO),
    CONSTRAINT FK_ORDEN_EMPLEADO
        FOREIGN KEY (ID_EMPRESA, ID_EMPLEADO_ASIGNADO)
        REFERENCES EMPLEADO (ID_EMPRESA, ID_EMPLEADO),
    CONSTRAINT CK_ORDEN_ESTADO
        CHECK (ESTADO IN ('RECIBIDA', 'EN_PROCESO', 'FINALIZADA',
                          'ENTREGADA', 'CANCELADA')),
    CONSTRAINT CK_ORDEN_FECHAS
        CHECK (FECHA_HORA_SALIDA IS NULL OR
               FECHA_HORA_SALIDA >= FECHA_HORA_INGRESO)
);

/* ---------------------------------------------------------------------------
   7. DETALLE_ORDEN
   Resuelve la relacion N:M entre ORDEN_LAVADO y SERVICIO. ID_EMPRESA se
   guarda para que las dos FK compuestas garanticen que orden y servicio son
   de la misma sede. PRECIO_APLICADO conserva el precio cobrado aunque luego
   cambie PRECIO_BASE. Cada servicio aparece una sola vez por orden.
   --------------------------------------------------------------------------- */
CREATE TABLE DETALLE_ORDEN (
    ID_DETALLE       NUMBER(10)       NOT NULL,
    ID_EMPRESA       NUMBER(10)       NOT NULL,
    ID_ORDEN         NUMBER(10)       NOT NULL,
    ID_SERVICIO      NUMBER(10)       NOT NULL,
    DETALLE          VARCHAR2(300)    NOT NULL,
    PRECIO_APLICADO  NUMBER(12,2)     NOT NULL,
    CONSTRAINT PK_DETALLE_ORDEN PRIMARY KEY (ID_DETALLE),
    CONSTRAINT FK_DETALLE_ORDEN
        FOREIGN KEY (ID_EMPRESA, ID_ORDEN)
        REFERENCES ORDEN_LAVADO (ID_EMPRESA, ID_ORDEN),
    CONSTRAINT FK_DETALLE_SERVICIO
        FOREIGN KEY (ID_EMPRESA, ID_SERVICIO)
        REFERENCES SERVICIO (ID_EMPRESA, ID_SERVICIO),
    CONSTRAINT UQ_DETALLE_ORDEN_SERVICIO UNIQUE (ID_ORDEN, ID_SERVICIO),
    CONSTRAINT CK_DETALLE_PRECIO CHECK (PRECIO_APLICADO >= 0)
);

/* ---------------------------------------------------------------------------
   8. FACTURA
   Documento de cobro de una orden. ID_ORDEN es UNIQUE (maximo una factura por
   orden) y NUMERO_FACTURA tambien es unico. SUBTOTAL, IMPUESTOS y TOTAL se
   guardan para conservar los importes emitidos. Estados: EMITIDA (sin pagos),
   PARCIAL (pagos menores al total), PAGADA (total cubierto) y ANULADA.
   --------------------------------------------------------------------------- */
CREATE TABLE FACTURA (
    ID_FACTURA      NUMBER(10)       NOT NULL,
    ID_ORDEN        NUMBER(10)       NOT NULL,
    NUMERO_FACTURA  VARCHAR2(30)     NOT NULL,
    FECHA_EMISION   TIMESTAMP        DEFAULT SYSTIMESTAMP NOT NULL,
    SUBTOTAL        NUMBER(12,2)     NOT NULL,
    IMPUESTOS       NUMBER(12,2)     DEFAULT 0 NOT NULL,
    TOTAL           NUMBER(12,2)     NOT NULL,
    ESTADO          VARCHAR2(15)     DEFAULT 'EMITIDA' NOT NULL,
    CONSTRAINT PK_FACTURA PRIMARY KEY (ID_FACTURA),
    CONSTRAINT UQ_FACTURA_ORDEN UNIQUE (ID_ORDEN),
    CONSTRAINT UQ_FACTURA_NUMERO UNIQUE (NUMERO_FACTURA),
    CONSTRAINT FK_FACTURA_ORDEN
        FOREIGN KEY (ID_ORDEN)
        REFERENCES ORDEN_LAVADO (ID_ORDEN),
    CONSTRAINT CK_FACTURA_SUBTOTAL CHECK (SUBTOTAL >= 0),
    CONSTRAINT CK_FACTURA_IMPUESTOS CHECK (IMPUESTOS >= 0),
    CONSTRAINT CK_FACTURA_TOTAL CHECK (TOTAL >= 0),
    CONSTRAINT CK_FACTURA_SUMA CHECK (TOTAL = SUBTOTAL + IMPUESTOS),
    CONSTRAINT CK_FACTURA_ESTADO
        CHECK (ESTADO IN ('EMITIDA', 'PARCIAL', 'PAGADA', 'ANULADA'))
);

/* ---------------------------------------------------------------------------
   9. PAGO
   Pagos o abonos de una factura (cero o varios por factura). La FK apunta a
   FACTURA, lo que evita el ciclo ORDEN_LAVADO <-> PAGO del modelo original.
   FECHA_PAGO tiene DEFAULT SYSTIMESTAMP; el trigger de PL_SQL_Lavadero.sql
   tambien asigna la fecha cuando llega NULL y valida que no sea anterior a
   la emision de la factura.
   --------------------------------------------------------------------------- */
CREATE TABLE PAGO (
    ID_PAGO      NUMBER(10)       NOT NULL,
    ID_FACTURA   NUMBER(10)       NOT NULL,
    FECHA_PAGO   TIMESTAMP        DEFAULT SYSTIMESTAMP NOT NULL,
    MONTO        NUMBER(12,2)     NOT NULL,
    METODO_PAGO  VARCHAR2(30)     NOT NULL,
    CONSTRAINT PK_PAGO PRIMARY KEY (ID_PAGO),
    CONSTRAINT FK_PAGO_FACTURA
        FOREIGN KEY (ID_FACTURA)
        REFERENCES FACTURA (ID_FACTURA),
    CONSTRAINT CK_PAGO_MONTO CHECK (MONTO > 0),
    CONSTRAINT CK_PAGO_METODO
        CHECK (METODO_PAGO IN ('Efectivo', 'Tarjeta', 'Transferencia'))
);

/* ---------------------------------------------------------------------------
   10. SECUENCIA SEQ_PAGO
   Genera los identificadores de los nuevos pagos (los datos de prueba usan
   del 1 al 18, por eso inicia en 19). Uso: SEQ_PAGO.NEXTVAL.
   --------------------------------------------------------------------------- */
CREATE SEQUENCE SEQ_PAGO
    START WITH 19
    INCREMENT BY 1
    MINVALUE 1
    NOCACHE
    NOCYCLE;

/* ---------------------------------------------------------------------------
   11. INDICES SOBRE CLAVES FORANEAS
   Solo las FK que no estan cubiertas por una restriccion UNIQUE o PRIMARY KEY.
   Cubiertas ya: EMPLEADO.ID_EMPRESA, SERVICIO.ID_EMPRESA,
   ORDEN_LAVADO.ID_EMPRESA y FACTURA.ID_ORDEN.
   --------------------------------------------------------------------------- */
CREATE INDEX IDX_VEHICULO_CLIENTE ON VEHICULO (ID_CLIENTE);
CREATE INDEX IDX_ORDEN_VEHICULO ON ORDEN_LAVADO (ID_VEHICULO);
CREATE INDEX IDX_ORDEN_EMPLEADO ON ORDEN_LAVADO (ID_EMPRESA, ID_EMPLEADO_ASIGNADO);
CREATE INDEX IDX_DETALLE_ORDEN ON DETALLE_ORDEN (ID_EMPRESA, ID_ORDEN);
CREATE INDEX IDX_DETALLE_SERVICIO ON DETALLE_ORDEN (ID_EMPRESA, ID_SERVICIO);
CREATE INDEX IDX_PAGO_FACTURA ON PAGO (ID_FACTURA);

/* ---------------------------------------------------------------------------
   12. COMENTARIOS DE DOCUMENTACION (diccionario de datos de Oracle)
   Se consultan en USER_TAB_COMMENTS y USER_COL_COMMENTS.
   --------------------------------------------------------------------------- */
COMMENT ON TABLE EMPRESA IS 'Sedes o sucursales del lavadero de vehiculos.';
COMMENT ON COLUMN EMPRESA.ID_EMPRESA IS 'Identificador unico de la sede.';
COMMENT ON COLUMN EMPRESA.NOMBRE_SUCURSAL IS 'Nombre comercial de la sucursal.';
COMMENT ON COLUMN EMPRESA.DIRECCION IS 'Direccion de la sucursal (opcional).';
COMMENT ON COLUMN EMPRESA.TELEFONO IS 'Telefono de la sucursal, como texto para conservar prefijos (opcional).';
COMMENT ON COLUMN EMPRESA.CIUDAD IS 'Ciudad donde funciona la sucursal.';

COMMENT ON TABLE CLIENTE IS 'Personas que solicitan los servicios del lavadero.';
COMMENT ON COLUMN CLIENTE.ID_CLIENTE IS 'Identificador unico del cliente.';
COMMENT ON COLUMN CLIENTE.NOMBRE IS 'Nombre completo del cliente.';
COMMENT ON COLUMN CLIENTE.TELEFONO IS 'Telefono de contacto del cliente (opcional).';
COMMENT ON COLUMN CLIENTE.CORREO IS 'Correo de contacto (opcional), si se registra, no puede repetirse.';

COMMENT ON TABLE EMPLEADO IS 'Personal que trabaja en una sede del lavadero.';
COMMENT ON COLUMN EMPLEADO.ID_EMPLEADO IS 'Identificador unico del empleado.';
COMMENT ON COLUMN EMPLEADO.ID_EMPRESA IS 'Sede a la que pertenece el empleado.';
COMMENT ON COLUMN EMPLEADO.NOMBRE IS 'Nombre completo del empleado.';
COMMENT ON COLUMN EMPLEADO.CARGO IS 'Cargo u oficio del empleado, por ejemplo Lavador, Supervisor o Cajero.';
COMMENT ON COLUMN EMPLEADO.TELEFONO IS 'Telefono de contacto del empleado (opcional).';

COMMENT ON TABLE SERVICIO IS 'Catalogo de servicios ofrecidos por cada sede.';
COMMENT ON COLUMN SERVICIO.ID_SERVICIO IS 'Identificador unico del servicio (en el modelo original la PK era ID_Empleado por error).';
COMMENT ON COLUMN SERVICIO.ID_EMPRESA IS 'Sede que ofrece el servicio.';
COMMENT ON COLUMN SERVICIO.NOMBRE_SERVICIO IS 'Nombre del servicio, no se repite dentro de una misma sede.';
COMMENT ON COLUMN SERVICIO.DESCRIPCION IS 'Descripcion del servicio (opcional).';
COMMENT ON COLUMN SERVICIO.PRECIO_BASE IS 'Precio vigente del servicio en el catalogo, en pesos colombianos.';
COMMENT ON COLUMN SERVICIO.TIEMPO_ESTIMADO_MIN IS 'Duracion estimada del servicio, expresada en minutos.';

COMMENT ON TABLE VEHICULO IS 'Vehiculos registrados por los clientes.';
COMMENT ON COLUMN VEHICULO.ID_VEHICULO IS 'Identificador tecnico unico del vehiculo.';
COMMENT ON COLUMN VEHICULO.ID_CLIENTE IS 'Cliente propietario o responsable del vehiculo.';
COMMENT ON COLUMN VEHICULO.PLACA IS 'Placa del vehiculo, unica y obligatoria.';
COMMENT ON COLUMN VEHICULO.MARCA IS 'Marca del vehiculo.';
COMMENT ON COLUMN VEHICULO.COLOR IS 'Color del vehiculo (opcional).';
COMMENT ON COLUMN VEHICULO.MODELO IS 'Modelo o linea del vehiculo (opcional).';
COMMENT ON COLUMN VEHICULO.TIPO_VEHICULO IS 'Clase de vehiculo, por ejemplo Automovil o Camioneta.';

COMMENT ON TABLE ORDEN_LAVADO IS 'Registro de ingreso y atencion de un vehiculo en una sede del lavadero.';
COMMENT ON COLUMN ORDEN_LAVADO.ID_ORDEN IS 'Identificador unico de la orden de lavado.';
COMMENT ON COLUMN ORDEN_LAVADO.ID_EMPRESA IS 'Sede donde se atiende la orden.';
COMMENT ON COLUMN ORDEN_LAVADO.ID_VEHICULO IS 'Vehiculo al que corresponde la orden.';
COMMENT ON COLUMN ORDEN_LAVADO.ID_EMPLEADO_ASIGNADO IS 'Empleado responsable de la sede de la orden, puede quedar NULL mientras se asigna.';
COMMENT ON COLUMN ORDEN_LAVADO.FECHA_HORA_INGRESO IS 'Fecha y hora en que el vehiculo ingresa al lavadero.';
COMMENT ON COLUMN ORDEN_LAVADO.FECHA_HORA_SALIDA IS 'Fecha y hora de salida, NULL mientras el vehiculo sigue en el lavadero.';
COMMENT ON COLUMN ORDEN_LAVADO.ESTADO IS 'Estado de la orden: RECIBIDA, EN_PROCESO, FINALIZADA, ENTREGADA o CANCELADA.';

COMMENT ON TABLE DETALLE_ORDEN IS 'Servicios incluidos en cada orden y precio aplicado en el momento de la atencion.';
COMMENT ON COLUMN DETALLE_ORDEN.ID_DETALLE IS 'Identificador unico de cada linea de la orden.';
COMMENT ON COLUMN DETALLE_ORDEN.ID_EMPRESA IS 'Sede usada para validar que la orden y el servicio son del mismo establecimiento.';
COMMENT ON COLUMN DETALLE_ORDEN.ID_ORDEN IS 'Orden a la que pertenece la linea.';
COMMENT ON COLUMN DETALLE_ORDEN.ID_SERVICIO IS 'Servicio realizado, no se repite dentro de una misma orden.';
COMMENT ON COLUMN DETALLE_ORDEN.DETALLE IS 'Descripcion del servicio realizado en la orden.';
COMMENT ON COLUMN DETALLE_ORDEN.PRECIO_APLICADO IS 'Precio historico cobrado por el servicio dentro de esta orden.';

COMMENT ON TABLE FACTURA IS 'Documento de cobro emitido para una orden de lavado (maximo una por orden).';
COMMENT ON COLUMN FACTURA.ID_FACTURA IS 'Identificador unico de la factura.';
COMMENT ON COLUMN FACTURA.ID_ORDEN IS 'Orden facturada, unica, porque una orden genera como maximo una factura.';
COMMENT ON COLUMN FACTURA.NUMERO_FACTURA IS 'Numero o consecutivo unico de la factura.';
COMMENT ON COLUMN FACTURA.FECHA_EMISION IS 'Fecha y hora de emision de la factura.';
COMMENT ON COLUMN FACTURA.SUBTOTAL IS 'Valor de los servicios antes de impuestos.';
COMMENT ON COLUMN FACTURA.IMPUESTOS IS 'Valor de los impuestos (IVA) aplicados al subtotal.';
COMMENT ON COLUMN FACTURA.TOTAL IS 'Valor total facturado, debe ser igual a SUBTOTAL mas IMPUESTOS.';
COMMENT ON COLUMN FACTURA.ESTADO IS 'Estado de cobro: EMITIDA (sin pagos), PARCIAL, PAGADA o ANULADA.';

COMMENT ON TABLE PAGO IS 'Pagos o abonos aplicados a una factura.';
COMMENT ON COLUMN PAGO.ID_PAGO IS 'Identificador unico del pago, los nuevos se generan con SEQ_PAGO.';
COMMENT ON COLUMN PAGO.ID_FACTURA IS 'Factura a la que se aplica el pago.';
COMMENT ON COLUMN PAGO.FECHA_PAGO IS 'Fecha y hora del pago, no debe ser anterior a la emision de la factura.';
COMMENT ON COLUMN PAGO.MONTO IS 'Valor pagado, mayor que cero.';
COMMENT ON COLUMN PAGO.METODO_PAGO IS 'Medio de pago: Efectivo, Tarjeta o Transferencia.';

/* ---------------------------------------------------------------------------
   13. VERIFICACION DEL RESULTADO
   Resultados esperados:
   13.1  9 filas con estas columnas: CLIENTE 4, DETALLE_ORDEN 6, EMPLEADO 5,
         EMPRESA 5, FACTURA 8, ORDEN_LAVADO 7, PAGO 5, SERVICIO 6, VEHICULO 7.
   13.2  Restricciones: P = 9, R = 10, U = 9, CHECK con nombre CK = 12.
   13.3  SEQ_PAGO: incremento 1, NOCACHE (cache 0) y NOCYCLE (N).
         ULTIMO_NUMERO debe mostrar 19.
   13.4  6 indices IDX_ creados.
   13.5  Una fila final que comienza con "DDL CORRECTO".
   --------------------------------------------------------------------------- */
-- 13.1 Tablas y numero de columnas
SELECT t.table_name AS TABLA, COUNT(c.column_name) AS COLUMNAS
FROM user_tables t
JOIN user_tab_columns c ON c.table_name = t.table_name
WHERE t.table_name IN ('EMPRESA', 'CLIENTE', 'EMPLEADO', 'SERVICIO', 'VEHICULO',
                       'ORDEN_LAVADO', 'DETALLE_ORDEN', 'FACTURA', 'PAGO')
GROUP BY t.table_name
ORDER BY t.table_name;

-- 13.2 Restricciones por tipo (P = primaria, R = foranea, U = unica, C = check)
SELECT constraint_type AS TIPO, COUNT(*) AS CANTIDAD
FROM user_constraints
WHERE table_name IN ('EMPRESA', 'CLIENTE', 'EMPLEADO', 'SERVICIO', 'VEHICULO',
                     'ORDEN_LAVADO', 'DETALLE_ORDEN', 'FACTURA', 'PAGO')
  AND (constraint_type IN ('P', 'R', 'U')
       OR (constraint_type = 'C' AND constraint_name LIKE 'CK%'))
GROUP BY constraint_type
ORDER BY constraint_type;

-- 13.3 Secuencia de pagos
SELECT sequence_name AS SECUENCIA, increment_by AS INCREMENTO,
       cache_size AS CACHE, cycle_flag AS CICLO, last_number AS ULTIMO_NUMERO
FROM user_sequences
WHERE sequence_name = 'SEQ_PAGO';

-- 13.4 Indices creados sobre claves foraneas
SELECT index_name AS INDICE, table_name AS TABLA
FROM user_indexes
WHERE index_name LIKE 'IDX%'
ORDER BY index_name;

-- 13.5 Resultado final
SELECT CASE
         WHEN (SELECT COUNT(*) FROM user_tables
               WHERE table_name IN ('EMPRESA', 'CLIENTE', 'EMPLEADO', 'SERVICIO',
                                    'VEHICULO', 'ORDEN_LAVADO', 'DETALLE_ORDEN',
                                    'FACTURA', 'PAGO')) = 9
          AND (SELECT COUNT(*) FROM user_constraints
               WHERE constraint_type = 'P'
                 AND table_name IN ('EMPRESA', 'CLIENTE', 'EMPLEADO', 'SERVICIO',
                                    'VEHICULO', 'ORDEN_LAVADO', 'DETALLE_ORDEN',
                                    'FACTURA', 'PAGO')) = 9
          AND (SELECT COUNT(*) FROM user_constraints
               WHERE constraint_type = 'R'
                 AND table_name IN ('EMPRESA', 'CLIENTE', 'EMPLEADO', 'SERVICIO',
                                    'VEHICULO', 'ORDEN_LAVADO', 'DETALLE_ORDEN',
                                    'FACTURA', 'PAGO')) = 10
          AND (SELECT COUNT(*) FROM user_constraints
               WHERE constraint_type = 'U'
                 AND table_name IN ('EMPRESA', 'CLIENTE', 'EMPLEADO', 'SERVICIO',
                                    'VEHICULO', 'ORDEN_LAVADO', 'DETALLE_ORDEN',
                                    'FACTURA', 'PAGO')) = 9
          AND (SELECT COUNT(*) FROM user_constraints
               WHERE constraint_type = 'C'
                 AND constraint_name LIKE 'CK%'
                 AND table_name IN ('EMPRESA', 'CLIENTE', 'EMPLEADO', 'SERVICIO',
                                    'VEHICULO', 'ORDEN_LAVADO', 'DETALLE_ORDEN',
                                    'FACTURA', 'PAGO')) = 12
          AND (SELECT COUNT(*) FROM user_sequences
               WHERE sequence_name = 'SEQ_PAGO' AND increment_by = 1
                 AND cache_size = 0 AND cycle_flag = 'N') = 1
          AND (SELECT COUNT(*) FROM user_indexes
               WHERE index_name LIKE 'IDX%') = 6
          AND (SELECT COUNT(*) FROM user_tab_comments
               WHERE comments IS NOT NULL
                 AND table_name IN ('EMPRESA', 'CLIENTE', 'EMPLEADO', 'SERVICIO',
                                    'VEHICULO', 'ORDEN_LAVADO', 'DETALLE_ORDEN',
                                    'FACTURA', 'PAGO')) = 9
          AND (SELECT COUNT(*) FROM user_col_comments
               WHERE comments IS NOT NULL
                 AND table_name IN ('EMPRESA', 'CLIENTE', 'EMPLEADO', 'SERVICIO',
                                    'VEHICULO', 'ORDEN_LAVADO', 'DETALLE_ORDEN',
                                    'FACTURA', 'PAGO')) = 53
         THEN 'DDL CORRECTO: 9 tablas, 10 FK, 9 UNIQUE, 12 CHECK, SEQ_PAGO, 6 indices y 62 comentarios.'
         ELSE 'REVISAR: hay diferencias con lo esperado, revise la Salida de script y las consultas 13.1 a 13.4.'
       END AS RESULTADO
FROM dual;

/* =============================== FIN DEL DDL ============================== */
