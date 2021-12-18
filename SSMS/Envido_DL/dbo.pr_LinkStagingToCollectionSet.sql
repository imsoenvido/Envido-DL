USE envido_dl 


IF EXISTS (select * FROM sys.objects WHERE type = 'P' AND name = 'pr_LinkStagingToCollectionSet')
DROP PROCEDURE [pr_LinkStagingToCollectionSet]
GO 

SET NOCOUNT ON
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*=========================================================================================
    DESCRIPTION:	Process data from a staging table into the matching collection and set
					
    USE:            EXEC dbo.pr_LinkStagingToCollectionSet @ImportTableMappingID = 1 -- SA-PCCOC Notificaiton data from SA-Health
					EXEC dbo.pr_LinkStagingToCollectionSet @ImportTableMappingID = 2 -- SCOOP Provation data 
					EXEC dbo.pr_LinkStagingToCollectionSet @ImportTableMappingID = 3 -- Staging to DL-SCOOP-Event

					------------------------------------
					begin tran 
					EXEC dbo.pr_LinkStagingToCollectionSet @ImportTableMappingID = 3
					rollback commit

					use envido 
					select COUNT(*) from envido.dbo.tblAnswerSet where setid = 318
					select COUNT(*)  from envido.dbo.tblAnswer where AnswerSetID in (select AnswerSEtID from tblAnswerSet where setid = 318)

                    
    REVISIONS:		22/09/2020	S.Walsh		Created
					01/10/2020	S.Walsh		Revision when loading Provation
					28/10/2020	S.Walsh		Correct format for dateonly, Add DB fields to permit us to nominate the destination DB 
					09/08/2021	DJF			Make LinkAnswerSetID table a temporary table to enable multiple processes to run at the same time

					 			
   ========================================================================================*/


CREATE PROCEDURE [dbo].[pr_LinkStagingToCollectionSet] 
	
	@ImportTableMappingID int,
	@debug int = 0
	
AS
BEGIN

	--declare @ImportTableMappingID int 
	--set @ImportTableMappingID = 2					-- This is only set for testing. Remove prior to deploying so there is no default 
	--declare @debug int 
	--Set @Debug = 1

	declare @CurrentDate datetime
	declare @SourceDB varchar (50)
	declare @SourceTable varchar (50)
	declare @DestDB varchar (50)
	declare @ExcludeQuestionID varchar (50)
	declare @PivotField varchar (50)
	declare @DestSetId varchar (max)
	declare @DefaultGroupid varchar (max)
	declare @DefaultUserID varchar(max)
	declare @QueAns dbo.QueAns
	declare @SQL varchar (max)
	declare @SqlInsert varchar (max)
	declare @SourceKey varchar (max)
	declare @CreateSourceAnswerSetIDs int 
		
	select @CurrentDate = getdate()
	select @SourceDB  = SourceDatabase from [tblLinkImportMappingTable] where ImportTableMappingID = @ImportTableMappingID
	select @SourceTable  = SourceTable from [tblLinkImportMappingTable] where ImportTableMappingID = @ImportTableMappingID
	select @DestDB  = DestDatabase from [tblLinkImportMappingTable] where ImportTableMappingID = @ImportTableMappingID
	select @DefaultGroupid  = DefaultGroupId from [tblLinkImportMappingTable] where ImportTableMappingID = @ImportTableMappingID
	select @DefaultUserID  = DefaultUserId from [tblLinkImportMappingTable] where ImportTableMappingID = @ImportTableMappingID
	select @CreateSourceAnswerSetIDs = CreateSourceAnswerSetIDs from  dbo.tblLinkImportMappingTable where ImportTableMappingID = @ImportTableMappingID 
	select @DestSetId = DestSetID from  dbo.tblLinkImportMappingFields where ImportTableMappingID = @ImportTableMappingID
	select @PivotField = SourceField from  dbo.tblLinkImportMappingFields where ImportTableMappingID = @ImportTableMappingID and IsPivotKey =1
	select @ExcludeQuestionID = cast(DestQuestionID as varchar) from  dbo.tblLinkImportMappingFields where ImportTableMappingID = @ImportTableMappingID and IsPivotKey =1
	
	IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results
	create table #Results (
		SourceKey varchar (50)
		,QuestionText nvarchar (max)
		,AnswerValue nvarchar (max)
	)

	IF OBJECT_ID('tempdb..#ImportData') IS NOT NULL DROP TABLE #ImportData
	create table #ImportData (
	 	AnswerSetID int
		,DestSetID int
		,SuperParentAnswerSetID int
		,ParentAnswerSetID int
		,DestQuestionID int
		,AnswerValue varchar(max)
		,AddedBy int
		,AddedDate datetime
		,LastModifiedBy int
		,LastModifiedDate datetime
		,GoupId int
		,[Sequence] int
	)

