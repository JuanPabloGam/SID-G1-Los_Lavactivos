-- ============================================================================
-- CONSULTAS DQL - PROYECTO LAVADERO DE AUTOS
-- ============================================================================

-- 1. Reporte de servicios más facturados por sucursal (TOP 5 / primeros 5 registros):
-- Muestra los 5 servicios con mayor ingreso total facturado en cada sucursal,
-- uniendo EMPRESA, DETALLE_ORDEN y SERVICIO mediante INNER JOIN, agrupando por
-- sucursal, ciudad y nombre del servicio, y ordenando de mayor a menor ingreso.
SELECT
    e.NOMBRE_SUCURSAL,
    e.CIUDAD,
    s.NOMBRE_SERVICIO,
    COUNT(do.ID_DETALLE) AS CANTIDAD_SERVICIOS,
    SUM(do.PRECIO_APLICADO) AS INGRESO_TOTAL
FROM EMPRESA e
INNER JOIN DETALLE_ORDEN do
    ON e.ID_EMPRESA = do.ID_EMPRESA
INNER JOIN SERVICIO s
    ON do.ID_SERVICIO = s.ID_SERVICIO
GROUP BY
    e.NOMBRE_SUCURSAL,
    e.CIUDAD,
    s.NOMBRE_SERVICIO
ORDER BY
    INGRESO_TOTAL DESC
FETCH FIRST 5 ROWS ONLY;

-- 2. Reporte de carga de órdenes por empleado (incluyendo empleados sin órdenes asignadas):
-- Lista los empleados de cada sucursal junto con el total de órdenes de lavado asignadas,
-- utilizando INNER JOIN con EMPRESA y LEFT OUTER JOIN con ORDEN_LAVADO para conservar
-- también a los empleados sin asignaciones, agrupado por empleado y ordenado por cantidad descendente.
SELECT
    e.NOMBRE_SUCURSAL,
    emp.ID_EMPLEADO,
    emp.NOMBRE AS NOMBRE_EMPLEADO,
    emp.CARGO,
    COUNT(ol.ID_ORDEN) AS TOTAL_ORDENES_ASIGNADAS
FROM EMPLEADO emp
INNER JOIN EMPRESA e
    ON emp.ID_EMPRESA = e.ID_EMPRESA
LEFT OUTER JOIN ORDEN_LAVADO ol
    ON emp.ID_EMPLEADO = ol.ID_EMPLEADO_ASIGNADO
    AND emp.ID_EMPRESA = ol.ID_EMPRESA
GROUP BY
    e.NOMBRE_SUCURSAL,
    emp.ID_EMPLEADO,
    emp.NOMBRE,
    emp.CARGO
ORDER BY
    TOTAL_ORDENES_ASIGNADAS DESC,
    emp.NOMBRE ASC;

-- 3. Reporte de clientes, vehículos y pagos acumulados (incluyendo clientes sin vehículos o sin pagos):
-- Muestra cada cliente registrado, cuántos vehículos tiene y el monto total pagado en facturas,
-- encadenando LEFT OUTER JOIN sobre VEHICULO, ORDEN_LAVADO, FACTURA y PAGO para no excluir
-- clientes sin vehículos ni facturas sin pagos, agrupado por cliente y ordenado por mayor pago.
SELECT
    c.ID_CLIENTE,
    c.NOMBRE AS NOMBRE_CLIENTE,
    c.TELEFONO,
    COUNT(DISTINCT v.ID_VEHICULO) AS TOTAL_VEHICULOS,
    NVL(SUM(p.MONTO), 0) AS TOTAL_PAGADO
FROM CLIENTE c
LEFT OUTER JOIN VEHICULO v
    ON c.ID_CLIENTE = v.ID_CLIENTE
LEFT OUTER JOIN ORDEN_LAVADO ol
    ON v.ID_VEHICULO = ol.ID_VEHICULO
LEFT OUTER JOIN FACTURA f
    ON ol.ID_ORDEN = f.ID_ORDEN
LEFT OUTER JOIN PAGO p
    ON f.ID_FACTURA = p.ID_FACTURA
GROUP BY
    c.ID_CLIENTE,
    c.NOMBRE,
    c.TELEFONO
ORDER BY
    TOTAL_PAGADO DESC,
    c.NOMBRE ASC;

-- 4. Reporte de las 3 sucursales con mayor facturación y recaudo:
-- Obtiene las 3 sucursales con mayor valor total facturado y su acumulado de pagos recibidos,
-- uniendo EMPRESA, ORDEN_LAVADO y FACTURA con INNER JOIN y PAGO con LEFT OUTER JOIN,
-- agrupando por sucursal y ciudad, y ordenando por total facturado de forma descendente.
SELECT
    e.ID_EMPRESA,
    e.NOMBRE_SUCURSAL,
    e.CIUDAD,
    COUNT(DISTINCT f.ID_FACTURA) AS FACTURAS_EMITIDAS,
    SUM(f.TOTAL) AS TOTAL_FACTURADO,
    NVL(SUM(p.MONTO), 0) AS TOTAL_RECAUDADO
FROM EMPRESA e
INNER JOIN ORDEN_LAVADO ol
    ON e.ID_EMPRESA = ol.ID_EMPRESA
INNER JOIN FACTURA f
    ON ol.ID_ORDEN = f.ID_ORDEN
LEFT OUTER JOIN PAGO p
    ON f.ID_FACTURA = p.ID_FACTURA
GROUP BY
    e.ID_EMPRESA,
    e.NOMBRE_SUCURSAL,
    e.CIUDAD
ORDER BY
    TOTAL_FACTURADO DESC
FETCH FIRST 3 ROWS ONLY;

-- 5. Reporte de órdenes de lavado por estado y tipo de vehículo:
-- Resume cuántas órdenes de lavado existen y el subtotal acumulado de servicios según
-- el estado de la orden (RECIBIDA, EN_PROCESO, FINALIZADA, ENTREGADA o CANCELADA) y el tipo
-- de vehículo, combinando ORDEN_LAVADO, VEHICULO y DETALLE_ORDEN, agrupado y ordenado
-- alfabéticamente por estado y tipo de vehículo.
SELECT
    ol.ESTADO AS ESTADO_ORDEN,
    v.TIPO_VEHICULO,
    COUNT(DISTINCT ol.ID_ORDEN) AS CANTIDAD_ORDENES,
    NVL(SUM(do.PRECIO_APLICADO), 0) AS SUBTOTAL_SERVICIOS
FROM ORDEN_LAVADO ol
INNER JOIN VEHICULO v
    ON ol.ID_VEHICULO = v.ID_VEHICULO
LEFT OUTER JOIN DETALLE_ORDEN do
    ON ol.ID_ORDEN = do.ID_ORDEN
GROUP BY
    ol.ESTADO,
    v.TIPO_VEHICULO
ORDER BY
    ol.ESTADO ASC,
    v.TIPO_VEHICULO ASC;