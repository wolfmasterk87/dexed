unit ce_dubprojeditor;

{$I ce_defines.inc}

interface

uses
  Classes, SysUtils, FileUtil, TreeFilterEdit, Forms, Controls, Graphics,
  Dialogs, ExtCtrls, Menus, StdCtrls, Buttons, ComCtrls, jsonparser, fpjson,
  ce_widget, ce_common, ce_interfaces, ce_observer, ce_dubproject, ce_sharedres;

type

  //TODO-cDUB: add new properties from UI

 { TCEDubProjectEditorWidget }

  TDubPropAddEvent = procedure(const propName: string; tpe: TJSONtype) of object;

  TCEDubProjectPropAddPanel = class(TForm)
  private
    fSelType: TRadioGroup;
    fEdName: TEdit;
    fEvent: TDubPropAddEvent;
    fBtnValidate: TBitBtn;
    procedure doValidate(sender: TObject);
  public
    constructor construct(event: TDubPropAddEvent);
  end;

  TCEDubProjectEditorWidget = class(TCEWidget, ICEProjectObserver)
    btnAcceptProp: TSpeedButton;
    btnAddProp: TSpeedButton;
    btnDelProp: TSpeedButton;
    edProp: TEdit;
    fltEdit: TTreeFilterEdit;
    imgList: TImageList;
    PageControl1: TPageControl;
    Panel1: TPanel;
    pnlToolBar: TPanel;
    pnlToolBar1: TPanel;
    propTree: TTreeView;
    fltInspect: TTreeFilterEdit;
    treeInspect: TTreeView;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    procedure btnAcceptPropClick(Sender: TObject);
    procedure btnAddPropClick(Sender: TObject);
    procedure btnDelPropClick(Sender: TObject);
    procedure propTreeSelectionChanged(Sender: TObject);
    procedure treeInspectDblClick(Sender: TObject);
  private
    fSelectedNode: TTreeNode;
    fProj: TCEDubProject;
    fNodeSources: TTreeNode;
    fNodeConfig: TTreeNode;
    procedure updateEditor;
    procedure updateInspector;
    procedure updateValueEditor;
    procedure setJsonValueFromEditor;
    procedure addProp(const propName: string; tpe: TJSONtype);
    //
    procedure projNew(aProject: ICECommonProject);
    procedure projChanged(aProject: ICECommonProject);
    procedure projClosing(aProject: ICECommonProject);
    procedure projFocused(aProject: ICECommonProject);
    procedure projCompiling(aProject: ICECommonProject);
    //
  protected
    procedure SetVisible(Value: boolean); override;
  public
    constructor create(aOwner: TComponent); override;
  end;

implementation
{$R *.lfm}

{$REGION TCEDubProjectPropAddPanel ---------------------------------------------}
constructor TCEDubProjectPropAddPanel.construct(event: TDubPropAddEvent);
var
  layout: TPanel;
begin
  inherited create(nil);
  width := 200;
  height := 120;
  fEvent := event;
  caption := 'add a DUB property';
  //
  fSelType := TRadioGroup.Create(self);
  fSelType.Parent := self;
  fSelType.Items.AddStrings(['array', 'object', 'value']);
  fSelType.Align:= alClient;
  fSelType.BorderSpacing.Around:=2;
  fSelType.Caption:= 'type';
  fSelType.ItemIndex:=2;
  //
  layout := TPanel.Create(self);
  layout.Parent := self;
  layout.Align := alBottom;
  layout.Height := 30;
  layout.BevelOuter:= bvNone;
  //
  fEdName := TEdit.Create(self);
  fEdName.Parent := layout;
  fEdName.Align:=alClient;
  fEdName.BorderSpacing.Around:=4;
  fEdName.Width:=80;
  //
  fBtnValidate := TBitBtn.Create(self);
  fBtnValidate.Parent := layout;
  fBtnValidate.Align:=alRight;
  fBtnValidate.BorderSpacing.Around:=4;
  fBtnValidate.Width:= 26;
  fBtnValidate.OnClick:=@doValidate;
  AssignPng(fBtnValidate, 'accept');
