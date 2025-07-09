# Auditoría y Documentación de `anpr_poc.py`

## 1. Instalación y Configuración

Antes de ejecutar la prueba de concepto, es necesario descargar e instalar el SDK del fabricante.

1.  **Descargar el SDK**: Baje el archivo ZIP desde la siguiente URL oficial:
    ```
    https://materialfile.dahuasecurity.com/uploads/soft/20250508/General_NetSDK_Eng_Python_linux64_IS_V3.060.0000000.0.R.250409.zip
    ```
2.  **Descomprimir**: Cree una carpeta llamada `sdk_docs_temp` en la raíz de este proyecto. Descomprima el contenido del archivo ZIP dentro de esta carpeta. La estructura de archivos resultante debería ser `sdk_docs_temp/General_NetSDK_.../`.
3.  **Credenciales**: Abra el archivo `anpr_poc.py` y modifique las variables `USER_NAME`, `PASSWORD`, `PORT` y la lista de `CAMERAS` con los datos de sus dispositivos.

Una vez completados estos pasos, puede ejecutar la prueba con el script `run_poc.sh`.

---

## 2. Resumen General

El proyecto `anpr-poc` es una prueba de concepto (PoC) diseñada para interactuar con una cámara de red compatible con un SDK específico. Su objetivo principal es el Reconocimiento Automático de Matrículas (ANPR).

El script principal, `anpr_poc.py`, se conecta a la cámara, se suscribe a los eventos de análisis de video inteligentes (IVS) y espera a que la cámara detecte una matrícula. Cuando esto ocurre, el script procesa la información, la registra en un archivo de texto y guarda la imagen asociada al evento en el disco.

## 3. Flujo de Ejecución

El script se ejecuta a través de `run_poc.sh`, que simplemente invoca `python3 anpr_poc.py`. El flujo de operación es el siguiente:

1.  **Inicialización del SDK**: El script carga e inicializa las librerías del SDK (`CLIENT_InitEx`) y configura un callback para gestionar desconexiones (`DisConnectCallBack`).
2.  **Login en el Dispositivo**: Utiliza credenciales codificadas (IP, puerto, usuario, contraseña) para autenticarse en la cámara mediante `CLIENT_LoginEx2`.
3.  **Inicio de "Real Play" (Opcional pero recomendado)**: Se inicia una transmisión de video en tiempo real con `CLIENT_RealPlayEx`. Aunque el script no procesa activamente los fotogramas de este video (el callback `RealDataCallBack_V2` está vacío), iniciar el "real play" es a menudo un requisito del SDK para asegurar que el dispositivo esté activo y enviando eventos correctamente.
4.  **Suscripción a Eventos de Alarma**: Este es el paso crucial. La función `CLIENT_StartListenEx` le dice a la cámara que comience a enviar todos los eventos de análisis que genere al script.
5.  **Procesamiento de Eventos (Callback)**: El script registra la función `AnalyzerDataCallBack` para que se ejecute cada vez que llega un evento. Esta función:
    *   Filtra los eventos para actuar solo sobre los relacionados con el tráfico y matrículas (ej. `EVENT_IVS_TRAFFICJUNCTION`).
    *   Extrae los datos del evento, como el número de matrícula (`szPlateNumber`), el color de la matrícula y la hora.
    *   Llama a `CLIENT_SaveFile` para guardar la imagen del vehículo que disparó el evento en un archivo JPG. El nombre del archivo se genera dinámicamente.
    *   Añade una línea de registro al archivo `anpr_log.txt` con los datos de la matrícula.
6.  **Bucle de Espera**: El script entra en un bucle infinito (`while True: time.sleep(1)`) para mantener el hilo principal vivo. Esto es necesario porque las operaciones del SDK (especialmente la escucha de eventos) se ejecutan en hilos secundarios. Si el script principal terminara, la conexión se cerraría.

## 4. Componentes Clave

*   **`anpr_poc.py`**: Script principal que contiene toda la lógica.
*   **`run_poc.sh`**: Script de utilidad para lanzar la aplicación.
*   **`AnalyzerDataCallBack` (función)**: Es el corazón de la PoC. Aquí se recibe, interpreta y procesa la información de los eventos de la cámara.
*   **`anpr_log.txt`**: Archivo de texto donde se registran las matrículas detectadas, sirviendo como un historial de eventos.
*   **Imágenes JPG**: Archivos de imagen guardados por el script, que proporcionan evidencia visual de cada detección de matrícula.

## 5. Conformidad con el SDK

