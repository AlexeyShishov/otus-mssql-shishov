/*
--�������� ���������: 

Select ord.CustomerID, det.StockItemID, SUM(det.UnitPrice), SUM(det.Quantity), COUNT(ord.OrderID)
FROM Sales.Orders AS ord
JOIN Sales.OrderLines AS det
ON det.OrderID = ord.OrderID
JOIN Sales.Invoices AS Inv
ON Inv.OrderID = ord.OrderID
JOIN Sales.CustomerTransactions AS Trans
ON Trans.InvoiceID = Inv.InvoiceID
JOIN Warehouse.StockItemTransactions AS ItemTrans
ON ItemTrans.StockItemID = det.StockItemID
WHERE Inv.BillToCustomerID != ord.CustomerID
AND (Select SupplierId
FROM Warehouse.StockItems AS It
Where It.StockItemID = det.StockItemID) = 12
AND (SELECT SUM(Total.UnitPrice*Total.Quantity)
FROM Sales.OrderLines AS Total
Join Sales.Orders AS ordTotal
On ordTotal.OrderID = Total.OrderID
WHERE ordTotal.CustomerID = Inv.CustomerID) > 250000
AND DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID
*/
Use WideWorldImporters
SET STATISTICS IO ON
SET STATISTICS TIME ON
GO
-- �������� � ����� ��������� ��������� ����
--2
Select ord.CustomerID, det.StockItemID, SUM(det.UnitPrice), SUM(det.Quantity), COUNT(ord.OrderID)
FROM Sales.Orders AS ord
	JOIN Sales.OrderLines AS det ON det.OrderID = ord.OrderID
	JOIN Sales.Invoices AS Inv ON Inv.OrderID = ord.OrderID
	JOIN Sales.CustomerTransactions AS Trans ON Trans.InvoiceID = Inv.InvoiceID
	JOIN Warehouse.StockItemTransactions AS ItemTrans ON ItemTrans.StockItemID = det.StockItemID
WHERE Inv.BillToCustomerID != ord.CustomerID
AND (Select SupplierId
	FROM Warehouse.StockItems AS It
	Where It.StockItemID = det.StockItemID) = 12
AND (SELECT SUM(Total.UnitPrice*Total.Quantity)
	FROM Sales.OrderLines AS Total
	Join Sales.Orders AS ordTotal
	On ordTotal.OrderID = Total.OrderID
	WHERE ordTotal.CustomerID = Inv.CustomerID) > 250000
AND DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID;

/*
������� ������� � �����, �� Inv.InvoiceDate � ord.OrderDate - ��� ������ date, �� datetime, �� ������ ������� � 0 ���� �� ���������

������� Inv.BillToCustomerID != ord.CustomerID ����� ��������� �� WHERE � ������� ����������� ������, �� ����� �� ��������, �� �������� �������� - ����� ������������ ����� � �������

���� ������ ������ Sales.CustomerTransactions � Warehouse.StockItemTransactions, �� ������� �� ���������� ������ � ��� �� ������������ ��� ����-����, ��� ���� ��-�� ���:
1. ��������� ������ ������ ���� "���� �� ������" ��-�� ���� ������������� ���������� �����, ����������� � ���������, ���� ������ �����������, �� ������ 7554 ����� �������� 7999258
2. �� ����� �������������� ���������� ������� ��������� �������� �� ��������� � ������ ����� �� ����������� - ���������� ������������ ����������
��� ���� � �������� ������� ��� ������ JOIN, �� ��������� � MSSQL ������������ INNER JOIN, ������� ���� ������ ������ ��� ��� ������ � ������� ����� ������� ������ � ��������� � ��������, ������� ��� 
� Sales.CustomerTransactions � Warehouse.StockItemTransactions � � ����������� ������� �� �� ����. ������� ������� �������� �� ������� �� ���

������ ��������� �������� ���������� �12 �� ������� �������, �������� �� ����� � ��������

����� ��� ������� �� ��������� ������� ������� �� 250� ������, �� ���, ����� ��� �������� ����� ���������� - �� ���������� (((
����� ���� ������ ����������, ������� "��� ������� ������������", ��������� ������� ������ ���������
*/


Select ord.CustomerID, det.StockItemID, SUM(det.UnitPrice), SUM(det.Quantity), COUNT(ord.OrderID)
FROM Sales.Orders AS ord
	JOIN Sales.OrderLines AS det ON det.OrderID = ord.OrderID
	JOIN Sales.Invoices AS Inv ON Inv.OrderID = ord.OrderID --AND Inv.BillToCustomerID != ord.CustomerID
	JOIN Sales.CustomerTransactions AS Trans ON Trans.InvoiceID = Inv.InvoiceID
	JOIN Warehouse.StockItems AS It on det.StockItemID = It.StockItemID AND it.SupplierID = 12
WHERE Inv.BillToCustomerID != ord.CustomerID
AND (SELECT SUM(Total.UnitPrice*Total.Quantity)
	FROM Sales.OrderLines AS Total
	Join Sales.Orders AS ordTotal
	On ordTotal.OrderID = Total.OrderID
	WHERE ordTotal.CustomerID = Inv.CustomerID) > 250000
AND Inv.InvoiceDate = ord.OrderDate
AND det.StockItemID in (SELECT StockItemID FROM Warehouse.StockItemTransactions)
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID;


/*
���������� �����������
����:
SQL Server Execution Times:
   CPU time = 625 ms,  elapsed time = 804 ms.

Table 'StockItemTransactions'. Scan count 1, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 29, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'StockItemTransactions'. Segment reads 1, segment skipped 0.
Table 'OrderLines'. Scan count 4, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 331, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'OrderLines'. Segment reads 2, segment skipped 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'CustomerTransactions'. Scan count 5, logical reads 261, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Orders'. Scan count 2, logical reads 883, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Invoices'. Scan count 1, logical reads 44525, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'StockItems'. Scan count 1, logical reads 2, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

�����:
SQL Server Execution Times:
   CPU time = 219 ms,  elapsed time = 355 ms.

Table 'OrderLines'. Scan count 4, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 331, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'OrderLines'. Segment reads 2, segment skipped 0.
Table 'StockItemTransactions'. Scan count 1, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 29, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'StockItemTransactions'. Segment reads 1, segment skipped 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'CustomerTransactions'. Scan count 5, logical reads 261, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Orders'. Scan count 1, logical reads 33036, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Invoices'. Scan count 1, logical reads 44525, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'StockItems'. Scan count 1, logical reads 2, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
*/