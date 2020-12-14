CREATE OR REPLACE PACKAGE MIGRATION_PROCESS 
IS
    Procedure MIGRATIONCONTACTNUMBER;
    Procedure MIGRATIONSUPPLIERS;
    Procedure MIGRATIONORDERANDINVOICE;
    Procedure MIGRATION;
    
END MIGRATION_PROCESS ;
/
CREATE OR REPLACE PACKAGE BODY MIGRATION_PROCESS 
IS

    Procedure MIGRATIONSUPPLIERS IS   
    BEGIN   
        INSERT INTO TblSupplier(SupplierName,SupplierContactName,SupplierAddress)
        SELECT DISTINCT Supplier_Name,SUPP_CONTACT_NAME,
        CONCAT(REPLACE(TRIM(REPLACE(REPLACE(REPLACE(SUPP_ADDRESS,' -,',''),'-,',''),' - ,','')),' ,Mauritius',''),' , Mauritius') from XXBCM_ORDER_MGT ;
        dbms_output.put_line('Migration Suppliers details completed successfully');
    END MIGRATIONSUPPLIERS;
    
    
    Procedure MIGRATIONCONTACTNUMBER IS
    
    BEGIN   
        INSERT INTO TblSupplierContact(SupplierName,SupplierContactNumber)
        SELECT DISTINCT
        SUPPLIER_NAME,
        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(trim(regexp_substr(SUPP_CONTACT_NUMBER, '[^,]+', 1, levels.column_value)),'.',''),'S',5),'O',0),'I',1),'s',5),'o',0),'i',1),' ','') as CONTACTNUMBER
        FROM  XXBCM_ORDER_MGT,
        table(cast(multiset(select level from dual connect by  level <= length (regexp_replace(SUPP_CONTACT_NUMBER, '[^,]+'))  + 1) as sys.OdciNumberList)) levels
        ORDER BY SUPPLIER_NAME;
        dbms_output.put_line('Migration Suppliers Contact details completed successfully');
    END MIGRATIONCONTACTNUMBER; 
    
    
    
    Procedure MIGRATIONORDERANDINVOICE IS
    Inserted_OrderValue  number;
    Inserted_SupplierValue  number;
    CURSOR c_sales IS
    select * from xxbcm_order_mgt;    
    r_sales c_sales%ROWTYPE;
   
    BEGIN
        OPEN c_sales;

        LOOP
        
            FETCH  c_sales  INTO r_sales;
            EXIT WHEN c_sales%NOTFOUND;
            
            
            
            INSERT INTO TBLOrders(OrderReference,OrderDate,OrderStatus,OrderDescription,OrderTotalAmount,OrderLineAmount,SupplierName)
            VALUES (r_sales.ORDER_REF,TO_DATE(r_sales.ORDER_DATE,'dd/mm/yyyy'),r_sales.Order_Status,r_sales.Order_Description,REPLACE(r_sales.Order_Total_Amount,',',''),
            REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(r_sales.Order_Line_Amount,',',''),'S',5),'O',0),'I',1),'s',5),'o',0),'i',1),r_sales.Supplier_Name);
            
            
            SELECT max(OrderID)  INTO Inserted_OrderValue FROM TBLOrders ;
          
            INSERT INTO TblInvoice(InvoiceReference,InvoiceDate,InvoiceStatus,InvoiceHoldReason,InvoiceDescription,InvoiceAmount,OrderId)
            VALUES(r_sales.INVOICE_REFERENCE,TO_DATE(r_sales.INVOICE_DATE,'dd/mm/yyyy'),r_sales.INVOICE_STATUS,r_sales.INVOICE_HOLD_REASON,
            r_sales.INVOICE_DESCRIPTION,
            REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(r_sales.INVOICE_AMOUNT,',',''),'S',5),'O',0),'I',1),'s',5),'o',0),'i',1),Inserted_OrderValue);
            
            
            DELETE FROM TblInvoice WHERE InvoiceReference IS NULL;
        END LOOP;

        CLOSE c_sales;
        dbms_output.put_line('Migration Order and Invoice completed successfully');
    END MIGRATIONORDERANDINVOICE;
    
    
    Procedure MIGRATION IS 
    BEGIN
        migrationsuppliers();
        migrationcontactnumber();
        migrationorderandinvoice();
    END MIGRATION;
    
END MIGRATION_PROCESS ;