/* ============================================================================
   OBJETIVO
   --------
   Implementar objetos PL/SQL para apoyar el proceso de facturacion y pagos:
   1. Funcion FN_SALDO_FACTURA: calcula el saldo pendiente de una factura.
   2. Procedimiento PR_REGISTRAR_PAGO: registra un pago validando las reglas
      de negocio y actualiza el estado de la factura.
   3. Trigger TRG_VALIDAR_FECHA_PAGO: asigna la fecha si llega NULL y evita
      registrar pagos anteriores a la fecha de emision de la factura.

   DEPENDENCIAS
   ------------
   Este archivo requiere que previamente se hayan ejecutado:
   - DDL_Lavadero.sql
   - DML_Lavadero.sql
   Es el ultimo de los cinco scripts del proyecto (DDL, DML,
   Consultas_Reportes, DQL y PL/SQL).

   IMPORTANTE
   ----------
   - El DDL crea la secuencia SEQ_PAGO con inicio en 19, pues el DML utiliza
     los identificadores de pago del 1 al 18.
   - El procedimiento NO ejecuta COMMIT ni ROLLBACK. La transaccion queda
     bajo el control de quien invoque el procedimiento.
   - Este archivo crea o reemplaza solamente la funcion, el procedimiento
     y el trigger documentados aqui. No modifica los datos existentes.
   ============================================================================ */

SET SERVEROUTPUT ON
SET VERIFY OFF
SET DEFINE OFF

PROMPT ======================================================================
PROMPT 1. FUNCION: FN_SALDO_FACTURA
PROMPT Calcula total de factura menos la suma de sus pagos.
PROMPT ======================================================================

CREATE OR REPLACE FUNCTION FN_SALDO_FACTURA (
    P_ID_FACTURA IN FACTURA.ID_FACTURA%TYPE
) RETURN NUMBER
IS
    V_SALDO NUMBER(12,2);
BEGIN
    SELECT F.TOTAL - NVL(SUM(P.MONTO), 0)
      INTO V_SALDO
      FROM FACTURA F
      LEFT JOIN PAGO P
        ON P.ID_FACTURA = F.ID_FACTURA
     WHERE F.ID_FACTURA = P_ID_FACTURA
     GROUP BY F.TOTAL;

    RETURN V_SALDO;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'No existe la factura indicada.'
        );
END;
/

SHOW ERRORS FUNCTION FN_SALDO_FACTURA

PROMPT ======================================================================
PROMPT 2. PROCEDIMIENTO: PR_REGISTRAR_PAGO
PROMPT Valida y registra un pago; actualiza el estado de la factura.
PROMPT ======================================================================

CREATE OR REPLACE PROCEDURE PR_REGISTRAR_PAGO (
    P_ID_FACTURA  IN FACTURA.ID_FACTURA%TYPE,
    P_MONTO       IN PAGO.MONTO%TYPE,
    P_METODO_PAGO IN PAGO.METODO_PAGO%TYPE
)
IS
    V_TOTAL_FACTURA FACTURA.TOTAL%TYPE;
    V_ESTADO        FACTURA.ESTADO%TYPE;
    V_SALDO         NUMBER(12,2);
