create or replace Procedure OrdersInPeriod

IS
    
    CURSOR c_contact IS
    select * from TblSupplierContact;    
    r_contact c_contact%ROWTYPE;
    GUID VARCHAR2(128 Byte);
    l_count NUMBER;
    c3 SYS_REFCURSOR;
BEGIN
    SELECT sys_guid() into GUID from dual;
    
    OPEN c_contact;
    LOOP
        FETCH  c_contact  INTO r_contact;
        EXIT WHEN c_contact%NOTFOUND;
        
        SELECT count(*) INTO l_count FROM TblSupplierContactTemp WHERE SUPPLIERNAME = r_contact.SUPPLIERNAME;
        
        IF l_count = 0 THEN
            INSERT INTO TblSupplierContactTemp (SUPPLIERNAME,SUPPLIERCONTACTNUMBER1,SUPPLIERCONTACTNUMBER2,GUID)
            VALUES(r_contact.SUPPLIERNAME,r_contact.SUPPLIERCONTACTNUMBER,null,GUID);
        ELSE
            UPDATE TblSupplierContactTemp
            SET SUPPLIERCONTACTNUMBER2 = r_contact.SUPPLIERCONTACTNUMBER
            WHERE SUPPLIERNAME = r_contact.SUPPLIERNAME;
        END IF;
        
       
    END LOOP;
    CLOSE c_contact;
    
    
     OPEN C3 FOR
        SELECT  ORDERS.SupplierName as "Supplier Name",
                ORDERS.suppliercontactname as "Supplier Contact Name",
                CONCAT(REGEXP_REPLACE( SUPPLIERCONTACTNUMBER1,'\d{4}$', '-' ),SUBSTR(SUPPLIERCONTACTNUMBER1,Length(SUPPLIERCONTACTNUMBER1)-3,4)) as "Supplier Contact No. 1",
                CONCAT(REGEXP_REPLACE( SUPPLIERCONTACTNUMBER2,'\d{4}$', '-' ),SUBSTR(SUPPLIERCONTACTNUMBER2,Length(SUPPLIERCONTACTNUMBER2)-3,4)) as "Supplier Contact No. 2",
                ORDERS.Count as "Total Orders",
                TRIM(TO_CHAR(ORDERS.sumamount,'999,999,999,999.00')) as "Order Total Amount"
        FROM
        (SELECT tblsupplier.SupplierName,tblsupplier.suppliercontactname,
                COUNT(tblorders.orderreference) as count ,SUM(ordertotalamount) as sumamount FROM TblSupplier 
                JOIN TblOrders on tblorders.suppliername = TblSupplier.SupplierName
                WHERE tblorders.orderdate >= '01 Jan 2017' and tblorders.orderdate <= '31 Aug 2017'
                GROUP BY tblsupplier.suppliername,tblsupplier.suppliercontactname) ORDERS
        JOIN TblSupplierContactTemp on TblSupplierContactTemp.suppliername = ORDERS.SupplierName;
    
        
    DBMS_SQL.RETURN_RESULT(c3);
    
    
    DELETE FROM TblSupplierContactTemp WHERE GUID = GUID;
END;


EXECUTE OrdersInPeriod;
