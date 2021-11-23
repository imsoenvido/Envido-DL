use envido_dl

GO

IF EXISTS (select * FROM sys.objects WHERE type = 'P' AND name = 'pr_LinkObservationValue')
DROP PROCEDURE [pr_LinkObservationValue]


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*=========================================================================================
    DESCRIPTION:     Generate the Obseravation value 

	USE:			EXEC pr_LinkObservationValue @ID = 1 -- tblLinkStagingNotificationCapDetail
					EXEC pr_LinkObservationValue @ID = 2 -- tblLinkStagingProvation
    
    
	PARAMETERS:		@Id - is the importTableMapping ID from tblLinkImportMappingTable

    REVISIONS:		30/10/2020	S.Walsh	Created 
					04/11/2020	S.Walsh	Update the ObservationValue

-- ========================================================================================*/

CREATE PROCEDURE [dbo].[pr_LinkObservationValue]  
	   	@ID int 
AS
BEGIN
	IF OBJECT_ID('tempdb..#CombinedObservation') IS NOT NULL DROP TABLE #CombinedObservation
	Create Table #CombinedObservation (SourveKey varchar(max), OBservationValue varchar (max))

	Declare @SourceTable varchar(max)
	Declare @SourceField varchar (max)
	Declare @SourceKey varchar (max)
	Declare @DestFieldType int
	Declare @Concat varchar (max)
	Declare @ObservationField varchar (max)
	Declare @ObservationValue varchar(max)


	Select @SourceTable = SourceTable from dbo.tblLinkImportMappingTable where ImportTableMappingID = @ID
	Select @SourceKey = SourceField from dbo.tblLinkImportMappingFields where ImportTableMappingID = @ID and IsPivotKey = 1
	Select @ObservationField = SourceField from dbo.tblLinkImportMappingFields where ImportTableMappingID = @ID  and IsConcatinated = 1

	Set @Concat = ''

	--Select the fields used in producing the observation value
	IF OBJECT_ID('tempdb..#ObservationValues') IS NOT NULL DROP TABLE #ObservationValues
	select	SourceField,DestQuestionType
	into	#ObservationValues
	from	dbo.tblLinkImportMappingFields OV
	where	OV.InObservationValue In (select ImportMappingID from dbo.tblLinkImportMappingFields where IsConcatinated = 1 and ImportTableMappingID = @ID )

-- Generate the observation value from a single or combination of fields 
	IF (select COUNT(*) from #ObservationValues ) = 0
	begin
		Print 'There is no observation value specified'
	end

	IF (select COUNT(*) from #ObservationValues )  = 1
	begin 
		Print 'The observation value is a single value'
		Select  @ObservationValue = quotename(SourceField) from  #ObservationValues
		Insert into #CombinedObservation
		Exec ('select '+@SourceKey+ ', '+@ObservationValue +' as  ObservationValue from ' + @SourceTable)
	end

	IF (select COUNT(*) from #ObservationValues ) >=2
	Begin

		DECLARE OV CURSOR
		FOR select SourceField,DestQuestionType from #ObservationValues 
		
		OPEN OV;

		FETCH NEXT FROM OV INTO @SourceField,@DestFieldType ;

		WHILE @@FETCH_STATUS = 0  
			BEGIN
				SELECT @Concat = @Concat + ''''+@SourceField+':'','
			
				-- Numbers
				If @DestFieldType  in(7,11)
					Set @SourceField = 'convert(varchar,'+quotename(@SourceField)+')'
				-- Date only 
				If @DestFieldType  = 29
					Set @SourceField = 'convert(varchar,'+quotename(@SourceField)+',105)'
				-- Date-Time
				If @DestFieldType  = 9
					Set @SourceField = 'convert(varchar,'+quotename(@SourceField)+',105) + '' '' + replace(RIGHT(CONVERT(VARCHAR, CONVERT(DATETIME, '+quotename(@SourceField)+'), 131), 14),'':00:000'','' '')'
				-- Other data types that don't need converting
				If @DestFieldType  In (1,2,5,6,10,17)
					Set @SourceField = quotename(@SourceField )

				-- Include a line return - this may need to be changes to accomodate the UI capabilities 
				SELECT @Concat = @Concat + @SourceField+'+char(13)+char(10),' +char(13)+char(10)

				FETCH NEXT FROM OV INTO  @SourceField,@DestFieldType 
			END;	

			CLOSE OV;
			DEALLOCATE OV;

			Select @Concat = Substring(@Concat,0,len(@Concat)-20)
			Insert into #CombinedObservation
			Exec ('select '+@SourceKey+ ',concat('+@Concat+') as  ObservationValue from ' + @SourceTable)
			PRINT ('select '+@SourceKey+ ',concat('+@Concat+') as  ObservationValue from ' + @SourceTable)

		End

		Declare @SQlUpdate varchar (max)
		set @SQlUpdate = ''

		select @SQlUpdate = @SQlUpdate + ' Update dbo.'+@SourceTable +' 
		set		'+@ObservationField +'= C.ObservationValue 
		from dbo.'+@SourceTable +' as X
		inner join #CombinedObservation C on X.SourceKey = C.SourveKey' 
		
		EXEC  (@SQlUpdate)

End

-- clean up
	IF OBJECT_ID('tempdb..#ObservationValues') IS NOT NULL DROP TABLE #ObservationValues
	IF OBJECT_ID('tempdb..#CombinedObservation') IS NOT NULL DROP TABLE #CombinedObservation

