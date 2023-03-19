/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

--подзапрос
SELECT PersonID, FullName FROM WideWorldImporters.Application.People
WHERE IsSalesperson =1 
AND PersonID NOT IN 
(
SELECT SalespersonPersonID FROM WideWorldImporters.Sales.Invoices
WHERE InvoiceDate = '20150704'
);

--WITH
WITH sales as
(
SELECT * FROM WideWorldImporters.Sales.Invoices
WHERE InvoiceDate = '20150704'
)
SELECT PersonID, FullName FROM WideWorldImporters.Application.People
WHERE IsSalesperson =1 
AND PersonID NOT IN (Select SalespersonPersonID from sales);

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/
--подзапрос
--вариант 1
SELECT StockItemID, StockItemName, UnitPrice FROM WideWorldImporters.Warehouse.StockItems
WHERE UnitPrice = (SELECT min(UnitPrice) FROM WideWorldImporters.Warehouse.StockItems);

--вариант 2
SELECT StockItemID, StockItemName, UnitPrice FROM WideWorldImporters.Warehouse.StockItems
WHERE StockItemID = (SELECT TOP (1) StockItemID FROM WideWorldImporters.Warehouse.StockItems ORDER BY UnitPrice asc);

-- WITH
--вариант 1
WITH minprice as 
	(SELECT TOP (1) StockItemID FROM WideWorldImporters.Warehouse.StockItems ORDER BY UnitPrice asc)
SELECT StockItemID, StockItemName, UnitPrice FROM WideWorldImporters.Warehouse.StockItems
WHERE StockItemID = (SELECT  TOP (1) StockItemID FROM minprice);

--вариант 2
WITH prices as 
	(SELECT UnitPrice FROM WideWorldImporters.Warehouse.StockItems)
SELECT StockItemID, StockItemName, UnitPrice FROM WideWorldImporters.Warehouse.StockItems
WHERE UnitPrice = (SELECT min(UnitPrice) FROM prices);

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/
--подзапрос
--вариант 1
SELECT CustomerID, CustomerName, PhoneNumber FROM WideWorldImporters.Sales.Customers
WHERE CustomerID in
(SELECT TOP 5 CustomerID FROM WideWorldImporters.Sales.CustomerTransactions ORDER BY TransactionAmount DESC);

--вариант 2 , из-за JOIN получаем дубликаты
SELECT TOP 5 data1.CustomerID,data1.CustomerName,data1.PhoneNumber FROM
	(SELECT c.CustomerID, c.CustomerName, c.PhoneNumber, ct.TransactionAmount 
	FROM WideWorldImporters.Sales.CustomerTransactions ct
	LEFT JOIN WideWorldImporters.Sales.Customers c on ct.CustomerID = c.CustomerID) as data1
ORDER BY data1.TransactionAmount;

-- WITH
--вариант 1
WITH trans as
	(SELECT TOP 5 CustomerID FROM WideWorldImporters.Sales.CustomerTransactions ORDER BY TransactionAmount DESC)
SELECT CustomerID, CustomerName, PhoneNumber FROM WideWorldImporters.Sales.Customers 
WHERE CustomerID in (SELECT * FROM trans);
--вариант 2, из-за JOIN получаем дубликаты
WITH trans as
	(SELECT c.CustomerID, c.CustomerName, c.PhoneNumber, ct.TransactionAmount 
	FROM WideWorldImporters.Sales.CustomerTransactions ct
	LEFT JOIN WideWorldImporters.Sales.Customers c on ct.CustomerID = c.CustomerID)
SELECT TOP 5 CustomerID,CustomerName,PhoneNumber FROM trans ORDER BY TransactionAmount;

/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

-- товаров получилось 4, тк у 3 и 4 одинаковая стоимость
--подзапрос
SELECT DISTINCT
cit.CityID as 'ID города'
,cit.CityName as 'Название города'
,p.FullName as 'Упаковщик'
FROM WideWorldImporters.Sales.Orders o
LEFT JOIN WideWorldImporters.Sales.Customers cust on o.CustomerID = cust.CustomerID
LEFT JOIN WideWorldImporters.Sales.Invoices inv on o.OrderID = inv.OrderID
LEFT JOIN WideWorldImporters.Application.People p on inv.PackedByPersonID = p.PersonID
LEFT JOIN WideWorldImporters.Application.Cities cit on cust.DeliveryCityID = cit.CityID
WHERE o.OrderID in
(
	SELECT OrderID FROM WideWorldImporters.Sales.OrderLines
	WHERE UnitPrice in
	(
		SELECT TOP 3 UnitPrice FROM WideWorldImporters.Sales.OrderLines 
		GROUP BY UnitPrice
		ORDER BY UnitPrice DESC
	)
)
ORDER BY cit.CityID, p.FullName;

