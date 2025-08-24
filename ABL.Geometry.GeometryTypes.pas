unit ABL.Geometry.GeometryTypes;

interface

uses
  Types, Math, SysUtils, ABL.IO.IOTypes;

const
  BradisSin: array[0..90] of Single = (
    //  1          2          3          4          5          6          7          8          9          10
    0,0.01745241,0.03489950,0.05233596,0.06975647,0.08715574,0.10452846,0.12186934,0.13917310,0.15643447,0.17364818,
      0.19080900,0.20791169,0.22495105,0.24192190,0.25881905,0.27563736,0.29237170,0.30901699,0.32556815,0.34202014,
      0.35836795,0.37460659,0.39073113,0.40673664,0.42261826,0.43837115,0.45399050,0.46947156,0.48480962,0.50000000,
      0.51503807,0.52991926,0.54463904,0.55919290,0.57357644,0.58778525,0.60181502,0.61566148,0.62932039,0.64278761,
      0.65605903,0.66913061,0.68199836,0.69465837,0.70710678,0.71933980,0.73135370,0.74314483,0.75470958,0.76604444,
      0.77714596,0.78801075,0.79863551,0.80901699,0.81915204,0.82903757,0.83867057,0.84804810,0.85716730,0.86602540,
      0.87461971,0.88294759,0.89100652,0.89879405,0.90630779,0.91354546,0.92050485,0.92718385,0.93358043,0.93969262,
      0.94551858,0.95105652,0.95630476,0.96126170,0.96592583,0.97029573,0.97437006,0.97814760,0.98162718,0.98480775,
      0.98768834,0.99026807,0.99254615,0.99452190,0.99619470,0.99756405,0.99862953,0.99939083,0.99984770,1.00000000
  );

type
  TABLGeometryType = (gtPoint, gtPolyline, gtContour, gtFilled, gtPoint3D);

  PVertex=^TVertex;
  TVertex=record
    x,y,z: Single;
    function Distance(P2: TVertex): Single;
    function ToString: string;
  end;

  PBox=^TBox;
  TBox=record
    FromPoint: TVertex;
    ToPoint: TVertex;
    function Center: TVertex;
  end;

  PGeometryDataHeader=^TGeometryDataHeader;
  TGeometryDataHeader=record
    TimedDataHeader: TTimedDataHeader;
    Rect: TRect;
    GeometryType: TABLGeometryType;
    Reserved0: byte;
    Reserved1: word;
    Count: Cardinal;
    function Data: Pointer;
    procedure Init;
  end;

  PPointArray = ^TPointArray;
  TPointArray = array [0..0] of TPoint;

  PVertexArray = ^TVertexArray;
  TVertexArray = array [0..0] of TVertex;

implementation

{ TVertex }

function TVertex.Distance(P2: TVertex): Single;
begin
  result:=Sqrt(Power(x-P2.x,2)+Power(y-P2.y,2)+Power(z-P2.z,2));
end;

function TVertex.ToString: string;
begin
  result:=IntToStr(x)+':'+IntToStr(y)+':'+IntToStr(z);
end;

{ TBox }

function TBox.Center: TVertex;
begin
  Result.x:=(FromPoint.x+ToPoint.x)/2;
  Result.y:=(FromPoint.y+ToPoint.y)/2;
  Result.z:=(FromPoint.z+ToPoint.z)/2;
end;

{ TGeometryDataHeader }

function TGeometryDataHeader.Data: Pointer;
begin
  result:=Pointer(NativeUInt(@Self)+SizeOf(TGeometryDataHeader));
end;

procedure TGeometryDataHeader.Init;
var
  Points: PPointArray;
  q: integer;
  Vertexes: PVertexArray;
begin
  TimedDataHeader.Init;
  TimedDataHeader.DataHeader.DataType:=3;
  if GeometryType<gtPoint3D then
  begin
    Points:=Data;
    if Count=0 then
    begin
      Rect.Left:=0;
      Rect.Top:=0;
      Rect.Right:=0;
      Rect.Bottom:=0;
    end
    else
    begin
      Rect.Left:=Points[0].x;
      Rect.Top:=Points[0].y;
      Rect.Right:=Points[0].x;
      Rect.Bottom:=Points[0].y;
      for q := 1 to Count-1 do
      begin
        if Points[q].x<Rect.Left then
          Rect.Left:=Points[q].x
        else if Points[q].x>Rect.Right then
          Rect.Right:=Points[q].x;
        if Points[q].y<Rect.Top then
          Rect.Top:=Points[q].y
        else if Points[q].y>Rect.Bottom then
          Rect.Bottom:=Points[q].y;
      end;
    end;
  end
  else
  begin
    Vertexes:=Data;
    if Count=0 then
    begin
      Rect.Left:=0;
      Rect.Top:=0;
      Rect.Right:=0;
      Rect.Bottom:=0;
    end
    else
    begin
      Rect.Left:=Vertexes[0].x;
      Rect.Top:=Vertexes[0].y;
      Rect.Right:=Vertexes[0].x;
      Rect.Bottom:=Vertexes[0].y;
      for q := 1 to Count-1 do
      begin
        if Vertexes[q].x<Rect.Left then
          Rect.Left:=Vertexes[q].x
        else if Vertexes[q].x>Rect.Right then
          Rect.Right:=Vertexes[q].x;
        if Vertexes[q].y<Rect.Top then
          Rect.Top:=Vertexes[q].y
        else if Vertexes[q].y>Rect.Bottom then
          Rect.Bottom:=Vertexes[q].y;
      end
    end;
  end;
end;

end.
