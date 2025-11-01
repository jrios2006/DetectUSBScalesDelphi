unit BalanzasJSON;

/// <summary>
/// Unidad que contiene funciones para leer y escribir archivos JSON relacionados
/// con básculas USB. Permite cargar la lista de dispositivos conocidos desde un JSON
/// y guardar los resultados de detección de básculas.
/// </summary>


interface

uses
  System.SysUtils, System.Classes, System.JSON, System.IOUtils,
  Balanzas; // Para TScaleDevice y TDetectedScale

/// <summary>
/// Lee el contenido completo de un archivo JSON y devuelve su contenido como cadena UTF-8.
/// </summary>
/// <param name="FileName">
/// Ruta completa del archivo JSON a leer. Debe existir en disco.
/// </param>
/// <returns>
/// Devuelve el contenido del archivo como una cadena UTF-8.
/// Si el archivo contiene BOM (marca de orden de bytes), esta función lo elimina automáticamente.
/// </returns>
/// <exception cref="Exception">
/// Se lanza una excepción si el archivo no existe o no se puede leer correctamente.
/// </exception>
/// <remarks>
/// Esta función no realiza validación del contenido JSON, solo lee el archivo como texto.
/// Para analizar el JSON, se puede usar <c>LoadDevicesFromJSON</c> o cualquier otro parser JSON.
/// </remarks>
function LoadJSONFile(const FileName: string): string;

/// <summary>
/// Carga la lista de dispositivos (básculas) desde un archivo JSON.
/// </summary>
/// <param name="FileName">
/// Ruta completa del archivo JSON que contiene la definición de dispositivos.
/// Debe existir y contener un arreglo "devices" con la estructura esperada.
/// </param>
/// <returns>
/// Devuelve un arreglo <c>TArray&lt;TScaleDevice&gt;</c> con todos los dispositivos
/// encontrados en el JSON.
/// Cada <c>TScaleDevice</c> contiene:
///   - <c>Manufacturer</c>: nombre del fabricante
///   - <c>VID</c>: Vendor ID en formato hexadecimal (sin "0x")
///   - <c>PIDs</c>: arreglo de Product IDs en formato hexadecimal (sin "0x")
/// </returns>
/// <exception cref="Exception">
/// Se lanza una excepción si:
///   - El archivo no existe
///   - No se puede leer el contenido JSON
///   - No se encuentra el arreglo "devices" dentro del JSON
/// </exception>
/// <remarks>
/// Esta función utiliza <c>LoadJSONFile</c> para leer el contenido del archivo.
/// Convierte todos los VID y PID a mayúsculas y elimina el prefijo "0x".
/// No valida la conectividad de los dispositivos; solo devuelve la definición del JSON.
/// </remarks>
function LoadDevicesFromJSON(const FileName: string): TArray<TScaleDevice>;

/// <summary>
/// Guarda la lista de básculas detectadas en un archivo JSON.
/// </summary>
/// <param name="Scales">
/// Arreglo <c>TArray&lt;TDetectedScale&gt;</c> con las básculas detectadas.
/// Cada <c>TDetectedScale</c> contiene:
///   - <c>Manufacturer</c>: nombre del fabricante
///   - <c>VID</c>: Vendor ID en formato hexadecimal
///   - <c>PID</c>: Product ID en formato hexadecimal
///   - <c>COMPort</c>: nombre del puerto serie donde está conectada la báscula
/// </param>
/// <param name="FileName">
/// Ruta completa del archivo JSON donde se guardarán los resultados.
/// Si el archivo ya existe, será sobrescrito.
/// </param>
/// <remarks>
/// La función genera un arreglo JSON donde cada objeto representa una báscula detectada.
/// Utiliza codificación UTF-8 y crea un JSON legible para futuras lecturas o integración con otros programas.
/// No valida la existencia de los puertos o la conexión actual de las básculas; simplemente guarda la información proporcionada.
/// </remarks>
procedure SaveScalesToJSON(const Scales: TArray<TDetectedScale>; const FileName: string);

implementation

function LoadJSONFile(const FileName: string): string;
var
  Bytes: TBytes;
  TextStart: Integer;
begin
  if not FileExists(FileName) then
    raise Exception.CreateFmt('No se encontró el archivo JSON: %s', [FileName]);

  Bytes := TFile.ReadAllBytes(FileName);
  TextStart := 0;

  // Elimina BOM si existe
  if (Length(Bytes) >= 3) and (Bytes[0] = $EF) and (Bytes[1] = $BB) and (Bytes[2] = $BF) then
    TextStart := 3;

  Result := TEncoding.UTF8.GetString(Bytes, TextStart, Length(Bytes) - TextStart);
end;

function LoadDevicesFromJSON(const FileName: string): TArray<TScaleDevice>;
var
  JSONText: string;
  JSONObj: TJSONObject;
  DevicesArray: TJSONArray;
  DeviceObj: TJSONObject;
  i, j: Integer;
  Device: TScaleDevice;
  PIDsArray: TJSONArray;
begin
  JSONText := LoadJSONFile(FileName);
  JSONObj := TJSONObject.ParseJSONValue(JSONText) as TJSONObject;
  if JSONObj = nil then
    raise Exception.Create('Error al analizar el archivo JSON.');

  try
    DevicesArray := JSONObj.GetValue<TJSONArray>('devices');
    if DevicesArray = nil then
      raise Exception.Create('El JSON no contiene el arreglo "devices".');

    SetLength(Result, DevicesArray.Count);

    for i := 0 to DevicesArray.Count - 1 do
    begin
      DeviceObj := DevicesArray.Items[i] as TJSONObject;
      Device.Manufacturer := DeviceObj.GetValue<string>('manufacturer');
      Device.VID := UpperCase(StringReplace(DeviceObj.GetValue<string>('vid'), '0X', '', [rfReplaceAll]));

      PIDsArray := DeviceObj.GetValue<TJSONArray>('pids');
      if PIDsArray <> nil then
      begin
        SetLength(Device.PIDs, PIDsArray.Count);
        for j := 0 to PIDsArray.Count - 1 do
          Device.PIDs[j] := UpperCase(StringReplace(PIDsArray.Items[j].Value, '0X', '', [rfReplaceAll]));
      end
      else
        SetLength(Device.PIDs, 0);

      Result[i] := Device;
    end;
  finally
    JSONObj.Free;
  end;
end;

procedure SaveScalesToJSON(const Scales: TArray<TDetectedScale>; const FileName: string);
var
  JSONArray: TJSONArray;
  JSONObj: TJSONObject;
  i: Integer;
begin
  JSONArray := TJSONArray.Create;
  try
    for i := 0 to High(Scales) do
    begin
      JSONObj := TJSONObject.Create;
      JSONObj.AddPair('manufacturer', Scales[i].Manufacturer);
      JSONObj.AddPair('vid', Scales[i].VID);
      JSONObj.AddPair('pid', Scales[i].PID);
      JSONObj.AddPair('com_port', Scales[i].COMPort);
      JSONArray.AddElement(JSONObj);
    end;
    TFile.WriteAllText(FileName, JSONArray.ToString, TEncoding.UTF8);
  finally
    JSONArray.Free;
  end;
end;

end.

