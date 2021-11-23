USE [envido_dl]
GO

IF EXISTS (select * FROM sys.objects WHERE type = 'P' AND name = 'pr_LinkStagingCancerNotification')
DROP PROCEDURE [pr_LinkStagingCancerNotification]

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*=========================================================================================
    DESCRIPTION:	Process raw Cancer notification data into a consumable data for systems
					that need cancer notification data.
					Moves the data from tblLinkLandCancerNotification to tblLinkStagingCancerNotification

	USE:			EXEC pr_LinkStagingCancerNotification
    
	PARAMETERS:		 

    REVISIONS:		06/08/2021	DJF		Created - Taken from pr_StagingNotificationToLanding

-- ========================================================================================*/


CREATE PROCEDURE [dbo].[pr_LinkStagingCancerNotification]  
	   	
AS
BEGIN

	-- First remove any duplicates that have come across from the source file. This doesn't happen often but it can occur
	
	IF OBJECT_ID('tempdb..#F') IS NOT NULL DROP TABLE #F
	SELECT	soundex(ltrim(Rtrim([Provider]))) +'-'+ltrim(Rtrim(LabReportID)) +'-'+ soundex(ltrim(rtrim(Last_name))) as NewSourceRecordKey
			,SourceRecordKey
			,ltrim(Rtrim([Provider])) as [Provider],LabReportID,ServiceDate,Title,First_Name,Last_name,DoB,Gender,Address,Suburb,Postcode,GP_First_Name,GP_Last_Name,GP_ProviderNumber
			,ObservationValue,DATEADDED,RequestDate 
			,RowID
		INTO	#F
		FROM	(
				SELECT	ROW_NUMBER () OVER (PARTITION BY LTRIM(RTRIM(LabReportID)) + '-' + LEFT(REPLACE(ServiceDate,'-',''),8)  + '-' + SOUNDEX(LTRIM(RTRIM(Last_name)))  ORDER BY last_name,servicedate) as RowID
						,LTRIM(RTRIM(LabReportID)) + '-' + LEFT(REPLACE(ServiceDate,'-',''),8)  + '-' + SOUNDEX(LTRIM(RTRIM(Last_name))) as SourceRecordKey
						,*
				FROM	dbo.tblLinkLandCancerNotification
				WHERE	Gender = 'M'
				) as X
		Where X.RowID = 1

	-- Reload the landing data

	TRUNCATE TABLE dbo.tblLinkLandCancerNotification
	
	INSERT INTO dbo.tblLinkLandCancerNotification (NewSourceRecordKey,[Provider],LabReportID,ServiceDate,Title,First_Name,Last_name,DoB,Gender,[Address],Suburb,Postcode,
													  GP_First_Name,GP_Last_Name,GP_ProviderNumber,ObservationValue,DATEADDED,RequestDate)
			SELECT	NewSourceRecordKey,Provider,LabReportID,ServiceDate,Title,First_Name,Last_name,DoB,Gender,[Address],Suburb,Postcode,GP_First_Name,
					GP_Last_Name,GP_ProviderNumber,ObservationValue,DATEADDED,RequestDate
			FROM #F
	
	-- Begin the process of moving the source records in into the staging table

	IF OBJECT_ID('tempdb..#X') IS NOT NULL DROP TABLE #X
    SELECT  NewSourceRecordKey = soundex(ltrim(Rtrim([Provider]))) +'-'+ltrim(Rtrim(LabReportID)) +'-'+ soundex(ltrim(rtrim(Last_name))) 
		INTO    #X
		FROM    dbo.tblLinkStagingCancerNotification


    INSERT INTO dbo.tblLinkStagingCancerNotification (
			SourceKey, [Provider],LabReportID,ServiceDate,RequestDate,ResultDate
			,Title,First_Name,Last_name,DOB,Gender
			,[Address],Suburb,Postcode
			,GP_First_Name,GP_Last_Name,GP_ProviderNumber, ReferringDoctorUnmapped
			,ObservationValue
    ) 
    SELECT  NewSourceRecordKey,
			LTRIM(RTRIM([Provider]))
            ,LTRIM(RTRIM(LabReportID))
            ,LTRIM(RTRIM(ServiceDate))
            ,RequestDate
			,RequestDate
            ,LTRIM(RTRIM(Title))
            ,LTRIM(RTRIM(First_Name))
            ,LTRIM(RTRIM(Last_name))
            ,LTRIM(RTRIM(DoB))
            ,LTRIM(RTRIM(Gender))
            ,LTRIM(RTRIM([Address]))
            ,LTRIM(RTRIM(Suburb))
            ,LTRIM(RTRIM(Postcode))
            ,LTRIM(RTRIM(GP_First_Name))
            ,LTRIM(RTRIM(GP_Last_Name))
			,LTRIM(RTRIM(GP_ProviderNumber))
			,case when Ltrim(rtrim(GP_Last_Name)) <> '' and ltrim(rtrim(GP_First_Name)) <> ''
						then Upper(ltrim(rtrim(GP_Last_name))) +'- '+ upper(ltrim(Rtrim(GP_First_name))) 
						else ''
					end
            ,LTRIM(RTRIM(ObservationValue))
    FROM    dbo.tblLinkLandCancerNotification
    WHERE	NewSourceRecordKey not in (SELECT NewSourceRecordKey FROM #X)

    -- CLEAN UP 
    DROP TABLE #F
    DROP TABLE #X
	
END
