# SID-G1 - Los Lavactivos

Proyecto final de **Sistemas Intensivos en Datos**: base de datos relacional en Oracle para un lavadero de vehículos con dos sedes en Cali. Registra sedes, clientes, vehículos, empleados, servicios, órdenes de lavado con su detalle, facturas y pagos.

**Integrantes:** Juan Camilo Vargas Muñoz, Pablo Ganboa Riquet, Juan David Delgado
**Docente:** Julián Alonso Cifuentes

## Contenido del repositorio

| Ruta | Descripción |
|---|---|
| `Scripts/DDL_Lavadero.sql` | Creación de las 9 tablas, restricciones, secuencia, índices y comentarios |
| `Scripts/DML_Lavadero.sql` | Carga de 155 registros de prueba con validación antes del COMMIT |
| `Scripts/Consultas_Reportes.sql` | Diez reportes de gestión (cada uno con al menos 10 filas) |
| `Scripts/DQL_Lavadero.sql` | Cinco consultas adicionales con INNER JOIN, LEFT OUTER JOIN, GROUP BY y TOP N |
| `Scripts/PL_SQL_Lavadero.sql` | Función FN_SALDO_FACTURA, procedimiento PR_REGISTRAR_PAGO y trigger TRG_VALIDAR_FECHA_PAGO |
| `ER_Lavadero.pdf`, `MER_Lavadero.pdf` | Modelo entidad-relación y modelo relacional actualizados |
| `DiagramaEntidadRelaciónProyecto/` | Proyecto de Oracle SQL Developer Data Modeler y primera versión de los diagramas |
| `Documentacion_Proyecto_Lavadero.pdf` | Documentación complementaria del proyecto |

## Orden de ejecución

Ejecutar en Oracle SQL Developer (F5, ejecutar script), sobre un esquema limpio:

1. `DDL_Lavadero.sql`
2. `DML_Lavadero.sql`
3. `Consultas_Reportes.sql`
4. `DQL_Lavadero.sql`
5. `PL_SQL_Lavadero.sql`

El DDL y el DML se ejecutan una sola vez. Las consultas y el script PL/SQL se pueden volver a ejecutar.

## Modelo

EMPRESA, CLIENTE, EMPLEADO, SERVICIO, VEHICULO, ORDEN_LAVADO, DETALLE_ORDEN, FACTURA y PAGO.
