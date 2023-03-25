/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

SELECT * FROM
(SELECT 
InvoiceID
,substring(cust.CustomerName, charindex('(',cust.CustomerName)+1,charindex(')',cust.CustomerName)-charindex('(',cust.CustomerName)-1) as 'CustomerLocation'
,FORMAT(DATEFROMPARTS(YEAR(InvoiceDate),Month(InvoiceDate),1), 'dd.MM.yyyy') as 'InvoinceMonth'
FROM 
WideWorldImporters.Sales.Invoices as inv
LEFT JOIN WideWorldImporters.Sales.Customers cust on inv.CustomerID = cust.CustomerID
WHERE inv.CustomerID between 2 and 6
) as SalesData
PIVOT
(
count(InvoiceID)
FOR CustomerLocation IN ([Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Sylvanite, MT], [Jessie, ND])
)
as SalesPerMonth
ORDER BY year(InvoinceMonth), Month(InvoinceMonth)


/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

SELECT CustomerName, AdressLine 
FROM
(SELECT CustomerName
	,DeliveryAddressLine1
	,DeliveryAddressLine2
	,PostalAddressLine1
	,PostalAddressLine2
FROM WideWorldImporters.Sales.Customers) as p
UNPIVOT 
	(Adressline for AdressType 
	IN (DeliveryAddressLine1
	,DeliveryAddressLine2
	,PostalAddressLine1
	,PostalAddressLine2
	))as unpvt
WHERE CustomerName LIKE '%Tailspin Toys%'

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/
SELECT CountryId, CountryName, CountryCode 
FROM
(SELECT CountryId
		,CountryName
		,LettCode = convert(sql_variant,IsoAlpha3Code)
		,NumCode = convert(sql_variant,IsoNumericCode) 
	FROM WideWorldImporters.Application.Countries) as countries
UNPIVOT
(CountryCode for CodeType IN (LettCode,NumCode)) as unpvt

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

SELECT C.CustomerID, C.CustomerName, Orders.*
FROM WideWorldImporters.Sales.Customers C
OUTER APPLY (SELECT TOP 2 OL.StockItemID as ItemID, OL.UnitPrice as Price, O.OrderDate as OrderDate
                FROM WideWorldImporters.Sales.Orders O
				LEFT JOIN WideWorldImporters.Sales.OrderLines OL on O.OrderID = OL.OrderID
                WHERE O.CustomerID = C.CustomerID
                ORDER BY OL.UnitPrice DESC) AS Orders
ORDER BY C.CustomerName;
