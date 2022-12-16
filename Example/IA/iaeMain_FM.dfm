object MinFM: TMinFM
  Left = 0
  Top = 0
  Caption = 'MinFM'
  ClientHeight = 299
  ClientWidth = 635
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object pnlLeft: TPanel
    Left = 0
    Top = 29
    Width = 185
    Height = 270
    Align = alLeft
    Caption = 'pnlLeft'
    TabOrder = 0
    object pnlLeftTop: TPanel
      Left = 1
      Top = 1
      Width = 183
      Height = 104
      Align = alTop
      Caption = 'pnlLeftTop'
      TabOrder = 0
    end
    object pnlLeftBottom: TPanel
      Left = 1
      Top = 105
      Width = 183
      Height = 164
      Align = alClient
      Caption = 'pnlLeftBottom'
      TabOrder = 1
      ExplicitTop = 42
      ExplicitHeight = 227
    end
  end
  object Panel2: TPanel
    Left = 185
    Top = 29
    Width = 450
    Height = 270
    Align = alClient
    Caption = 'Panel2'
    TabOrder = 1
    object pnlRightTop: TPanel
      Left = 1
      Top = 1
      Width = 448
      Height = 160
      Align = alTop
      Caption = 'pnlRightTop'
      TabOrder = 0
      ExplicitLeft = 5
      ExplicitTop = 2
    end
    object pnlRightBottom: TPanel
      Left = 1
      Top = 161
      Width = 448
      Height = 108
      Align = alClient
      TabOrder = 1
    end
  end
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 635
    Height = 29
    Align = alTop
    Caption = 'pnlTop'
    TabOrder = 2
    object eLink: TEdit
      Left = 85
      Top = 4
      Width = 543
      Height = 21
      Align = alCustom
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
      Text = 'rtsp://admin:a0w2j5b61!@192.168.2.3:554/stream1'
      OnChange = eLinkChange
      OnKeyDown = eLinkKeyDown
    end
    object bGo: TButton
      Left = 4
      Top = 4
      Width = 75
      Height = 21
      Caption = #1057#1090#1072#1088#1090
      TabOrder = 1
      OnClick = bGoClick
    end
  end
end
