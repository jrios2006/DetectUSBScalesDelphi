unit SetupAPI;

interface

uses
  Windows;

const
  DIGCF_DEFAULT         = $00000001;
  DIGCF_PRESENT         = $00000002;
  DIGCF_ALLCLASSES      = $00000004;
  DIGCF_PROFILE         = $00000008;
  DIGCF_DEVICEINTERFACE = $00000010;

  SPDRP_HARDWAREID      = $00000001;
  SPDRP_FRIENDLYNAME    = $0000000C;

  DICS_FLAG_GLOBAL      = $00000001;
  DIREG_DEV             = $00000001;
  KEY_READ              = $20019;

type
  HDEVINFO = Pointer;

  PSP_DEVINFO_DATA = ^SP_DEVINFO_DATA;
  SP_DEVINFO_DATA = record
    cbSize: DWORD;
    ClassGuid: TGUID;
    DevInst: DWORD;
    Reserved: ULONG_PTR;
  end;

function SetupDiGetClassDevs(ClassGuid: PGUID; Enumerator: PChar; hwndParent: HWND; Flags: DWORD): HDEVINFO; stdcall;
function SetupDiEnumDeviceInfo(DeviceInfoSet: HDEVINFO; MemberIndex: DWORD; var DeviceInfoData: SP_DEVINFO_DATA): BOOL; stdcall;
function SetupDiGetDeviceInstanceId(DeviceInfoSet: HDEVINFO; DeviceInfoData: PSP_DEVINFO_DATA;
  DeviceInstanceId: PChar; DeviceInstanceIdSize: DWORD; RequiredSize: PDWORD): BOOL; stdcall;
function SetupDiGetDeviceRegistryProperty(DeviceInfoSet: HDEVINFO; DeviceInfoData: PSP_DEVINFO_DATA;
  Property_: DWORD; PropertyRegDataType: PDWORD; PropertyBuffer: PBYTE;
  PropertyBufferSize: DWORD; RequiredSize: PDWORD): BOOL; stdcall;
function SetupDiOpenDevRegKey(DeviceInfoSet: HDEVINFO; DeviceInfoData: PSP_DEVINFO_DATA;
  Scope, HwProfile, KeyType, samDesired: DWORD): HKEY; stdcall;
function SetupDiDestroyDeviceInfoList(DeviceInfoSet: HDEVINFO): BOOL; stdcall;

implementation

function SetupDiGetClassDevs; external 'setupapi.dll' name 'SetupDiGetClassDevsA';
function SetupDiEnumDeviceInfo; external 'setupapi.dll' name 'SetupDiEnumDeviceInfo';
function SetupDiGetDeviceInstanceId; external 'setupapi.dll' name 'SetupDiGetDeviceInstanceIdA';
function SetupDiGetDeviceRegistryProperty; external 'setupapi.dll' name 'SetupDiGetDeviceRegistryPropertyA';
function SetupDiOpenDevRegKey; external 'setupapi.dll' name 'SetupDiOpenDevRegKey';
function SetupDiDestroyDeviceInfoList; external 'setupapi.dll' name 'SetupDiDestroyDeviceInfoList';

end.
