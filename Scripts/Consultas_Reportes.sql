/* ============================================================================
   OBJETIVO
   --------
   Generar reportes de gestion, operacion, facturacion y pagos del lavadero
   utilizando las nueve tablas del modelo definitivo.

   IMPORTANTE SOBRE EL ALCANCE
   --------------------------
   No se adjunto el listado documental de los reportes originalmente
   propuestos. Por esa razon, estos diez reportes se documentan como
   PROPUESTAS PARA LA VERSION DEFINITIVA, basadas en el modelo y los datos
   de prueba aprobados. No se presentan como transcripcion de un listado
   original que no estuvo disponible.

   REQUISITO DE LA ACTIVIDAD
   ------------------------
   Cada reporte debe devolver al menos 10 filas con el DML actual.
   Cada consulta incluye TOTAL_FILAS_REPORTE (funcion analitica COUNT OVER)
   para mostrar en cada fila cuantas filas devuelve el reporte completo.
   El valor se repite en todas las filas del mismo resultado.

   ORDEN DE EJECUCION
   -----------------
   1. DDL_Lavadero.sql
   2. DML_Lavadero.sql
   3. Consultas_Reportes.sql (este archivo)
   4. PL_SQL_Lavadero.sql

   COMO EJECUTAR
   -------------
   1. Conectarse al esquema donde se ejecutaron el DDL y el DML.
   2. Abrir este archivo y verificar la conexion de la hoja SQL.
   3. Presionar F5 (Ejecutar script).
   4. Revisar las diez salidas. En cada reporte, TOTAL_FILAS_REPORTE debe
      ser igual o superior a 10. SQL Developer mostrara tambien la cantidad
      de filas seleccionadas al terminar cada consulta.

   NOTA
   ----
   Este archivo contiene exclusivamente consultas SELECT. No crea, modifica
   ni elimina tablas o registros y puede ejecutarse varias veces.

   REPORTES INCLUIDOS
   ------------------
   01. Ordenes de lavado con cliente, vehiculo, empleado y factura.
   02. Estado de cuenta por factura: total, pagos y saldo pendiente.
   03. Ingresos por servicio y sede.
   04. Facturacion acumulada por cliente.
   05. Productividad por empleado y mes.
   06. Ingresos por sede, mes y tipo de vehiculo.
   07. Pagos registrados con factura, metodo de pago y sede.
   08. Vehiculos atendidos: propietario, ordenes y gasto facturado.
   09. Servicios solicitados por tipo de vehiculo.
   10. Tiempo real de atencion frente al tiempo estimado.

   ============================================================================ */

SET PAGESIZE 100
SET LINESIZE 320
SET VERIFY OFF
SET FEEDBACK ON
SET DEFINE OFF
SET WRAP OFF
SET TRIMSPOOL ON
SET TAB OFF

-- Formato de impresion: limitar anchos para evitar encabezados y filas partidas.
COLUMN NOMBRE_SUCURSAL       FORMAT A24
COLUMN CLIENTE               FORMAT A25
COLUMN EMPLEADO_ASIGNADO     FORMAT A22
COLUMN EMPLEADO              FORMAT A22
COLUMN PROPIETARIO           FORMAT A25
COLUMN NUMERO_FACTURA        FORMAT A16
COLUMN ESTADO_FACTURA        FORMAT A10
COLUMN ESTADO                FORMAT A12
COLUMN PLACA                 FORMAT A8
COLUMN MARCA                 FORMAT A12
COLUMN MODELO                FORMAT A14
COLUMN TIPO_VEHICULO         FORMAT A12
COLUMN NOMBRE_SERVICIO       FORMAT A22
COLUMN CARGO                 FORMAT A14
COLUMN PERIODO               FORMAT A7
COLUMN METODO_PAGO           FORMAT A14
COLUMN FECHA_EMISION         FORMAT A30
COLUMN FECHA_PAGO            FORMAT A30
COLUMN FECHA_HORA_INGRESO    FORMAT A30
COLUMN FECHA_HORA_SALIDA     FORMAT A30

PROMPT ======================================================================
PROMPT REPORTE 01. ORDENES DE LAVADO CON CLIENTE, VEHICULO, EMPLEADO Y FACTURA
PROMPT Resultado esperado con el DML actual: 20 filas (minimo requerido: 10).
PROMPT ======================================================================

SELECT COUNT(*) OVER () AS TOTAL_FILAS_REPORTE,
       O.ID_ORDEN, E.NOMBRE_SUCURSAL, O.FECHA_HORA_INGRESO,
       O.FECHA_HORA_SALIDA, O.ESTADO,
       C.ID_CLIENTE, C.NOMBRE AS CLIENTE,
       V.PLACA, V.MARCA, V.MODELO, V.TIPO_VEHICULO,
       NVL(EM.NOMBRE, 'Sin asignar') AS EMPLEADO_ASIGNADO,
       F.NUMERO_FACTURA, F.TOTAL AS TOTAL_FACTURADO, F.ESTADO AS ESTADO_FACTURA
