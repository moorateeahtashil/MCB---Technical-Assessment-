create or replace PROCEDURE HighestOrderTotal
IS
  c2 SYS_REFCURSOR;  
BEGIN

  OPEN c2 FOR 
    SELECT TRIM(leading '0' from regexp_substr(MAX(orderreference), '^(PO)(.*)$', 1, 1, 'i',2)) as "Order Reference",
    MAX(TO_CHAR(TO_DATE(OrderDate, 'DD-MON-RR') ,'MONTH DD, YYYY'))as "Order Date",
    MAX(UPPER(SupplierName)) as "Supplier Name",
    MAX(TRIM(TO_CHAR(ordertotalamount,'999,999,999,999.00')))  as "Order Total Amount",
    MAX(OrderStatus) As "Order Status",
    listagg(distinct invoicereference, ',') within group (order by invoicereference)  as "Invoice References"
    FROM(
        SELECT HighestOrder.*,TblInvoice.InvoiceReference
        FROM (SELECT Order2.*, rownum rnum from
             (SELECT * FROM TblOrders WHERE ordertotalamount is not null ORDER BY ordertotalamount DESC) Order2
        WHERE rownum <= 3 ) HighestOrder
    JOIN TblInvoice on TblInvoice.InvoiceReference like ('%' || HighestOrder.OrderReference || '%')
    WHERE HighestOrder.rnum >= 3);
     DBMS_SQL.RETURN_RESULT(c2);

END HighestOrderTotal;

Execute HighestOrderTotal;