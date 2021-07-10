//----------------------------------------------//
//只写了一个上传,是因为一个朋友只要上传功能,下载//
//就没有写,把源码贴出来供大家学习,当时着急没写几//
//行注释,连错误处理也少得可怜,见谅.                                 //
//可以上传整个目录,单线程                       //
//QQ:5659170  网虫先生                          //
//----------------------------------------------//

unit U_FtpTool;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IdBaseComponent, IdComponent, IdTCPConnection,
  IdTCPClient, IdFTP, FileCtrl,IdFTPCommon, ExtCtrls, ComCtrls,IdFTPList,
  ImgList,IdGlobal,StrUtils, ShellCtrls, Buttons;

type
  TMyFirstThread = class(TThread)
  private

  protected
    procedure Execute;override;
  end;

type
  TForm1 = class(TForm)
    IdFTP1: TIdFTP;
    ImageList1: TImageList;
    ImageList2: TImageList;
    Panel1: TPanel;
    Label1: TLabel;
    HostEdit: TEdit;
    Label2: TLabel;
    UserIDEdit: TEdit;
    Label3: TLabel;
    PasswordEdit: TEdit;
    Label4: TLabel;
    PortEdit: TEdit;
    Button1: TButton;
    Panel2: TPanel;
    ShellComboBox1: TShellComboBox;
    ShellListView1: TShellListView;
    Panel3: TPanel;
    ListView1: TListView;
    Panel4: TPanel;
    CurrentDirEdit: TEdit;
    SpeedButton1: TSpeedButton;
    Label5: TLabel;
    Button2: TButton;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    ListBox1: TListBox;
    Panel5: TPanel;
    ProgressBar1: TProgressBar;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure ListView1DblClick(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure IdFTP1Work(Sender: TObject; AWorkMode: TWorkMode;
      const AWorkCount: Integer);
    procedure FormCreate(Sender: TObject);
    procedure IdFTP1WorkBegin(Sender: TObject; AWorkMode: TWorkMode;
      const AWorkCountMax: Integer);
    procedure IdFTP1WorkEnd(Sender: TObject; AWorkMode: TWorkMode);
    procedure PasswordEditKeyPress(Sender: TObject; var Key: Char);
  private
    ByteCount:Integer;
    YUpLoadByte:integer;
    Thread1:TMyFirstThread;
    UpLoadType:String;//'1'表示上传类型是文件夹,'0'表示上传类型是文件
    FileSize:Integer;
    procedure List(DirName:string);
    procedure UpLoad(Remote_path,Local_path:string);
    function GetDirectorySize(ADirectory: string): Integer;
    procedure AfterUpLoad(Send : TObject);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses U_ModalDialog;

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
  if IdFTP1.Connected then
     IdFTP1.Disconnect;
  IdFTP1.Host:=Trim(HostEdit.Text);
  if Trim(UserIDEdit.Text)='' then
  begin
    IdFTP1.Username:='anonymous';
    IdFTP1.Password:='';
  end
  else
  begin
    IdFTP1.Username:=Trim(UserIDEdit.Text);
    IdFTP1.Password:=Trim(PasswordEdit.Text);
  end;
  IdFTP1.Port:=StrToInt(PortEdit.Text);
  try
    IdFTP1.Connect;
  except
    ShowMessage('连接失败');
  end;
  CurrentDirEdit.Text:='/';
  Self.List(CurrentDirEdit.Text);
  Button2.Enabled:=True;
  Panel3.Visible:=True;
end;


procedure TForm1.UpLoad(Remote_path,Local_path:string);
var strl1,strl2,strl3:TStringList;
    sr: TSearchRec;
    i,j,DirCount,FileCount:integer;
    str:string;
begin
  IdFTP1.ChangeDir(Remote_path);

  DirCount:=0;FileCount:=0;

  IdFTP1.MakeDir(Copy(Local_path,LastDelimiter('\',Local_path)+1,length(Local_path)));

  if FindFirst(Local_path + '\*.*', faDirectory, sr) = 0 then
  begin
    strl1:=TStringList.Create;
    repeat
      if (sr.Attr = faDirectory) and(sr.Name<>'.') and (sr.Name<>'..') then
      begin
        strl1.Add(sr.Name);
        Inc(DirCount);
      end;
    until FindNext(sr) <> 0;
    FindClose(sr);
  end;

  for i:=0 to DirCount-1 do
  begin
    UpLoad(Remote_path+'/'+Copy(Local_path,LastDelimiter('\',Local_path)+1,length(Local_path)),Local_path+'\'+strl1.Strings[i]);
  end;

  if FindFirst(Local_path + '\*.*',faAnyFile, sr )=0 then
  begin
    strl2:=TStringList.Create;
    repeat
      if (sr.Attr <> faDirectory) then
      begin
        strl2.Add(sr.Name);
        Inc(FileCount);
      end;
    until FindNext(sr) <>0;
    FindClose(sr);
  end;

  IdFTP1.ChangeDir(Remote_path+'/'+Copy(Local_path,LastDelimiter('\',Local_path)+1,length(Local_path)));

  for j:=0 to FileCount-1 do
  begin
    try
      IdFTP1.Put(Local_path+'\'+strl2[j],IdFTP1.RetrieveCurrentDir+'/'+strl2[j]);
      ListBox1.Items.Add('@_@   '+strl2[j]+'上传成功!');
    except
      ListBox1.Items.Add(':o   '+strl2[j]+'上传失败!');
      Continue;
    end;
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);
var strl1:TStringList;
    i:integer;
begin
  if ShellListView1.SelectedFolder=nil then
  begin
    ShowMessage('请选择要上传的文件或文件夹');
    Exit;
  end;

  strl1:=TStringList.Create;

  for i:=0 to IdFTP1.DirectoryListing.Count-1 do
  begin
    strl1.Add(IdFTP1.DirectoryListing.Items[i].FileName);
  end;

  for i:=0 to strl1.Count-1 do
  begin
    if strl1[i] <> ShellListView1.SelectedFolder.DisplayName then
       Continue
    else
    begin
     if Application.MessageBox('目录或文件已经存在，是否替换？','提示',MB_OkCancel+MB_IconQuestion)=IdOk then
     begin
       IdFTP1.Delete(strl1[i]);
     end
     else
     begin
       Exit;
     end;
//      ShowMessage('目录或文件已经存在');
//      Exit;
    end;
  end;
  Button2.Enabled:=False;
  ListBox1.Clear;
  if ShellListView1.SelectedFolder.IsFolder then
  begin
    UpLoadType:='1';
    YUpLoadByte:=0;
    ProgressBar1.Position:=0;
    ByteCount:=GetDirectorySize(ShellListView1.SelectedFolder.PathName);
    ProgressBar1.Min:=0;
    ProgressBar1.Max:=ByteCount;
  end;

  if not ShellListView1.SelectedFolder.IsFolder then
  begin
     UpLoadType:='0';
     YUpLoadByte:=0;
     ProgressBar1.Position:=0;
     ByteCount:=FileSizeByName(ShellListView1.SelectedFolder.PathName);
     ProgressBar1.Max:=ByteCount;
  end;
  if not Assigned(Form2) then
     Form2:=TForm2.Create(Application);
  Form2.Show;
  Form1.ListView1.Enabled:=False;
  Form1.Button1.Enabled:=False;
  Thread1:=TMyFirstThread.Create(False);
  Thread1.Priority:=tpNormal;
  Thread1.OnTerminate:=AfterUpLoad;
  Thread1.FreeOnTerminate:=True;
end;

procedure TForm1.List(DirName: string);
var NewItem:TListItem;
    i:integer;
    LS: TStringList;
begin
  Ls:=TStringList.Create;

  ListView1.Clear;
  IdFTP1.ChangeDir(DirName);
  IdFTP1.List(Ls);
  CurrentDirEdit.Text:=IdFTP1.RetrieveCurrentDir;
  for i:=0 to IdFTP1.DirectoryListing.Count-1 do
  begin
    With IdFTP1.DirectoryListing.Items[i] do
    begin
      if (FileName='.') OR (FileName='..')  then Continue;
      NewItem:=ListView1.Items.Add;
      NewItem.Caption:=FileName;
      NewItem.SubItems.Add(IntToStr(Size));
      if ItemType = ditDirectory then
      begin
         NewItem.StateIndex:=0;
         NewItem.SubItems.Add('文件文件夹');
      end
      else
      begin
        NewItem.SubItems.Add('其它类型');
      end;
      NewItem.SubItems.Add(FormatDateTime('yyyy/mm/dd hh:mm', ModifiedDate));
      NewItem.SubItems.Add(OwnerName);
    end;
  end;
end;

procedure TForm1.ListView1DblClick(Sender: TObject);
begin
  if ListView1.Selected=nil then Exit;
  if  IdFTP1.DirectoryListing.Items[ListView1.ItemIndex].ItemType = ditDirectory then
      Self.List(ListView1.Items[ListView1.ItemIndex].Caption);
end;


procedure TForm1.SpeedButton1Click(Sender: TObject);
begin
  if IdFTP1.RetrieveCurrentDir<>'/' then
     Self.List('..');
end;

procedure TForm1.IdFTP1Work(Sender: TObject; AWorkMode: TWorkMode;
  const AWorkCount: Integer);
begin
  ProgressBar1.Position:=AWorkCount+YUpLoadByte;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  ByteCount:=0;
  YUpLoadByte:=0;
end;

function TForm1.GetDirectorySize(ADirectory: string): Integer;
var
  Dir: TSearchRec;
  Ret: integer;
  Path: string;
begin
  Result := 0;
  Path := ExtractFilePath(ADirectory);
  Ret := Sysutils.FindFirst(ADirectory, faAnyFile, Dir);
  if Ret <> NO_ERROR then exit;
  try
    while ret = NO_ERROR do
    begin
      inc(Result, Dir.Size);
      if (Dir.Attr in [faDirectory]) and (Dir.Name[1] <> '.') then
        Inc(Result, GetDirectorySize(Path + Dir.Name + '\*.*'));
      Ret := Sysutils.FindNext(Dir);
    end;
  finally
    Sysutils.FindClose(Dir);
  end;
end;

{ TMyFirstThread }

procedure TForm1.AfterUpLoad(Send : TObject);
begin
  Form1.ListBox1.Items.Add('全部上传完成');
  Form1.List(Form1.CurrentDirEdit.Text);
  Form1.Button2.Enabled:=True;
  Form1.Button1.Enabled:=True;
  Form1.ListView1.Enabled:=True;
  Form2.Close;
end;

procedure TMyFirstThread.Execute;
begin
  inherited;
  if Form1.UpLoadType='1' then
     Form1.UpLoad(Form1.IdFTP1.RetrieveCurrentDir,Form1.ShellListView1.SelectedFolder.PathName);
  if Form1.UpLoadType='0' then
  begin
    try
      Form1.IdFTP1.Put(Form1.ShellListView1.SelectedFolder.PathName,Form1.IdFTP1.RetrieveCurrentDir+'/'+Form1.ShellListView1.SelectedFolder.DisplayName);
      Form1.ListBox1.Items.Add('@_@   '+Form1.ShellListView1.SelectedFolder.DisplayName+'上传成功!');
    except
      Form1.ListBox1.Items.Add(':o   '+Form1.ShellListView1.SelectedFolder.DisplayName+'上传失败!');
    end;
  end;
end;

procedure TForm1.IdFTP1WorkBegin(Sender: TObject; AWorkMode: TWorkMode;
  const AWorkCountMax: Integer);
begin
  FileSize:=AWorkCountMax;
end;

procedure TForm1.IdFTP1WorkEnd(Sender: TObject; AWorkMode: TWorkMode);
begin
  YUpLoadByte:=YUpLoadByte+FileSize;
end;

procedure TForm1.PasswordEditKeyPress(Sender: TObject; var Key: Char);
begin
  if Key=#13 then
     Button1.Click;
end;

end.