FROM ORDEN_LAVADO O
JOIN EMPRESA E ON E.ID_EMPRESA = O.ID_EMPRESA
JOIN VEHICULO V ON V.ID_VEHICULO = O.ID_VEHICULO
JOIN CLIENTE C ON C.ID_CLIENTE = V.ID_CLIENTE
LEFT JOIN EMPLEADO EM
       ON EM.ID_EMPLEADO = O.ID_EMPLEADO_ASIGNADO
      AND EM.ID_EMPRESA = O.ID_EMPRESA
LEFT JOIN FACTURA F ON F.ID_ORDEN = O.ID_ORDEN
ORDER BY O.FECHA_HORA_INGRESO, O.ID_ORDEN;

PROMPT ======================================================================
PROMPT REPORTE 02. ESTADO DE CUENTA POR FACTURA
PROMPT Incluye total, pagos recibidos, saldo pendiente y cantidad de pagos.
PROMPT Resultado esperado con el DML actual: 20 filas.
PROMPT ======================================================================

WITH PAGOS_POR_FACTURA AS (
    SELECT ID_FACTURA, SUM(MONTO) AS TOTAL_PAGADO, COUNT(*) AS CANTIDAD_PAGOS
    FROM PAGO
    GROUP BY ID_FACTURA
)
SELECT COUNT(*) OVER () AS TOTAL_FILAS_REPORTE,
       F.ID_FACTURA, F.NUMERO_FACTURA, F.FECHA_EMISION,
       C.NOMBRE AS CLIENTE, V.PLACA,
       F.SUBTOTAL, F.IMPUESTOS, F.TOTAL,
       NVL(P.TOTAL_PAGADO, 0) AS TOTAL_PAGADO,
       GREATEST(F.TOTAL - NVL(P.TOTAL_PAGADO, 0), 0) AS SALDO_PENDIENTE,
       NVL(P.CANTIDAD_PAGOS, 0) AS CANTIDAD_PAGOS,
       F.ESTADO
FROM FACTURA F
JOIN ORDEN_LAVADO O ON O.ID_ORDEN = F.ID_ORDEN
JOIN VEHICULO V ON V.ID_VEHICULO = O.ID_VEHICULO
JOIN CLIENTE C ON C.ID_CLIENTE = V.ID_CLIENTE
LEFT JOIN PAGOS_POR_FACTURA P ON P.ID_FACTURA = F.ID_FACTURA
ORDER BY F.FECHA_EMISION, F.ID_FACTURA;

PROMPT ======================================================================
PROMPT REPORTE 03. INGRESOS POR SERVICIO Y SEDE
PROMPT Resultado esperado con el DML actual: 12 filas.
PROMPT ======================================================================

SELECT COUNT(*) OVER () AS TOTAL_FILAS_REPORTE,
       E.ID_EMPRESA, E.NOMBRE_SUCURSAL,
       S.ID_SERVICIO, S.NOMBRE_SERVICIO,
       COUNT(D.ID_DETALLE) AS VECES_SOLICITADO,
       COUNT(DISTINCT D.ID_ORDEN) AS ORDENES_ATENDIDAS,
       SUM(D.PRECIO_APLICADO) AS INGRESOS_SERVICIO
FROM EMPRESA E
JOIN SERVICIO S ON S.ID_EMPRESA = E.ID_EMPRESA
JOIN DETALLE_ORDEN D
  ON D.ID_EMPRESA = S.ID_EMPRESA
 AND D.ID_SERVICIO = S.ID_SERVICIO
GROUP BY E.ID_EMPRESA, E.NOMBRE_SUCURSAL, S.ID_SERVICIO, S.NOMBRE_SERVICIO
ORDER BY E.ID_EMPRESA, S.ID_SERVICIO;

PROMPT ======================================================================
PROMPT REPORTE 04. FACTURACION ACUMULADA POR CLIENTE
PROMPT Resultado esperado con el DML actual: 15 filas.
PROMPT ======================================================================

SELECT COUNT(*) OVER () AS TOTAL_FILAS_REPORTE,
       C.ID_CLIENTE, C.NOMBRE AS CLIENTE,
       COUNT(DISTINCT F.ID_FACTURA) AS FACTURAS_EMITIDAS,
       SUM(F.SUBTOTAL) AS SUBTOTAL_ACUMULADO,
       SUM(F.IMPUESTOS) AS IMPUESTOS_ACUMULADOS,
       SUM(F.TOTAL) AS TOTAL_FACTURADO
