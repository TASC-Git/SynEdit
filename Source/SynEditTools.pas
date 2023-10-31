unit SynEditTools;

interface
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Forms, Math,
  SynEditHighlighter, SynEdit;

procedure TascSynPaintTransient(Sender: TObject; Canvas: TCanvas; TransientType: TTransientType);

implementation


procedure TascSynPaintTransient(Sender: TObject; Canvas: TCanvas; TransientType: TTransientType);
// as much as highlighting the [ ] brackets would be good in SQL mode the entire word is returned
// eg. [test] rather than [ so square brackets dont work.
const
  OpenChars: array[0..2] of WideChar = ('(','{','<');
  CloseChars: array[0..2] of WideChar = (')','}','>');
var
  Editor: TSynEdit;
  Attri: TSynHighlighterAttributes;

function IsCharBracket(AChar: WideChar): Boolean;
begin
  case AChar of
    '{',
    '(',
    '<',
    '}',
    ')',
    '>':
    Result:= True;
  else
    Result:= False;
  end;
end;

function CharToPixels(P: TBufferCoord): TPoint;
begin
  Result:=Editor.RowColumnToPixels(Editor.BufferToDisplayPos(P));
end;

procedure SetCanvasStyle;
begin
  Editor.Canvas.Brush.Style:= bsSolid; //Clear;
  Editor.Canvas.Font.Assign(Editor.Font);
  Editor.Canvas.Font.Style:= Attri.Style;
  if (TransientType = ttAfter) then begin
    Editor.Canvas.Font.Color:= clBlack;
    Editor.Canvas.Brush.Color:= $00FFFFAA;
  end
  else begin
    Editor.Canvas.Font.Color:= Attri.Foreground;
    Editor.Canvas.Brush.Color:= Attri.Background;
  end;

  if (Editor.Canvas.Font.Color = clNone) then
    Editor.Canvas.Font.Color:= Editor.Font.Color;
  if (Editor.Canvas.Brush.Color = clNone) then
    Editor.Canvas.Brush.Color:= Editor.Color;
end;

var
   P  : TBufferCoord;
   Pix: TPoint;
   D  : TDisplayCoord;
   S  : String;
   I, start, ln: Integer;
   TmpCharA,
   TmpCharB: WideChar;

begin
  try
    Editor:= TSynEdit(Sender);

    if not Assigned(Editor) or
       (Editor.PaintLock > 0) or
{$IFDEF USEVIRTUALLIST}
       (Editor.VirtualMode) or
{$ENDIF}
       (Editor.Lines.Count = 0) then exit;

    LN := Length(Editor.Text);
    if LN < 2 then exit;

    Start:= Editor.SelStart;

    if (Start > 0) and
       (Start <= LN) then
      TmpCharA:= Editor.Text[Start]
    else
      TmpCharA:= #0;

    if (Start < LN) then
      TmpCharB:= Editor.Text[Start + 1]
    else
      TmpCharB:= #0;

    if not IsCharBracket(TmpCharA) and
       not IsCharBracket(TmpCharB) then
      Exit;

    P:= Editor.CaretXY;
    D:= Editor.DisplayXY;

    S:= TmpCharB;
    if not IsCharBracket(TmpCharB) then begin
      P.Char:= P.Char - 1;
      S:= TmpCharA;
    end;

    Editor.GetHighlighterAttriAtRowCol(P,S,Attri);

    if (Editor.Highlighter.SymbolAttribute = Attri) then begin
      for i:= low(OpenChars) to High(OpenChars) do
      begin
        if (S = OpenChars[i]) or
           (S = CloseChars[i]) then
        begin
          Pix:= CharToPixels(P);
          SetCanvasStyle;
          Editor.Canvas.TextOut(Pix.X,
                                Pix.Y,
                                S);
          P := Editor.GetMatchingBracketEx(P);

          if (P.Char > 0) and
             (P.Line > 0) then
          begin
            Pix:= CharToPixels(P);
            if Pix.X > Editor.GutterWidth then
            begin
              SetCanvasStyle;
              if S = OpenChars[i] then
                Editor.Canvas.TextOut(Pix.X,
                                      Pix.Y,
                                      CloseChars[i])
              else
                Editor.Canvas.TextOut(Pix.X,
                                      Pix.Y,
                                      OpenChars[i]);
            end; //if Pix.X >
          end; //if (P.Char > 0)
        end; //if (S = OpenChars[i])
      end; //for i:= low(OpenChars)
      Editor.Canvas.Brush.Style := bsSolid;
    end; //if (Editor.Highlighter.SymbolAttribute = Attri)
  except
  // TODO
  end; //tryend;
end;


end.
