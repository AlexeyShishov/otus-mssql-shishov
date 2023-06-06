/*
1. �������� �������� ��������� ������������
������� � ��������� ������� ������ �������.

5. �� ������ �������� - ������ ��������������� ��� ��������� ���� ������-������ �� ������ � ��. 
�� ���� ����������������, ����� � ����� � ����������� �� ��������� ������� �������� - READ COMMITTED, �� ������� ��������, ����������� ������.
����������� ������������� �� �������� �� �������� ��, �� � �������� ���� "������� ������������/����������� ��������" (��� � �.1) ��������� ����� ������ ����� �������� ���� ���������.
����, ���� ��� �������� �� �� 2-4 ��� ����� ���������� ��� ������ ������, �� ������������ READ UNCOMMITTED �������� - ��� ������������ ����� �������� �������� ��� ���� ��������, ��� ������� 1 ������ ����� �� ����� ������������
*/

USE WideWorldImporters;
GO

DROP PROCEDURE IF EXISTS sp_ClientIDWithMaxInvoiceSum
GO

CREATE PROCEDURE sp_ClientIDWithMaxInvoiceSum
AS 
	SELECT top(1) inv.CustomerID FROM Sales.Invoices as inv
	LEFT JOIN Sales.InvoiceLines il on il.InvoiceID = inv.InvoiceID
	GROUP BY il.InvoiceID, inv.CustomerID 
	ORDER BY SUM(il.quantity*il.UnitPrice) DESC;
GO

DROP PROCEDURE IF EXISTS sp_ClientWithMaxInvoiceSum 
GO

CREATE PROCEDURE sp_ClientWithMaxInvoiceSum
AS
	SELECT top(1) cust.CustomerID, cust.CustomerName, inv.InvoiceID, SUM(il.quantity*il.UnitPrice) as ChequeSum FROM Sales.Invoices as inv
	LEFT JOIN Sales.InvoiceLines il on il.InvoiceID = inv.InvoiceID
	LEFT JOIN Sales.Customers cust on inv.CustomerID = cust.CustomerID
	GROUP BY il.InvoiceID, cust.CustomerID, cust.CustomerName, inv.InvoiceID 
	ORDER BY SUM(il.quantity*il.UnitPrice) DESC;
GO

Exec sp_ClientIDWithMaxInvoiceSum;
Exec sp_ClientWithMaxInvoiceSum;

/*
2. �������� �������� ��������� � ��������
���������� �ustomerID, ��������� �����
������� �� ����� �������.
������������ ������� :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/

DROP PROCEDURE IF EXISTS sp_ShowClientInvoices
GO

CREATE PROCEDURE sp_ShowClientInvoices
	@�ustomerID INT
AS
	SET NOCOUNT ON;
	SELECT cust.CustomerID, cust.CustomerName, inv.InvoiceID, SUM(il.quantity*il.UnitPrice) as ChequeSum FROM Sales.Invoices as inv
	LEFT JOIN Sales.InvoiceLines il on il.InvoiceID = inv.InvoiceID
	LEFT JOIN Sales.Customers cust on inv.CustomerID = cust.CustomerID
	WHERE cust.CustomerID = @�ustomerID
	GROUP BY il.InvoiceID, cust.CustomerID, cust.CustomerName, inv.InvoiceID 
	ORDER BY inv.InvoiceID;
GO

Exec sp_ShowClientInvoices 123;

/*
3. ������� ���������� ������� � �������� ���������, ���������� � ��� ������� � ������������������ � ������.
*/

DROP PROCEDURE IF EXISTS sp_AvgInvoiceSumForCust 
GO

CREATE PROCEDURE sp_AvgInvoiceSumForCust
AS
	SELECT CustomerID, Name, AVG(ChequeSum) as AvgInvoiceSum FROM
	(SELECT 
	cust.CustomerID as CustomerID,  
	cust.CustomerName as Name,
	SUM(il.quantity*il.UnitPrice) OVER (partition by inv.InvoiceID ) as ChequeSum 
	FROM Sales.Invoices as inv
	LEFT JOIN Sales.InvoiceLines il on il.InvoiceID = inv.InvoiceID
	LEFT JOIN Sales.Customers cust on inv.CustomerID = cust.CustomerID) as sumdata
	GROUP BY CustomerID, Name
	ORDER BY CustomerID
GO

DROP FUNCTION IF EXISTS ufn_AvgInvoiceSumForCust; 
GO
CREATE FUNCTION ufn_AvgInvoiceSumForCust ()
RETURNS TABLE 
AS  
RETURN 
(
SELECT CustomerID, Name, AVG(ChequeSum) as AvgInvoiceSum FROM
	(SELECT 
	cust.CustomerID as CustomerID,  
	cust.CustomerName as Name,
	SUM(il.quantity*il.UnitPrice) OVER (partition by inv.InvoiceID ) as ChequeSum 
	FROM Sales.Invoices as inv
	LEFT JOIN Sales.InvoiceLines il on il.InvoiceID = inv.InvoiceID
	LEFT JOIN Sales.Customers cust on inv.CustomerID = cust.CustomerID) as sumdata
	GROUP BY CustomerID, Name
)
GO

EXEC sp_AvgInvoiceSumForCust
SELECT * FROM ufn_AvgInvoiceSumForCust() ORDER BY CustomerID;
GO
/*
Query cost � ����� ��������� - 50%, ����� ���������� ���������. 
����������, ��� ��� ������� ���, ��� ������ ���� � ��� �� ������, � ���� � ���� ������� � �������� ��������� ����������(������� ��� ���������) ��� ����� ����, �� ��� �������� ����
*/

/*
4. �������� ��������� ������� �������� ��� �� ����� ������� ��� ������ ������ result set'� ��� ������������� �����.
*/
DROP FUNCTION IF EXISTS ufn_AllOrdersForClient; 
GO
CREATE FUNCTION ufn_AllOrdersForClient (@�ustomerID INT)
RETURNS TABLE 
AS  
RETURN 
(
	SELECT cust.CustomerID, inv.InvoiceDate, inv.InvoiceID, SUM(il.quantity*il.UnitPrice) as ChequeSum 
	FROM Sales.Invoices as inv
	LEFT JOIN Sales.InvoiceLines il on il.InvoiceID = inv.InvoiceID
	LEFT JOIN Sales.Customers cust on inv.CustomerID = cust.CustomerID
	WHERE cust.CustomerID = @�ustomerID
	GROUP BY cust.CustomerID, inv.InvoiceDate, inv.InvoiceID
)
GO


SELECT c.CustomerID, CustomerName, funcuse.* FROM Sales.Customers c
CROSS APPLY (SELECT * FROM ufn_AllOrdersForClient(CustomerID)) as funcuse
ORDER BY c.CustomerID

-- ������� �������

DROP PROCEDURE IF EXISTS sp_ClientIDWithMaxInvoiceSum
DROP PROCEDURE IF EXISTS sp_ClientWithMaxInvoiceSum
DROP PROCEDURE IF EXISTS sp_ShowClientInvoices
DROP PROCEDURE IF EXISTS sp_AvgInvoiceSumForCust 
DROP FUNCTION IF EXISTS ufn_AvgInvoiceSumForCust 
DROP FUNCTION IF EXISTS ufn_AllOrdersForClient