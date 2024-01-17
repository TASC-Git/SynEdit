unit VirtualEditTree2;
/// This replaces the old VirtualEditTree component which was only used for Combobox support
/// To prevent loader errors when loading the project there are 2 stubs for the old component
/// and these could be removed once all references to EditTree are gone

interface

uses
   SysUtils,
   Windows,
   Winapi.Messages,
   System.Types,
   Vcl.Controls,
   StdCtrls,
   VirtualTrees,
   VirtualTrees.EditLink;

type

   TCustomVirtualEditTree = class(TVirtualStringTree)

   end;

   TVirtualEditTree = class(TCustomVirtualEditTree)

   end;

   // Provides a combobox for the TVirtualStringTree
   TComboEditLink = class(TWinControlEditLink)
   private
      FLinkComboBox: TComboBox;
      FOriginalIndex: integer;
      function GetEdit: TComboBox;
      procedure SetEdit(const Value: TComboBox);
   public
      destructor Destroy; override;

      function BeginEdit: boolean; override; stdcall;
      function CancelEdit: boolean; override; stdcall;
      function EndEdit: boolean; override; stdcall;
      function PrepareEdit(Tree: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex): boolean; override; stdcall;
      procedure SetBounds(R: TRect); override; stdcall;

      property Edit: TComboBox read GetEdit write SetEdit;

      property LinkComboBox: TComboBox read FLinkComboBox write FLinkComboBox;
   end;

implementation

{ TComboEditLink }

destructor TComboEditLink.Destroy;
begin
   Edit.OnChange := Nil;
   LinkComboBox := Nil;
   if Assigned(FEdit) then
      FreeAndNil(FEdit);
   inherited;
end;

function TComboEditLink.BeginEdit: boolean;
begin
   result := inherited;
   if result then
   begin
      FOriginalIndex := Edit.ItemIndex;
   end;
end;

function TComboEditLink.CancelEdit: boolean;
// The TCombobox doesn't support cancel (like string edit) so this is here as reference
// rather than does anything because a Cancel request is never received
// You could create something like TVCombobox to handle say the ESC key to cancel or the enter key
begin
   result := inherited;
   if result then
      Edit.ItemIndex := FOriginalIndex;
end;

function TComboEditLink.EndEdit: boolean;
// The OnChange of the link combo handles changes at the caller and thus this does nothing
// also left for reference
begin
   result := inherited;
end;

function TComboEditLink.GetEdit: TComboBox;
begin
   result := TComboBox(FEdit);
end;

function TComboEditLink.PrepareEdit(Tree: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex): boolean;
// The local combobox will be freed by the tree as will LinkComboBox. The entire editor link is freed when editing is complete
// OnChange is critical for saving changes to the selection
begin
   result := inherited;
   if result then
   begin
      Edit := TComboBox.Create(Tree);
      Edit.Parent := Tree;
      Edit.Items.StrictDelimiter := true;
      Edit.Items.CommaText := LinkComboBox.Items.CommaText;
      Edit.Style := csDropDownList;
      Edit.OnChange := LinkComboBox.OnChange;
      Edit.ItemIndex := LinkComboBox.ItemIndex;
   end;
end;

procedure TComboEditLink.SetBounds(R: TRect);
begin
   inherited;
   FEdit.SetBounds(R.Left, R.Top, R.Width, R.Height);
end;

procedure TComboEditLink.SetEdit(const Value: TComboBox);
begin
   inherited SetEdit(Value);
end;

end.
