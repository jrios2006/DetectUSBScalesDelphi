unit Dispositivos;

interface

uses
  Windows, SysUtils, Registry, SetupAPI;

type

  /// <summary>
  /// Registro que contiene información de un dispositivo detectado en el sistema.
  /// </summary>
  TDeviceInfo = record
    /// <summary>Nombre amigable del dispositivo tal como lo muestra Windows en el Administrador de dispositivos.</summary>
    FriendlyName: string;
    /// <summary>ID de hardware completo del dispositivo (incluye VID, PID, versión, etc.).</summary>
    HardwareID: string;
    /// <summary>Vendor ID (VID) extraído del HardwareID.</summary>
    VID: string;
    /// <summary>Product ID (PID) extraído del HardwareID.</summary>
    PID: string;
    /// <summary>Nombre del puerto COM asignado al dispositivo (si aplica).</summary>
    COMPort: string;
    /// <summary>Nombre del equipo donde se detectó el dispositivo.</summary>
    ComputerName: string;
  end;

/// <summary>
/// Enumera todos los dispositivos presentes en el sistema que tengan VID, PID y un puerto COM asignado.
/// </summary>
/// <remarks>
/// Esta función recorre todos los dispositivos disponibles mediante la API de Windows SetupAPI.
/// Para cada dispositivo intenta obtener:
///   - <c>FriendlyName</c>: nombre amigable del dispositivo.
///   - <c>HardwareID</c>: identificador de hardware con VID y PID.
///   - <c>VID</c> y <c>PID</c> extraídos del HardwareID.
///   - <c>COMPort</c>: puerto COM asignado (si existe).
///   - <c>ComputerName</c>: nombre del equipo local.
///
/// Solo se incluyen en el resultado los dispositivos que tengan los tres valores:
/// VID, PID y COMPort. Esto permite filtrar dispositivos irrelevantes (audio, cámaras, etc.).
/// </remarks>
/// <returns>
/// Arreglo de <see cref="TDeviceInfo"/> con la información de los dispositivos filtrados.
/// </returns>
function EnumerateAllDevices: TArray<TDeviceInfo>;

implementation


const
  MAX_COMPUTERNAME_LENGTH = 31;

function EnumerateAllDevices: TArray<TDeviceInfo>;
var
  DeviceInfoSet: HDEVINFO;
  DeviceInfoData: SP_DEVINFO_DATA;
  DeviceIndex: Cardinal;
  RequiredSize: DWORD;
  RegDataType: DWORD;
  FriendlyNameA: array[0..511] of AnsiChar;
  HardwareIDA: array[0..1023] of AnsiChar;
  FriendlyName, HardwareID, VID, PID, COMPort, ComputerName: string;
  Devices: TArray<TDeviceInfo>;
  RegKey: HKEY;
  PortName: array[0..255] of Char;
  DataSize: DWORD;
  Size: DWORD;
begin
  SetLength(Devices, 0);

  // Nombre del equipo
  SetLength(ComputerName, MAX_COMPUTERNAME_LENGTH + 1);
  Size := MAX_COMPUTERNAME_LENGTH + 1;
  if not GetComputerName(PChar(ComputerName), Size) then
    ComputerName := '(unknown)';

  // Obtener todos los dispositivos presentes
  DeviceInfoSet := SetupDiGetClassDevs(nil, nil, 0, DIGCF_PRESENT or DIGCF_ALLCLASSES);
  if (NativeUInt(DeviceInfoSet) = NativeUInt(INVALID_HANDLE_VALUE)) then
    Exit;

  DeviceIndex := 0;
  DeviceInfoData.cbSize := SizeOf(SP_DEVINFO_DATA);

  while SetupDiEnumDeviceInfo(DeviceInfoSet, DeviceIndex, DeviceInfoData) do
  begin
    FillChar(FriendlyNameA, SizeOf(FriendlyNameA), 0);
    FillChar(HardwareIDA, SizeOf(HardwareIDA), 0);

    // Nombre amigable
    if SetupDiGetDeviceRegistryProperty(DeviceInfoSet, @DeviceInfoData,
       SPDRP_FRIENDLYNAME, @RegDataType, @FriendlyNameA, SizeOf(FriendlyNameA), @RequiredSize) then
      FriendlyName := string(FriendlyNameA)
    else
      FriendlyName := '(sin nombre)';

    // Hardware ID (para VID/PID)
    if SetupDiGetDeviceRegistryProperty(DeviceInfoSet, @DeviceInfoData,
       SPDRP_HARDWAREID, @RegDataType, @HardwareIDA, SizeOf(HardwareIDA), @RequiredSize) then
      HardwareID := string(HardwareIDA)
    else
      HardwareID := '';

    VID := '';
    PID := '';
    if Pos('VID_', UpperCase(HardwareID)) > 0 then
      VID := Copy(UpperCase(HardwareID), Pos('VID_', UpperCase(HardwareID)) + 4, 4);
    if Pos('PID_', UpperCase(HardwareID)) > 0 then
      PID := Copy(UpperCase(HardwareID), Pos('PID_', UpperCase(HardwareID)) + 4, 4);

    // Buscar COM Port si aplica
    COMPort := '';
    RegKey := SetupDiOpenDevRegKey(DeviceInfoSet, @DeviceInfoData, DICS_FLAG_GLOBAL, 0, DIREG_DEV, KEY_READ);
    if RegKey <> 0 then
    begin
      FillChar(PortName, SizeOf(PortName), 0);
      DataSize := SizeOf(PortName);
      if RegQueryValueEx(RegKey, 'PortName', nil, nil, @PortName, @DataSize) = ERROR_SUCCESS then
        COMPort := PortName;
      RegCloseKey(RegKey);
    end;

    // SOLO agregar si tiene VID, PID y COM Port
    if (VID <> '') and (PID <> '') and (COMPort <> '') then
    begin
      SetLength(Devices, Length(Devices) + 1);
      Devices[High(Devices)].FriendlyName := FriendlyName;
      Devices[High(Devices)].HardwareID := HardwareID;
      Devices[High(Devices)].VID := VID;
      Devices[High(Devices)].PID := PID;
      Devices[High(Devices)].COMPort := COMPort;
      Devices[High(Devices)].ComputerName := ComputerName;
    end;

    Inc(DeviceIndex);
  end;

  SetupDiDestroyDeviceInfoList(DeviceInfoSet);
  Result := Devices;
end;

end.

