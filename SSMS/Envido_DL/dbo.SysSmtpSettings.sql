USE [envido_dl]
GO
/****** Object:  Table [dbo].[SysSmtpSettings]    Script Date: 16/11/2021 3:17:27 PM ******/
DROP TABLE [dbo].[SysSmtpSettings]
GO
/****** Object:  Table [dbo].[SysSmtpSettings]    Script Date: 16/11/2021 3:17:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SysSmtpSettings](
	[DBServer] [varchar](100) NOT NULL,
	[AccountProfile] [varchar](100) NOT NULL,
	[FromAddress] [varchar](100) NOT NULL
) ON [PRIMARY]
GO
INSERT [dbo].[SysSmtpSettings] ([DBServer], [AccountProfile], [FromAddress]) VALUES (N'HLT439SQL014', N'PCCOC', N'DLDatabase.Notification@sa.gov.au')
GO
