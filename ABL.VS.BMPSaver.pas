unit ABL.VS.BMPSaver;

interface

uses
  ABL.Core.DirectThread, Graphics, Windows, ABL.Core.BaseQueue, ABL.VS.VSTypes, SysUtils,
  Classes, ABL.Core.ThreadQueue;

type
  TBMPFileHeader = Packed record
    bfType: Word;         // 0x4d42 | 0x4349 | 0x5450
    bfSize: integer;         // размер файла
    bfReserved: integer;     // 0
    bfOffBits: integer;      // смещение до поля данных,
  end;

  TBMPHeader = record
    biSize: DWORD;
    biWidth: Longint;
    biHeight: Longint;
    biPlanes: Word;
    biBitCount: Word;
    biCompression: DWORD;
    biSizeImage: DWORD;
    biXPelsPerMeter: Longint;
    biYPelsPerMeter: Longint;
    biClrUsed: DWORD;
    biClrImportant: DWORD;
  end;

  PSaveInstruction=^TSaveInstruction;
  TSaveInstruction=record
    FileName: TFileName;
    ImageDataHeader: PImageDataHeader;
  end;

  TBMPSaver=class(TDirectThread)
  private
  protected
    procedure DoExecute(var AInputData: Pointer; var AResultData: Pointer); override;
  public
    constructor Create(AInputQueue: TBaseQueue; AName: string = ''); reintroduce;
    procedure SaveAsBmp(ImageDataHeader: PImageDataHeader; FileName: TFileName);
  end;

procedure ABLSaveAsBMP(ImageDataHeader: PImageDataHeader; FileName: TFileName);

implementation

var
  DebugBMPSaver: TBMPSaver;

procedure ABLSaveAsBMP(ImageDataHeader: PImageDataHeader; FileName: TFileName);
begin
  if not assigned(DebugBMPSaver) then
    DebugBMPSaver:=TBMPSaver.Create(TThreadQueue.Create('DebugBMPSaver'));
  DebugBMPSaver.SaveAsBmp(ImageDataHeader,FileName);
end;

{ TBMPSaver }

constructor TBMPSaver.Create(AInputQueue: TBaseQueue; AName: string);
begin
  inherited Create(AInputQueue,nil,AName);
  Start;
end;

procedure TBMPSaver.DoExecute(var AInputData, AResultData: Pointer);
var
  SaveInstruction: PSaveInstruction;
  aw3: integer;
  BMPHeader: TBMPHeader;
  BMPFileHeader: TBMPFileHeader;
  row,q: integer;
  FileStream: TFileStream;
  buf: array of byte;
  ByteArray: PByteArray;
begin
  SaveInstruction:=AInputData;
  //выровненная длина строки
  aw3:=SaveInstruction.ImageDataHeader.Width*3;
  while (aw3 mod 4)>0 do
    Inc(aw3);
  FillChar(BMPHeader,SizeOf(TBMPHeader),0);
  // заполняем заголовок файла
  BMPFileHeader.bfType:=$4D42;	// 'BM'
  BMPFileHeader.bfSize:=SizeOf(TBMPFileHeader)+SizeOf(TBMPHeader)+aw3*SaveInstruction.ImageDataHeader.Height;
  BMPFileHeader.bfReserved:=0;
  BMPFileHeader.bfOffBits:=SizeOf(TBMPFileHeader)+SizeOf(TBMPHeader);
  // заполняем заголовок картинки
  BMPHeader.biPlanes:=1;
  BMPHeader.biSize:=SizeOf(TBMPHeader);
  BMPHeader.biWidth:=SaveInstruction.ImageDataHeader.Width;
  BMPHeader.biHeight:=SaveInstruction.ImageDataHeader.Height;
  BMPHeader.biBitCount:=24;
  BMPHeader.biCompression:=0;
  if FileExists(SaveInstruction.FileName) then
    DeleteFile(SaveInstruction.FileName);
  FileStream:=TFileStream.Create(SaveInstruction.FileName,fmCreate);
  try
    //пишем заголовок
    FileStream.Write(BMPFileHeader,SizeOf(TBMPFileHeader));
    FileStream.Write(BMPHeader,SizeOf(TBMPHeader));
    //буфер пикселей
    SetLength(buf,aw3);
    FillChar(buf[0],aw3,0);
    if SaveInstruction.ImageDataHeader.FlipMarker then
      // сначала нижняя строка
      row:=SaveInstruction.ImageDataHeader.Height-1
    else
      // сначала верхняя строка
      row:=0;
    ByteArray:=SaveInstruction.ImageDataHeader.Data;
    for q := 0 to SaveInstruction.ImageDataHeader.Height-1 do
    begin
      Move(ByteArray[row*SaveInstruction.ImageDataHeader.Width*3],buf[0],SaveInstruction.ImageDataHeader.Width*3);
      FileStream.Write(buf[0],length(buf));
      if SaveInstruction.ImageDataHeader.FlipMarker then
        Dec(row)
      else
        Inc(row);
    end;
  finally
    FileStream.Free;
  end;
end;

procedure TBMPSaver.SaveAsBmp(ImageDataHeader: PImageDataHeader; FileName: TFileName);
var
  SaveInstruction: PSaveInstruction;
  tmpData: Pointer;
begin
   New(SaveInstruction);
   SaveInstruction.FileName:=FileName;
   GetMem(tmpData,ImageDataHeader.TimedDataHeader.DataHeader.Size);
   Move(ImageDataHeader^,tmpData^,ImageDataHeader.TimedDataHeader.DataHeader.Size);
   SaveInstruction.ImageDataHeader:=tmpData;
   FInputQueue.Push(SaveInstruction);
end;

end.
