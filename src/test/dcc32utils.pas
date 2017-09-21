unit dcc32utils;

interface

uses
  System.Classes;

type
  DCC32 = record
    class function Compile(const AParams: String; StdOut: TStrings): cardinal; static;
    class function FindDelphiRootDir: String; static;
  end;

implementation

uses
  Winapi.Windows, System.Win.Registry, System.SysUtils;

function ExecProcess(const ACommand, AParameters: String; AStrings: TStrings): cardinal;
const
  MAX_BUFFER = 2400;
var
  saSecurity: TSecurityAttributes;
  hReadPipe: THandle;
  hWrite: THandle;
  suiStartup: TStartupInfo;
  piProcess: TProcessInformation;
  buffer: array[0..MAX_BUFFER] of AnsiChar;
  dAvail, dRead: DWord;
  dRunning: DWord;
  exitCode: DWORD;
  tmp: String;
begin
  exitCode := 0;
  saSecurity.nLength := SizeOf(TSecurityAttributes);
  saSecurity.bInheritHandle := True;
  saSecurity.lpSecurityDescriptor := nil;
  if CreatePipe(hReadPipe, hWrite, @saSecurity, 0) then
  begin
    FillChar(suiStartup, SizeOf(TStartupInfo), #0);
    suiStartup.cb := SizeOf(TStartupInfo);
    suiStartup.hStdInput := hReadPipe;
    suiStartup.hStdOutput := hWrite;
    suiStartup.hStdError := hWrite;
    suiStartup.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
    suiStartup.wShowWindow := SW_HIDE;
    if CreateProcess(nil, PChar(ACommand + ' ' + AParameters), @saSecurity,
      @saSecurity, True, NORMAL_PRIORITY_CLASS, nil, nil, suiStartup, piProcess) then
    begin
      repeat
        dRunning  := WaitForSingleObject(piProcess.hProcess, 100);
        PeekNamedPipe(hReadPipe, nil, 0, nil, @dAvail, nil);
        if (dAvail > 0) then
        repeat
          dRead := 0;
          ReadFile(hReadPipe, buffer[0], MAX_BUFFER, dRead, nil);
          Buffer[dRead] := #0;
          SetLength(tmp, dRead);
          OemToChar(Buffer, PWideChar(tmp));
          AStrings.Add(tmp);
        until (dRead < MAX_BUFFER);
      until (dRunning <> WAIT_TIMEOUT);
      GetExitCodeProcess(piProcess.hProcess, exitCode);
      CloseHandle(piProcess.hProcess);
      CloseHandle(piProcess.hThread);
    end;
    CloseHandle(hReadPipe);
    CloseHandle(hWrite);
  end;
  Result := exitCode;
end;

class function DCC32.Compile(const AParams: String; StdOut: TStrings): DWORD;
begin
  Result := ExecProcess(ExcludeTrailingPathDelimiter(DCC32.FindDelphiRootDir) + '\bin\dcc32.exe', AParams, StdOut);
end;

class function DCC32.FindDelphiRootDir: String;
var
  reg: TRegistry;
  versions: TStrings;
begin
  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_CURRENT_USER;
    if reg.OpenKeyReadOnly('SOFTWARE\Embarcadero\BDS') then
    begin
      versions := TStringList.Create;
      try
        reg.GetKeyNames(versions);
        if (versions.Count > 0) and reg.KeyExists(versions[0]) then
        begin
          reg.OpenKeyReadOnly(versions[0]);
          Result := reg.ReadString('RootDir');
        end;
      finally
        versions.Free;
      end;
      reg.CloseKey;
    end;
  finally
    reg.Free;
  end;
end;

end.
