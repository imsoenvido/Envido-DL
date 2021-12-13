USE envido_dl 


IF EXISTS (select * FROM sys.objects WHERE type = 'P' AND name = 'pr_LinkCreateEnvidoDLCollection')
DROP PROCEDURE [pr_LinkCreateEnvidoDLCollection]
GO 

SET NOCOUNT ON
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*=========================================================================================
    DESCRIPTION:	Create a new data linkage collection in envido_dl database based on the 
					
    USE:            EXEC dbo.pr_LinkCreateEnvidoDLCollection
					
    REVISIONS:		10/12/2021	DJF			Created

					 			
   ========================================================================================*/


CREATE PROCEDURE [dbo].[pr_LinkCreateEnvidoDLCollection] 
	
AS
BEGIN

Declare @EnvironmentName nVarChar(max)
exec pr_LinkWhichServer @EnvironmentName OUTPUT

-- Define the specific details for this new data linkage collection being created

-- ######################## Collection details ########################
Declare @CollectionName NVARCHAR(100) = 'BDM'
Declare @Description NVARCHAR(800) = 'Births, Deaths and Marriages'
Declare @Rationale NVARCHAR(800) = 'Data from Births, Deaths and Marriages'
Declare @ToDate datetime = DATEADD(year, 1, getdate())
Declare @type smallint = 0
Declare @addedby int
Declare @lastmodifiedby int
Declare @AccountID varchar(100)

if (@EnvironmentName = 'Development')
	BEGIN
	set @addedby = 1
	set @lastmodifiedby = 1
	set @AccountID = '2344886c-6d2f-443a-abee-93a31d83987b'
	END

if (@EnvironmentName = 'Staging')
	BEGIN
	set @addedby = 1
	set @lastmodifiedby = 1
	set @AccountID = '2344886c-6d2f-443a-abee-93a31d83987b'
	END

if (@EnvironmentName = 'Production')
	BEGIN
	set @addedby = 1
	set @lastmodifiedby = 1
	set @AccountID = '2344886c-6d2f-443a-abee-93a31d83987b'
	END

Declare @CollectionID int = 0
-- Add in the collection details
declare @tc table(CollectionID int)
insert @tc
	exec uspCollection_Add @CollectionName, @Description, @Rationale, @ToDate, @type, @addedby, @lastmodifiedby, @AccountID
select @CollectionID = CollectionID from @tc

-- ######################## tblSet details ########################
Declare @setname nvarchar(100) = 'BDM'
Declare @parentsetId int = null
set @addedby = 1			-- Previously declared
set @lastmodifiedby = 1		-- Previously declared
Declare @AllowOnlyOne bit = 0

Declare @SetID int = 0
-- Add in the set details
declare @ts table(SetID int)
insert @ts
	exec uspSet_Add @setname, @collectionid, @parentsetId, @addedby, @lastmodifiedby, @AllowOnlyOne
select @SetID = SetID from @ts

-- ######################## tblQuestion details ########################
Declare @TableName nVarChar(max) = 'tblLinkStagingBDM'
Declare @Column_Name nVarChar(max) = ''
Declare @Column_Type nVarChar(max) = ''
Declare @Column_Length nVarChar(max) = ''

