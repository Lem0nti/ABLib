object MainFM: TMainFM
  Left = 0
  Top = 0
  Caption = #1044#1077#1084#1086' ABLib'
  ClientHeight = 408
  ClientWidth = 635
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object PageControl: TPageControl
    Left = 0
    Top = 0
    Width = 635
    Height = 408
    ActivePage = tsVS_Render
    Align = alClient
    TabOrder = 0
    object tsCore: TTabSheet
      Caption = 'Core'
      object bCreate: TButton
        Left = 16
        Top = 8
        Width = 153
        Height = 25
        Caption = #1057#1086#1079#1076#1072#1090#1100' '#1085#1072#1073#1086#1088' '#1082#1083#1072#1089#1089#1086#1074
        TabOrder = 0
        OnClick = bCreateClick
      end
      object mCoreLog: TMemo
        Left = 184
        Top = 10
        Width = 432
        Height = 356
        Align = alCustom
        Anchors = [akLeft, akTop, akRight, akBottom]
        ScrollBars = ssVertical
        TabOrder = 1
      end
      object bSend: TButton
        Left = 16
        Top = 48
        Width = 153
        Height = 25
        Caption = #1054#1090#1087#1088#1072#1074#1080#1090#1100' 100 '#1089#1086#1086#1073#1097#1077#1085#1080#1081
        TabOrder = 2
        OnClick = bSendClick
      end
    end
    object tsIO: TTabSheet
      Caption = 'IO'
      ImageIndex = 1
      object mIOLog: TMemo
        Left = 192
        Top = 18
        Width = 432
        Height = 356
        Align = alCustom
        Anchors = [akLeft, akTop, akRight, akBottom]
        ScrollBars = ssVertical
        TabOrder = 0
      end
      object leText: TLabeledEdit
        Left = 11
        Top = 32
        Width = 166
        Height = 21
        EditLabel.Width = 30
        EditLabel.Height = 13
        EditLabel.Caption = 'leText'
        TabOrder = 1
      end
      object bSendTCP: TButton
        Left = 11
        Top = 72
        Width = 166
        Height = 25
        Caption = 'bSendTCP'
        TabOrder = 2
        OnClick = bSendTCPClick
      end
    end
    object tsVS_Render: TTabSheet
      Caption = 'VS + Render + IA'
      ImageIndex = 2
      object pnlVideo: TPanel
        Left = 16
        Top = 56
        Width = 593
        Height = 310
        Align = alCustom
        Anchors = [akLeft, akTop, akRight, akBottom]
        Caption = 'pnlVideo'
        TabOrder = 0
        OnResize = pnlVideoResize
        object pnlLeftTop: TPanel
          Left = 0
          Top = 0
          Width = 185
          Height = 41
          Caption = 'pnlLeftTop'
          TabOrder = 0
        end
        object pnlRightTop: TPanel
          Left = 328
          Top = 0
          Width = 185
          Height = 41
          Caption = 'pnlRightTop'
          TabOrder = 1
        end
        object pnlLeftBottom: TPanel
          Left = 0
          Top = 200
          Width = 185
          Height = 41
          Caption = 'pnlLeftBottom'
          TabOrder = 2
        end
        object pnlRightBottom: TPanel
          Left = 368
          Top = 208
          Width = 185
          Height = 41
          Caption = 'pnlRightBottom'
          TabOrder = 3
        end
      end
      object leRTSPLink: TLabeledEdit
        Left = 88
        Top = 16
        Width = 440
        Height = 21
        EditLabel.Width = 71
        EditLabel.Height = 13
        EditLabel.Caption = 'RTSP '#1089#1089#1099#1083#1082#1072': '
        LabelPosition = lpLeft
        TabOrder = 1
        Text = 'rtsp://admin:a0w2j5b61!@192.168.2.3:554/stream1'
        OnKeyDown = leRTSPLinkKeyDown
      end
      object bGo: TBitBtn
        Left = 534
        Top = 14
        Width = 75
        Height = 25
        Caption = #1047#1072#1093#1074#1072#1090
        TabOrder = 2
        OnClick = bGoClick
      end
    end
  end
  object IdTCPClient: TIdTCPClient
    ConnectTimeout = 0
    Host = '127.0.0.1'
    IPVersion = Id_IPv4
    Port = 12345
    ReadTimeout = -1
    Left = 36
    Top = 24
  end
end
