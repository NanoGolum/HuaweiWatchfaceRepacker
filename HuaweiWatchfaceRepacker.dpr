program HuaweiWatchfaceRepacker;

{$APPTYPE CONSOLE}
{$R *.res}

uses SysUtils, Windows, Vcl.Graphics, Vcl.Imaging.pngimage, System.UITypes, System.Classes;

type
  TPixel = record
            B: Byte;
            G: Byte;
            R: Byte;
            A: Byte;
           end;
const
 ImageID: array[1..4] of Byte = ($45, $23, $88, $88);
 FAT_ID: array[1..4] of Byte = ($08, $00, $00, $00);
 ConstColorID: TPixel = (B:$89; G:$67; R:$45; A:$23);
 DestinationFileName = 'com.huawei.watchface';

var
 WatchFaceFile: array of Byte;
 WatchFaceFileStream: TBytesStream;
 WatchFaceFileSize: Longword;
 WatchFaceFilePos: Longword;
 FAT_Offset: Longword;
 FAT_Pointer: Longword;
 FAT_Counter: Longword;
 SavePos: Longword;
 V: Longword;
 UnpackDir: String;
 i, w, h: Word;
 PngFilesCount: Word;
 ImageCounter: Word = 0;
 
 CurrentColorCount: Longword = 0;
 CurrentColor: TPixel;

Function ComparePixel(P1, P2: TPixel): Boolean;
begin
  Result := ((P1.R = P2.R) and (P1.G = P2.G) and (P1.B = P2.B) and (P1.A = P2.A));
end;

Procedure CopyPixel(P1: TPixel; var P2: TPixel);
begin
  P2.R := P1.R; P2.G := P1.G; P2.B := P1.B; P2.A := P1.A;
end;
 
Procedure BitmapToPNG(const ABitmap: TBitmap; ImageIndex: Word);
var
  APNG: TPNGImage;
  dStep: Integer;
  p,d,v: PByte;
  x,y: Integer;
begin
  APNG := TPNGImage.Create;
  try
    APNG.Assign(ABitmap);
    APNG.CreateAlpha;
    if ABitmap.PixelFormat = pf32Bit then
    begin
      dStep := BytesPerScanline(ABitmap.Width, 32, 32);
      d := ABitmap.Scanline[0];
       for y := 0 to ABitmap.height-1 do
      begin
        p := PByte(Integer(d) - y*dStep);
        v := @APNG.AlphaScanline[y]^[0];
        for x := 0 to ABitmap.Width-1 do
        begin
          v^ := PRGBQuad(p)^.rgbReserved;
          inc(p, SizeOf(TRGBQuad));
          inc(v);
        end;
      end;
    end;
    APNG.SaveToFile(IntToStr(ImageIndex) + '.png');
   except
    Writeln('Error: Can''t save png');
    FreeAndNil(APNG);
  end;
end;

procedure LoadWatchFaceFile();
var
  FS: TFileStream;
begin
  Writeln('Processing file ' + ParamStr(2));
  try
   FS := TFileStream.Create(ParamStr(2), fmOpenRead);
   WatchFaceFileSize := FS.Size;
   SetLength(WatchFaceFile, WatchFaceFileSize);
   FS.ReadData(WatchFaceFile, WatchFaceFileSize);
  except
   Writeln('Error: Can''t read file');
   Halt;
  end;
  FS.Free;
end;

function Find_Header_FAT_Offset: LongWord;
var
 WatchFaceFilePos: LongWord;
begin
  Result := 0;
  WatchFaceFilePos := 0;
  
  Repeat
   if (WatchFaceFile[WatchFaceFilePos] = FAT_ID[1]) and
      (WatchFaceFile[WatchFaceFilePos+1] = FAT_ID[2]) and
      (WatchFaceFile[WatchFaceFilePos+2] = FAT_ID[3]) and
      (WatchFaceFile[WatchFaceFilePos+3] = FAT_ID[4]) then
      begin
       Inc(WatchFaceFilePos, SizeOf(FAT_ID));
       Result := WatchFaceFilePos;
      end
     else Inc(WatchFaceFilePos);
   Until (WatchFaceFilePos >= Length(WatchFaceFile)-5) or (Result <> 0);
end;

procedure SaveHeader(Offset: LongWord);
var
  FS: TFileStream;
{  WatchFaceFilePos, FileCount, V1, V2: LongWord;
  FAT_Start: Boolean;}
