{%RunFlags BUILD-}
unit xlbtdevice;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Classes,
  synaser;

const
  AUX_RSSI_CALC     = 255.0; // floating point precision needed
  // positions
  RESPONSE_LENGTH_POS = 3;
  MAC_ADDRESS_START_POS = 9;
  MAC_ADDRESS_LEN   = 6;
  MAC_ADDRESS_END_POS = MAC_ADDRESS_START_POS + 6;
  EVENT_CODE_POSITION = 4;
  ERROR_CODE_POSITION = 6;
  EV_POS_RSSI_VALUE = 15;
  EV_POS_EVENTTYPE  = 7;
  EV_POS_DATALENGTH = 9;
  // events and return codes
  EVENT_GAPDEVICEINITDONE = #6#0;
  EVENT_GAPDeviceDiscoveryDone = #6#1;
  EVENT_GAPNOTIFICATION = #05#$1b;
  ETYPE_DEVICEDISCOVERED = #4;
  ETYPE_CONNECTABLE = #0;
  EVENT_GAPEXTENSIONCommandSTATUS = #6#$7f;
  EVENT_GAPDeviceInformation = #6#$0D;
  EVENT_GAPEstablishLink = #6#7;
  SUCCESS_CODE      = 0;
  // multipliers (seconds / 100) (ex: 100 --> 1 second)
  INQUIRY_MULTIPLIER = 96.0;
  CONNECTION_MULTIPLIER = 10;
  HCI_NORMAL_MULTIPLIER = 5;

  // HCI commands
  GAP_DeviceInit =
    #1#0#$fe#$26#8#3#0#0#0#0#0#0#0#0  +
    #0#0#0#0#0#0#0#0#0#0#0#0#0#0  + #0#0#0#0#0#0#0#0#0#0#0#0#0#0;
  GAP_GetParam   = #1#$31#$fe;
  GAP_DeviceDiscoveryRequest = #1#4#$FE;
  tGAP_DiscoveryActive = #3#3#1#0;
  TGAP_CONN_EST_INT_MIN = #1#$15;
  //                            "\x01\x00\xfe\x26\x08\x03\x00\x00\x00\x00\x00\x00\x00\x00\
  //                            \x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\
  //                            \x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00"
  //GAP_DeviceDiscoveryRequest  = #1#4#$fe#3#3#1#0;
  //                            "\x01\x04\xfe\x03\x03\x01\x00"
  GAP_DeviceDiscoveryCancel = #1#5#$fe#0;
  //                            "\x01\x05\xfe\x00"
  GAP_EstablishLinkRequest = #1#9#$fe#9#0#0#0;
//                            "\x01\x09\xfe\x09\x00\x00\x00\xfe\xca\x00\x00\xfe\xca"
//GAP_TerminateLinkRequest    = \
//                            "\x01\x0a\xfe\x02\x00\x00"
//ATT_WriteReq                = \
//                            "\x01\x12\xfd\x07\x00\x00\x00\x00\x17\x00\x2a"
//ATT_NotifReq                = \
//                            "\x01\x12\xfd\x08\x00\x00\x00\x00\x1b\x00\x01\x00"

// machine states

type
  debugproc = procedure(s: string) of object;

  tBTDevice = class
  private
    serial: tBlockSerial;
    fDebug: debugProc;

    procedure InitCom(anr: integer);
    function ReadLine: string;
    procedure debugln(s1: string; s2: string = ''; s3: string = '');
  public
    peerAddr: string;
    connectable: boolean;
    constructor Create(anr: integer);
    destructor Destroy; override;
    procedure Write(s: string);
    procedure Read(aMultiplier: double);
    property OnDebug: debugproc write fDebug;

  end;

function asHex(s: string): string;

implementation

function asHex(s: string): string;
begin

  SetLength(Result, Length(s) * 2);
  { Call the binary to hexadecimal conversion procedure. }
  BinToHex(PChar(s), PChar(Result), Length(s) * SizeOf(char));
end;

function reverse(s: string): string;
var
  i: integer;
begin
  Result := '';
  for i := length(s) downto 1 do
    Result := Result+s[i];
end;

procedure tBTDevice.debugln(s1: string; s2: string = ''; s3: string = '');
var
  s: string;
begin
  if assigned(fDebug) then
  begin
    s := s1;
    if s2<>'' then
      s := s+#10+s2;
    if s3<>'' then
      s := s+#10+s3;
    fDebug(s);
  end;
end;

constructor tBTDevice.Create(anr: integer);
begin
  inherited Create;

  initCom(anr);

end;

destructor tBTDevice.Destroy;
begin
  inherited;
  FreeAndNil(serial);
end;


procedure tBTDevice.initCom(anr: integer);

var
  io: integer;
  {$IFDEF WIN32}
