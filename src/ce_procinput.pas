unit ce_procinput;

{$I ce_defines.inc}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  Menus, StdCtrls, ce_widget, process, ce_common, ce_interfaces;

type
  TCEProcInputWidget = class(TCEWidget)
    btnSend: TButton;
    txtInp: TEdit;
    txtExeName: TStaticText;
    procedure btnSendClick(Sender: TObject);
    procedure txtInpKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    fMruPos: Integer;
    fMru: TMRUList;
    fProc: TProcess;
    procedure sendInput;
    procedure setProc(const aValue: TProcess);
    //
    procedure optset_InputMru(aReader: TReader);
    procedure optget_InputMru(aWriter: TWriter);
  public
    constructor create(aOwner: TComponent); override;
    destructor destroy; override;
    //
    procedure sesoptDeclareProperties(aFiler: TFiler); override;
    property process: TProcess read fProc write setProc;
  end;

implementation
{$R *.lfm}

uses
  ce_symstring, LCLType;

{$REGION Standard Comp/Obj -----------------------------------------------------}
constructor TCEProcInputWidget.create(aOwner: TComponent);
begin
  inherited;
  fMru := TMRUList.Create;
  fMru.maxCount := 25;
end;

destructor TCEProcInputWidget.destroy;
begin
  fMru.Free;
  inherited;
end;
{$ENDREGION --------------------------------------------------------------------}

{$REGION ICESessionOptionsObserver ---------------------------------------------}
procedure TCEProcInputWidget.sesoptDeclareProperties(aFiler: TFiler);
begin
  inherited;
  aFiler.DefineProperty(Name + '_inputMru', @optset_InputMru, @optget_InputMru, true);
end;

procedure TCEProcInputWidget.optset_InputMru(aReader: TReader);
begin
  fMru.DelimitedText := aReader.ReadString;
end;

procedure TCEProcInputWidget.optget_InputMru(aWriter: TWriter);
begin
  aWriter.WriteString(fMru.DelimitedText);
end;
{$ENDREGION --------------------------------------------------------------------}

{$REGION Process input things --------------------------------------------------}
procedure TCEProcInputWidget.setProc(const aValue: TProcess);
begin
  // TODO: process list
  // TODO: each TCESynMemo must have its own runnable TProcess
  // currently they share the CEMainForm.fRunProc variable.
  if fProc <> nil then
    fProc.Terminate(1);

  txtExeName.Caption := 'no process';
  fProc := nil;
  if aValue = nil then
    exit;
  if not (poUsePipes in aValue.Options) then
    exit;
  fProc := aValue;
  txtExeName.Caption := shortenPath(fProc.Executable);
end;

procedure TCEProcInputWidget.sendInput;
var
  inp: string;
begin
  fMru.Insert(0,txtInp.Text);
  fMruPos := 0;
  if txtInp.Text <> '' then
    inp := symbolExpander.get(txtInp.Text) + lineEnding
  else
    inp := txtInp.Text + lineEnding;
  fProc.Input.Write(inp[1], length(inp));
  txtInp.Text := '';
end;

procedure TCEProcInputWidget.btnSendClick(Sender: TObject);
begin
  if fProc = nil then
    exit;
  sendInput;
end;

procedure TCEProcInputWidget.txtInpKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_RETURN:
      if fProc <> nil then sendInput;
    VK_UP: begin
      fMruPos += 1;
      if fMruPos > fMru.Count-1 then fMruPos := 0;
      txtInp.Text := fMru.Strings[fMruPos];
    end;
    VK_DOWN: begin
      fMruPos -= 1;
      if fMruPos < 0 then fMruPos := fMru.Count-1;
      txtInp.Text := fMru.Strings[fMruPos];
    end;
  end;
end;
{$ENDREGION --------------------------------------------------------------------}

end.
