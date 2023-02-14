/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/
USE WideWorldImporters;
SELECT StockItemID, StockItemName FROM Warehouse.StockItems
WHERE StockItemName like '%urgent%' or StockItemName like 'Animal%';

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

USE WideWorldImporters;
SELECT s.SupplierID, s.SupplierName 
FROM Purchasing.Suppliers s
LEFT JOIN Purchasing.PurchaseOrders po on s.SupplierID = po.SupplierID
WHERE po.PurchaseOrderID IS NULL;

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

USE WideWorldImporters;
SELECT o.OrderID as "№ заказа"
,FORMAT(o.OrderDate, 'dd.MM.yyyy') as "Дата"
,FORMAT(o.OrderDate, 'MMMM', 'Ru-RU') as "Месяц заказа"
,DATEPART(quarter, o.OrderDate) as "Квартал заказа"
,ceiling(DATEPART(month, o.OrderDate)/4.0) as "Треть года заказа"
,c.CustomerName

FROM Sales.Orders o
LEFT JOIN Sales.OrderLines ol on o.OrderID = ol.OrderID
LEFT JOIN Sales.Customers c on o.CustomerID = c.CustomerID
AND ol.PickingCompletedWhen IS NOT NULL
GROUP BY o.OrderID, o.OrderDate,c.CustomerName
HAVING (sum(ol.UnitPrice) > 100 or sum(ol.Quantity) > 20)
ORDER BY "Квартал заказа", "Треть года заказа", "Дата";

--вариант этого запроса с постраничной выборкой, пропустив первую 1000 и отобразив следующие 100 записей.
USE WideWorldImporters;
SELECT o.OrderID as "№ заказа"
,FORMAT(o.OrderDate, 'dd.MM.yyyy') as "Дата"
,FORMAT(o.OrderDate, 'MMMM', 'Ru-RU') as "Месяц заказа"
,DATEPART(quarter, o.OrderDate) as "Квартал заказа"
,ceiling(DATEPART(month, o.OrderDate)/4.0) as "Треть года заказа"
,c.CustomerName

FROM Sales.Orders o
LEFT JOIN Sales.OrderLines ol on o.OrderID = ol.OrderID
LEFT JOIN Sales.Customers c on o.CustomerID = c.CustomerID
AND ol.PickingCompletedWhen IS NOT NULL
GROUP BY o.OrderID, o.OrderDate,c.CustomerName
HAVING (sum(ol.UnitPrice) > 100 or sum(ol.Quantity) > 20)
ORDER BY "Квартал заказа", "Треть года заказа", "Дата"
OFFSET 1000 ROWS
 FETCH NEXT 100 ROWS ONLY;  


/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

USE WideWorldImporters;
SELECT 
dm.DeliveryMethodName as "Способ доставки"
,po.ExpectedDeliveryDate as "Дата доставки план."
,s.SupplierName as "Поставщик"
,p.FullName as "Принимает заказ"
,*
FROM Purchasing.PurchaseOrders po
LEFT JOIN Purchasing.Suppliers s on po.SupplierID = s.SupplierID
LEFT JOIN Application.DeliveryMethods dm on po.DeliveryMethodID = dm.DeliveryMethodID
LEFT JOIN Application.People p on po.ContactPersonID = p.PersonID
WHERE dm.DeliveryMethodName in ('Air Freight', 'Refrigerated Air Freight')
AND po.IsOrderFinalized = 1
AND po.ExpectedDeliveryDate between '20130101' and '20130201'


/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

USE WideWorldImporters;
SELECT top (10) 
c.CustomerName as 'Client'
,p.FullName 
FROM Sales.Orders s
LEFT JOIN Sales.Customers c on s.CustomerID = c.CustomerID
LEFT JOIN Application.People p on s.SalespersonPersonID = p.PersonID
Order by s.OrderDate DESC;
/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

USE WideWorldImporters;
SELECT 
c.CustomerID as "id"
,c.CustomerName
,c.PhoneNumber
FROM Sales.Orders o
LEFT JOIN Sales.Customers c on o.CustomerID = c.CustomerID
LEFT JOIN Sales.OrderLines ol on ol.OrderID = o.OrderID
LEFT JOIN Warehouse.StockItems si on ol.StockItemID = si.StockItemID
WHERE si.StockItemName = 'Chocolate frogs 250g';