FROM CLIENTE C
JOIN VEHICULO V ON V.ID_CLIENTE = C.ID_CLIENTE
JOIN ORDEN_LAVADO O ON O.ID_VEHICULO = V.ID_VEHICULO
JOIN FACTURA F ON F.ID_ORDEN = O.ID_ORDEN
GROUP BY C.ID_CLIENTE, C.NOMBRE
ORDER BY TOTAL_FACTURADO DESC, C.ID_CLIENTE;

PROMPT ======================================================================
PROMPT REPORTE 05. PRODUCTIVIDAD POR EMPLEADO Y MES
PROMPT Agrupa las ordenes atendidas por empleado y periodo YYYY-MM.
PROMPT Resultado esperado con el DML actual: 16 filas.
PROMPT ======================================================================

SELECT COUNT(*) OVER () AS TOTAL_FILAS_REPORTE,
       E.ID_EMPRESA, E.ID_EMPLEADO, E.NOMBRE AS EMPLEADO, E.CARGO,
       TO_CHAR(O.FECHA_HORA_INGRESO, 'YYYY-MM') AS PERIODO,
       COUNT(O.ID_ORDEN) AS ORDENES_ATENDIDAS
FROM EMPLEADO E
JOIN ORDEN_LAVADO O
  ON O.ID_EMPRESA = E.ID_EMPRESA
 AND O.ID_EMPLEADO_ASIGNADO = E.ID_EMPLEADO
GROUP BY E.ID_EMPRESA, E.ID_EMPLEADO, E.NOMBRE, E.CARGO,
         TO_CHAR(O.FECHA_HORA_INGRESO, 'YYYY-MM')
ORDER BY E.ID_EMPRESA, PERIODO, E.ID_EMPLEADO;

PROMPT ======================================================================
PROMPT REPORTE 06. INGRESOS POR SEDE, MES Y TIPO DE VEHICULO
PROMPT Resultado esperado con el DML actual: 12 filas.
PROMPT ======================================================================

SELECT COUNT(*) OVER () AS TOTAL_FILAS_REPORTE,
       E.ID_EMPRESA, E.NOMBRE_SUCURSAL,
       TO_CHAR(O.FECHA_HORA_INGRESO, 'YYYY-MM') AS PERIODO,
       V.TIPO_VEHICULO,
       COUNT(O.ID_ORDEN) AS ORDENES_ATENDIDAS,
       SUM(F.SUBTOTAL) AS SUBTOTAL,
       SUM(F.IMPUESTOS) AS IMPUESTOS,
       SUM(F.TOTAL) AS INGRESOS_FACTURADOS
FROM EMPRESA E
JOIN ORDEN_LAVADO O ON O.ID_EMPRESA = E.ID_EMPRESA
JOIN VEHICULO V ON V.ID_VEHICULO = O.ID_VEHICULO
JOIN FACTURA F ON F.ID_ORDEN = O.ID_ORDEN
GROUP BY E.ID_EMPRESA, E.NOMBRE_SUCURSAL,
         TO_CHAR(O.FECHA_HORA_INGRESO, 'YYYY-MM'),
         V.TIPO_VEHICULO
ORDER BY E.ID_EMPRESA, PERIODO, V.TIPO_VEHICULO;

PROMPT ======================================================================
PROMPT REPORTE 07. PAGOS REGISTRADOS CON FACTURA, METODO Y SEDE
PROMPT Resultado esperado con el DML actual: 18 filas.
PROMPT ======================================================================

SELECT COUNT(*) OVER () AS TOTAL_FILAS_REPORTE,
       P.ID_PAGO, P.FECHA_PAGO, P.MONTO, P.METODO_PAGO,
       F.ID_FACTURA, F.NUMERO_FACTURA, F.TOTAL AS TOTAL_FACTURA,
       O.ID_ORDEN, E.NOMBRE_SUCURSAL,
       C.NOMBRE AS CLIENTE, V.PLACA
FROM PAGO P
JOIN FACTURA F ON F.ID_FACTURA = P.ID_FACTURA
JOIN ORDEN_LAVADO O ON O.ID_ORDEN = F.ID_ORDEN
JOIN EMPRESA E ON E.ID_EMPRESA = O.ID_EMPRESA
JOIN VEHICULO V ON V.ID_VEHICULO = O.ID_VEHICULO
JOIN CLIENTE C ON C.ID_CLIENTE = V.ID_CLIENTE
ORDER BY P.FECHA_PAGO, P.ID_PAGO;

PROMPT ======================================================================
PROMPT REPORTE 08. VEHICULOS ATENDIDOS, PROPIETARIO Y GASTO
PROMPT Resultado esperado con el DML actual: 20 filas.
PROMPT ======================================================================

