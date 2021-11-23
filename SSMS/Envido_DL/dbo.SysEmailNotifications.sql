USE [envido_dl]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'U' AND name = 'SysEmailNotifications')
DROP TABLE [SysEmailNotifications]

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SysEmailNotifications](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Profile] [varchar](max) NOT NULL,
	[HasFile] [int] NOT NULL,
	[Recipients] [varchar](max) NOT NULL,
	[EmailSubject] [varchar](max) NOT NULL,
	[SQlStatement] [varchar](max) NULL,
	[ExculdeQueryOutput] [int] NOT NULL,
	[AttachFile] [smallint] NOT NULL,
	[EmailFileName] [varchar](50) NULL,
	[ResultHeader] [smallint] NOT NULL,
	[ResultSeparator] [varchar](10) NULL,
	[Padding] [smallint] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET IDENTITY_INSERT [dbo].[SysEmailNotifications] ON 
GO
INSERT [dbo].[SysEmailNotifications] ([ID], [Profile], [HasFile], [Recipients], [EmailSubject], [SQlStatement], [ExculdeQueryOutput], [AttachFile], [EmailFileName], [ResultHeader], [ResultSeparator], [Padding]) 
VALUES (1, N'PCCOC', 0, N'scott.walsh@sa.gov.au', N'SSIS-SA-PCCOC-DL SA-PATHOLOGY File Path Error', NULL, 1, 0, NULL, 0, NULL, 1)
GO
INSERT [dbo].[SysEmailNotifications] ([ID], [Profile], [HasFile], [Recipients], [EmailSubject], [SQlStatement], [ExculdeQueryOutput], [AttachFile], [EmailFileName], [ResultHeader], [ResultSeparator], [Padding]) 
VALUES (2, N'PCCOC', 0, N'scott.walsh@sa.gov.au', N'SSIS-SA-PCCOC-DL SA-PATHOLOGY File Name Error', NULL, 1, 0, NULL, 0, NULL, 1)
GO
INSERT [dbo].[SysEmailNotifications] ([ID], [Profile], [HasFile], [Recipients], [EmailSubject], [SQlStatement], [ExculdeQueryOutput], [AttachFile], [EmailFileName], [ResultHeader], [ResultSeparator], [Padding]) 
VALUES (3, N'PCCOC', 0, N'scott.walsh@sa.gov.au', N'SSIS-SA-PCCOC-DL SA-PATHOLOGY  - ERROR IMPORTING DATA TO dbo.StagingSaPathology', NULL, 1, 0, NULL, 0, NULL, 1)
GO
INSERT [dbo].[SysEmailNotifications] ([ID], [Profile], [HasFile], [Recipients], [EmailSubject], [SQlStatement], [ExculdeQueryOutput], [AttachFile], [EmailFileName], [ResultHeader], [ResultSeparator], [Padding]) 
VALUES (4, N'PCCOC', 0, N'scott.walsh@sa.gov.au', N'SSIS-SA-PCCOC-DL eNotification - ERROR IMPORTING DATA TO dbo.StagingNotificationCapDetail', NULL, 1, 0, NULL, 0, NULL, 1)
GO
INSERT [dbo].[SysEmailNotifications] ([ID], [Profile], [HasFile], [Recipients], [EmailSubject], [SQlStatement], [ExculdeQueryOutput], [AttachFile], [EmailFileName], [ResultHeader], [ResultSeparator], [Padding]) 
VALUES (5, N'PCCOC', 0, N'scott.walsh@sa.gov.au', N'SSIS-SA-PCCOC-DL BDM -  File Path Error', NULL, 1, 0, NULL, 0, NULL, 1)
GO
INSERT [dbo].[SysEmailNotifications] ([ID], [Profile], [HasFile], [Recipients], [EmailSubject], [SQlStatement], [ExculdeQueryOutput], [AttachFile], [EmailFileName], [ResultHeader], [ResultSeparator], [Padding]) 
VALUES (6, N'PCCOC', 0, N'scott.walsh@sa.gov.au', N'SSIS-SA-PCCOC-DL BDM File Name Error', NULL, 1, 0, NULL, 0, NULL, 1)
GO
INSERT [dbo].[SysEmailNotifications] ([ID], [Profile], [HasFile], [Recipients], [EmailSubject], [SQlStatement], [ExculdeQueryOutput], [AttachFile], [EmailFileName], [ResultHeader], [ResultSeparator], [Padding]) 
VALUES (7, N'PCCOC', 0, N'scott.walsh@sa.gov.au', N'SSIS-SA-PCCOC-DL BDM SA- ERROR IMPORTING DATA TO dbo.StagingBDM', NULL, 1, 0, NULL, 0, NULL, 1)
GO
INSERT [dbo].[SysEmailNotifications] ([ID], [Profile], [HasFile], [Recipients], [EmailSubject], [SQlStatement], [ExculdeQueryOutput], [AttachFile], [EmailFileName], [ResultHeader], [ResultSeparator], [Padding]) 
VALUES (9, N'PCCOC', 0, N'scott.walsh@sa.gov.au', N'SSIS-SA-PCCOC-DL eNNotification - No entries for 7 days', NULL, 1, 0, NULL, 0, NULL, 1)
GO
INSERT [dbo].[SysEmailNotifications] ([ID], [Profile], [HasFile], [Recipients], [EmailSubject], [SQlStatement], [ExculdeQueryOutput], [AttachFile], [EmailFileName], [ResultHeader], [ResultSeparator], [Padding]) 
VALUES (12, N'PCCOC', 0, N'scott.walsh@sa.gov.au', N'SSIS-SA-PCCOC-DL ARC File Path Error', NULL, 1, 0, NULL, 0, NULL, 1)
GO
INSERT [dbo].[SysEmailNotifications] ([ID], [Profile], [HasFile], [Recipients], [EmailSubject], [SQlStatement], [ExculdeQueryOutput], [AttachFile], [EmailFileName], [ResultHeader], [ResultSeparator], [Padding]) 
VALUES (13, N'PCCOC', 0, N'scott.walsh@sa.gov.au', N'SSIS-SA-PCCOC-DL RAH File Path Error', NULL, 1, 0, NULL, 0, NULL, 1)
GO
INSERT [dbo].[SysEmailNotifications] ([ID], [Profile], [HasFile], [Recipients], [EmailSubject], [SQlStatement], [ExculdeQueryOutput], [AttachFile], [EmailFileName], [ResultHeader], [ResultSeparator], [Padding]) 
VALUES (15, N'PCCOC', 0, N'operations@envido.com.au', N'SSIS-SCOOP-DL PROVATION -  File Path Error', NULL, 1, 0, NULL, 0, NULL, 1)
GO
INSERT [dbo].[SysEmailNotifications] ([ID], [Profile], [HasFile], [Recipients], [EmailSubject], [SQlStatement], [ExculdeQueryOutput], [AttachFile], [EmailFileName], [ResultHeader], [ResultSeparator], [Padding]) 
VALUES (16, N'PCCOC', 0, N'operations@envido.com.au', N'SSIS-SCOOP-DL PROVATION - File Name Error', NULL, 1, 0, NULL, 0, NULL, 1)
GO
INSERT [dbo].[SysEmailNotifications] ([ID], [Profile], [HasFile], [Recipients], [EmailSubject], [SQlStatement], [ExculdeQueryOutput], [AttachFile], [EmailFileName], [ResultHeader], [ResultSeparator], [Padding]) 
VALUES (17, N'PCCOC', 0, N'operations@envido.com.au', N'SSIS-SCOOP-DL PROVATION - ERROR IMPORTING DATA to dbo.Staging', NULL, 1, 0, NULL, 0, NULL, 1)
GO
INSERT [dbo].[SysEmailNotifications] ([ID], [Profile], [HasFile], [Recipients], [EmailSubject], [SQlStatement], [ExculdeQueryOutput], [AttachFile], [EmailFileName], [ResultHeader], [ResultSeparator], [Padding]) 
	VALUES (18, N'PCCOC', 0, N'scott.walsh@sa.gov.au', N'SSIS-SAPCCOC-DL eNotification - ERROR IMPORTING DATA to dbo.Staging', NULL, 1, 0, NULL, 0, NULL, 1)
GO

SET IDENTITY_INSERT [dbo].[SysEmailNotifications] OFF
GO