-- CTE
WITH topprices as 
(
SELECT TOP 3 UnitPrice FROM WideWorldImporters.Sales.OrderLines 
		GROUP BY UnitPrice
		ORDER BY UnitPrice DESC
)
SELECT DISTINCT
cit.CityID as 'ID города'
,cit.CityName as 'Название города'
,p.FullName as 'Упаковщик'
FROM WideWorldImporters.Sales.Orders o
LEFT JOIN WideWorldImporters.Sales.OrderLines ol on ol.OrderID = o.OrderID
LEFT JOIN WideWorldImporters.Sales.Customers cust on o.CustomerID = cust.CustomerID
LEFT JOIN WideWorldImporters.Sales.Invoices inv on o.OrderID = inv.OrderID
LEFT JOIN WideWorldImporters.Application.People p on inv.PackedByPersonID = p.PersonID
LEFT JOIN WideWorldImporters.Application.Cities cit on cust.DeliveryCityID = cit.CityID
WHERE ol.UnitPrice in (SELECT UnitPrice FROM topprices) 

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SET STATISTICS IO, TIME ON

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	--SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC;

--запрос отбирает инвойсы, и выводит данные о заказе(id, дата), сотруднике, который заключил сделку, сумму в инвойсе из присоединённой таблицы Invoice lines, с фильтром на сумму заказа сумма заказа более 27000, 
-- и общую стоимость собранного заказа подзапросом к таблице OrderLines от которой идёт подзапрос к таблице Orders с фильтром по дате окончания сборки заказа не равной NULL

-- вариант и ускорения и улучшения читаемости запроса - использование только JOIN и агрегирующих функций, отбор заказов далем через CTE и iiner join к этой таблице, прсто джойнами не получилось
WITH SelInvoices as
(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000
)
SELECT
inv.InvoiceID
,inv.InvoiceDate
,p.FullName AS SalesPersonName
,SelInvoices.TotalSumm as TotalSummByInvoice
,SUM(ol.PickedQuantity*ol.UnitPrice) as TotalSummForPickedItems
FROM WideWorldImporters.Sales.Invoices as inv
LEFT JOIN WideWorldImporters.Application.People as p on inv.SalespersonPersonID = p.PersonID
LEFT JOIN WideWorldImporters.Sales.OrderLines as ol on inv.OrderID = ol.OrderID
LEFT JOIN WideWorldImporters.Sales.Orders as o on inv.OrderID = o.OrderID AND o.PickingCompletedWhen IS NOT NULL
INNER JOIN SelInvoices on inv.InvoiceID = SelInvoices.InvoiceID
GROUP BY inv.InvoiceID, inv.InvoiceDate, p.FullName, SelInvoices.TotalSumm
ORDER BY TotalSummByInvoice DESC;

--группировку по TotalSumm пришлось добавлять тк иначе MS SQL Studio не даёт

/*
результаты улучшения быстродействия:
 уход от подзапросов нескольких уровней вложенности ускорил работу более чем в 62 раза

--- исходный вараинт
(8 rows affected)
Table 'OrderLines'. Scan count 16, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 508, lob physical reads 3, lob page server reads 0, lob read-ahead reads 790, lob page server read-ahead reads 0.
Table 'OrderLines'. Segment reads 1, segment skipped 0.
Table 'InvoiceLines'. Scan count 16, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 322, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'InvoiceLines'. Segment reads 1, segment skipped 0.
Table 'Orders'. Scan count 9, logical reads 725, physical reads 3, page server reads 0, read-ahead reads 667, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Invoices'. Scan count 9, logical reads 11652, physical reads 3, page server reads 0, read-ahead reads 11366, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'People'. Scan count 9, logical reads 28, physical reads 1, page server reads 0, read-ahead reads 2, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 422 ms,  elapsed time = 6295 ms.

--- доработанный вариант
(8 rows affected)
Table 'OrderLines'. Scan count 2, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 163, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'OrderLines'. Segment reads 1, segment skipped 0.
Table 'InvoiceLines'. Scan count 4, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 322, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'InvoiceLines'. Segment reads 2, segment skipped 0.
Table 'People'. Scan count 1, logical reads 11, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Invoices'. Scan count 0, logical reads 29, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 109 ms,  elapsed time = 106 ms.

Completion time: 2023-03-19T10:16:01.1462991+03:00

*/