BEGIN
    -- Validar el monto antes de consultar o modificar registros.
    IF P_MONTO IS NULL OR P_MONTO <= 0 THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'El monto del pago debe ser mayor que cero.'
        );
    END IF;

    -- Respetar exactamente los valores permitidos por CK_PAGO_METODO.
    IF P_METODO_PAGO IS NULL
       OR P_METODO_PAGO NOT IN ('Efectivo', 'Tarjeta', 'Transferencia') THEN
        RAISE_APPLICATION_ERROR(
            -20003,
            'Metodo de pago no valido. Use Efectivo, Tarjeta o Transferencia.'
        );
    END IF;

    -- Bloquear la factura para evitar pagos concurrentes que excedan el total.
    BEGIN
        SELECT TOTAL, ESTADO
          INTO V_TOTAL_FACTURA, V_ESTADO
          FROM FACTURA
         WHERE ID_FACTURA = P_ID_FACTURA
           FOR UPDATE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                -20004,
                'No existe la factura indicada.'
            );
    END;

    -- No se permiten pagos sobre facturas anuladas o ya pagadas.
    IF V_ESTADO = 'ANULADA' THEN
        RAISE_APPLICATION_ERROR(
            -20005,
            'No se pueden registrar pagos sobre una factura anulada.'
        );
    ELSIF V_ESTADO = 'PAGADA' THEN
        RAISE_APPLICATION_ERROR(
            -20006,
            'La factura ya se encuentra pagada.'
        );
    END IF;

    -- La funcion obtiene el saldo considerando todos los pagos registrados.
    V_SALDO := FN_SALDO_FACTURA(P_ID_FACTURA);

    IF V_SALDO <= 0 THEN
        RAISE_APPLICATION_ERROR(
            -20007,
            'La factura no tiene saldo pendiente.'
        );
    END IF;

    IF P_MONTO > V_SALDO THEN
        RAISE_APPLICATION_ERROR(
            -20008,
            'El pago excede el saldo pendiente de la factura.'
        );
    END IF;

    -- FECHA_PAGO se envia como NULL intencionalmente:
    -- TRG_VALIDAR_FECHA_PAGO asigna SYSTIMESTAMP antes de validar NOT NULL.
    INSERT INTO PAGO (
        ID_PAGO,
        ID_FACTURA,
        FECHA_PAGO,
        MONTO,
        METODO_PAGO
    ) VALUES (
        SEQ_PAGO.NEXTVAL,
        P_ID_FACTURA,
        NULL,
        P_MONTO,
        P_METODO_PAGO
    );

    -- Si el abono cubre exactamente el saldo, la factura queda PAGADA.
    -- En caso contrario, queda PARCIAL.
    IF P_MONTO = V_SALDO THEN
        UPDATE FACTURA
           SET ESTADO = 'PAGADA'
         WHERE ID_FACTURA = P_ID_FACTURA;
    ELSE
        UPDATE FACTURA
           SET ESTADO = 'PARCIAL'
         WHERE ID_FACTURA = P_ID_FACTURA;
    END IF;

    DBMS_OUTPUT.PUT_LINE(
        'Pago registrado. Factura: ' || P_ID_FACTURA ||
        ' | Monto: ' || TO_CHAR(P_MONTO) ||
        ' | Estado actualizado: ' ||
        CASE
            WHEN P_MONTO = V_SALDO THEN 'PAGADA'
            ELSE 'PARCIAL'
        END
    );

    -- No se confirma la transaccion aqui. El usuario decide COMMIT o ROLLBACK.
END;
/

SHOW ERRORS PROCEDURE PR_REGISTRAR_PAGO

PROMPT ======================================================================
PROMPT 3. TRIGGER: TRG_VALIDAR_FECHA_PAGO
PROMPT Asigna fecha cuando es NULL y valida que no anteceda a la factura.
PROMPT ======================================================================

CREATE OR REPLACE TRIGGER TRG_VALIDAR_FECHA_PAGO
BEFORE INSERT OR UPDATE OF FECHA_PAGO, ID_FACTURA
ON PAGO
FOR EACH ROW
DECLARE
    V_FECHA_EMISION FACTURA.FECHA_EMISION%TYPE;
BEGIN
    -- Si no se proporciona fecha, se utiliza la fecha y hora del servidor.
    IF :NEW.FECHA_PAGO IS NULL THEN
        :NEW.FECHA_PAGO := SYSTIMESTAMP;
    END IF;

    -- Consultar la fecha de emision de la factura asociada.
    BEGIN
        SELECT FECHA_EMISION
          INTO V_FECHA_EMISION
          FROM FACTURA
         WHERE ID_FACTURA = :NEW.ID_FACTURA;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                -20009,
                'No existe la factura asociada al pago.'
            );
    END;

    -- Un pago no puede tener fecha anterior a la emision de su factura.
    IF :NEW.FECHA_PAGO < V_FECHA_EMISION THEN
        RAISE_APPLICATION_ERROR(
            -20010,
            'La fecha del pago no puede ser anterior a la emision de la factura.'
        );
    END IF;
END;
/

SHOW ERRORS TRIGGER TRG_VALIDAR_FECHA_PAGO

PROMPT ======================================================================
PROMPT 4. VERIFICACION DE OBJETOS PL/SQL
PROMPT Deben aparecer la funcion, el procedimiento y el trigger como VALID.
PROMPT ======================================================================

SELECT OBJECT_NAME,
       OBJECT_TYPE,
       STATUS
  FROM USER_OBJECTS
 WHERE OBJECT_NAME IN (
       'FN_SALDO_FACTURA',
       'PR_REGISTRAR_PAGO',
       'TRG_VALIDAR_FECHA_PAGO'
 )
 ORDER BY OBJECT_TYPE, OBJECT_NAME;

PROMPT ======================================================================
PROMPT 5. VERIFICACION DE ERRORES DE COMPILACION
PROMPT La consulta debe devolver cero filas.
PROMPT ======================================================================

SELECT NAME,
       TYPE,
       LINE,
       POSITION,
       TEXT
  FROM USER_ERRORS
 WHERE NAME IN (
       'FN_SALDO_FACTURA',
       'PR_REGISTRAR_PAGO',
       'TRG_VALIDAR_FECHA_PAGO'
 )
 ORDER BY NAME, SEQUENCE;

PROMPT ======================================================================
PROMPT FIN DE PL_SQL_LAVADERO.SQL
PROMPT No se insertaron pagos ni se modificaron datos de prueba.
PROMPT ======================================================================
