USE [envido_dl]
GO

IF EXISTS (select * FROM sys.objects WHERE type = 'P' AND name = 'pr_LinkStagingBDM')
DROP PROCEDURE [pr_LinkStagingBDM]

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*=========================================================================================
    DESCRIPTION:	Process raw BDM data into a consumable data for systems that need DBM data.
					Moves the data from tblLinkLandBDM to tblLinkStagingBDM

	USE:			EXEC pr_LinkStagingBDM
    
	PARAMETERS:		 

    REVISIONS:		09/12/2021	DJF		Created - Taken from pr_StagingBDMToLanding

-- ========================================================================================*/

CREATE PROCEDURE [dbo].[pr_LinkStagingBDM]  
	   	
AS
BEGIN

insert into tblLinkStagingBDM (	[Registration number], [Surname], [Given names], [Sex], [Date of death], [Place of death - line 1], [Place of death - line 2],
								[Date of birth], [Age at death], [Age at death units], [Place of birth], [Occupation], [Address - line 1], [Address - line 2],
								[Aboriginal indicator], [TSI indicator], [Marital status], 
								[Marriage 1 - date of marriage indicator], [Marriage 1 - date of marriage], [Marriage 1 - age at marriage indicator], [Marriage 1 - age at marriage],
								[Marriage 2 - date of marriage indicator], [Marriage 2 - date of marriage], [Marriage 2 - age at marriage indicator], [Marriage 2 - age at marriage],
								[Marriage 3 - date of marriage indicator], [Marriage 3 - date of marriage], [Marriage 3 - age at marriage indicator], [Marriage 3 - age at marriage],
								[Coroner indicator], [Coroner name], [Coroner address 1], [Coroner address 2],
								[Cause of death 1 - cause], [Cause of death 1 - duration], [Cause of death 1 - duration units],
								[Cause of death 2 - cause], [Cause of death 2 - duration], [Cause of death 2 - duration units],
								[Cause of death 3 - cause], [Cause of death 3 - duration], [Cause of death 3 - duration units],
								[Cause of death 4 - cause], [Cause of death 4 - duration], [Cause of death 4 - duration units],
								[Cause of death 5 - cause], [Cause of death 5 - duration], [Cause of death 5 - duration units],
								[Cause of death 6 - cause], [Cause of death 6 - duration], [Cause of death 6 - duration units],
								[Cause of death 7 - cause], [Cause of death 7 - duration], [Cause of death 7 - duration units],
								[ImportedDateTime], [Father Surname], [Father Given Name], [Mother Surname], [Mother Given Name])

	Select	[Registration number], [Surname], [Given names], [Sex], [Date of death], [Place of death - line 1], [Place of death - line 2], [Date of birth], 
			[Age at death], [Age at death units], [Place of birth], [Occupation], [Address - line 1], [Address - line 2],
			[Aboriginal indicator], [TSI indicator], [Marital status],
			[Marriage 1 - date of marriage indicator], [Marriage 1 - date of marriage], [Marriage 1 - age at marriage indicator], [Marriage 1 - age at marriage],
			[Marriage 2 - date of marriage indicator], [Marriage 2 - date of marriage], [Marriage 2 - age at marriage indicator], [Marriage 2 - age at marriage],
			[Marriage 3 - date of marriage indicator], [Marriage 3 - date of marriage], [Marriage 3 - age at marriage indicator], [Marriage 3 - age at marriage],
			[Coroner indicator], [Coroner name], [Coroner address 1], [Coroner address 2],
			[Cause of death 1 - cause], [Cause of death 1 - duration], [Cause of death 1 - duration units],
			[Cause of death 2 - cause], [Cause of death 2 - duration], [Cause of death 2 - duration units],
			[Cause of death 3 - cause], [Cause of death 3 - duration], [Cause of death 3 - duration units],
			[Cause of death 4 - cause], [Cause of death 4 - duration], [Cause of death 4 - duration units],
			[Cause of death 5 - cause], [Cause of death 5 - duration], [Cause of death 5 - duration units],
			[Cause of death 6 - cause], [Cause of death 6 - duration], [Cause of death 6 - duration units],
			[Cause of death 7 - cause], [Cause of death 7 - duration], [Cause of death 7 - duration units],
			[ImportedDateTime], [Father Surname], [Father Given Name], [Mother Surname], [Mother Given Name]
		from tblLinkLandBDM
			where [Sex] = 'M'
			and CONVERT(datetime,[Date of death]) >= '1998-01-01'
			and [Registration number] NOT IN (SELECT [Registration number] FROM dbo.tblLinkStagingBDM)

	
END
