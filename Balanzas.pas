unit Balanzas;
/// <summary>
/// GUID estándar de Windows para interfaces de dispositivos COM (puertos serie/USB).
/// Se usa con la API SetupDi* para enumerar dispositivos COM virtuales.
/// </summary>
interface

uses
  Windows, SysUtils, Classes;

  const
  GUID_DEVINTERFACE_COMPORT: TGUID = '{86E0D1E0-8089-11D0-9CE4-08003E301F73}';

type
  /// <summary>
  /// Representa un modelo de báscula que queremos detectar.
  /// </summary>
  /// <remarks>
  /// Cada báscula se define con su fabricante, VID y lista de PIDs compatibles.
  /// VID y PIDs deben estar en formato hexadecimal, sin el prefijo '0x'.
  /// Ejemplo:
  ///   VID = '24BC'
  ///   PIDs = ['0010', '0005']
  /// </remarks>
  TScaleDevice = record
    /// <summary>Nombre del fabricante de la báscula.</summary>
    Manufacturer: string;

    /// <summary>Vendor ID del dispositivo (hexadecimal, sin '0x').</summary>
    VID: string;

    /// <summary>Lista de Product IDs compatibles (hexadecimal, sin '0x').</summary>
    PIDs: TArray<string>;
  end;

  /// <summary>
  /// Representa una báscula detectada en un puerto COM del sistema.
  /// </summary>
  /// <remarks>
  /// Cada registro incluye la información de fabricante, VID, PID y el puerto COM
  /// donde se ha detectado el dispositivo.
  /// </remarks>
  TDetectedScale = record
    /// <summary>Nombre del fabricante de la báscula.</summary>
    Manufacturer: string;

    /// <summary>Vendor ID detectado en el dispositivo (hexadecimal, sin '0x').</summary>
    VID: string;

    /// <summary>Product ID detectado en el dispositivo (hexadecimal, sin '0x').</summary>
    PID: string;

    /// <summary>Puerto COM donde se detectó la báscula, por ejemplo 'COM5'.</summary>
    COMPort: string;
  end;


// Funciones públicas que otros programas pueden usar
function DetectScalesPorts(const Devices: TArray<TScaleDevice>): TArray<string>;
function GetScaleTypeForPort(const COMPort: string; const Devices: TArray<TScaleDevice>): string;

implementation

uses
  SetupAPI;  // Tu unit para SetupDi* API

