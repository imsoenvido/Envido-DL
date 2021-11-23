USE [envido_dl]
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'U' AND name = 'tblLinkImportMappingTable')
DROP TABLE [tblLinkImportMappingTable]

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[tblLinkImportMappingTable](
	ImportTableMappingID int identity(1,1) NOT NULL
	,SourceDatabase varchar (50) NOT NULL 
	,SourceTable varchar (50) NOT NULL 
	,DestDatabase varchar (50) NOT NULL 
	,DestCollectionId int NOT NULL 
	,DefaultGroupID int NULL
	,DefaultUserID int NULL
	,CreateSourceAnswerSetIDs int 
	,ImportStoredProcedure varchar (50) NULL
)

insert into [tblLinkImportMappingTable] (SourceDatabase,SourceTable,DestDatabase,DestCollectionId,DefaultGroupID,DefaultUserID,CreateSourceAnswerSetIDs, ImportStoredProcedure) VALUES ('envido_dl','tblLinkStagingNotificationCapDetail','envido_dl',1,1,17,1,NULL)
insert into [tblLinkImportMappingTable] (SourceDatabase,SourceTable,DestDatabase,DestCollectionId,DefaultGroupID,DefaultUserID,CreateSourceAnswerSetIDs, ImportStoredProcedure) VALUES ('envido_dl','tblLinkStagingProvation','envido_dl',2,2,17,1,'pr_LinkStagingProvation')
insert into [tblLinkImportMappingTable] (SourceDatabase,SourceTable,DestDatabase,DestCollectionId,DefaultGroupID,DefaultUserID,CreateSourceAnswerSetIDs, ImportStoredProcedure) VALUES ('envido_dl','tblLinkStagingProvation','envido',93,2,17,0,NULL)