begin
  Writeln('Saving header');
{
    WatchFaceFilePos := 0;
    FileCount := 0;
    FAT_Start := False;

    Repeat
     if (WatchFaceFile[WatchFaceFilePos] = FAT_ID[1]) and
        (WatchFaceFile[WatchFaceFilePos+1] = FAT_ID[2]) and
        (WatchFaceFile[WatchFaceFilePos+2] = FAT_ID[3]) and
        (WatchFaceFile[WatchFaceFilePos+3] = FAT_ID[4]) then
        begin
         Inc(WatchFaceFilePos, SizeOf(FAT_ID));
         FAT_Start := True;
         Writeln('FAT offset: ' + IntToStr(WatchFaceFilePos));
        end
     else Inc(WatchFaceFilePos);
    Until (WatchFaceFilePos >= Offset-5) or FAT_Start;

    if FAT_Start then
     repeat
      Inc(FileCount);
      Move(WatchFaceFile[WatchFaceFilePos], V1, SizeOf(V1));
      Move(WatchFaceFile[WatchFaceFilePos+4], V2, SizeOf(V2));
      Writeln('FAT entry ' + IntToStr(FileCount) + ': ' +
               IntToStr(V1) + ' : ' +
               IntToStr(V2));
      Inc(WatchFaceFilePos, 8); 
     until (WatchFaceFilePos >= Offset-5);
}
  try
   FS := TFileStream.Create('header', fmCreate);
   FS.WriteData(WatchFaceFile, Offset);  
  except
   Writeln('Error: Can''t save header');
   Halt;
  end;

  FS.Free;
end;

function ReadColor(): TPixel;
var
 Dot: TPixel;
 l1, l2, l3, l4: Byte;
begin
 if (currentColorCount > 0) then begin Dec(currentColorCount); Result := currentColor; Exit; end;
 Dot.B := WatchFaceFile[WatchFaceFilePos]; Inc(WatchFaceFilePos);
 Dot.G := WatchFaceFile[WatchFaceFilePos]; Inc(WatchFaceFilePos);
 Dot.R := WatchFaceFile[WatchFaceFilePos]; Inc(WatchFaceFilePos);
 Dot.A := WatchFaceFile[WatchFaceFilePos]; Inc(WatchFaceFilePos);
 if ComparePixel(Dot, ConstColorID) then
  begin
   CurrentColor.B := WatchFaceFile[WatchFaceFilePos]; Inc(WatchFaceFilePos);
   CurrentColor.G := WatchFaceFile[WatchFaceFilePos]; Inc(WatchFaceFilePos);
   CurrentColor.R := WatchFaceFile[WatchFaceFilePos]; Inc(WatchFaceFilePos);
   CurrentColor.A := WatchFaceFile[WatchFaceFilePos]; Inc(WatchFaceFilePos);
   l1 := WatchFaceFile[WatchFaceFilePos]; Inc(WatchFaceFilePos);
   l2 := WatchFaceFile[WatchFaceFilePos]; Inc(WatchFaceFilePos);
   l3 := WatchFaceFile[WatchFaceFilePos]; Inc(WatchFaceFilePos);
   l4 := WatchFaceFile[WatchFaceFilePos]; Inc(WatchFaceFilePos);
   CurrentColorCount := (l4 shl 24) + (l3 shl 16) + (l2 shl 8) + l1 - 1;
   Dot := CurrentColor;
  end;
 Result := Dot;
end;

function SetPngAlphaToBitmap(const AImage: TPngImage;
  const ABitmap: TBitmap): TBitmap;
var
  y,x: Integer;
  start: Integer;
  dst: PRGBQuad;
  src: pByte;
begin
  Result := ABitmap;
  if not Assigned(Result) or (Result.PixelFormat <> pf32bit) or
    (Result.Height < 1) then
    Exit;
 
  AImage.CreateAlpha;
  start := DWORD(Result.ScanLine[0]);
 
  for y := 0 to AImage.Height-1 do
  begin
    if y >= ABitmap.Height then
      Break;
    src := @(AImage.AlphaScanline[y]^[0]);
    dst := PRGBQuad(start - y*Result.Width*4);
    for x := 0 to AImage.Width-1 do
    begin
      if x < ABitmap.Width then
      begin
        dst^.rgbReserved := src^;
        inc(dst)
      end;
      inc(src);
    end;
  end;