end;

procedure TCEDubProjectPropAddPanel.doValidate(sender: TObject);
var
  tpe: TJSONtype;
begin
  if assigned(fEvent) and (fEdName.Text <> '') then
  begin
    case fSelType.ItemIndex of
      0: tpe := TJSONtype.jtArray;
      1: tpe := TJSONtype.jtObject;
      else tpe := TJSONtype.jtString;
    end;
    fEvent(fEdName.Text, tpe);
    Close;
  end;
end;
{$ENDREGION}

{$REGION Standard Comp/Obj -----------------------------------------------------}
constructor TCEDubProjectEditorWidget.create(aOwner: TComponent);
begin
  inherited;
  fNodeSources := treeInspect.Items[0];
  fNodeConfig := treeInspect.Items[1];
  //
  AssignPng(btnAddProp, 'textfield_add');
  AssignPng(btnDelProp, 'textfield_delete');
  AssignPng(btnAcceptProp, 'accept');
end;

procedure TCEDubProjectEditorWidget.SetVisible(Value: boolean);
begin
  inherited;
  if not Value then exit;
  //
  updateEditor;
end;
{$ENDREGION}

{$REGION ICEProjectObserver ----------------------------------------------------}
procedure TCEDubProjectEditorWidget.projNew(aProject: ICECommonProject);
begin
  fProj := nil;
  enabled := false;
  if aProject.getFormat <> pfDub then
    exit;
  enabled := true;
  fProj := TCEDubProject(aProject.getProject);
  //
end;

procedure TCEDubProjectEditorWidget.projChanged(aProject: ICECommonProject);
begin
  if fProj = nil then
    exit;
  if aProject.getProject <> fProj then
    exit;
  if not Visible then
    exit;

  updateEditor;
  updateInspector;
end;

procedure TCEDubProjectEditorWidget.projClosing(aProject: ICECommonProject);
begin
  if fProj = nil then
    exit;
  if aProject.getProject <> fProj then
    exit;
  fProj := nil;
  //
  updateEditor;
  updateInspector;
  enabled := false;
end;

procedure TCEDubProjectEditorWidget.projFocused(aProject: ICECommonProject);
begin
  fProj := nil;
  enabled := false;
  if aProject.getFormat <> pfDub then
    exit;
  fProj := TCEDubProject(aProject.getProject);
  enabled := true;
  if not Visible then
    exit;

  updateEditor;
  updateInspector;
end;

procedure TCEDubProjectEditorWidget.projCompiling(aProject: ICECommonProject);
begin
end;
{$ENDREGION}

{$REGION Editor ----------------------------------------------------------------}
procedure TCEDubProjectEditorWidget.propTreeSelectionChanged(Sender: TObject);
begin
  fSelectedNode := nil;
  btnDelProp.Enabled := false;
  btnAddProp.Enabled := false;
  if propTree.Selected = nil then exit;
  //
  fSelectedNode := propTree.Selected;
  btnDelProp.Enabled := (fSelectedNode.Level > 0) and (fSelectedNode.Text <> 'name')
    and (fSelectedNode.data <> nil);
  updateValueEditor;
  btnAddProp.Enabled := TJSONData(fSelectedNode.Data).JSONType in [jtObject, jtArray];
end;

procedure TCEDubProjectEditorWidget.btnAcceptPropClick(Sender: TObject);
begin
  if fSelectedNode = nil then exit;
  //
  setJsonValueFromEditor;
end;

procedure TCEDubProjectEditorWidget.btnAddPropClick(Sender: TObject);
var
  pnl: TCEDubProjectPropAddPanel;
begin
  if fSelectedNode = nil then exit;
  //
  pnl := TCEDubProjectPropAddPanel.construct(@addProp);
  pnl.ShowModal;
  pnl.Free;
end;