const
 scom     : array[0..7]of string[5]=('COM1','COM2','COM3','COM4','COM5','COM6','COM7','COM8');
{$ELSE}
const
  scom: array[0..8] of string[15] =
    ('/dev/ttyS0', '/dev/ttyS1', '/dev/ttyS2', '/dev/ttyS3', '/dev/ttyS4',
    '/dev/ttyS5', '/dev/ttyS6', '/dev/ttyS7', '/dev/ttyS8');
{$ENDIF}
begin
  if (anr<1) or (anr>8) then
  begin
    exit;
  end;
  serial := TBlockSerial.Create;
  serial.linuxLock := False;
  //  try
  serial.Connect(scom[anr-1]);

  //  serial.config(115200,8,'N',1,false,false);
  serial.config(57600, 8, 'N', 1, False, True);

  //    piszlog(logrCP,'start 3',scom[anr-1],ser.lasterror,false);
  //  except
  //    serial:=nil;
  //  end;
end;


function tBTDevice.ReadLine: string;
begin
  // if serial.waitingData<>0 then begin
  Result := serial.recvPacket(100);
  if Result<>'' then
    debugln('odcztyy '+IntToStr(length(Result))+':'+asHex(Result));

  //  end else begin
  //    result:='';
  // end;

end;

procedure tBtDevice.Write(s: string);
begin
  serial.SendString(s);
end;

procedure tBTDevice.Read(aMultiplier: double);
var
  timeout: double;
  string_to_parse: boolean;
  return_line: string;
  event:   string;
  event_Type: char;
  xStatus: char;
  xLen, rssi: integer;
  mac:     string;
  notified_value: char;
  return_lenght: integer;
  start:   tDateTime;
  sStatus: string;
begin
  //read from serial during timeout, events parsed by arrival
  // serial read_time control variables
  string_to_parse := False;
  timeout := (1/(24*60*60*100.0)) * aMultiplier;
  // print "\t(%d seconds remaining...)" %timeout
  start := now+timeout;
  //    debugln('read start ');

  //read from serial port and show results
  //   while start > now() do begin
  // try to work 'til timeout
  string_to_parse := True;
  return_line := readline();
  //     debugln('time ',format(' %d %d ',[start,now()]));
  // while thereis string to parse
  while string_to_parse do
  begin
    if length(return_line) > 3 then
    begin
      // frame parsing
      return_lenght := Ord(return_line[RESPONSE_LENGTH_POS]) + 1;
      event := return_line[EVENT_CODE_POSITION+1] +
        return_line[EVENT_CODE_POSITION];
      event_type := return_line[EV_POS_EVENTTYPE];
      if (event = EVENT_GAPExtensionCommandStatus) then
      begin
        xStatus := return_line[error_code_position];
        case xStatus of
          #0: sStatus := 'SUCCESS';
          #$10: sStatus := 'Not ready';
          else
            sStatus := 'unknown';
        end;
        debugln('Command status '+sStatus+'  '+asHex(
          copy(return_Line, error_code_position+1, 2)));
        xLen := Ord(return_line[EV_POS_DataLength]);
        debugLN('value '+asHex(copy(return_line, EV_POS_DATALength+1, xLen)));

      end;
      if (event = EVENT_GAPDeviceInitDone) then
      begin
        mac := copy(return_line, error_code_position+1, 6);
        debugln('dev addr: '+asHex(mac));
      end;
      if (event = EVENT_GAPDeviceDiscoveryDone) then
      begin
        debugln('device discovery done num'+IntToStr(
          Ord(return_line[EV_POS_EVENTTYPE])));

      end;
      if (event = EVENT_GAPDeviceInformation) and
        (event_type = ETYPE_CONNECTABLE) then
      begin
        debugln('connectable'+copy(return_line, 18, 38));
        connectable := True;

      end;
      if (event = EVENT_GAPEstablishLink) then
      begin
        xStatus := return_line[error_code_position];
        case xStatus of
          #0: sStatus := 'SUCCESS';
          #$10: sStatus := 'Not ready';
          else
            sStatus := 'unknown';
        end;
        debugln('establish link '+sStatus);
        mac := copy(return_line, MAC_ADDRESS_START_POS, MAC_ADDRESS_LEN);
        debugln(#9#9'- mac: ', asHex(mac));
      end;
      if (event = EVENT_GAPDeviceInformation) and
        (event_type = ETYPE_DEVICEDISCOVERED) then
      begin
        debugln('response frame = ' + return_line);
        debugln(#9#9'- friendly name:', copy(return_line, 18, 38));
        // not all the frames carry RSSI
        rssi := Ord(return_line[EV_POS_RSSI_VALUE]);
        debugln(#9#9+format('- rssi: %f%s.',
          [(rssi * 100/AUX_RSSI_CALC), '%']));
        //print_progressbar(rssi * 100/AUX_RSSI_CALC)
        // get mac and reverse byte order
        mac := copy(return_line, MAC_ADDRESS_START_POS, MAC_ADDRESS_LEN);
        //mac := mac[::-1]
        peerAddr := mac;
        debugln(#9#9'- mac: ', asHex(mac));
      end;
      if event = EVENT_GAPNOTIFICATION then
      begin
        notified_value := return_line[length(return_line)];
        debugln(#9'notified value = ', notified_value);
      end;

      // next subframe within frame
      return_line :=
        copy(return_line, (return_lenght + RESPONSE_LENGTH_POS), 1000);
      return_line := return_line+readline();
    end
    else
    begin
      string_to_parse := False;
    end;
  end;
  //   end;
  //   debugln('read stop');
  //serial_fd.flushInput(); serial_fd.flushOutput();
end;


end.