/// <summary>
/// Elimina caracteres nulos y espacios de una cadena.
/// </summary>
function CleanStr(const S: string): string;
begin
  Result := Trim(StringReplace(S, #0, '', [rfReplaceAll]));
end;


/// <summary>
/// Devuelve una lista de puertos COM donde se han detectado básculas conectadas.
/// </summary>
/// <param name="Devices">
/// Arreglo de dispositivos conocidos (TScaleDevice) que contiene el fabricante, VID y lista de PIDs.
/// La función compara los dispositivos serie/USB del sistema con esta lista para identificar básculas.
/// </param>
/// <returns>
/// Arreglo de cadenas (TArray&lt;string&gt;) con los nombres de los puertos COM donde se detectaron básculas.
/// Si no se detecta ninguna báscula, devuelve un arreglo vacío.
/// </returns>
/// <remarks>
/// Esta función recorre todos los dispositivos serie/USB disponibles usando la API de Windows SetupAPI.
/// Extrae el VID y PID del HardwareID de cada dispositivo y los compara con los valores proporcionados en <paramref name="Devices"/>.
/// Se devuelve únicamente el puerto COM; para obtener el tipo/fabricante de la báscula en un puerto específico,
/// se puede usar la función <see cref="GetScaleTypeForPort"/>.
/// </remarks>
function DetectScalesPorts(const Devices: TArray<TScaleDevice>): TArray<string>;
  var
    DeviceInfoSet: HDEVINFO;
    DeviceInfoData: SP_DEVINFO_DATA;
    DeviceIndex: Cardinal;
    RequiredSize: DWORD;
    RegDataType: DWORD;
    FriendlyNameA: array[0..511] of AnsiChar;
    HardwareIDA: array[0..1023] of AnsiChar;
    COMPort, HardwareID: string;
    VID, PID: string;
    D, P: Integer;
    MatchFound: Boolean;
    MatchIndex: Integer;
    Ports: TArray<string>;
begin
  SetLength(Ports, 0);

  DeviceInfoSet := SetupDiGetClassDevs(@GUID_DEVINTERFACE_COMPORT, nil, 0, DIGCF_PRESENT or DIGCF_DEVICEINTERFACE);
  if (NativeUInt(DeviceInfoSet) = NativeUInt(INVALID_HANDLE_VALUE)) or (DeviceInfoSet = nil) then
    Exit;

  DeviceIndex := 0;
  DeviceInfoData.cbSize := SizeOf(SP_DEVINFO_DATA);

  while SetupDiEnumDeviceInfo(DeviceInfoSet, DeviceIndex, DeviceInfoData) do
  begin
    FillChar(FriendlyNameA, SizeOf(FriendlyNameA), 0);
    FillChar(HardwareIDA, SizeOf(HardwareIDA), 0);

    if SetupDiGetDeviceRegistryProperty(DeviceInfoSet, @DeviceInfoData,
       SPDRP_FRIENDLYNAME, @RegDataType, @FriendlyNameA, SizeOf(FriendlyNameA), @RequiredSize) then
      COMPort := string(FriendlyNameA)
    else
      COMPort := '(desconocido)';

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

    if (VID <> '') and (PID <> '') then
    begin
      MatchFound := False;

      for D := 0 to High(Devices) do
      begin
        if SameText(CleanStr(StringReplace(Devices[D].VID, '0x', '', [rfReplaceAll])), CleanStr(VID)) then
        begin
          for P := 0 to High(Devices[D].PIDs) do
          begin
            if SameText(CleanStr(StringReplace(Devices[D].PIDs[P], '0x', '', [rfReplaceAll])), CleanStr(PID)) then
            begin
              MatchFound := True;
              Break;
            end;
          end;
        end;
        if MatchFound then Break;
      end;

      if MatchFound then
      begin
        SetLength(Ports, Length(Ports)+1);
        Ports[High(Ports)] := COMPort;
      end;
    end;

    Inc(DeviceIndex);
  end;

  SetupDiDestroyDeviceInfoList(DeviceInfoSet);

  Result := Ports;
end;

/// <summary>
/// Devuelve el fabricante de la báscula conectada a un puerto COM específico.
/// </summary>
/// <param name="COMPort">
/// Nombre del puerto COM donde se desea identificar la báscula, por ejemplo 'COM5'.
/// </param>
/// <param name="Devices">
/// Arreglo de dispositivos conocidos (TScaleDevice) cargados desde JSON u otra fuente.
/// Contiene el fabricante, VID y lista de PIDs para comparar con el dispositivo detectado.
/// </param>
/// <returns>
/// Cadena con el nombre del fabricante si se encuentra una coincidencia,
/// o cadena vacía ('') si no se detecta ninguna báscula en el puerto.
/// </returns>
/// <remarks>
/// La función recorre todos los dispositivos serie/USB del sistema usando la API de Windows SetupAPI.
/// Extrae VID y PID del HardwareID del dispositivo y compara con los valores de <paramref name="Devices"/>.
/// Solo devuelve un fabricante por puerto; si hay varios dispositivos compatibles, devuelve el primero encontrado.
/// </remarks>
function GetScaleTypeForPort(const COMPort: string; const Devices: TArray<TScaleDevice>): string;
  var
    DeviceInfoSet: HDEVINFO;
    DeviceInfoData: SP_DEVINFO_DATA;
    DeviceIndex: Cardinal;
    RequiredSize: DWORD;
    RegDataType: DWORD;
    FriendlyNameA: array[0..511] of AnsiChar;
    HardwareIDA: array[0..1023] of AnsiChar;
    HardwareID: string;  // <<<<<< Asegúrate de tener esta línea
    VID, PID: string;
    D, P: Integer;
    MatchFound: Boolean;
    MatchIndex: Integer;
    Ports: TArray<string>;
begin
  Result := '';

  DeviceInfoSet := SetupDiGetClassDevs(@GUID_DEVINTERFACE_COMPORT, nil, 0, DIGCF_PRESENT or DIGCF_DEVICEINTERFACE);
  if (NativeUInt(DeviceInfoSet) = NativeUInt(INVALID_HANDLE_VALUE)) or (DeviceInfoSet = nil) then
    Exit;

  DeviceIndex := 0;
  DeviceInfoData.cbSize := SizeOf(SP_DEVINFO_DATA);

  while SetupDiEnumDeviceInfo(DeviceInfoSet, DeviceIndex, DeviceInfoData) do
  begin
    FillChar(FriendlyNameA, SizeOf(FriendlyNameA), 0);
    FillChar(HardwareIDA, SizeOf(HardwareIDA), 0);

    if SetupDiGetDeviceRegistryProperty(DeviceInfoSet, @DeviceInfoData,
       SPDRP_FRIENDLYNAME, @RegDataType, @FriendlyNameA, SizeOf(FriendlyNameA), @RequiredSize) then
    begin
      if CleanStr(string(FriendlyNameA)) <> COMPort then
      begin
        Inc(DeviceIndex);
        Continue;
      end;
    end
    else
    begin
      Inc(DeviceIndex);
      Continue;
    end;

    if SetupDiGetDeviceRegistryProperty(DeviceInfoSet, @DeviceInfoData,
       SPDRP_HARDWAREID, @RegDataType, @HardwareIDA, SizeOf(HardwareIDA), @RequiredSize) then
      HardwareID := string(HardwareIDA)
    else
      HardwareID := '';

    // Extraer VID/PID desde HardwareID
    VID := '';
    PID := '';
    if Pos('VID_', UpperCase(HardwareID)) > 0 then
      VID := Copy(UpperCase(HardwareID), Pos('VID_', UpperCase(HardwareID)) + 4, 4);
    if Pos('PID_', UpperCase(HardwareID)) > 0 then
      PID := Copy(UpperCase(HardwareID), Pos('PID_', UpperCase(HardwareID)) + 4, 4);

    if (VID <> '') and (PID <> '') then
    begin
      MatchFound := False;
      for D := 0 to High(Devices) do
      begin
        if SameText(CleanStr(StringReplace(Devices[D].VID, '0x', '', [rfReplaceAll])), CleanStr(VID)) then
        begin
          for P := 0 to High(Devices[D].PIDs) do
          begin
            if SameText(CleanStr(StringReplace(Devices[D].PIDs[P], '0x', '', [rfReplaceAll])), CleanStr(PID)) then
            begin
              MatchFound := True;
              Break;
            end;
          end;
        end;
        if MatchFound then Break;
      end;

      if MatchFound then
      begin
        Result := Devices[D].Manufacturer;
        Break;
      end;
    end;

    Inc(DeviceIndex);
  end;

  SetupDiDestroyDeviceInfoList(DeviceInfoSet);
end;

end.