procedure TCEDubProjectEditorWidget.addProp(const propName: string;
  tpe: TJSONtype);
var
  arr: TJSONArray;
  obj: TJSONObject;
  nod: TTreeNode;
begin
  if fSelectedNode = nil then exit;
  //
  fProj.beginModification;
  if TJSONData(fSelectedNode.Data).JSONType = jtArray then
  begin
    arr := TJSONArray(fSelectedNode.Data);
    case tpe of
      jtArray: arr.Add(TJSONArray.Create());
      jtObject: arr.Add(TJSONObject.Create());
      jtString:arr.Add('<value>');
    end;
  end
  else if TJSONData(fSelectedNode.Data).JSONType = jtObject then
  begin
    obj := TJSONObject(fSelectedNode.Data);
    case tpe of
      jtArray: obj.Add(propName, TJSONArray.Create());
      jtObject: obj.Add(propName, TJSONObject.Create());
      jtString: obj.Add(propName, '<value>');
    end;
  end;
  fProj.endModification;
  nod := propTree.Items.FindNodeWithText('<value>');
  if nod <> nil then propTree.Selected := nod
  else nod := propTree.Items.FindNodeWithText(propName);
  if nod <> nil then propTree.Selected := nod;
  propTree.MakeSelectionVisible;
end;

procedure TCEDubProjectEditorWidget.btnDelPropClick(Sender: TObject);
var
  prt: TJSONData;
begin
  if fSelectedNode = nil then exit;
  if fSelectedNode.Level = 0 then exit;
  if fSelectedNode.Text = 'name' then exit;
  if fSelectedNode.Data = nil then exit;
  if fSelectedNode.Parent.Data = nil then exit;
  //
  fProj.beginModification;
  prt := TJSONData(fSelectedNode.Parent.Data);
  if prt.JSONType = jtObject then
    TJSONObject(prt).Delete(fSelectedNode.Index)
  else if prt.JSONType = jtArray then
    TJSONArray(prt).Delete(fSelectedNode.Index);
  fProj.endModification;
  //
  updateValueEditor;
end;

procedure TCEDubProjectEditorWidget.setJsonValueFromEditor;
var
  dat: TJSONData;
  vFloat: TJSONFloat;
  vInt: integer;
  vInt64: int64;
  vBool: boolean;
begin
  if fSelectedNode = nil then exit;
  if fSelectedNode.Data = nil then exit;
  if fProj = nil then exit;
  //
  fProj.beginModification;
  dat := TJSONData(fSelectedNode.Data);
  case dat.JSONType of
    jtNumber:
      case TJSONNumber(dat).NumberType of
        ntFloat:
          if TryStrToFloat(edProp.Text, vFloat) then
            dat.AsFloat := vFloat;
        ntInt64:
          if TryStrToInt64(edProp.Text, vInt64) then
            dat.AsInt64 := vInt64;
        ntInteger:
          if TryStrToInt(edProp.Text, vInt) then
            dat.AsInteger := vInt;
      end;
     jtBoolean:
      if TryStrToBool(edProp.Text, vBool) then
        dat.AsBoolean := vBool;
      jtString:
        dat.AsString := edProp.Text;
  end;
  fProj.endModification;
end;

procedure TCEDubProjectEditorWidget.updateValueEditor;
var
  dat: TJSONData;
begin
  edProp.Clear;
  if fSelectedNode = nil then exit;
  if fSelectedNode.Data = nil then exit;
  //
  dat := TJSONData(fSelectedNode.Data);
  case dat.JSONType of
    jtNumber:
      case TJSONNumber(dat).NumberType of
        ntFloat:
          edProp.Text := FloatToStr(dat.AsFloat);
        ntInt64:
          edProp.Text := IntToStr(dat.AsInt64);
        ntInteger:
          edProp.Text := IntToStr(dat.AsInteger);
      end;
    jtBoolean:
      edProp.Text := BoolToStr(dat.AsBoolean);
    jtString:
      edProp.Text := dat.AsString;
  end;
