USE [envido_dl]

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'U' AND name = 'tblLinkImportMappingFields')
DROP TABLE [tblLinkImportMappingFields]

SET ANSI_NULLS ON


SET QUOTED_IDENTIFIER ON

CREATE TABLE [dbo].[tblLinkImportMappingFields](
	[ImportMappingID] [int] IDENTITY(1,1) NOT NULL,
	[ImportTableMappingID] [int] NOT NULL,
	[SourceField] [nvarchar](50) NOT NULL,
	[IncludeField] int NOT NULL,
	[FieldInSourceFile] [bit] NOT NULL,
	[DefaultDestAnswersOptionID] [int] NULL,
	[DefaultDestValue]  [nvarchar](max) NULL,
	[DestCollectionID] [int] NOT NULL,
	[DestSetID] [int] NOT NULL,
	[DestQuestionID] [int] NOT NULL,
	[DestQuestionText] [nvarchar](50) NOT NULL,
	[DestQuestionType] [int] NOT NULL,
	[IsPivotKey] [int] NULL,
	[IsConcatinated] [int] NULL,
	[InObservationValue] [int] NULL,
	[Sequence] [int] NULL,
 CONSTRAINT [PK_DlImportMapping] PRIMARY KEY CLUSTERED 
(
	[ImportMappingID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]


SET IDENTITY_INSERT [dbo].[tblLinkImportMappingFields] ON  
-- get the data from DEV to insert here

SET IDENTITY_INSERT [dbo].[tblLinkImportMappingFields] OFF

