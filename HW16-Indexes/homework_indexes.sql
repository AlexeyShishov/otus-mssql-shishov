/*

Думаем какие запросы у вас будут в базе и добавляем для них индексы. Проверяем, что они используются в запросе. 

*/

-- Сначала нужно выполнить запросы из Create_DB.sql , это файл для создания БД к проекту, индексы создаются в основном скрипте

-- для отображения плана в текстовом виде
--SET STATISTICS PROFILE ON
--GO
--Тестовые запросы, можно прогонять и на пустой БД, без данных

USE AShishov_project
GO
SELECT top (10) * FROM Clients.Clients WHERE ShortName = 'Иванов А.А.'
SELECT top (10) * FROM MainData.Operations
SELECT top (10) * FROM RefBooks.Tariffs

-- выключить настройки из начала скрипта
--SET STATISTICS PROFILE OFF
--GO
