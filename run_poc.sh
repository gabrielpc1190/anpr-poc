#!/bin/bash
# Este script configura el entorno y ejecuta la prueba de concepto de ANPR.

# Obtiene la ruta absoluta del directorio actual
BASE_DIR=$(pwd)

# Construye la ruta a las librerías del SDK
SDK_LIB_PATH="$BASE_DIR/sdk_docs_temp/General_NetSDK_ChnEng_Python_linux64_IS_V3.060.0000000.0.R.250409/dist"

# Exporta la ruta de las librerías para que el sistema las encuentre
export LD_LIBRARY_PATH=$SDK_LIB_PATH

echo "LD_LIBRARY_PATH set to: $LD_LIBRARY_PATH"
echo "Starting python script..."

# Ejecuta el script de Python
python3 anpr_poc.py
