{%RunFlags BUILD-}
unit mbmain;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  xlbtdevice,
  SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Edit1: TEdit;
    Memo1: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    BLE : tBtDevice;
    machine_state : integer;
    { private declarations }
    procedure print(s:string);
  public
    { public declarations }
    procedure Doactivate(sender : tObject);
    procedure main;
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

const
DEVICE_INIT_STATE           = 0;
GET_PARAM_STATE             = 1;
INQUIRY_STATE               = 2;
CANCEL_INQUIRY_STATE        = 3;
LINK_REQ_ESTABLISH_STATE    = 4;
ATT_WRITE_VALUE_STATE       = 5;
ATT_WRITE_BEHAVIOUR_STATE   = 6;
WAITING_NOTIFICATION_STATE  = 7;
TERMINATING_LINK_STATE      = 8;

procedure TForm1.FormCreate(Sender: TObject);
begin
    print ('Bluetooth Low Energy simple demo under Linux.');
    print ('---------------------------------------------');
   // serial._fd globally defined
   BLE:=tBtDevice.create(3);

end;


procedure TForm1.FormDestroy(Sender: TObject);
begin
    BLE.destroy;

end;

procedure tForm1.print(s : string);
begin
    memo1.Append(s+#10);

end;

procedure TForm1.Doactivate(sender: tObject);
begin

end;




procedure  tForm1.main();
var
    inquiry_rounds: integer;
    operation_multiplier: double;
begin
//    os.system("clear")
   // machine states
    // inquiry rounds
    inquiry_rounds := 0;
    machine_state := DEVICE_INIT_STATE;

    // continuous bucle state_machine
    while(machine_state < LINK_REQ_ESTABLISH_STATE) do begin
        // operation timeout
        operation_multiplier := HCI_NORMAL_MULTIPLIER;

        // Tx command sent to serial
        // Rx event HCI_LE_ExtEvent (command status from HCI)
        // + Rx event (command results from GAP)
        // + Rx event (command END from HCI)
        if machine_state = DEVICE_INIT_STATE then begin
            print (GAP_DeviceInit);
            BLE.write(GAP_DeviceInit);
            inc(machine_state);
        end else if  machine_state = GET_PARAM_STATE then begin
	    // really, now we are not doing anything here"
	    inc(machine_state);
        end else if machine_state = INQUIRY_STATE then begin
            operation_multiplier := INQUIRY_MULTIPLIER;

            if(inquiry_rounds < MAX_INQUIRY_ROUNDS) then begin
               if(inquiry_rounds = 0) then begin
	 	    // first time
		    print ('GAP_DeviceDiscoveryRequest');
                    BLE.write(GAP_DeviceDiscoveryRequest);
		    inc(inquiry_rounds );
	       end else if (inquiry_rounds = MAX_INQUIRY_ROUNDS) then begin
		  // last time
	          inc(machine_state)
               end;
            end;
        end else if  machine_state = CANCEL_INQUIRY_STATE then begin
            print ('Canceling GAP_DeviceDiscoveryRequest just-in-case:');
            BLE.write(GAP_DeviceDiscoveryCancel);
	    // next statement situates machine_state in LINK_REQ_ESTABLISH_STATE, and we finish this little demo here
	    inc(machine_state);
        end;

        // always try to read after state_machine
        BLE.read(operation_multiplier);
    end;
    print ('End of execution.');
   end;


end.