end;

procedure TCEDubProjectEditorWidget.updateEditor;

  procedure addPropsFrom(node: TTreeNode; data: TJSONData);
  var
    i: integer;
    c: TTreeNode;
  begin
    node.Data:= data;
    if data.JSONType = jtObject then for i := 0 to data.Count-1 do
    begin
      node.ImageIndex:=7;
      node.SelectedIndex:=7;
      node.StateIndex:=7;
      c := node.TreeNodes.AddChildObject(node, TJSONObject(data).Names[i],
        TJSONObject(data).Items[i]);
      case TJSONObject(data).Items[i].JSONType of
        jtObject, jtArray:
          addPropsFrom(c, TJSONObject(data).Items[i]);
        else begin
          c.ImageIndex:=9;
          c.SelectedIndex:=9;
          c.StateIndex:=9;
        end;
      end;
    end else if data.JSONType = jtArray then for i := 0 to data.Count-1 do
    begin
      node.ImageIndex:=8;
      node.SelectedIndex:=8;
      node.StateIndex:=8;
      c := node.TreeNodes.AddChildObject(node, format('item %d',[i]),
        TJSONArray(data).Items[i]);
      case TJSONArray(data).Items[i].JSONType of
        jtObject, jtArray:
          addPropsFrom(c, TJSONArray(data).Items[i]);
        else begin
          c.ImageIndex:=9;
          c.SelectedIndex:=9;
          c.StateIndex:=9;
        end;
      end;
    end;
  end;

begin
  propTree.Items.Clear;
  edProp.Clear;
  if (fProj = nil) or (fProj.json = nil) then
    exit;
  //
  propTree.BeginUpdate;
  addPropsFrom(propTree.Items.Add(nil, 'project'), fProj.json);
  propTree.EndUpdate;
end;
{$ENDREGION}

{$REGION Inspector -------------------------------------------------------------}
procedure TCEDubProjectEditorWidget.updateInspector;
var
  i: integer;
  j: integer;
  node : TTreeNode;
begin
  if (fNodeConfig = nil) or (fNodeSources = nil) then
    exit;
  //
  fNodeConfig.DeleteChildren;
  fNodeSources.DeleteChildren;
  //
  if (fProj = nil) then
    exit;
  //
  j := fProj.getActiveConfigurationIndex;
  treeInspect.BeginUpdate;
  for i:= 0 to fProj.configurationCount-1 do
  begin
    if i <> j then
    begin
      node := treeInspect.Items.AddChild(fNodeConfig, fProj.configurationName(i));
      node.ImageIndex := 3;
      node.SelectedIndex := 3;
      node.StateIndex := 3;
    end
    else
    begin
      node := treeInspect.Items.AddChild(fNodeConfig, fProj.configurationName(i) +' (active)');
      node.ImageIndex := 10;
      node.SelectedIndex := 10;
      node.StateIndex := 10;
    end;
  end;
  for i := 0 to fProj.sourcesCount-1 do
  begin
    node := treeInspect.Items.AddChild(fNodeSources, fProj.sourceRelative(i));
    node.ImageIndex := 2;
    node.SelectedIndex := 2;
    node.StateIndex := 2;
  end;
  treeInspect.EndUpdate;
end;

procedure TCEDubProjectEditorWidget.treeInspectDblClick(Sender: TObject);
var
  node: TTreeNode;
  fname: string;
begin
  if treeInspect.Selected = nil then exit;
  if fProj = nil then exit;
  node := treeInspect.Selected;
  // open file
  if node.Parent = fNodeSources then
  begin
    fname := fProj.sourceAbsolute(node.Index);
    if isEditable(extractFileExt(fname)) then
      getMultiDocHandler.openDocument(fname);
  end
  // select active config
  else if node.Parent = fNodeConfig then
  begin
    fProj.setActiveConfigurationIndex(node.Index);
    fNodeConfig.Expand(true);
  end;
end;
{$ENDREGION}

end.