Declare @questiontext nvarchar(max)
Declare @questionTypeid int
Declare @defaultvalue nvarchar(255) = null
Declare @sequence int = 0
set @addedby = 1			-- Previously declared
Declare @ispublished bit = 1
Declare @isfilter bit = 0
Declare @isrequired bit = 0
Declare @tooltip nvarchar(max) = ''
Declare @quecode nvarchar(50)
Declare @validation nvarchar(50) = ''
Declare @value1 nvarchar(50) = ''
Declare @value2 nvarchar(50) = ''
Declare @IsDisplayInTable bit = 0
Declare @NoOfCol int = null
Declare @UnitID int = null
Declare @Formula nvarchar(max) = null
Declare @ConQuestionID int = null
Declare @Operator nvarchar(50) = null
Declare @CompareValue nvarchar(250) = null
Declare @OtherText bit = null
Declare @ConQuestionTypeID int = null
Declare @DateConditionOperator nvarchar(50) = null
Declare @SSRSReportID int = null
Declare @Format varchar(50) = ''
Declare @IsNumericOptions bit = 0
Declare @CalculationType bit = 0
Declare @Interval nvarchar(20) = null
Declare @DisplayOnLightBox bit = 0
Declare @ValidForCurrentDate bit = 0
set @Rationale = ''				-- Previously declared
Declare @IsComplianceReport bit = 0
Declare @IsTrackStatus bit = 0
Declare @AllowedExt nvarchar(200) = null
Declare @IsInline bit = 0
Declare @IsQuestionOnly bit = 0
Declare @IsInlineNew varchar(5) = null

DECLARE InformationSchemaSearch CURSOR FOR select column_name, data_type, character_maximum_length from INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @TableName
OPEN InformationSchemaSearch
FETCH NEXT FROM InformationSchemaSearch INTO @Column_Name, @Column_Type, @Column_Length
WHILE @@FETCH_STATUS = 0  
	BEGIN
	if (@Column_Name != 'AnswerSetID')
		begin
		if (@Column_Length is null)
			print @Column_Name + ', ' + @Column_Type + ', null'
		else
			print @Column_Name + ', ' + @Column_Type + ', ' + @Column_Length

		if (@Column_Type = 'int') set @questionTypeid = 7			-- Number
		if (@Column_Type = 'nvarchar') set @questionTypeid = 5		-- Text box
		if (@Column_Type = 'date') set @questionTypeid = 9			-- Date
		if (@Column_Type = 'smalldatetime') set @questionTypeid = 9	-- Date

		set @sequence = @sequence + 2

		set @quecode = REPLACE(REPLACE(@Column_Name, ' ', ''), '-','')
		if (LEN(@quecode) > 50) set @quecode = SUBSTRING(@quecode, 1, 50)

		if (@questionTypeID = 5)
			BEGIN
			set @validation = 'MaxLength'
			set @value1 = @Column_Length
			END

		exec uspQuestion_Add @Column_Name, @questionTypeid, @setid, @defaultvalue, @sequence, @addedBy, @ispublished, @isfilter, @isrequired, @tooltip, @quecode,
							 @validation, @value1, @value2, @IsDisplayInTable, @NoOfCol, @UnitID, @Formula, @ConQuestionID, @Operator, @CompareValue, @OtherText,
							 @ConQuestionTypeID, @DateConditionOperator, @SSRSReportID, @Format, @IsNumericOptions, @CalculationType, @Interval, @DisplayOnLightBox,
							 @ValidForCurrentDate, @Rationale, @IsComplianceReport, @IsTrackStatus, @AllowedExt, @IsInline, @IsQuestionOnly, @IsInlineNew
		end

	FETCH NEXT FROM InformationSchemaSearch INTO @Column_Name, @Column_Type, @Column_Length
	END  

CLOSE InformationSchemaSearch
DEALLOCATE InformationSchemaSearch

-- Add in the ProcessedFlag
exec uspQuestion_Add 'ProcessedFlag', 1, @setid, @defaultvalue, @sequence, @addedBy, @ispublished, @isfilter, @isrequired, @tooltip, @quecode,
					 @validation, '', '', 1, @NoOfCol, @UnitID, @Formula, @ConQuestionID, @Operator, @CompareValue, @OtherText,
					 @ConQuestionTypeID, @DateConditionOperator, @SSRSReportID, @Format, @IsNumericOptions, @CalculationType, @Interval, @DisplayOnLightBox,
					 @ValidForCurrentDate, @Rationale, @IsComplianceReport, @IsTrackStatus, @AllowedExt, @IsInline, @IsQuestionOnly, @IsInlineNew
END			 