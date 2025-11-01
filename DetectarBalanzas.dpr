program DetectarBalanzas;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Balanzas,       // Contiene TScaleDevice y TDetectedScale
  BalanzasJSON;   // Funciones JSON que usan Balanzas.TScaleDevice

/// <summary>
/// Programa de prueba para la detección de básculas USB conectadas al equipo.
/// Utiliza las unidades <c>Balanzas</c> y <c>BalanzasJSON</c> para:
///   1. Cargar la lista de dispositivos conocidos desde un archivo JSON.
///   2. Detectar los puertos COM donde hay básculas conectadas.
///   3. Identificar el tipo de cada báscula detectada.
///   4. Mostrar los resultados por consola.
/// </summary>
/// <remarks>
/// Flujo de uso:
///   1. Crear un archivo JSON con la lista de dispositivos compatibles (p.ej. "devices.json").
///   2. Llamar a <c>LoadDevicesFromJSON</c> para cargar los dispositivos.
///   3. Llamar a <c>DetectScalesPorts</c> para obtener los puertos donde están las básculas.
///   4. Para cada puerto detectado, usar <c>GetScaleTypeForPort</c> para obtener el tipo de báscula.
///   5. Mostrar los resultados en consola o guardarlos mediante <c>SaveScalesToJSON</c> si se desea.
/// </remarks>

var
  Devices: TArray<TScaleDevice>;
  Ports: TArray<string>;
  i: Integer;
begin
  try
    Writeln('--- DETECCIÓN DE BALANZAS USB ---');

    // Cargar dispositivos desde JSON
    Devices := LoadDevicesFromJSON('devices.json');

    // Detectar puertos de básculas
    Ports := DetectScalesPorts(Devices);

    // Mostrar resultados
    if Length(Ports) = 0 then
      Writeln('No se detectaron básculas.')
    else
    begin
      Writeln('Básculas detectadas:');
      for i := 0 to High(Ports) do
        Writeln(Ports[i], ' - Tipo: ', GetScaleTypeForPort(Ports[i], Devices));
    end;

    Writeln('Finalizado. Presione ENTER para salir...');
    Readln;

  except
    on E: Exception do
      Writeln('Error: ', E.Message);
  end;
end.

