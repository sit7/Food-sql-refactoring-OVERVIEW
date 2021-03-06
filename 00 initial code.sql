USE [FoodDB]
GO
/****** Object:  UserDefinedFunction [dbo].[f_fooMenuByExpDocumentVersion]    Script Date: 28.04.2021 15:54:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER FUNCTION [dbo].[f_fooMenuByExpDocumentVersion](@Menuid int)

RETURNS 
@MenuByExpDocument TABLE 
(
FoodID int,Name varchar(100),NomenclatureID int,UnitMeasure varchar(50),EatingTime varchar(50),EatingTimeID int,MenuID int,MenuDate datetime,ObjectID int,[Object] varchar(50),UltraShortName  varchar(50), EatingCategoryID int,EatingCategory varchar(50),
PortionCount int,PortionCountFact int,ControlPortionCount int,Recipe varchar(100),OriginalRecipe varchar(100),RecipeID int,Netto decimal (18,5),BruttoByRecalcPlan decimal (18,5),BruttoByRecalcDop decimal (18,5),FoodPercent decimal (18,5),LossPercent decimal (18,5),
BruttoByRecalcFact decimal (18,5),Brutto decimal (18,5),FoodLoss decimal (18,5),Price decimal (18,5),
PersonPortionCount int,NettoRecipe decimal (18,5),PortionCount24 int,ParentMenuCategoryTimeRecipeID int,MenuCategoryTimeRecipeID int,IsHeat int,OrderNumber int,MenuCorrectionTypeID int,IsVisible int,
DocFoodID int,EggMeasureUnit decimal (18,5),MenuAmount decimal (18,5), MenuAmountEatingCategory decimal (18,5), MenuAmountDopEatingCategory decimal (18,5), ExpAmount decimal (18,5),ExpAmountDop decimal (18,5),mainEatingCategoryID int,mainEatingCategoryDopID int,DocLossPercent decimal (18,5), RecipeLoss decimal (18,5), 
KoefToNorm decimal (18,5),OrderNumberEatingCategory int,OrderNumberEatingTime int, MeasureUnitString varchar(100), BoilLoss decimal (18,5),IsAlone int, OrderForExp int, Food1C varchar(50), EatingCategory1C varchar(50), RoundTo decimal (3,1), PersonAmount decimal (18,5), IsMain int

)
AS
BEGIN
	if (select ObjectID from foomenu where Menuid = @Menuid)=232 or (select ObjectID from foomenu where Menuid = @Menuid)=93
	insert into @MenuByExpDocument
	SELECT FoodID,t.Name,NomenclatureID,UnitMeasure,EatingTime,EatingTimeID,MenuID,MenuDate,ObjectID,[Object],UltraShortName,
t.EatingCategoryID,t.EatingCategory,PortionCount,PortionCountFact,ControlPortionCount,Recipe,OriginalRecipe,RecipeID,Netto,BruttoByRecalcPlan,BruttoByRecalcDop,
FoodPercent,LossPercent,BruttoByRecalcFact,Brutto,FoodLoss,Price,PersonPortionCount,NettoRecipe,PortionCount24,
ParentMenuCategoryTimeRecipeID,MenuCategoryTimeRecipeID,IsHeat,OrderNumber,MenuCorrectionTypeID,IsVisible,DocFoodID,EggMeasureUnit,
round(sum(round(BruttoByRecalcPlan*PortionCount,3)) over (partition by MenuID, FoodID, LossPercent, EatingCategory ORDER BY t.OrderForExp /*ROWS UNBOUNDED PRECEDING*/)/EggMeasureUnit,3) as MenuAmount,
round(sum(round(BruttoByRecalcPlan*PortionCount,3)) over (partition by MenuID, FoodID, LossPercent, EatingCategory ORDER BY t.OrderForExp /*ROWS UNBOUNDED PRECEDING*/)/EggMeasureUnit,3) as MenuAmountEatingCategory, 
round(sum(round(BruttoByRecalcDop*(PortionCountFact-PortionCount),3)) over (partition by MenuID, FoodID, LossPercent, EatingCategory ORDER BY t.OrderForExp /*ROWS UNBOUNDED PRECEDING*/)/EggMeasureUnit,3) as MenuAmountDopEatingCategory,ExpAmount,ExpAmountDop,
sum(MainEatingCategory) over (partition by FoodID) as mainEatingCategoryID,sum(MainEatingCategoryDop) over (partition by FoodID) as mainEatingCategoryDopID,DocLossPercent, RecipeLoss, KoefToNorm,OrderNumberEatingCategory,OrderNumberEatingCategory as OrderNumberEatingTime, MeasureUnitString, BoilLoss as BoilLoss,case when count(FoodID) over (partition by MenuCategoryTimeRecipeID) =1 then 1 else 0 end as IsAlone, OrderForExp, t.Food1C, t.EatingCategory1C, RoundTo,
round(sum(round(BruttoByRecalcPlan*PersonPortionCount,3)) over (partition by MenuID, FoodID, LossPercent, EatingCategory ORDER BY t.OrderForExp /*ROWS UNBOUNDED PRECEDING*/)/EggMeasureUnit,3) as PersonAmount, IsMain
from
(SELECT        DocDetail.FoodID, DocDetail.Name, v_fooMenu.NomenclatureID, v_fooMenu.UnitMeasure, v_fooMenu.EatingTime, v_fooMenu.EatingTimeID, v_fooMenu.MenuID, v_fooMenu.MenuDate, v_fooMenu.ObjectID, v_fooMenu.[Object], v_fooMenu.UltraShortName, v_fooMenu.EatingCategoryID,v_fooMenu.EatingCategory, 
    v_fooMenu.PortionCount, v_fooMenu.PortionCountFact,v_fooMenu.ControlPortionCount, v_fooMenu.Recipe, v_fooMenu.OriginalRecipe,  v_fooMenu.RecipeID ,  
	v_fooMenu.Netto, RecipeLossOriginal as RecipeLoss,BoilLoss,PortionCount24,AllPortionCount,
/*		case ROW_NUMBER() over (partition by DocDetail.FoodID, v_fooMenu.MenuID,OrderForExp,  isnull(SkyRecipeLoss,1)*DocDetail.LossPercent, DocDetail.FoodPercent order by OrderForExp asc, BruttoSkyFood/(1-DocDetail.LossPercent/100.00) asc,OrderNumber desc, DocDetail.FoodPercent) = count(BruttoSkyFood/(1-DocDetail.LossPercent/100.00)) over (partition by DocDetail.FoodID, v_fooMenu.MenuID,OrderForExp,  isnull(SkyRecipeLoss,1)*DocDetail.LossPercent, DocDetail.FoodPercent) then 
   (isnull(DocDetail.Amount,0)-sum(DocDetail.FoodPercent*BruttoSkyFood/(1-DocDetail.LossPercent/100.00)*AllPortionCount) over (partition by DocDetail.FoodID,v_fooMenu.MenuID,  isnull(SkyRecipeLoss,1)*DocDetail.LossPercent, DocDetail.FoodPercent order by OrderForExp asc, BruttoSkyFood/(1-DocDetail.LossPercent/100.00) asc, OrderNumber desc, DocDetail.FoodPercent ROWS UNBOUNDED PRECEDING))/AllPortionCount+BruttoSkyFood/(1-DocDetail.LossPercent/100.00)*DocDetail.FoodPercent
   else BruttoSkyFood/(1-DocDetail.LossPercent/100.00)*DocDetail.FoodPercent  end as BruttoByRecalcPlan*/
	case when ROW_NUMBER() over (partition by DocDetail.FoodID, v_fooMenu.MenuID,  isnull(SkyRecipeLoss,1)*DocDetail.LossPercent, DocDetail.FoodPercent order by BruttoSkyFood/(1-DocDetail.LossPercent/100.00)*AllPortionCount desc, OrderForExp desc, OrderNumber desc, DocDetail.FoodPercent desc, MenuCategoryTimeRecipeID) = 1 then 
   (isnull(DocDetail.Amount,0)-sum(DocDetail.FoodPercent*BruttoSkyFood/(1-DocDetail.LossPercent/100.00)*AllPortionCount) over (partition by DocDetail.FoodID,v_fooMenu.MenuID,  isnull(SkyRecipeLoss,1)*DocDetail.LossPercent, DocDetail.FoodPercent /*order by BruttoSkyFood/(1-DocDetail.LossPercent/100.00)*AllPortionCount asc, OrderForExp asc, OrderNumber desc ROWS UNBOUNDED PRECEDING*/))/AllPortionCount+BruttoSkyFood/(1-DocDetail.LossPercent/100.00)*DocDetail.FoodPercent
   else BruttoSkyFood/(1-DocDetail.LossPercent/100.00)*DocDetail.FoodPercent  end as BruttoByRecalcPlan,DocDetail.FoodPercent, isnull(SkyRecipeLoss,1)*DocDetail.LossPercent as LossPercent,DocDetail.LossPercent as DocLossPercent,
0	as BruttoByRecalcFact,
case when DocDetailDop.FoodID = DocDetail.FoodID then 
case when MenuCorrectionTypeID = 1  and (AllPortionCountFact-AllPortionCount) <> 0 then 
	case when OrderForExp = max(OrderForExp) over (partition by v_fooMenu.FoodID, v_fooMenu.MenuID, DocDetail.FoodPercent) and ROW_NUMBER() over (partition by v_fooMenu.FoodID, v_fooMenu.MenuID,OrderForExp,  isnull(SkyRecipeLoss,1)*DocDetail.LossPercent, DocDetail.FoodPercent, MenuCorrectionTypeID order by OrderForExp asc, BruttoSkyFood/(1-DocDetail.LossPercent/100.00) asc,OrderNumber desc, DocDetail.FoodPercent) = count(BruttoSkyFood/(1-DocDetail.LossPercent/100.00)) over (partition by v_fooMenu.FoodID, v_fooMenu.MenuID,OrderForExp,  isnull(SkyRecipeLoss,1)*DocDetail.LossPercent, DocDetail.FoodPercent, MenuCorrectionTypeID) 
	then (isnull(DocDetailDop.Amount,0)-sum(DocDetail.FoodPercent*BruttoSkyFood/(1-DocDetail.LossPercent/100.00)*(AllPortionCountFact-AllPortionCount)) over (partition by v_fooMenu.FoodID,v_fooMenu.MenuID,  isnull(SkyRecipeLoss,1)*DocDetail.LossPercent, DocDetail.FoodPercent, MenuCorrectionTypeID order by OrderForExp asc, BruttoSkyFood/(1-DocDetail.LossPercent/100.00) asc, OrderNumber desc, DocDetail.FoodPercent ROWS UNBOUNDED PRECEDING))/(AllPortionCountFact-AllPortionCount)+BruttoSkyFood/(1-DocDetail.LossPercent/100.00)*DocDetail.FoodPercent
	else BruttoSkyFood/(1-DocDetail.LossPercent/100.00)*DocDetail.FoodPercent  end 
else 0 end else 0 end as BruttoByRecalcDop,
OrderNumberEatingCategory,
	v_fooMenu.Brutto, v_fooMenu.FoodLoss, DocDetail.Price as Price, KoefToNorm, MenuNumber, SignDate,
	v_fooMenu.PersonPortionCount, v_fooMenu.NettoRecipe, v_fooMenu.ParentMenuCategoryTimeRecipeID, v_fooMenu.MenuCategoryTimeRecipeID, v_fooMenu.IsHeat, v_fooMenu.OrderNumber,v_fooMenu.MenuCorrectionTypeID, IsVisible, DocDetail.FoodID as DocFoodID, DocDetail.EggMeasureUnit,
	case when DocDetail.FoodID = 189 then round(isnull(DocDetail.Amount,0)/DocDetail.EggMeasureUnit,0) else isnull(DocDetail.Amount,0)/DocDetail.EggMeasureUnit end as ExpAmount, 
	case when DocDetailDop.FoodID = DocDetail.FoodID then case when DocDetailDop.FoodID = 189 then round(isnull(DocDetailDop.Amount,0)/DocDetail.EggMeasureUnit,0)  else isnull(DocDetailDop.Amount,0)/DocDetail.EggMeasureUnit end else 0 end as ExpAmountDop, 
	v_fooMenu.RoundTo, OrderForExp, case when ROW_NUMBER() over (partition by DocDetail.FoodID order by BruttoSkyFood*PortionCount desc) = 1 then EatingCategoryID else 0 end as MainEatingCategory,
	case when MenuCorrectionTypeID = 1 then case when ROW_NUMBER() over (partition by v_fooMenu.FoodID, MenuCorrectionTypeID order by BruttoSkyFood*PortionCount desc) = 1 then EatingCategoryID else 0 end else 0 end as MainEatingCategoryDop, isnull(MU.MeasureUnitString,'') as MeasureUnitString, DocDetail.Food1C, EatingCategory1C, DocDetail.IsMain
FROM            v_fooMenu
left join  
(select fooIncDocDetail.FoodID, fooIncDocDetail.FoodName as Name, foofood.NomenclatureID, case  fooIncDocDetail.FoodID when 189 then 
(sum(fooIncDocDetail.Price*(1+isnull(fooIncDocDetail.VATRate/100,0))*fooExpDocDetail.Amount)/sum(fooexpdocdetail.amount))
else 
(sum(fooIncDocDetail.Price*(1+isnull(fooIncDocDetail.VATRate/100,0))*fooExpDocDetail.Amount)/sum(fooexpdocdetail.amount*fooIncDocDetail.MeasureUnit)) end as Price, sum(fooExpDocDetail.Amount*fooIncDocDetail.MeasureUnit*fooUnitMeasureKoef.Koef) as Amount, fooDocument.DocDate, fooDocument.ObjectID, sum(fooExpDocDetail.Amount*fooIncDocDetail.MeasureUnit)/sum(sum(fooExpDocDetail.Amount*fooIncDocDetail.MeasureUnit)) over (partition by fooDocument.DocDate, fooDocument.ObjectID, fooFood.NomenclatureID) as FoodPercent, case when fooIncDocDetail.FoodID in (192,66,308) then case fooIncDocDetail.LossPercent when 0 then fooFoodLoss.PercentValue else fooIncDocDetail.LossPercent end else fooIncDocDetail.LossPercent end as LossPercent,
(case when fooIncDocDetail.FoodID = 189 then sum(fooIncDocDetail.MeasureUnit*fooExpDocDetail.Amount)/sum(fooExpDocDetail.Amount) else 1 end) as EggMeasureUnit, '' as MeasureUnitString, foofood.Code1C as Food1C, fooObjectPerson.IsMain
from fooDocument 
inner join fooExpDocDetail on fooDocument.DocumentID = fooExpDocDetail.DocumentID
inner join fooIncDocDetail on fooExpDocDetail.IncDocDetailID = fooIncDocDetail.IncDocDetailID
inner join fooDocument IncDocument on fooIncDocDetail.DocumentID = IncDocument.DocumentID
inner join fooObjectPerson on IncDocument.ObjectPersonID = fooObjectPerson.ObjectPersonID
inner join fooMenu on fooDocument.DocDate = fooMenu.MenuDate and fooDocument.ObjectID = fooMenu.ObjectID and fooMenu.MenuID = @MenuID
inner join foofood on foofood.FoodID = fooIncDocDetail.FoodID
left join fooFoodLoss on fooFood.FoodID = fooFoodLoss.FoodID and isnull(fooFoodLoss.MonthID, Month(MenuDate))=Month(MenuDate)
inner join fooUnitMeasure as fooUnitMeasureInc on  fooIncDocDetail.UnitMeasureID = fooUnitMeasureInc.UnitMeasureID
inner join fooUnitMeasure as fooUnitMeasureFood on  foofood.UnitMeasureID = fooUnitMeasureFood.UnitMeasureID
inner join fooUnitMeasureKoef on fooUnitMeasureInc.UnitMeasureID = fooUnitMeasureKoef.UnitMeasureIDInc and fooUnitMeasureFood.UnitMeasureID = fooUnitMeasureKoef.UnitMeasureIDMenu
where fooDocument.DocumentTypeID=3   and fooDocument.RecordStatusID=1 and fooExpDocDetail.RecordStatusID=1 and fooIncDocDetail.RecordStatusID=1 and fooExpDocDetail.Amount <> 0
group by fooIncDocDetail.FoodID, fooIncDocDetail.FoodName, foofood.NomenclatureID, fooDocument.DocDate, fooDocument.ObjectID, case when fooIncDocDetail.FoodID in (192,66,308) then case fooIncDocDetail.LossPercent when 0 then fooFoodLoss.PercentValue else fooIncDocDetail.LossPercent end else fooIncDocDetail.LossPercent end, fooFood.Code1c, fooObjectPerson.IsMain) DocDetail on DocDetail.NomenclatureID = v_fooMenu.NomenclatureID and DocDetail.DocDate = v_fooMenu.MenuDate and DocDetail.ObjectID = v_fooMenu.ObjectID
left join (select FoodID, ' ('+[dbo].[BeautyStr](sum(Amount1))+ ' по '+ ltrim(Str(sum(MeasureUnit1),7,3))+
case when sum(Amount2) <> 0 then ', '+ [dbo].[BeautyStr](sum(Amount2))+ ' по '+ ltrim(Str(sum(MeasureUnit2),7,3)) else '' end+
case when sum(Amount3) <> 0 then ', '+ [dbo].[BeautyStr](sum(Amount3))+ ' по '+ ltrim(Str(sum(MeasureUnit3),7,3)) else '' end+
case when sum(Amount4) <> 0 then ', '+ [dbo].[BeautyStr](sum(Amount4))+ ' по '+ ltrim(Str(sum(MeasureUnit4),7,3)) else '' end+
case when sum(Amount5) <> 0 then ', '+ [dbo].[BeautyStr](sum(Amount5))+ ' по '+ ltrim(Str(sum(MeasureUnit5),7,3)) else '' end +')' as MeasureUnitString
from 
(select Foodid,IsUndividedPack,
case when ROW_NUMBER() over (partition by FoodID order by MeasureUnit,IsUndividedPack)=1 then Amount  else 0 end as Amount1,
case when ROW_NUMBER() over (partition by FoodID order by MeasureUnit,IsUndividedPack)=1 then MeasureUnit  else 0 end as MeasureUnit1,
case when ROW_NUMBER() over (partition by FoodID order by MeasureUnit,IsUndividedPack)=2 then Amount  else 0 end as Amount2,
case when ROW_NUMBER() over (partition by FoodID order by MeasureUnit,IsUndividedPack)=2 then MeasureUnit  else 0 end as MeasureUnit2,
case when ROW_NUMBER() over (partition by FoodID order by MeasureUnit,IsUndividedPack)=3 then Amount  else 0 end as Amount3,
case when ROW_NUMBER() over (partition by FoodID order by MeasureUnit,IsUndividedPack)=3 then MeasureUnit  else 0 end as MeasureUnit3,
case when ROW_NUMBER() over (partition by FoodID order by MeasureUnit,IsUndividedPack)=4 then Amount  else 0 end as Amount4,
case when ROW_NUMBER() over (partition by FoodID order by MeasureUnit,IsUndividedPack)=4 then MeasureUnit  else 0 end as MeasureUnit4,
case when ROW_NUMBER() over (partition by FoodID order by MeasureUnit,IsUndividedPack)=5 then Amount  else 0 end as Amount5,
case when ROW_NUMBER() over (partition by FoodID order by MeasureUnit,IsUndividedPack)=5 then MeasureUnit  else 0 end as MeasureUnit5
from 
( select fooIncDocDetail.Foodid, 
sum(fooExpDocDetail.Amount)  as Amount,
(fooIncDocDetail.MeasureUnit) as MeasureUnit,sum(isnull(fooIncDocDetail.IsUndividedPack,0)) as IsUndividedPack
from
fooDocument 
inner join fooExpDocDetail on fooDocument.DocumentID = fooExpDocDetail.DocumentID
inner join fooIncDocDetail on fooExpDocDetail.IncDocDetailID = fooIncDocDetail.IncDocDetailID
inner join fooMenu on fooDocument.DocDate = fooMenu.MenuDate and fooDocument.ObjectID = fooMenu.ObjectID and fooMenu.MenuID = @MenuID
where fooDocument.DocumentTypeID=3   and fooDocument.RecordStatusID=1 and fooExpDocDetail.RecordStatusID=1 and fooIncDocDetail.RecordStatusID=1 and fooExpDocDetail.Amount <> 0
group by FoodID, MeasureUnit
)MU1)MU2
group by FoodID
having sum(IsUndividedPack) <> 0) as MU on DocDetail.FoodID = MU.FoodID
left join  
(select fooIncDocDetail.FoodID, sum(fooIncDocDetail.Price/fooIncDocDetail.Amount*fooExpDocDetail.Amount)/sum(fooExpDocDetail.Amount*fooIncDocDetail.MeasureUnit) as Price, sum(fooExpDocDetail.Amount*fooIncDocDetail.MeasureUnit*fooUnitMeasureKoef.Koef) as Amount, fooDocument.DocDate, fooDocument.ObjectID, sum(fooExpDocDetail.Amount*fooIncDocDetail.MeasureUnit)/sum(sum(fooExpDocDetail.Amount*fooIncDocDetail.MeasureUnit)) over (partition by fooDocument.DocDate, fooDocument.ObjectID, fooIncDocDetail.FoodID) as FoodPercent, case when fooIncDocDetail.FoodID in (192,66,308) then case fooIncDocDetail.LossPercent when 0 then fooFoodLoss.PercentValue else fooIncDocDetail.LossPercent end else fooIncDocDetail.LossPercent end as LossPercent,
(case when fooIncDocDetail.FoodID = 189 then sum(fooIncDocDetail.MeasureUnit*fooExpDocDetail.Amount)/sum(fooExpDocDetail.Amount) else 1 end) as EggMeasureUnit, '' as MeasureUnitString
from fooDocument 
inner join fooExpDocDetail on fooDocument.DocumentID = fooExpDocDetail.DocumentID
inner join fooIncDocDetail on fooExpDocDetail.IncDocDetailID = fooIncDocDetail.IncDocDetailID
inner join fooMenu on fooDocument.DocDate = fooMenu.MenuDate and fooDocument.ObjectID = fooMenu.ObjectID and fooMenu.MenuID = @MenuID
inner join foofood on foofood.FoodID = fooIncDocDetail.FoodID
left join fooFoodLoss on fooFood.FoodID = fooFoodLoss.FoodID and isnull(fooFoodLoss.MonthID, Month(MenuDate))=Month(MenuDate)
inner join fooUnitMeasure as fooUnitMeasureInc on  fooIncDocDetail.UnitMeasureID = fooUnitMeasureInc.UnitMeasureID
inner join fooUnitMeasure as fooUnitMeasureFood on  foofood.UnitMeasureID = fooUnitMeasureFood.UnitMeasureID
inner join fooUnitMeasureKoef on fooUnitMeasureInc.UnitMeasureID = fooUnitMeasureKoef.UnitMeasureIDInc and fooUnitMeasureFood.UnitMeasureID = fooUnitMeasureKoef.UnitMeasureIDMenu
where fooDocument.DocumentTypeID=7   and fooDocument.RecordStatusID=1 and fooExpDocDetail.RecordStatusID=1 and fooIncDocDetail.RecordStatusID=1 and fooExpDocDetail.Amount <> 0
group by fooIncDocDetail.FoodID, fooDocument.DocDate, fooDocument.ObjectID, case when fooIncDocDetail.FoodID in (192,66,308) then case fooIncDocDetail.LossPercent when 0 then fooFoodLoss.PercentValue else fooIncDocDetail.LossPercent end else fooIncDocDetail.LossPercent end) DocDetailDop on DocDetailDop.FoodID = v_fooMenu.FoodID and DocDetailDop.DocDate = v_fooMenu.MenuDate and DocDetailDop.ObjectID = v_fooMenu.ObjectID
where NettoRecipe <>0 and (PortionCount+PersonPortionCount) <> 0 and v_fooMenu.IsFromStorage = 1 and v_fooMenu.MenuID = @MenuID and v_fooMenu.EatingCategoryID not in (12,13)) as t

	else
	insert into @MenuByExpDocument
	SELECT FoodID,t.Name,NomenclatureID,UnitMeasure,EatingTime,EatingTimeID,MenuID,MenuDate,ObjectID,[Object],UltraShortName,
