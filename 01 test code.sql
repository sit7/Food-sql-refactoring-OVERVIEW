--Подробное тестирование на конкретном проблемном документе - должно быть объяснимое расхождение - собственно из-за которого и правим

 DECLARE @MenuId int, @DocumentID int
 SET @MenuId = 34648 -- проблемное ,меню с творогом на дс 50 к2 от 30 января

 SELECT * FROM [f_fooMenuByExpDocumentVersionSit7](@MenuId)  
 SELECT * FROM [f_fooMenuByExpDocumentVersion](@MenuId)
 SELECT @MenuId, * FROM [f_fooMenuByExpDocumentVersionSit7](@MenuId)  EXCEPT SELECT @MenuId, * FROM [f_fooMenuByExpDocumentVersion](@MenuId)

--Аналогичное тестирование на документах, проблемы с которыми выявлены уже в процессе рефактринга кода

 
  SELECT 33554, * FROM [f_fooMenuByExpDocumentVersionSit7](33554)  EXCEPT SELECT 33554, * FROM [f_fooMenuByExpDocumentVersion](33554)
	UNION ALL
  SELECT 34990, * FROM [f_fooMenuByExpDocumentVersionSit7](34990)  EXCEPT SELECT 34990, * FROM [f_fooMenuByExpDocumentVersion](34990)
	UNION ALL
  SELECT 34465, * FROM [f_fooMenuByExpDocumentVersionSit7](34465)  EXCEPT SELECT 34465, * FROM [f_fooMenuByExpDocumentVersion](34465)
	UNION ALL
  SELECT 34466, * FROM [f_fooMenuByExpDocumentVersionSit7](34466)  EXCEPT SELECT 34466, * FROM [f_fooMenuByExpDocumentVersion](34466)
	UNION ALL
  SELECT 34467, * FROM [f_fooMenuByExpDocumentVersionSit7](34467)  EXCEPT SELECT 34467, * FROM [f_fooMenuByExpDocumentVersion](34467)
	UNION ALL
  SELECT 34468, * FROM [f_fooMenuByExpDocumentVersionSit7](34468)  EXCEPT SELECT 34468, * FROM [f_fooMenuByExpDocumentVersion](34468)
	UNION ALL
  SELECT 33400, * FROM [f_fooMenuByExpDocumentVersionSit7](33400)  EXCEPT SELECT 33400, * FROM [f_fooMenuByExpDocumentVersion](33400)
  
 -- прогон по всем документам за период - тотальное тестирование на исторических данных 

Declare My_cursor CURSOR local  FOR 
Select MenuID From fooMenu where YEAR(MenuDate) =2020 AND MONTH(MenuDate)=1
Open My_cursor
Fetch next from My_cursor into @MenuId
while @@Fetch_STATUS=0
Begin
	SELECT @MenuId, * FROM [f_fooMenuByExpDocumentVersionSit7](@MenuId)  EXCEPT SELECT @MenuId, * FROM [f_fooMenuByExpDocumentVersion](@MenuId)

	Fetch next from My_cursor into @MenuId
end
  