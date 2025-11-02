{**
  <summary>
    Programa de prueba para la detección de básculas USB conectadas al equipo.
    Muestra en consola todos los dispositivos USB/COM presentes y luego identifica
    los puertos donde hay básculas basadas en un archivo JSON de dispositivos conocidos.
  </summary>

  <remarks>
    Flujo de funcionamiento:
      1. Llama a <c>EnumerateAllDevices</c> para listar todos los dispositivos con VID, PID y puerto COM.
      2. Muestra la lista completa de dispositivos en la consola.
      3. Carga los dispositivos compatibles desde un archivo JSON usando <c>LoadDevicesFromJSON</c>.
      4. Llama a <c>DetectScalesPorts</c> para identificar los puertos COM donde hay básculas.
      5. Para cada puerto detectado, obtiene el tipo de báscula con <c>GetScaleTypeForPort</c>.
      6. Muestra los resultados finales en la consola.
  </remarks>

  <example>
    Uso típico:
      1. Crear un archivo JSON llamado "devices.json" con la lista de dispositivos compatibles.
      2. Ejecutar el programa.
      3. Observar en consola la lista de todos los dispositivos y las básculas detectadas.
  </example>
}
program DetectarBalanzas;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Balanzas,
  BalanzasJSON,
  Dispositivos in 'Dispositivos.pas';

var
  Devices: TArray<TScaleDevice>;
  Ports: TArray<string>;
  AllDevices: TArray<TDeviceInfo>;
  D: TDeviceInfo;
  i: Integer;
begin
  try
    Writeln('--- LISTA DE DISPOSITIVOS USB/COM PRESENTES ---');

    // Obtener y mostrar todos los dispositivos
    AllDevices := EnumerateAllDevices;
    for D in AllDevices do
      Writeln(Format('%-40s  VID=%-4s  PID=%-4s  COM=%-6s  PC=%s',
        [D.FriendlyName, D.VID, D.PID, D.COMPort, D.ComputerName]));

    Writeln;
    Writeln('--- DETECCIÓN DE BALANZAS USB ---');

    // Cargar dispositivos desde JSON
    Devices := LoadDevicesFromJSON('devices.json');

    // Detectar puertos de básculas
    Ports := DetectScalesPorts(Devices);

    // Mostrar resultados de básculas detectadas
    if Length(Ports) = 0 then
      Writeln('No se detectaron básculas.')
    else
    begin
      Writeln('Básculas detectadas:');
      for i := 0 to High(Ports) do
        Writeln(Ports[i], ' - Tipo: ', GetScaleTypeForPort(Ports[i], Devices));
    end;

    Writeln;
    Writeln('Finalizado. Presione ENTER para salir...');
    Readln;

  except
    on E: Exception do
      Writeln('Error: ', E.Message);
  end;
end.
