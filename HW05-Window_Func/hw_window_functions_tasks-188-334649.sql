/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
-- ---------------------------------------------------------------------------

USE WideWorldImporters
/*
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/
set statistics time, io on
SELECT
inv.OrderID as 'id продажи'
,c.CustomerName as 'название клиента'
,inv.InvoiceDate as 'дата продажи'
,SUM(ol.UnitPrice * ol.Quantity) as 'сумма продажи'
,(SELECT SUM(ol2.UnitPrice * ol2.Quantity) 
	FROM Sales.Invoices as inv2 
	LEFT JOIN [WideWorldImporters].[Sales].[OrderLines] ol2 on inv2.OrderID = ol2.OrderID
	WHERE inv2.InvoiceDate >= '20150101' AND inv2.InvoiceDate <= EOMONTH(inv.InvoiceDate)) as 'нар итог по пред месяцам'
FROM Sales.Invoices as inv
LEFT JOIN [WideWorldImporters].[Sales].[OrderLines] ol on inv.OrderID = ol.OrderID
LEFT JOIN [WideWorldImporters].[Sales].[Customers] c on inv.CustomerID = c.CustomerID
WHERE inv.InvoiceDate >= '20150101'
GROUP BY inv.OrderID, c.CustomerName, inv.InvoiceDate
ORDER BY inv.InvoiceDate

/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/
SELECT distinct * FROM
(
SELECT
inv.OrderID as 'id продажи'
,c.CustomerName as 'название клиента'
,inv.InvoiceDate as 'дата продажи'
,SUM(ol.UnitPrice * ol.Quantity) OVER(partition by inv.OrderID) as 'сумма продажи'
,SUM(ol.UnitPrice * ol.Quantity) OVER (ORDER BY YEAR(inv.Invoicedate), MONTH(inv.Invoicedate)) as 'нар итог по пред месяцам'
FROM Sales.Invoices as inv
LEFT JOIN [WideWorldImporters].[Sales].[OrderLines] ol on inv.OrderID = ol.OrderID
LEFT JOIN [WideWorldImporters].[Sales].[Customers] c on inv.CustomerID = c.CustomerID
WHERE inv.InvoiceDate >= '20150101'
)as req1 
ORDER BY 3

/*
2 запроса выполнены c set statistics time, io on
(31440 rows affected)
Table 'OrderLines'. Scan count 888, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 326, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'OrderLines'. Segment reads 444, segment skipped 0.
Table 'Worktable'. Scan count 443, logical reads 164589, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Workfile'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Invoices'. Scan count 2, logical reads 22800, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Customers'. Scan count 1, logical reads 40, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 52265 ms,  elapsed time = 52400 ms.

(31440 rows affected)
Table 'OrderLines'. Scan count 2, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 163, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'OrderLines'. Segment reads 1, segment skipped 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Invoices'. Scan count 1, logical reads 11400, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Customers'. Scan count 1, logical reads 40, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 282 ms,  elapsed time = 804 ms.

Запрос с оконными функциями выполенен менее чем за секунду вместо 52

Completion time: 2023-03-02T20:42:46.4778463+03:00

*/

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/
SELECT 
MonthNum
,ItemName
,SumPerMonth
FROM
(
	SELECT
	dat1.MonthNum
	,dat1.SumPerMonth
	,dat1.ItemName
	,RANK() OVER (partition by MonthNum Order by SumPerMonth DESC) as SalesRank
	FROM
		(
		SELECT DISTINCT
		MONTH(inv.Invoicedate) as MonthNum
		,DATENAME(month, DATEADD(month, MONTH(inv.Invoicedate)-1, CAST('2008-01-01' AS datetime)))  as MonthName1
		,SUM(ol.Quantity) OVER(partition by ol.StockItemID ORDER BY MONTH(inv.Invoicedate)) as SumPerMonth
		,si.StockItemName as ItemName
		FROM Sales.Invoices as inv
		LEFT JOIN [WideWorldImporters].[Sales].[OrderLines] ol on inv.OrderID = ol.OrderID
		LEFT JOIN [WideWorldImporters].Warehouse.StockItems si on ol.StockItemID = si.StockItemID
		WHERE inv.InvoiceDate BETWEEN '20160101' AND '20161231'
		) 
	as dat1
)as dat2
WHERE SalesRank < 3
ORDER BY MonthNum, SalesRank

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

SELECT 
StockItemID as 'ID'
,StockItemName as 'Название'
,ISNULL(Brand, 'no brand') as 'Брэнд'
,UnitPrice as 'Цена за шт'
,ROW_NUMBER() OVER (Partition BY LEFT(StockItemName,1) Order by StockItemName) as 'Нумерация по первому символу'
,COUNT(StockItemID) OVER() as 'Общее кол-во'
,COUNT(StockItemID) OVER(Partition BY LEFT(StockItemName,1)) as 'Кол-во по первому символу'
,ISNULL(CAST(LEAD(StockItemID) OVER (order by StockItemName) AS CHAR),'No item') as 'ID следующего по имени'
,ISNULL(CAST(LAG(StockItemID) OVER (order by StockItemName) AS CHAR),'No item') as 'ID предыдущего по имени'
,ROW_NUMBER() OVER (order by StockItemName) as 'Rownum'
,ISNULL(LAG (StockItemName,2) OVER (ORDER by StockItemName),'No item') as 'Название товара на две строки выше' --надеюсь тут сортировка, как и ранее, по имени товара
,NTILE(30) OVER (PARTITION BY TypicalWeightPerUnit ORDER BY TypicalWeightPerUnit) 'Номер в группе по весу'
FROM [WideWorldImporters].Warehouse.StockItems
ORDER BY 2

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/
SELECT
SalespersonPersonID as 'ID продавца'
,FullName as 'Продавец'
,CustomerID as 'ID покупателя'
,CustomerName as 'Покупатель'
,InvoiceDate as 'Дата сделки'
,OrderCost as 'Стоимость заказа'
FROM
(
	SELECT
	inv.SalespersonPersonID
	,p.FullName
	,inv.CustomerID
	,c.CustomerName
	,inv.InvoiceDate
	,SUM(ol.Quantity * ol.UnitPrice) OVER (Partition by ol.orderID) as OrderCost
	,RANK() OVER (partition by inv.SalespersonPersonID order by inv.InvoiceDate DESC, inv.orderid DESC) as OrderRank
	FROM [WideWorldImporters].Sales.Invoices inv
	LEFT JOIN [WideWorldImporters].[Sales].[OrderLines] ol on inv.OrderID = ol.OrderID
	LEFT JOIN [WideWorldImporters].Sales.customers c on inv.CustomerID = c.CustomerID
	LEFT JOIN [WideWorldImporters].Application.People p on inv.SalespersonPersonID = p.PersonID
) as req
WHERE OrderRank = 1
/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

SELECT 
CustomerID as 'ID покупателя'
,CustomerName as 'Покупатель'
,InvoiceDate as 'Дата сделки'
,StockItemID as 'ID товара'
FROM
(
	SELECT
	inv.CustomerID
	,c.CustomerName
	,inv.InvoiceDate
	,ol.StockItemID
	,ol.UnitPrice
	,DENSE_RANK() OVER (partition by inv.CustomerID order by ol.UnitPrice DESC) as PriceRank
	FROM [WideWorldImporters].Sales.Invoices inv
	LEFT JOIN [WideWorldImporters].[Sales].[OrderLines] ol on inv.OrderID = ol.OrderID
	LEFT JOIN [WideWorldImporters].Sales.customers c on inv.CustomerID = c.CustomerID
) as req
WHERE PriceRank < 2

--Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность. 