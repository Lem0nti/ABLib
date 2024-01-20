unit ABL.Core.CoreTypes;

interface

type
  PDataHeader=^TDataHeader;
  TDataHeader=record
    Magic: Word;     //������ ������ ���� ����� 16961
    Version: byte;   //0
    DataType: byte;  //0 ��� TDataHeader
    Size: Cardinal;  //������ ������ ������ � ����������
  end;

  TData=record
    DataHeader: TDataHeader;
    Data: Pointer;
  end;

implementation

end.
