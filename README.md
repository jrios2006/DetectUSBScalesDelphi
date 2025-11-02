# Manual de Uso – Detección de Básculas USB en Delphi

## 1. Objetivo

Este conjunto de unidades y programa permite:

1. Detectar básculas USB conectadas al equipo.
2. Identificar el tipo de báscula mediante su VID/PID.
3. Obtener los puertos COM asociados.
4. Guardar o procesar la información de manera estructurada (JSON).

Se utiliza en aplicaciones Delphi que necesitan interactuar con básculas en entornos de laboratorio, industria o comercio.

---

## 2. Unidades

### 2.1 `Balanzas.pas`

**Funcionalidad:**

- Detecta puertos COM donde hay básculas usando la API de Windows `SetupDi*`.
- Compara VID/PID de los dispositivos conectados con los del JSON.
- Proporciona funciones públicas:

| Función | Descripción |
|---------|------------|
| `DetectScalesPorts(const Devices: TArray<TScaleDevice>): TArray<string>` | Devuelve un arreglo de strings con los puertos COM donde hay básculas detectadas. |
| `GetScaleTypeForPort(const COMPort: string; const Devices: TArray<TScaleDevice>): string` | Dado un puerto COM, devuelve el fabricante o tipo de báscula detectada. |

**Tipos definidos:**

```delphi
type
  TScaleDevice = record
    Manufacturer: string;  // Nombre del fabricante
    VID: string;           // ID del fabricante (hexadecimal, sin "0x")
    PIDs: TArray<string>;  // Lista de PID compatibles
  end;

  TDetectedScale = record
    Manufacturer: string;  // Nombre del fabricante detectado
    VID: string;           // VID detectado
    PID: string;           // PID detectado
    COMPort: string;       // Puerto COM donde se detectó la báscula
  end;

```

---

### Constantes:

```delphi
GUID_DEVINTERFACE_COMPORT: GUID usado para enumerar dispositivos COM.
```

---

### 2.2 `BalanzasJSON.pas`


**Funcionalidad:**

Funciones públicas:

* Maneja JSON para cargar y guardar dispositivos y resultados de detección.

Funciones públicas:

| Función                                                                          | Descripción                                                                      |
| -------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| `LoadJSONFile(const FileName: string): string`                                   | Lee un archivo JSON completo como string, eliminando BOM si existe.              |
| `LoadDevicesFromJSON(const FileName: string): TArray<TScaleDevice>`              | Convierte un JSON con dispositivos en un arreglo de `TScaleDevice`.              |
| `SaveScalesToJSON(const Scales: TArray<TDetectedScale>; const FileName: string)` | Guarda básculas detectadas en un JSON, incluyendo puerto, VID, PID y fabricante. |

## Ejemplo de JSON válido `devices.json`

```json
{
  "devices": [
    {
      "manufacturer": "Sartorius",
      "vid": "0x24BC",
      "pids": ["0x0010", "0x0005"]
    },
    {
      "manufacturer": "FTDI (FT232/FT2232/FT4232/FT232RL)",
      "vid": "0x0403",
      "pids": ["0x6001", "0x6010", "0x6011"]
    }
  ]
}
```

---

### 2.3 `Dispositivos.pas`

**Funcionalidad:**

Funciones públicas:

* Lista todos los dispositivos USB/COM presentes en el equipo que tengan VID, PID y puerto COM asignado.
* Proporciona información completa de cada dispositivo:

```delphi
TDeviceInfo = record
  FriendlyName: string; // Nombre amigable del dispositivo
  HardwareID: string;   // ID de hardware completo (VID, PID, REV)
  VID: string;          // Vendor ID extraído del HardwareID
  PID: string;          // Product ID extraído del HardwareID
  COMPort: string;      // Puerto COM asignado
  ComputerName: string; // Nombre del equipo
end;
```

Funciones principal:

| Función               | Descripción                                                                                    |
| --------------------- | ---------------------------------------------------------------------------------------------- |
| `EnumerateAllDevices` | Devuelve un arreglo de `TDeviceInfo` con todos los dispositivos que tengan VID, PID y COMPort. |

---

## Programa de prueba: DetectarBalanzas.dpr

Flujo de ejecución:

1. Lista todos los dispositivos presentes llamando a EnumerateAllDevices.
2. Muestra los resultados en consola (nombre, VID, PID, COM, equipo).
3. Carga dispositivos conocidos desde JSON (LoadDevicesFromJSON).
4. Detecta los puertos COM donde hay básculas (DetectScalesPorts).
5. Identifica el tipo de báscula para cada puerto (GetScaleTypeForPort).
6. Muestra los resultados finales en consola.


Variables principales:

| Variable     | Tipo                   | Descripción                                      |
| ------------ | ---------------------- | ------------------------------------------------ |
| `AllDevices` | `TArray<TDeviceInfo>`  | Lista completa de dispositivos presentes.        |
| `Devices`    | `TArray<TScaleDevice>` | Lista de dispositivos conocidos del JSON.        |
| `Ports`      | `TArray<string>`       | Arreglo de puertos COM detectados como básculas. |
| `D`          | `TDeviceInfo`          | Registro para recorrer `AllDevices`.             |
| `i`          | Integer                | Iterador para recorrer `Ports`.                  |


### Ejemplo de salida

```bash
--- LISTA DE DISPOSITIVOS USB/COM PRESENTES ---
Dispositivo serie USB (COM5)              VID=24BC  PID=0010  COM=COM5    PC=DESJRA01

--- DETECCIÓN DE BALANZAS USB ---
Básculas detectadas:
Dispositivo serie USB (COM5) - Tipo: Sartorius

Finalizado. Presione ENTER para salir...
```

---