t.EatingCategoryID,t.EatingCategory,PortionCount,PortionCountFact,ControlPortionCount,Recipe,OriginalRecipe,RecipeID,Netto,BruttoByRecalcPlan,BruttoByRecalcDop,
FoodPercent,LossPercent,BruttoByRecalcFact,Brutto,FoodLoss,Price,PersonPortionCount,NettoRecipe,PortionCount24,
ParentMenuCategoryTimeRecipeID,MenuCategoryTimeRecipeID,IsHeat,OrderNumber,MenuCorrectionTypeID,IsVisible,DocFoodID,EggMeasureUnit,
round(sum(round(BruttoByRecalcPlan*(PortionCount+ControlPortionCount+PortionCount24),3)/*+round(BruttoByRecalcPlan*(PersonPortionCount),3)*/) over (partition by MenuID, FoodID, LossPercent, EatingCategory ORDER BY t.OrderForExp /*ROWS UNBOUNDED PRECEDING*/)/EggMeasureUnit,3) as MenuAmount, 
round(sum(round(BruttoByRecalcPlan*PortionCount,3)) over (partition by MenuID, FoodID, LossPercent, EatingCategory ORDER BY t.OrderForExp /*ROWS UNBOUNDED PRECEDING*/)/EggMeasureUnit,3) as MenuAmountEatingCategory, 
round(sum(round(BruttoByRecalcDop*(PortionCountFact-PortionCount),3)) over (partition by MenuID, FoodID, LossPercent, EatingCategory ORDER BY t.OrderForExp /*ROWS UNBOUNDED PRECEDING*/)/EggMeasureUnit,3) as MenuAmountDopEatingCategory,ExpAmount,ExpAmountDop,
fooEatingCategory.EatingCategoryID as mainEatingCategoryID,fooEatingCategoryDop.EatingCategoryID as mainEatingCategoryDopID,DocLossPercent, RecipeLoss, KoefToNorm,OrderNumberEatingCategory,OrderNumberEatingCategory as OrderNumberEatingTime, MeasureUnitString, BoilLoss as BoilLoss,case when count(FoodID) over (partition by MenuCategoryTimeRecipeID) =1 then 1 else 0 end as IsAlone, t.OrderForExp, t.Food1C, t.EatingCategory1C, RoundTo,
round(sum(round(BruttoByRecalcPlan*PersonPortionCount,3)) over (partition by MenuID, FoodID, LossPercent, EatingCategory ORDER BY t.OrderForExp /*ROWS UNBOUNDED PRECEDING*/)/EggMeasureUnit,3) as PersonAmount, IsMain
from
(SELECT        DocDetail.FoodID, DocDetail.Name, v_fooMenu.NomenclatureID, v_fooMenu.UnitMeasure, v_fooMenu.EatingTime, v_fooMenu.EatingTimeID, v_fooMenu.MenuID, v_fooMenu.MenuDate, v_fooMenu.ObjectID, v_fooMenu.[Object], v_fooMenu.UltraShortName, v_fooMenu.EatingCategoryID,v_fooMenu.EatingCategory, 
    v_fooMenu.PortionCount, v_fooMenu.PortionCountFact,v_fooMenu.ControlPortionCount, v_fooMenu.Recipe, v_fooMenu.OriginalRecipe,  v_fooMenu.RecipeID ,  
	v_fooMenu.Netto, RecipeLossOriginal as RecipeLoss,BoilLoss,
	case when OrderForExp = max(OrderForExp) over (partition by DocDetail.FoodID, v_fooMenu.MenuID, DocDetail.FoodPercent) and ROW_NUMBER() over (partition by DocDetail.FoodID, v_fooMenu.MenuID,OrderForExp,  isnull(SkyRecipeLoss,1)*DocDetail.LossPercent, DocDetail.FoodPercent order by OrderForExp asc, BruttoSkyFood/(1-DocDetail.LossPercent/100.00) asc,OrderNumber desc, DocDetail.FoodPercent) = count(BruttoSkyFood/(1-DocDetail.LossPercent/100.00)) over (partition by DocDetail.FoodID, v_fooMenu.MenuID,OrderForExp,  isnull(SkyRecipeLoss,1)*DocDetail.LossPercent, DocDetail.FoodPercent) then 
   (isnull(DocDetail.Amount,0)-sum(DocDetail.FoodPercent*BruttoSkyFood/(1-DocDetail.LossPercent/100.00)*AllPortionCount) over (partition by DocDetail.FoodID,v_fooMenu.MenuID,  isnull(SkyRecipeLoss,1)*DocDetail.LossPercent, DocDetail.FoodPercent order by OrderForExp asc, BruttoSkyFood/(1-DocDetail.LossPercent/100.00) asc, OrderNumber desc, DocDetail.FoodPercent ROWS UNBOUNDED PRECEDING))/AllPortionCount+BruttoSkyFood/(1-DocDetail.LossPercent/100.00)*DocDetail.FoodPercent
   else BruttoSkyFood/(1-DocDetail.LossPercent/100.00)*DocDetail.FoodPercent  end as BruttoByRecalcPlan,DocDetail.FoodPercent, isnull(SkyRecipeLoss,1)*DocDetail.LossPercent as LossPercent,DocDetail.LossPercent as DocLossPercent,
0	as BruttoByRecalcFact,
case when DocDetailDop.FoodID = DocDetail.FoodID and  DocDetailDop.LossPercent = DocDetail.LossPercent then 
case when MenuCorrectionTypeID = 1  and (AllPortionCountFact-AllPortionCount) <> 0 then 
	case when OrderForExp = max(OrderForExp) over (partition by v_fooMenu.FoodID, v_fooMenu.MenuID, DocDetail.FoodPercent) and ROW_NUMBER() over (partition by v_fooMenu.FoodID, v_fooMenu.MenuID,OrderForExp,  isnull(SkyRecipeLoss,1)*DocDetail.LossPercent, DocDetail.FoodPercent, MenuCorrectionTypeID order by OrderForExp asc, BruttoSkyFood/(1-DocDetail.LossPercent/100.00) asc,OrderNumber desc, DocDetail.FoodPercent) = count(BruttoSkyFood/(1-DocDetail.LossPercent/100.00)) over (partition by v_fooMenu.FoodID, v_fooMenu.MenuID,OrderForExp,  isnull(SkyRecipeLoss,1)*DocDetail.LossPercent, DocDetail.FoodPercent, MenuCorrectionTypeID) 
	then (isnull(DocDetailDop.Amount,0)-sum(DocDetail.FoodPercent*BruttoSkyFood/(1-DocDetail.LossPercent/100.00)*(AllPortionCountFact-AllPortionCount)) over (partition by v_fooMenu.FoodID,v_fooMenu.MenuID,  isnull(SkyRecipeLoss,1)*DocDetail.LossPercent, DocDetail.FoodPercent, MenuCorrectionTypeID order by OrderForExp asc, BruttoSkyFood/(1-DocDetail.LossPercent/100.00) asc, OrderNumber desc, DocDetail.FoodPercent ROWS UNBOUNDED PRECEDING))/(AllPortionCountFact-AllPortionCount)+BruttoSkyFood/(1-DocDetail.LossPercent/100.00)*DocDetail.FoodPercent
	else BruttoSkyFood/(1-DocDetail.LossPercent/100.00)*DocDetail.FoodPercent  end 
else 0 end else 0 end as BruttoByRecalcDop,
OrderNumberEatingCategory,
	v_fooMenu.Brutto, v_fooMenu.FoodLoss, DocDetail.Price as Price, KoefToNorm, MenuNumber, SignDate,PortionCount24,
	v_fooMenu.PersonPortionCount, v_fooMenu.NettoRecipe, v_fooMenu.ParentMenuCategoryTimeRecipeID, v_fooMenu.MenuCategoryTimeRecipeID, v_fooMenu.IsHeat, v_fooMenu.OrderNumber,v_fooMenu.MenuCorrectionTypeID, IsVisible, DocDetail.FoodID as DocFoodID, DocDetail.EggMeasureUnit,
	case when DocDetail.FoodID = 189 then round(isnull(DocDetail.Amount,0)/DocDetail.EggMeasureUnit,0) else isnull(DocDetail.Amount,0)/DocDetail.EggMeasureUnit end as ExpAmount, 
	case when DocDetailDop.FoodID = DocDetail.FoodID and  DocDetailDop.LossPercent = DocDetail.LossPercent then case when DocDetailDop.FoodID = 189 then round(isnull(DocDetailDop.Amount,0)/DocDetail.EggMeasureUnit,0)  else isnull(DocDetailDop.Amount,0)/DocDetail.EggMeasureUnit end else 0 end as ExpAmountDop,
	v_fooMenu.RoundTo, OrderForExp, max(OrderForExp) over (partition by v_fooMenu.MenuID, v_fooMenu.FoodID, isnull(SkyRecipeLoss,1)*(DocDetail.LossPercent)) MainOrderForExp, 
	max(case MenuCorrectionTypeID when 1 then OrderForExp else 0 end) over (partition by v_fooMenu.MenuID, v_fooMenu.FoodID, isnull(SkyRecipeLoss,1)*(DocDetail.LossPercent)) MainOrderForExpDop,isnull(MU.MeasureUnitString,'') as MeasureUnitString, DocDetail.Food1C, EatingCategory1C, DocDetail.IsMain
FROM            v_fooMenu
left join  
(select fooIncDocDetail.FoodID, foofood.Name, foofood.NomenclatureID, case  fooIncDocDetail.FoodID when 189 then 
(sum(fooIncDocDetail.Price*(1+isnull(fooIncDocDetail.VATRate/100,0))*fooExpDocDetail.Amount)/sum(fooexpdocdetail.amount))
else 
(sum(fooIncDocDetail.Price*(1+isnull(fooIncDocDetail.VATRate/100,0))*fooExpDocDetail.Amount)/sum(fooexpdocdetail.amount*fooIncDocDetail.MeasureUnit)) end as Price, sum(fooExpDocDetail.Amount*fooIncDocDetail.MeasureUnit*fooUnitMeasureKoef.Koef) as Amount, fooDocument.DocDate, fooDocument.ObjectID, sum(fooExpDocDetail.Amount*fooIncDocDetail.MeasureUnit)/sum(sum(fooExpDocDetail.Amount*fooIncDocDetail.MeasureUnit)) over (partition by fooDocument.DocDate, fooDocument.ObjectID, fooFood.NomenclatureID) as FoodPercent, case when fooIncDocDetail.FoodID in (192,66,308) then case fooIncDocDetail.LossPercent when 0 then fooFoodLoss.PercentValue else fooIncDocDetail.LossPercent end else fooIncDocDetail.LossPercent end as LossPercent,
(case when fooIncDocDetail.FoodID = 189 then sum(fooIncDocDetail.MeasureUnit*fooExpDocDetail.Amount)/sum(fooExpDocDetail.Amount) else 1 end) as EggMeasureUnit,'' as MeasureUnitString, foofood.Code1C as Food1C, fooObjectPerson.IsMain
from fooDocument 
inner join fooExpDocDetail on fooDocument.DocumentID = fooExpDocDetail.DocumentID
inner join fooIncDocDetail on fooExpDocDetail.IncDocDetailID = fooIncDocDetail.IncDocDetailID
inner join fooDocument IncDocument on fooIncDocDetail.DocumentID = IncDocument.DocumentID
inner join fooObjectPerson on IncDocument.ObjectPersonID = fooObjectPerson.ObjectPersonID
inner join fooMenu on fooDocument.DocDate = fooMenu.MenuDate and fooDocument.ObjectID = fooMenu.ObjectID and fooMenu.MenuID = @MenuID
inner join foofood on foofood.FoodID = fooIncDocDetail.FoodID
left join fooFoodLoss on fooFood.FoodID = fooFoodLoss.FoodID and isnull(fooFoodLoss.MonthID, Month(MenuDate))=Month(MenuDate)
inner join fooUnitMeasure as fooUnitMeasureInc on  fooIncDocDetail.UnitMeasureID = fooUnitMeasureInc.UnitMeasureID
inner join fooUnitMeasure as fooUnitMeasureFood on  foofood.UnitMeasureID = fooUnitMeasureFood.UnitMeasureID
inner join fooUnitMeasureKoef on fooUnitMeasureInc.UnitMeasureID = fooUnitMeasureKoef.UnitMeasureIDInc and fooUnitMeasureFood.UnitMeasureID = fooUnitMeasureKoef.UnitMeasureIDMenu
where fooDocument.DocumentTypeID=3   and fooDocument.RecordStatusID=1 and fooExpDocDetail.RecordStatusID=1 and fooIncDocDetail.RecordStatusID=1 and fooExpDocDetail.Amount <> 0
group by fooIncDocDetail.FoodID, foofood.Name, foofood.NomenclatureID, fooDocument.DocDate, fooDocument.ObjectID, case when fooIncDocDetail.FoodID in (192,66,308) then case fooIncDocDetail.LossPercent when 0 then fooFoodLoss.PercentValue else fooIncDocDetail.LossPercent end else fooIncDocDetail.LossPercent end, fooFood.Code1c, fooObjectPerson.IsMain) DocDetail on DocDetail.NomenclatureID = v_fooMenu.NomenclatureID and DocDetail.DocDate = v_fooMenu.MenuDate and DocDetail.ObjectID = v_fooMenu.ObjectID
left join (select FoodID, ' ('+[dbo].[BeautyStr](sum(Amount1))+ ' по '+ ltrim(Str(sum(MeasureUnit1),7,3))+
case when sum(Amount2) <> 0 then ', '+ [dbo].[BeautyStr](sum(Amount2))+ ' по '+ ltrim(Str(sum(MeasureUnit2),7,3)) else '' end+
case when sum(Amount3) <> 0 then ', '+ [dbo].[BeautyStr](sum(Amount3))+ ' по '+ ltrim(Str(sum(MeasureUnit3),7,3)) else '' end+
case when sum(Amount4) <> 0 then ', '+ [dbo].[BeautyStr](sum(Amount4))+ ' по '+ ltrim(Str(sum(MeasureUnit4),7,3)) else '' end+
case when sum(Amount5) <> 0 then ', '+ [dbo].[BeautyStr](sum(Amount5))+ ' по '+ ltrim(Str(sum(MeasureUnit5),7,3)) else '' end +')' as MeasureUnitString
from 
(select Foodid,IsUndividedPack,
case when ROW_NUMBER() over (partition by FoodID order by MeasureUnit,IsUndividedPack)=1 then Amount  else 0 end as Amount1,
case when ROW_NUMBER() over (partition by FoodID order by MeasureUnit,IsUndividedPack)=1 then MeasureUnit  else 0 end as MeasureUnit1,
case when ROW_NUMBER() over (partition by FoodID order by MeasureUnit,IsUndividedPack)=2 then Amount  else 0 end as Amount2,
case when ROW_NUMBER() over (partition by FoodID order by MeasureUnit,IsUndividedPack)=2 then MeasureUnit  else 0 end as MeasureUnit2,
case when ROW_NUMBER() over (partition by FoodID order by MeasureUnit,IsUndividedPack)=3 then Amount  else 0 end as Amount3,
case when ROW_NUMBER() over (partition by FoodID order by MeasureUnit,IsUndividedPack)=3 then MeasureUnit  else 0 end as MeasureUnit3,
case when ROW_NUMBER() over (partition by FoodID order by MeasureUnit,IsUndividedPack)=4 then Amount  else 0 end as Amount4,
case when ROW_NUMBER() over (partition by FoodID order by MeasureUnit,IsUndividedPack)=4 then MeasureUnit  else 0 end as MeasureUnit4,
case when ROW_NUMBER() over (partition by FoodID order by MeasureUnit,IsUndividedPack)=5 then Amount  else 0 end as Amount5,
case when ROW_NUMBER() over (partition by FoodID order by MeasureUnit,IsUndividedPack)=5 then MeasureUnit  else 0 end as MeasureUnit5
from 
( select fooIncDocDetail.Foodid, 
sum(fooExpDocDetail.Amount)  as Amount,
(fooIncDocDetail.MeasureUnit) as MeasureUnit,sum(isnull(fooIncDocDetail.IsUndividedPack,0)) as IsUndividedPack
from
fooDocument 
inner join fooExpDocDetail on fooDocument.DocumentID = fooExpDocDetail.DocumentID
inner join fooIncDocDetail on fooExpDocDetail.IncDocDetailID = fooIncDocDetail.IncDocDetailID
inner join fooMenu on fooDocument.DocDate = fooMenu.MenuDate and fooDocument.ObjectID = fooMenu.ObjectID and fooMenu.MenuID = @MenuID
where fooDocument.DocumentTypeID=3   and fooDocument.RecordStatusID=1 and fooExpDocDetail.RecordStatusID=1 and fooIncDocDetail.RecordStatusID=1 and fooExpDocDetail.Amount <> 0
group by FoodID, MeasureUnit
)MU1)MU2
group by FoodID
having sum(IsUndividedPack) <> 0) as MU on DocDetail.FoodID = MU.FoodID
left join  
(select fooIncDocDetail.FoodID, foofood.NomenclatureID, sum(fooIncDocDetail.Price/fooIncDocDetail.Amount*fooExpDocDetail.Amount)/sum(fooExpDocDetail.Amount*fooIncDocDetail.MeasureUnit) as Price, sum(fooExpDocDetail.Amount*fooIncDocDetail.MeasureUnit*fooUnitMeasureKoef.Koef) as Amount, fooDocument.DocDate, fooDocument.ObjectID, sum(fooExpDocDetail.Amount*fooIncDocDetail.MeasureUnit)/sum(sum(fooExpDocDetail.Amount*fooIncDocDetail.MeasureUnit)) over (partition by fooDocument.DocDate, fooDocument.ObjectID, fooIncDocDetail.FoodID) as FoodPercent, case when fooIncDocDetail.FoodID in (192,66,308) then case fooIncDocDetail.LossPercent when 0 then fooFoodLoss.PercentValue else fooIncDocDetail.LossPercent end else fooIncDocDetail.LossPercent end as LossPercent,
(case when fooIncDocDetail.FoodID = 189 then sum(fooIncDocDetail.MeasureUnit*fooExpDocDetail.Amount)/sum(fooExpDocDetail.Amount) else 1 end) as EggMeasureUnit,'' as MeasureUnitString
from fooDocument 
inner join fooExpDocDetail on fooDocument.DocumentID = fooExpDocDetail.DocumentID
inner join fooIncDocDetail on fooExpDocDetail.IncDocDetailID = fooIncDocDetail.IncDocDetailID
inner join fooMenu on fooDocument.DocDate = fooMenu.MenuDate and fooDocument.ObjectID = fooMenu.ObjectID and fooMenu.MenuID = @MenuID
inner join foofood on foofood.FoodID = fooIncDocDetail.FoodID
left join fooFoodLoss on fooFood.FoodID = fooFoodLoss.FoodID and isnull(fooFoodLoss.MonthID, Month(MenuDate))=Month(MenuDate)
inner join fooUnitMeasure as fooUnitMeasureInc on  fooIncDocDetail.UnitMeasureID = fooUnitMeasureInc.UnitMeasureID
inner join fooUnitMeasure as fooUnitMeasureFood on  foofood.UnitMeasureID = fooUnitMeasureFood.UnitMeasureID
inner join fooUnitMeasureKoef on fooUnitMeasureInc.UnitMeasureID = fooUnitMeasureKoef.UnitMeasureIDInc and fooUnitMeasureFood.UnitMeasureID = fooUnitMeasureKoef.UnitMeasureIDMenu
where fooDocument.DocumentTypeID=7   and fooDocument.RecordStatusID=1 and fooExpDocDetail.RecordStatusID=1 and fooIncDocDetail.RecordStatusID=1 and fooExpDocDetail.Amount <> 0
group by fooIncDocDetail.FoodID, foofood.NomenclatureID, fooDocument.DocDate, fooDocument.ObjectID, case when fooIncDocDetail.FoodID in (192,66,308) then case fooIncDocDetail.LossPercent when 0 then fooFoodLoss.PercentValue else fooIncDocDetail.LossPercent end else fooIncDocDetail.LossPercent end) DocDetailDop on DocDetailDop.NomenclatureID = v_fooMenu.NomenclatureID and DocDetailDop.DocDate = v_fooMenu.MenuDate and DocDetailDop.ObjectID = v_fooMenu.ObjectID
where isnull(DocDetail.Amount, 0) <> 0 and NettoRecipe <>0 and (PortionCount+PersonPortionCount+PortionCount24) <> 0 and v_fooMenu.IsFromStorage = 1 and v_fooMenu.MenuID = @MenuID and v_fooMenu.EatingCategoryID not in (12,13)) as t
inner join fooEatingCategory on MainOrderForExp = fooEatingCategory.OrderForExp
inner join fooEatingCategory fooEatingCategoryDop on MainOrderForExpDop = fooEatingCategoryDop.OrderForExp
	
	
	RETURN 
END