Print '--STEP-1: Select all the staging records that have not already been processed into the collection-set.'
			-- This essentially pivots the data for use in uspWorkListRecord_Insert @QueAns later
	set @SQL = ''
	set @SQL  = 'select	' + @PivotField + ', F.* from '+@SourceDB+'.dbo.'+ltrim(rtrim(@SourceTable)) +' R cross apply ( values '+char(13) 
		select @SQL  =  case 
						 when IncludeField = 1 and FieldInSourceFile = 0 and DefaultDestAnswersOptionID is not null  and DefaultDestAnswersOptionID is not null 
							then @SQL+ '		('''+SourceField+''',cast('+cast(DefaultDestAnswersOptionID as varchar)+' as varchar(max))),'+char(13)
						 when IncludeField = 1 and FieldInSourceFile = 0 and DefaultDestAnswersOptionID is not null  and DefaultDestAnswersOptionID is null  and DefaultDestValue is not null 
							then @SQL+ '		('''+SourceField+''',cast('+cast(DefaultDestValue as varchar(max))+' as varchar(max))),'+char(13)
						 when IncludeField = 1  and FieldInSourceFile = 0  
							then @SQL+ '		('''+SourceField+''',''''),'+ char(13)
						 when IncludeField = 1 and FieldInSourceFile = 1  and DestQuestionType = 9 
							then @SQL+ '		('''+SourceField+''',convert(varchar(max),'+quotename(SourceField)+',105) + '' '' + replace(RIGHT(CONVERT(varchar(max), CONVERT(DATETIME, ['+SourceField+']), 131), 14),'':00:000'','' '')),'+char(13)
 						 when IncludeField = 1 and FieldInSourceFile = 1 and DestQuestionType = 29 
							then @SQL+ '		('''+SourceField+''',convert(varchar(max),'+quotename(SourceField)+',105)),'+char(13)
						 when IncludeField = 1 and FieldInSourceFile = 1 and DefaultDestAnswersOptionID is null and DestQuestionType In (1,10) 
							then @SQL+ '		('''+SourceField+''', isnull((select cast(AnswersOptionsID as varchar(max)) from tblAnswersOptions where QuestionID = '+CAST(DestQuestionID as varchar(max))+' and AnswerText= ['+SourceField+']),'''')),'+char(13)
 						 when IncludeField = 1 and FieldInSourceFile = 1 and DestQuestionType In (2,4,5,6,7,11,17,20) 
							then @SQL+ '		('''+SourceField+''',isnull(cast('+quotename(SourceField)+' as varchar(max)),'''')),'+char(13)					
						 when IncludeField = 1 and FieldInSourceFile = 1 and DefaultDestAnswersOptionID is not null 
							then @SQL+ '		('''+SourceField+''',cast('+cast(DefaultDestAnswersOptionID as varchar(max))+' as varchar(max))),'+char(13)
						 when IncludeField = 1 and FieldInSourceFile = 1 and DefaultDestAnswersOptionID is not null and DefaultDestAnswersOptionID is not null 
							then @SQL+ '		('''+SourceField+''',cast('+cast(DefaultDestAnswersOptionID as varchar(max))+' as varchar)),'+char(13)
						 when IncludeField = 1 and FieldInSourceFile = 1 and DefaultDestAnswersOptionID is not null  and DefaultDestAnswersOptionID is null  and DefaultDestValue is not null 
							then @SQL+ '		('''+SourceField+''',cast('+cast(DefaultDestValue as varchar)+' as varchar(max))),'+char(13)
						 when IncludeField = 0 then @SQL + ''
						 else @SQL+ '		Not sure' + char(13)
						 --need for Checkbox
					end 
		from dbo.tblLinkImportMappingFields
			where ImportTableMappingID = @ImportTableMappingID
			and IncludeField = 1

	select @SQL = substring(@SQL,0,len(@SQL)-1)

 	select @SQL = @SQL + '
	) F (QuestionText,AnswerValue)
	where '+ ltrim(rtrim(@PivotField)) +' not in (select AnswerText from '+@DestDB+'.dbo.tblAnswer where QuestionID = '+ @ExcludeQuestionID+')'

	insert into #Results (SourceKey,QuestionText,AnswerValue)
	exec(@SQL)
	
	if @debug = 1
		print (@SQL)	
	-- select * from #Results

Print '--STEP-2: Get the next AnswerSetID of the destination database'

	Declare @sqlCommand nvarchar(1000)
	Declare @NewAnswerSetIdSeed int
	
	Set @sqlCommand = 'select  @ID = max(answerSetID) + 1 from '+@DestDB +'.dbo.tblAnswerSet'
	EXECUTE sp_executesql @sqlCommand, N'@DestDB varchar (50), @ID int OUTPUT',@DestDB = @DestDB, @ID = @NewAnswerSetIdSeed OUTPUT
	
	--select  @ID = max(answerSetID) + 1 from envido.dbo.tblAnswerSet
	Print '--@NewAnswerSetIdSeed:' + cast(@NewAnswerSetIdSeed as varchar)
	
	
	declare @sqltable varchar (max)
	select @sqltable = ''	
	
	If @NewAnswerSetIdSeed IS NULL 
		Select @NewAnswerSetIdSeed  = 1

	--IF EXISTS (select * from sys.objects WHERE type = 'U' AND name = 'LinkAnswerSetID')
	--Drop Table [LinkAnswerSetID]

	--select @sqltable  = @sqltable  + '
	--create table '+@SourceDB+'.dbo.LinkAnswerSetID (
	--	AnswerSetId int identity ('+cast(@NewAnswerSetIdSeed as varchar)+',1)
	--	,SourceKey varchar (50))'

	--exec  (@sqltable)
	
	--if @debug = 1
	--	print (@sqltable)

	IF OBJECT_ID('tempdb..#LinkAnswerSetID') IS NOT NULL DROP TABLE #LinkAnswerSetID

	create table #LinkAnswerSetID (
	 	SourceKey varchar (50)
	)

	select @sqltable  = @sqltable  + 'Alter table #LinkAnswerSetID Add AnswerSetId int identity ('+cast(@NewAnswerSetIdSeed as varchar)+',1)'

	exec  (@sqltable)
	
	if @debug = 1
		print (@sqltable)

	set @sqltable = ''
	
Print '--STEP-3: Generate an Answerset for the new records '
	
	insert	into #LinkAnswerSetID (SourceKey)
	select	distinct SourceKey 
	from	#Results

	-- select * from #Results 

Print '--STEP-4: generate the data ready to import' 
	
	select @sqltable = @sqltable +'select	LASID.AnswerSetID
			,MF.DestSetID
			,case when S.ParentSetId is null then NULL else LASID.AnswerSetID end as SuperParentAnswerSetID
			,case when S.ParentSetId is null then NULL else LASID.AnswerSetID end as ParentAnswerSetID
			,MF.DestQuestionID
			,Case when Q.QuestionTypeID in (1,10) and MF.DefaultDestAnswersOptionID IS NULL and R.AnswerValue <> ''''
				Then (select Cast(AnswersOptionsID as varchar) from  '+@DestDB +'.dbo.tblAnswersOptions AO Where AO.QuestionID = Q.QuestionID And AO.AnsCode = ltrim(rtrim(R.AnswerValue)))
				Else R.AnswerValue
			End as AnswerValue
			,'''+ convert(varchar,@DefaultUserID) +''' as AddedBy
			,'''+ convert(varchar,@CurrentDate,121) +''' as AddedDate
			,'+ convert(varchar,@DefaultUserID) +' as LastModifiedBy
			,'''+ convert(varchar,@CurrentDate,121) +''' as LastModifiedDate
			,'+ convert(varchar,@DefaultGroupid)+' as GoupId
			,Q.[Sequence]
	from	#Results R
	inner join dbo.tblLinkImportMappingFields MF on R.QuestionText = MF.SourceField
	inner join '+@DestDB +'.dbo.tblQuestion Q on MF.DestQuestionID = Q.QuestionID
	inner join '+@DestDB +'.dbo.tblSet S on Q.SetID = S.SetID
	inner join '+ +'#LinkAnswerSetID LASID on R.SourceKey =  LASID.SourceKey
	Where MF.ImportTableMappingID = '+ CAST(@ImportTableMappingID as varchar)+'
	Order by LASID.AnswerSEtID , Q.[Sequence]'

	print (@sqltable)

	Insert into #ImportData 
	Exec(@sqltable) 
	-- select * from #ImportData 


	-- If the destination is a collection on Envido_DL, add the AnswerSetIDs to the source table. 
	-- This is used in furture as the SourceAnswerSetID of the collection in the Envido Account 

	If @CreateSourceAnswerSetIDs = 1 
	begin 
		Print '--Add the AnswerSetID to the source table on Envido_DL'

		Set @SqlInsert = ''

		select @SqlInsert = @SqlInsert  + '
		update '+@SourceDB +'.dbo.'+@SourceTable+'
		set AnswerSetID = X.AnswerSetID
		from	(select	DT.AnswerSetID
						,ST.SourceKey 
				from '+@SourceDB +'.dbo.'+@SourceTable+' ST
				inner join (select AnswerSetID,AnswerValue from #ImportData where DestQuestionID = '+cast(@ExcludeQuestionID as varchar)+') DT
				on ST.SourceKey = DT.AnswerValue
				) X
		where '+@SourceDB +'.dbo.'+@SourceTable+'.'+cast(@PivotField as varchar)+' = X.'+cast(@PivotField as varchar)

		exec  (@SqlInsert)
	
		if @debug = 1
			print (@SqlInsert)
	
		Set @SqlInsert = ''
	End

Print '--STEP-5: Insert the AnswerSet records to the destination collection'

	Set @SqlInsert = ''

	select @SqlInsert  = @SqlInsert +'
	Set Identity_Insert '+@DestDB +'.dbo.tblAnswerSet  on 
		Insert into '+@DestDB +'.dbo.tblAnswerSet (AnswerSetID,SetID,SuperParentAnswerSetID,ParentAnswerSetID,AddedBy,AddedDate,LastModifiedBy,LastModifiedDate,GoupID)
		select	distinct AnswerSetID, DestSetID, SuperParentAnswerSetID, ParentAnswerSetID, AddedBy, AddedDate,LastModifiedBy, LastModifiedDate,GoupId
		from	dbo.#ImportData
		order by AnswerSetID
	Set Identity_Insert '+@DestDB +'.dbo.tblAnswerSet  off'
	
	exec  (@SqlInsert)
	
	if @debug = 1
		print (@SqlInsert)
	
	Set @SqlInsert = ''

Print '--STEP-6: Insert the Answer records'

	Set @SqlInsert = ''

	select @SqlInsert  = @SqlInsert +'
	insert into '+@DestDB +'.dbo.tblAnswer (QuestionID,AnswerSetID,AnswerText)
	select	DestQuestionID,AnswerSetID,AnswerValue
	from	dbo.#ImportData
	order by AnswerSetID,[Sequence]'

	exec  (@SqlInsert)
	
	if @debug = 1
		print (@SqlInsert)
	
	Set @SqlInsert = ''

Print '--STEP-7: Pivot and insert to the numbered table'

	/*** PROBABLY need to add conversions to for dates : possibly re-foramt the date in #ImportData to MDY from DMY ****/

	-- Retrieve the numbered columns for the table

	IF OBJECT_ID('tempdb..#Cols') IS NOT NULL DROP TABLE #Cols
	select distinct DestQuestionID into #Cols  FROM	#ImportData R order by DestQuestionID 

	Declare @Column varchar(max)
	set @Column = ''
	Select @Column = STUFF((SELECT ','+'['+ convert(varchar,DestQuestionID) +']' FROM	#Cols R order by DestQuestionID FOR XML PATH('')),1, 1, '')			

	print '@DestDB = ' + @DestDB
	print '@DestSetId = ' + convert (varchar,@DestSetId)
	print '@Column = ' + @Column

	EXEC('insert into '+@DestDB +'.dbo.['+@DestSetId+'] (AnswerSetID,SuperAnswerSetID,ParentAnswerSetID,CreatedBy,ModifiedBy,CreatedOn,ModifiedOn,GroupID, '+ @Column + ') 
	SELECT AnswerSetId,SuperParentAnswerSetID,ParentAnswerSetID,AddedBy,LastModifiedBy,AddedDate,LastModifiedDate,GoupId,'+ @Column + 
	'FROM (SELECT AnswerSetID,SuperParentAnswerSetID,ParentAnswerSetID,AddedBy,LastModifiedBy,AddedDate,LastModifiedDate,GoupId,DestQuestionID, AnswerValue as Value1 				
			FROM #ImportData) AS P PIVOT
			(
			Max(Value1) 
			FOR DestQuestionID IN (' + @Column + ')
			) AS Record ')

END





--	declare @ImportTableMappingID int 
--	set @ImportTableMappingID = 3					-- This is only set for testing. Remove prior to deploying so there is no default 
--	declare @debug int 
--	Set @Debug = 1
--	declare @CurrentDate datetime
--	declare @SourceDB varchar (50)
--	declare @SourceTable varchar (50)
--	declare @DestDB varchar (50)
--	declare @ExcludeQuestionID varchar (50)
--	declare @PivotField varchar (50)
--	declare @DestSetId varchar (max)
--	declare @DefaultGroupid varchar (max)
--	declare @DefaultUserID varchar(max)
--	declare @QueAns dbo.QueAns
--	declare @SQL varchar (max)
--	declare @SqlInsert varchar (max)
--	declare @SourceKey varchar (max)
--	declare @CreateSourceAnswerSetIDs int 
		
--	select @CurrentDate = getdate()
--	select @SourceDB  = SourceDatabase from [tblLinkImportMappingTable] where ImportTableMappingID = @ImportTableMappingID
--	select @SourceTable  = SourceTable from [tblLinkImportMappingTable] where ImportTableMappingID = @ImportTableMappingID
--	select @DestDB  = DestDatabase from [tblLinkImportMappingTable] where ImportTableMappingID = @ImportTableMappingID
--	select @DefaultGroupid  = DefaultGroupId from [tblLinkImportMappingTable] where ImportTableMappingID = @ImportTableMappingID
--	select @DefaultUserID  = DefaultUserId from [tblLinkImportMappingTable] where ImportTableMappingID = @ImportTableMappingID
--	select @CreateSourceAnswerSetIDs = CreateSourceAnswerSetIDs from  dbo.tblLinkImportMappingTable where ImportTableMappingID = @ImportTableMappingID 
--	select @DestSetId = DestSetID from  dbo.tblLinkImportMappingFields where ImportTableMappingID = @ImportTableMappingID
--	select @PivotField = SourceField from  dbo.tblLinkImportMappingFields where ImportTableMappingID = @ImportTableMappingID and IsPivotKey =1
--	select @ExcludeQuestionID = cast(DestQuestionID as varchar) from  dbo.tblLinkImportMappingFields where ImportTableMappingID = @ImportTableMappingID and IsPivotKey =1

--Print '--STEP-7: Pivot and insert to the numbered table'

--	/*** PROBABLY need to add conversions to for dates : possibly re-foramt the date in #ImportData to MDY from DMY ****/

--	-- Retrieve the numbered columns for the table

--	-- select * from #Cols
--	-- select * From #ImportData

--	IF OBJECT_ID('tempdb..#Cols') IS NOT NULL DROP TABLE #Cols
--	select distinct DestQuestionID into #Cols  FROM	#ImportData R order by DestQuestionID 

--	Declare @Column varchar(max)
--	set @Column = ''
--	Select @Column = STUFF((SELECT ','+'['+ convert(varchar,DestQuestionID) +']' FROM	#Cols R order by DestQuestionID FOR XML PATH('')),1, 1, '')	
--	print @Column 

--	EXEC('insert into '+@DestDB +'.dbo.['+@DestSetId+'] (AnswerSetID,SuperAnswerSetID,ParentAnswerSetID,CreatedBy,ModifiedBy,CreatedOn,ModifiedOn,GroupID, '+ @Column + ') 
--	SELECT AnswerSetId,SuperParentAnswerSetID,ParentAnswerSetID,AddedBy,LastModifiedBy,AddedDate,LastModifiedDate,GoupId,'+ @Column + 
--	'FROM (SELECT AnswerSetID,SuperParentAnswerSetID,ParentAnswerSetID,AddedBy,LastModifiedBy,AddedDate,LastModifiedDate,GoupId,DestQuestionID, AnswerValue as Value1 				
--			FROM #ImportData) AS P PIVOT
--			(
--			Max(Value1) 
--			FOR DestQuestionID IN (' + @Column + ')
--			) AS Record ')
			 