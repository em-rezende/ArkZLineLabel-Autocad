; Script de Instalacao do ArkZMemorialDescritivo
; Gerado para Inno Setup

#define MyAppName "ArkZ Memorial Descritivo"
#define MyAppVersion "260915"
#define MyAppPublisher "ARK-Z ARQUITETURA"
#define MyAppURL "https://arkz.duckdns.org"

[Setup]
AppId={{24081A5C-6906-4CD6-A2F9-96A652170C94}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\Autodesk\ApplicationPlugins\ArkZMemorialDescritivo.bundle
DefaultGroupName=ARK-Z\ArkZMemorialDescritivo
AllowNoIcons=yes
PrivilegesRequired=admin
OutputDir=.\Output
OutputBaseFilename=ArkZMemorialDescritivo_v_{#MyAppVersion}_Setup
SetupIconFile=.\support\Ark-Z.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
WizardImageFile=.\support\ArkZ_large.bmp
WizardSmallImageFile=.\support\ArkZ_small.bmp
UninstallDisplayIcon={app}\Contents\Resources\Ark-Z.ico
UninstallDisplayName={#MyAppName} v{#MyAppVersion}
AppCopyright=(c) 2026 ARK-Z ARQUITETURA

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Files]
; ============================================================
; INSTALACAO DE ARQUIVOS DE SUPORTE
; ============================================================
; IMPORTANTE: o parametro Excludes evita que arquivos que NAO fazem parte
; do pacote sejam embutidos pelo curinga ".\Fonts\*" com recursesubdirs.
; Sem ele o proprio script (Fonts\Install ArkZMemorialDescritivo.iss) era copiado
; para dentro do bundle instalado.
Source: ".\Fonts\*"; DestDir: "{autopf}\Autodesk\ApplicationPlugins\ArkZMemorialDescritivo.bundle\"; Excludes: "*.iss,.gitignore,.git*,*.bak"; Flags: ignoreversion recursesubdirs
Source: "README.MD"; DestDir: "{autopf}\Autodesk\ApplicationPlugins\ArkZMemorialDescritivo.bundle\"; Flags: ignoreversion recursesubdirs
Source: "LICENSE"; DestDir: "{autopf}\Autodesk\ApplicationPlugins\ArkZMemorialDescritivo.bundle\"; Flags: ignoreversion recursesubdirs
Source: "Instrucoes.txt"; DestDir: "{autopf}\Autodesk\ApplicationPlugins\ArkZMemorialDescritivo.bundle\"; Flags: ignoreversion recursesubdirs

[UninstallDelete]
; ============================================================
; REMOVE TODOS OS ARQUIVOS DO ArkZMemorialDescritivo
; ============================================================
Type: filesandordirs; Name: "{app}"
Type: filesandordirs; Name: "{group}"


; ============================================================
; CÓDIGO PASCAL
; ============================================================
[Code]

// ============================================================
// FUNCAO PARA VERIFICAR SE O AUTOCAD ESTA INSTALADO
// ============================================================
function IsAutoCADInstalled: Boolean;
var
  RegKey: string;
  i: Integer;
  SubKeys: TArrayOfString;
  j: Integer;
begin
  Result := False;
  RegKey := 'Software\Autodesk\AutoCAD\';
  
  for i := 19 to 26 do
  begin
    if RegKeyExists(HKEY_CURRENT_USER, RegKey + 'R' + IntToStr(i) + '.0') then
    begin
      if RegGetSubkeyNames(HKEY_CURRENT_USER, RegKey + 'R' + IntToStr(i) + '.0', SubKeys) then
      begin
        for j := 0 to GetArrayLength(SubKeys) - 1 do
        begin
          if Pos('ACAD-', SubKeys[j]) = 1 then
          begin
            Result := True;
            Exit;
          end;
        end;
      end;
    end;
    
    if RegKeyExists(HKEY_CURRENT_USER, RegKey + 'R' + IntToStr(i) + '.1') then
    begin
      if RegGetSubkeyNames(HKEY_CURRENT_USER, RegKey + 'R' + IntToStr(i) + '.1', SubKeys) then
      begin
        for j := 0 to GetArrayLength(SubKeys) - 1 do
        begin
          if Pos('ACAD-', SubKeys[j]) = 1 then
          begin
            Result := True;
            Exit;
          end;
        end;
      end;
    end;
  end;
end;

// ============================================================
// TELA DE BOAS-VINDAS PERSONALIZADA
// ============================================================
function InitializeSetup(): Boolean;
begin
  Result := True;
  
  if not IsAutoCADInstalled then
  begin
    MsgBox('ATENCAO: Nenhuma versao do AutoCAD foi encontrada neste computador.' + #13#10 +
           'O Ark ZMemorial Descritivo requer AutoCAD 2013 ou superior para funcionar.' + #13#10 + #13#10 +
           'A instalacao continuara, mas o programa pode nao funcionar corretamente.',
           mbInformation, MB_OK);
  end;
end;

// ============================================================
// FUNCAO DE LIMPEZA - REMOVE ARQUIVOS CUIX/MNR DO ArkZMemorialDescritivo
// ============================================================
procedure DeleteArkZMemorialDescritivoFiles(const RootPath: string);
var
  FindRec: TFindRec;
  FilePath: string;
  FileName: string;
begin
  if FindFirst(RootPath + '\*', FindRec) then
  begin
    try
      repeat
        if (FindRec.Name <> '.') and (FindRec.Name <> '..') then
        begin
          FilePath := RootPath + '\' + FindRec.Name;
          FileName := LowerCase(FindRec.Name);
          
          if FindRec.Attributes and FILE_ATTRIBUTE_DIRECTORY <> 0 then
            DeleteArkZMemorialDescritivoFiles(FilePath)
          else if (Pos('ArkZMemorialDescritivo', FileName) > 0) and   // <<< CORRIGIDO: tudo minúsculo
                  ((Pos('.cuix', FileName) > 0) or 
                   (Pos('.mnr', FileName) > 0)) then
            DeleteFile(FilePath);
        end;
      until not FindNext(FindRec);
    finally
      FindClose(FindRec);
    end;
  end;
end;

// ============================================================
// EVENTO DE DESINSTALACAO
// ============================================================
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  i: Integer;
  Versions: array of string;
  SupportPath: string;
begin
  if CurUninstallStep = usUninstall then
  begin
    Versions := ['2013', '2014', '2015', '2016', '2017', '2018', 
                 '2019', '2020', '2021', '2022', '2023', '2024', '2025', '2026'];
    
    for i := 0 to GetArrayLength(Versions) - 1 do
    begin
      SupportPath := ExpandConstant('{userappdata}') + 
                     '\Autodesk\AutoCAD ' + Versions[i];
      
      if DirExists(SupportPath) then
        DeleteArkZMemorialDescritivoFiles(SupportPath);
    end;
  end;
end;