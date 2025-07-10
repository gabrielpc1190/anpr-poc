#!/bin/bash
# Este script configura el entorno y ejecuta la prueba de concepto de ANPR.

# Nombre del archivo ZIP del SDK esperado en la raíz del proyecto
SDK_ZIP_NAME="General_NetSDK_Eng_Python_linux64_IS_V3.060.0000000.0.R.250409.zip"
# Nombre de la carpeta del SDK después de descomprimir.
# AJUSTAR SI EL NOMBRE REAL DIFIERE (ej. General_NetSDK_ChnEng_Python_linux64_IS_V3.060.0000000.0.R.250409)
SDK_EXTRACTED_DIR_NAME="General_NetSDK_ChnEng_Python_linux64_IS_V3.060.0000000.0.R.250409"

# Obtiene la ruta absoluta del directorio actual
BASE_DIR=$(pwd)

# --- Verificación de dependencias del script ---
if ! command -v unzip &> /dev/null; then
    echo "ERROR: 'unzip' no está instalado. Por favor, instálalo para continuar (ej: sudo apt-get install unzip)"
    exit 1
fi

if ! command -v python3 &> /dev/null; then
    echo "ERROR: 'python3' no está instalado. Por favor, instálalo para continuar."
    exit 1
fi

if ! python3 -m pip --version &> /dev/null; then
    echo "ADVERTENCIA: 'pip' para python3 podría no estar instalado. Intentando instalar el SDK..."
    echo "Si la instalación del SDK falla, por favor instala pip para python3 (ej: sudo apt-get install python3-pip)"
fi

# --- Verificación de existencia del SDK ---
if [ ! -f "$BASE_DIR/$SDK_ZIP_NAME" ]; then
    echo "---------------------------------------------------------------------------------"
    echo "ERROR: El archivo SDK '$SDK_ZIP_NAME' no se encuentra en el directorio raíz."
    echo "Por favor, descarga el SDK desde:"
    echo "https://materialfile.dahuasecurity.com/uploads/soft/20250508/$SDK_ZIP_NAME"
    echo "y colócalo en el directorio: $BASE_DIR"
    echo "---------------------------------------------------------------------------------"
    exit 1
fi
echo "Archivo SDK '$SDK_ZIP_NAME' encontrado."

# --- Descompresión del SDK (si aún no está descomprimido) ---
if [ ! -d "$BASE_DIR/$SDK_EXTRACTED_DIR_NAME" ]; then
    echo "Descomprimiendo SDK '$SDK_ZIP_NAME'..."
    # Creamos un directorio temporal para descomprimir y evitar problemas si el zip no tiene un directorio raíz único.
    TEMP_UNZIP_DIR=$(mktemp -d)
    unzip -q "$BASE_DIR/$SDK_ZIP_NAME" -d "$TEMP_UNZIP_DIR"
    if [ $? -ne 0 ]; then
        echo "ERROR: No se pudo descomprimir el archivo SDK. Asegúrate de que 'unzip' esté instalado y el archivo no esté corrupto."
        rm -rf "$TEMP_UNZIP_DIR"
        exit 1
    fi

    # Asumimos que el contenido relevante está dentro de una carpeta con el nombre SDK_EXTRACTED_DIR_NAME o similar dentro del zip.
    # Si el zip extrae directamente los contenidos sin una carpeta contenedora principal, esta lógica necesitará ajuste.
    # O si el nombre de la carpeta interna es diferente a SDK_EXTRACTED_DIR_NAME.
    # Por ahora, intentamos mover el contenido esperado.
    if [ -d "$TEMP_UNZIP_DIR/$SDK_EXTRACTED_DIR_NAME" ]; then
        mv "$TEMP_UNZIP_DIR/$SDK_EXTRACTED_DIR_NAME" "$BASE_DIR/"
        echo "SDK movido a '$BASE_DIR/$SDK_EXTRACTED_DIR_NAME'."
    else
        # Si la carpeta no está como se esperaba, intentamos encontrar la carpeta principal (si hay solo una)
        CONTENT_COUNT=$(ls -1A "$TEMP_UNZIP_DIR" | wc -l)
        if [ "$CONTENT_COUNT" -eq 1 ]; then
            EXTRACTED_CONTENT_NAME=$(ls -1A "$TEMP_UNZIP_DIR")
            # Si el nombre es diferente al esperado pero es el único, lo usamos.
            if [ "$EXTRACTED_CONTENT_NAME" != "$SDK_EXTRACTED_DIR_NAME" ]; then
                echo "Advertencia: El directorio extraído '$EXTRACTED_CONTENT_NAME' es diferente de SDK_EXTRACTED_DIR_NAME ('$SDK_EXTRACTED_DIR_NAME'). Usando '$EXTRACTED_CONTENT_NAME'."
                SDK_EXTRACTED_DIR_NAME="$EXTRACTED_CONTENT_NAME"
            fi
            mv "$TEMP_UNZIP_DIR/$EXTRACTED_CONTENT_NAME" "$BASE_DIR/"
            echo "SDK movido a '$BASE_DIR/$SDK_EXTRACTED_DIR_NAME'."
        else
            echo "ERROR: La estructura del ZIP no es la esperada. No se encontró la carpeta '$SDK_EXTRACTED_DIR_NAME' directamente."
            echo "Contenido del directorio temporal de descompresión ($TEMP_UNZIP_DIR):"
            ls -lA "$TEMP_UNZIP_DIR"
            echo "Por favor, ajusta SDK_EXTRACTED_DIR_NAME o la lógica de descompresión en el script."
            rm -rf "$TEMP_UNZIP_DIR"
            exit 1
        fi
    fi
    rm -rf "$TEMP_UNZIP_DIR"