Tras revisar los ejemplos proporcionados en la carpeta `sdk_docs_temp`, se confirma que la implementación de `anpr_poc.py` está **totalmente conforme** a las especificaciones y patrones del SDK.

*   **Patrón de Diseño**: El flujo de "Inicializar -> Iniciar Sesión -> Iniciar Escucha -> Esperar en Bucle" es el patrón estándar demostrado en los ejemplos `AlarmListenDemo.py` y `IntelligentTrafficDemo.py`.
*   **Manejo de Eventos**: El uso de `CLIENT_StartListenEx` con una función de callback (`AnalyzerDataCallBack`) es la metodología recomendada por el SDK para el manejo de eventos asíncronos.
*   **Estructura de Datos**: La forma en que se accede y se parsea la estructura de datos del evento (`DEV_EVENT_INFO`) para extraer la información de la matrícula (`stuObject` y `stPlateInfo`) es idéntica a la implementación en `TrafficDemo.py`, lo que indica un uso correcto de la API.

## 6. Conclusión

La prueba de concepto `anpr_poc.py` es una implementación robusta y correcta para la funcionalidad de ANPR. Sigue fielmente las directrices del SDK, utiliza las funciones adecuadas y está estructurada de una manera lógica y eficiente para cumplir su propósito. El código es limpio y demuestra una comprensión clara de cómo interactuar con el hardware a través del SDK proporcionado.

## 7. Estructura del Paquete de Eventos (event_packets.log)

Para facilitar la depuración y el análisis futuro, el script ha sido modificado para registrar los campos clave de cada paquete de evento de tráfico en el archivo `event_packets.log`. Cada entrada es un objeto JSON que representa un único evento.

### Ejemplo de Paquete:

```json
{
    "timestamp_capture": "2025-07-08T18:53:43.686579",
    "camera_ip": "10.45.14.11",
    "event_time_utc": "2025-07-08T18:53:43",
    "plate_number": "CARMELA",
    "vehicle_color": "Unknown",
    "vehicle_speed": 0,
    "lane": 1
}
```

### Descripción de los Campos:

*   **`timestamp_capture`**: (String, ISO 8601) La fecha y hora en que el script de Python procesó el evento. Es útil para medir latencias.
*   **`camera_ip`**: (String) La dirección IP de la cámara que originó el evento.
*   **`event_time_utc`**: (String, ISO 8601) La fecha y hora en que la cámara generó el evento, según su reloj interno (UTC).
*   **`plate_number`**: (String) El número de matrícula detectado por la cámara.
*   **`vehicle_color`**: (String) El color del vehículo según la detección de la cámara. A menudo puede ser "Unknown" si no se determina con certeza.
*   **`vehicle_speed`**: (Integer) La velocidad del vehículo en km/h en el momento de la detección. `0` puede indicar que el vehículo estaba detenido o que la velocidad no fue medida.
*   **`lane`**: (Integer) El número del carril en el que se detectó el vehículo.

## 8. Captura y Almacenamiento de Imágenes

El script está configurado para recibir y guardar una imagen JPG por cada evento de matrícula detectado. Este proceso es fundamental para tener una evidencia visual de cada evento.

### Cómo Funciona:

1.  **Solicitud de la Imagen**: Durante la inicialización de la suscripción a eventos (`sdk.RealLoadPictureEx`), el parámetro `bNeedPicFile` se establece en `1`. Esto le indica al SDK que, además de los metadatos del evento, debe enviar el búfer de datos de la imagen asociada.

2.  **Recepción en el Callback**: La función `analyzer_data_callback` recibe dos parámetros clave para la imagen:
    *   `pBuffer`: Un puntero al inicio del búfer de datos que contiene la imagen en formato JPG.
    *   `dwBufSize`: El tamaño total en bytes de dicho búfer.

3.  **Procesamiento y Guardado**:
    *   Dentro del callback, se comprueba que `dwBufSize` sea mayor que cero para asegurar que hay datos de imagen para procesar.
    *   Se genera un nombre de archivo único utilizando la fecha, la hora, la IP de la cámara y el número de matrícula (ej: `20250708_185633_10-45-14-12_PAMELA.jpg`). Esto evita colisiones y facilita la búsqueda de imágenes.
    *   El script abre un nuevo archivo en modo de escritura binaria (`"wb"`) en la carpeta `capturas/`.
    *   Finalmente, se leen los `dwBufSize` bytes desde el puntero `pBuffer` y se escriben directamente en el archivo. El resultado es una imagen JPG válida.

Este método es eficiente, ya que maneja los datos de la imagen directamente en memoria y los escribe en el disco sin necesidad de librerías de procesamiento de imágenes adicionales.