end;


procedure SaveImage(ImageIndex: Word; var ImageWidth, ImageHeight: Word);
var
  APNG: TPNGImage;
  Width, Height: Word;
  Pixel: TPixel;
  PixelPtr: PRGBTriple;
  i,j: LongInt;
  AlphaPtr: pByte;
  CurrentColor: TPixel;
  CurrentColorCount: LongWord;
//  F: file;

 procedure SaveColor;
 var k: LongInt;
 begin
   if (CurrentColorCount > 3) then
    begin
     WatchFaceFileStream.Write(ConstColorID, SizeOf(ConstColorID));
     WatchFaceFileStream.Write(CurrentColor, SizeOf(CurrentColor));
     WatchFaceFileStream.Write(CurrentColorCount, SizeOf(CurrentColorCount));
    end
   else
    for k := 1 to CurrentColorCount do WatchFaceFileStream.Write(CurrentColor, SizeOf(CurrentColor));
  end;


begin
  APNG := TPNGImage.Create;
  CurrentColorCount := 1;
  ImageWidth := 0;
  ImageHeight := 0;
//  AssignFile(F, IntToStr(ImageIndex) + '.raw');
//  Rewrite(F, 1);

  try
    APNG.LoadFromFile(IntToStr(ImageIndex) + '.png');
    APNG.CreateAlpha;

    Width := APNG.Width;
    Height := APNG.Height;

    WatchFaceFileStream.Write(ImageID, SizeOf(ImageID));
    WatchFaceFileStream.Write(Width, SizeOf(Width));
    WatchFaceFileStream.Write(Height, SizeOf(Height));

    for i := 0 to Height-1 do
     begin
      PixelPtr := APNG.ScanLine[i];
      AlphaPtr := @(APNG.AlphaScanline[i]^[0]);
      for j := 0 to Width-1 do
       begin
        Pixel.A := AlphaPtr^;
        Pixel.R := PixelPtr^.rgbtRed;
        Pixel.G := PixelPtr^.rgbtGreen;
        Pixel.B := PixelPtr^.rgbtBlue;
        inc(PixelPtr);
        inc(AlphaPtr);

        if ((i=0) and (j=0)) then CopyPixel(Pixel, CurrentColor)
         else
        if ComparePixel(Pixel, CurrentColor) then
          Inc(CurrentColorCount) 
        else
         begin
          SaveColor;
          CopyPixel(Pixel, CurrentColor);
          CurrentColorCount := 1; 
         end;
//        BlockWrite(F, Pixel, SizeOf(Pixel));
       end;
     end;
     SaveColor;
  except
    Writeln('Error: Can''t load png');
    FreeAndNil(APNG);
  end;

  ImageWidth := Width;
  ImageHeight := Height;
//  CloseFile(F);
end;


procedure GetImage(Position: Longword; ImageIndex: Word);
var
//  F: file;
  Width, Height: Word;
  Pixel: TPixel;
  ABitmap: TBitmap;
  PixelPtr: PRGBQuad;
  i,j: Word;
begin
  ABitmap := TBitmap.Create;
//  AssignFile(F, IntToStr(ImageIndex) + '.raw');
//  Rewrite(F, 1);
  Width := WatchFaceFile[Position] + (WatchFaceFile[Position+1] shl 8);
  Height := WatchFaceFile[Position + 2] + (WatchFaceFile[Position+3] shl 8);
  WatchFaceFilePos := Position+4;

  ABitmap.PixelFormat := pf32Bit;
  ABitmap.SetSize(Width, Height);
  ABitmap.AlphaFormat := afDefined;

  for i := 0 to Height-1 do
   begin
    PixelPtr := ABitmap.ScanLine[i];
    for j := 0 to Width-1 do
     begin
      Pixel := ReadColor();
      PixelPtr^.rgbReserved := Pixel.A;
      PixelPtr^.rgbRed := Pixel.R;
      PixelPtr^.rgbGreen := Pixel.G;
      PixelPtr^.rgbBlue := Pixel.B;
      inc(PixelPtr);
 //     BlockWrite(F, Pixel, SizeOf(Pixel));
     end;
   end;

//  ABitmap.SaveToFile(IntToStr(ImageIndex) + '.bmp');
  Writeln('Image #' + IntToStr(ImageCounter) + ': ' + IntToStr(Width) + 'x' + IntToStr(Height) + ', Offset: ' + IntToStr(Position - SizeOf(ImageID)) + ', Size: ' + IntToStr(WatchFaceFilePos - Position + SizeOf(ImageID)));