else
    echo "Directorio del SDK '$BASE_DIR/$SDK_EXTRACTED_DIR_NAME' ya existe. Saltando descompresión."
fi

# --- Instalación del SDK (archivo .whl) ---
SDK_WHL_PATH="$BASE_DIR/$SDK_EXTRACTED_DIR_NAME/dist/NetSDK-2.0.0.1-py3-none-linux_x86_64.whl"

if [ ! -f "$SDK_WHL_PATH" ]; then
    echo "---------------------------------------------------------------------------------"
    echo "ERROR: El archivo wheel del SDK '$SDK_WHL_PATH' no se encuentra."
    echo "Por favor, verifica la estructura del SDK descomprimido y el nombre del archivo .whl."
    echo "Contenido de '$BASE_DIR/$SDK_EXTRACTED_DIR_NAME/dist':"
    ls -l "$BASE_DIR/$SDK_EXTRACTED_DIR_NAME/dist"
    echo "---------------------------------------------------------------------------------"
    exit 1
fi

echo "Instalando SDK desde '$SDK_WHL_PATH'..."
# Es recomendable usar un entorno virtual, pero para este script instalaremos a nivel de usuario o sistema.
# Usamos python3 -m pip para asegurar que usamos el pip asociado a python3
python3 -m pip install "$SDK_WHL_PATH" --force-reinstall --user
# Si se requiere instalación a nivel de sistema y se tienen permisos:
# sudo python3 -m pip install "$SDK_WHL_PATH" --force-reinstall

if [ $? -ne 0 ]; then
    echo "ERROR: Falló la instalación del SDK (pip install). Verifica que pip esté instalado y que no haya conflictos."
    exit 1
fi
echo "SDK instalado correctamente."

# La variable LD_LIBRARY_PATH podría no ser necesaria si el wheel instala las .so en una ruta estándar.
# Si después de la instalación del wheel aún hay problemas de librerías no encontradas,
# se podría necesitar identificar dónde pip instaló las .so y agregar esa ruta a LD_LIBRARY_PATH.
# Por ahora, la dejamos comentada.
# echo "LD_LIBRARY_PATH (si es necesario) debería ser configurado por la instalación del wheel."

# NOTA sobre la carpeta NetSDK local:
# Si el script anpr_poc.py debe usar los módulos de la carpeta NetSDK que está junto a él,
# y no los instalados por el wheel, asegúrate de que PYTHONPATH priorice el directorio local,
# o considera eliminar/renombrar la carpeta NetSDK local para evitar conflictos si el wheel es el preferido.
# Por defecto, Python busca primero en el directorio del script.

echo "Starting python script..."

# Ejecuta el script de Python
python3 anpr_poc.py
