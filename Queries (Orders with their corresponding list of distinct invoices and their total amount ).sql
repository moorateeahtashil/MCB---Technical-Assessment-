create or replace PROCEDURE OrderSummary
IS
  c1 SYS_REFCURSOR;  
BEGIN

  OPEN c1 FOR 
    SELECT TRIM(leading '0' from regexp_substr(tblorders.orderreference, '^(PO)(.*)$', 1, 1, 'i',2)) as "Order Reference",
    LTRIM(TO_CHAR(tblorders.orderdate,'MON-yyyy'),'0') as "Order Period",
    UPPER(substr(TblSupplier.SupplierName,1,1))||LOWER(substr(TblSupplier.SupplierName,2,length(TblSupplier.SupplierName))) as "Supplier Name",
    TRIM(TO_CHAR(tblorders.ordertotalamount,'999,999,999,999.00')) as "Order Total Amount",
    tblorders.orderstatus as "Order Status",
    tblinvoice.invoicereference as "Invoice Reference",
    TRIM(TO_CHAR(sum(tblinvoice.invoiceamount),'999,999,999,999.00')) as "Invoice Total Amount",
    CASE WHEN tblinvoice.invoicestatus='Paid' THEN 'Ok'
    WHEN tblinvoice.invoicestatus='Pending' THEN 'To follow up'
    WHEN NVL(tblinvoice.invoicestatus, '')=''  THEN 'To verify'
    ELSE tblinvoice.invoicestatus
    END AS "Action"
    FROM tblorders JOIN tblinvoice on tblorders.orderid = tblinvoice.orderid
    JOIN TblSupplier on TblSupplier.SupplierName = tblorders.suppliername
    GROUP BY tblorders.orderreference,tblorders.orderdate,TblSupplier.SupplierName,
    tblorders.orderstatus,tblorders.ordertotalamount,tblinvoice.invoicereference,
    tblinvoice.invoicestatus
    ORDER BY tblorders.orderdate DESC;
  DBMS_SQL.RETURN_RESULT(c1);
    
END OrderSummary;

EXECUTE OrderSummary;