SELECT COUNT(*) OVER () AS TOTAL_FILAS_REPORTE,
       V.ID_VEHICULO,
       V.PLACA,
       V.MARCA,
       V.MODELO,
       V.TIPO_VEHICULO,
       C.NOMBRE AS PROPIETARIO,
       COUNT(O.ID_ORDEN) AS ORDENES_ATENDIDAS,
       SUM(F.TOTAL) AS GASTO_TOTAL_FACTURADO
FROM VEHICULO V
JOIN CLIENTE C ON C.ID_CLIENTE = V.ID_CLIENTE
JOIN ORDEN_LAVADO O ON O.ID_VEHICULO = V.ID_VEHICULO
JOIN FACTURA F ON F.ID_ORDEN = O.ID_ORDEN
GROUP BY V.ID_VEHICULO, V.PLACA, V.MARCA, V.MODELO,
         V.TIPO_VEHICULO, C.NOMBRE
ORDER BY GASTO_TOTAL_FACTURADO DESC, V.ID_VEHICULO;

PROMPT ======================================================================
PROMPT REPORTE 09. SERVICIOS SOLICITADOS POR TIPO DE VEHICULO
PROMPT Resultado esperado con el DML actual: 22 filas.
PROMPT ======================================================================

SELECT COUNT(*) OVER () AS TOTAL_FILAS_REPORTE,
       V.TIPO_VEHICULO,
       S.ID_SERVICIO,
       S.NOMBRE_SERVICIO,
       COUNT(D.ID_DETALLE) AS VECES_SOLICITADO,
       SUM(D.PRECIO_APLICADO) AS INGRESOS_GENERADOS
FROM VEHICULO V
JOIN ORDEN_LAVADO O
  ON O.ID_VEHICULO = V.ID_VEHICULO
JOIN DETALLE_ORDEN D
  ON D.ID_ORDEN = O.ID_ORDEN
 AND D.ID_EMPRESA = O.ID_EMPRESA
JOIN SERVICIO S
  ON S.ID_SERVICIO = D.ID_SERVICIO
 AND S.ID_EMPRESA = D.ID_EMPRESA
GROUP BY V.TIPO_VEHICULO,
         S.ID_SERVICIO,
         S.NOMBRE_SERVICIO
ORDER BY V.TIPO_VEHICULO, VECES_SOLICITADO DESC, S.ID_SERVICIO;

PROMPT ======================================================================
PROMPT REPORTE 10. TIEMPO REAL DE ATENCION FRENTE AL TIEMPO ESTIMADO
PROMPT Resultado esperado con el DML actual: 20 filas.
PROMPT ======================================================================

SELECT COUNT(*) OVER () AS TOTAL_FILAS_REPORTE,
       O.ID_ORDEN,
       E.NOMBRE_SUCURSAL,
       V.PLACA,
       V.TIPO_VEHICULO,
       O.FECHA_HORA_INGRESO,
       O.FECHA_HORA_SALIDA,
       SUM(S.TIEMPO_ESTIMADO_MIN) AS TIEMPO_ESTIMADO_MIN,
       ROUND(
           (CAST(O.FECHA_HORA_SALIDA AS DATE) -
            CAST(O.FECHA_HORA_INGRESO AS DATE)) * 1440
       ) AS TIEMPO_REAL_MIN,
       ROUND(
           (CAST(O.FECHA_HORA_SALIDA AS DATE) -
            CAST(O.FECHA_HORA_INGRESO AS DATE)) * 1440
           - SUM(S.TIEMPO_ESTIMADO_MIN)
       ) AS DIFERENCIA_MIN
FROM ORDEN_LAVADO O
JOIN EMPRESA E ON E.ID_EMPRESA = O.ID_EMPRESA
JOIN VEHICULO V ON V.ID_VEHICULO = O.ID_VEHICULO
JOIN DETALLE_ORDEN D
  ON D.ID_ORDEN = O.ID_ORDEN
 AND D.ID_EMPRESA = O.ID_EMPRESA
JOIN SERVICIO S
  ON S.ID_SERVICIO = D.ID_SERVICIO
 AND S.ID_EMPRESA = D.ID_EMPRESA
WHERE O.FECHA_HORA_SALIDA IS NOT NULL
GROUP BY O.ID_ORDEN,
         E.NOMBRE_SUCURSAL,
         V.PLACA,
         V.TIPO_VEHICULO,
         O.FECHA_HORA_INGRESO,
         O.FECHA_HORA_SALIDA
ORDER BY O.ID_ORDEN;

PROMPT ======================================================================
PROMPT FIN DE CONSULTAS_REPORTES.SQL
PROMPT Verificar TOTAL_FILAS_REPORTE >= 10 en cada uno de los diez reportes.
PROMPT ======================================================================