//  CloseFile(F);
  BitmapToPNG(ABitmap, ImageIndex);
  FreeAndNil(ABitmap);
end;

begin
  if not((ParamCount = 2) and ((ParamStr(1) = 'pack') or (ParamStr(1) = 'unpack'))) then
   begin
    Writeln('Usage:');
    Writeln(' HuaweiWatchfaceRepacker.exe <unpack> <non-zip com.huawei.watchface or *.bin>');
    Writeln(' HuaweiWatchfaceRepacker.exe <pack> <input dir>');
    Exit;
   end;

  UnpackDir := ParamStr(2) + '.out';

  if (ParamStr(1) = 'unpack') then
   begin
    LoadWatchFaceFile;
    Writeln('Destination folder is ' + UnpackDir);
    CreateDir(UnpackDir);
    ChDir(UnpackDir);

    WatchFaceFilePos := 0;
    Repeat
     if (WatchFaceFile[WatchFaceFilePos] = ImageID[1]) and
        (WatchFaceFile[WatchFaceFilePos+1] = ImageID[2]) and
        (WatchFaceFile[WatchFaceFilePos+2] = ImageID[3]) and
        (WatchFaceFile[WatchFaceFilePos+3] = ImageID[4]) then
         begin
          if (ImageCounter = 0) then SaveHeader(WatchFaceFilePos);
          Inc(ImageCounter);
          GetImage(WatchFaceFilePos+4, ImageCounter);
        end
     else Inc(WatchFaceFilePos);
    Until (WatchFaceFilePos >= WatchFaceFileSize-5);
    Writeln('Done.');
   end;

  if (ParamStr(1) = 'pack') then
   begin
    try
     ChDir(ParamStr(2));
    except
     Writeln('Error: Can''t find folder ' + ParamStr(2));
     Exit;
    end;

    Writeln('Creating ' + DestinationFileName + ' in folder ' + ParamStr(2));
    WatchFaceFileStream := TBytesStream.Create;

    try
     WatchFaceFileStream.LoadFromFile('header');
     SetLength(WatchFaceFile, WatchFaceFileStream.Size);
     WatchFaceFileStream.ReadBuffer(WatchFaceFile[0], WatchFaceFileStream.Size);
    except
     Writeln('Error: Can''t load header');
     WatchFaceFileStream.Free; 
     Exit;
    end;

    FAT_Offset := Find_Header_FAT_Offset;
    if (FAT_Offset = 0) then
     begin
       Writeln('Can''t find FAT ID in header');
       WatchFaceFileStream.Free;
       Exit;
     end
    else Writeln('FAT offset in header: ' + IntToStr(FAT_Offset));

    FAT_Pointer := 8;

    PngFilesCount := 0;
    while FileExists(IntToStr(PngFilesCount+1) + '.png') do inc(PngFilesCount);
    Writeln('Found ' + IntToStr(PngFilesCount) + ' images');

    for i := 1 to PngFilesCount do
     begin
      FAT_Counter := WatchFaceFileStream.Position;
      SaveImage(i, w, h);
      Inc(FAT_Pointer, WatchFaceFileStream.Position - FAT_Counter);
      V := WatchFaceFileStream.Position - FAT_Counter;

      SavePos := WatchFaceFileStream.Position;
      WatchFaceFileStream.Position := FAT_Offset;

      WatchFaceFileStream.WriteData(V, SizeOf(V));
      if (i <> PngFilesCount) then WatchFaceFileStream.WriteData(FAT_Pointer, SizeOf(FAT_Pointer));

      FAT_Offset := WatchFaceFileStream.Position;
      WatchFaceFileStream.Position := SavePos;

      Writeln('Image #' + IntToStr(i) + ': ' + IntToStr(w) + 'x' + IntToStr(h) + ', Size: ' + IntToStr(V) + ', FAT_EOF: ' + IntToStr(FAT_Pointer));
     end;
    
    try
      WatchFaceFileStream.SaveToFile(DestinationFileName);
    except
     Writeln('Error: Can''t write ' + DestinationFileName);
     WatchFaceFileStream.Free; 
     Exit;
    end;

    WatchFaceFileStream.Free;
    Writeln('Done.');
   end;



end.

