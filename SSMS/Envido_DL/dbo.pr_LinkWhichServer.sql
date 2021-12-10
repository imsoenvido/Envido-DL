use envido_dl

GO

IF EXISTS (select * FROM sys.objects WHERE type = 'P' AND name = 'pr_LinkWhichServer')
DROP PROCEDURE [pr_LinkWhichServer]


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*=========================================================================================
    DESCRIPTION:	Determines which server we are running on
	
	USE:			EXEC pr_LinkWhichServer @EnvironmentName
    
    REVISIONS:		10/12/2021	DJF		Created 

-- ========================================================================================*/

CREATE PROCEDURE [dbo].[pr_LinkWhichServer]  
	   	@EnvironmentName nVarChar(max) OUTPUT
AS
BEGIN

declare @ServerName nVarChar(max)
SELECT @ServerName=@@SERVERNAME

if @ServerName='HLT142SQL034'
	set @EnvironmentName = 'Production'
if @ServerName='HLT439SQL014'
	set @EnvironmentName = 'Staging'
if @ServerName='HLT439SQL014\dev'
	set @EnvironmentName = 'Development'

END
