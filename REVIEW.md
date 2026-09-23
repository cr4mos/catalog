# Validación del catálogo

## Comportamiento verificado

- Búsqueda por nombre, marca y categoría, incluyendo categorías españolas, acentos, mayúsculas, guiones y palabras repartidas entre campos.
- Favoritos locales disponibles durante la carga y sin conexión, incluso sin copia del catálogo.
- Conservación de detalles y disponibilidad guardados al leer una caché antigua.
- Reconciliación de favoritos exclusivamente con respuestas remotas completas; productos desaparecidos se presentan sin existencias.
- Persistencia y migración de favoritos, lectura/escritura de caché, recuperación y reintentos.
- Manejo de timeout, desconexión, pérdida de señal, respuestas HTTP y cancelación mediante pruebas de transporte local.
- Categorías y controles en español, ficha estructurada y formato de moneda MXN.

## Pruebas automatizadas

- **49 pruebas y 71 ejecuciones incluyendo parámetros: todas aprobadas, sin omisiones.**
- Ejecución final: Xcode 27.2 beta, iPad Pro 13-inch (M5), iOS 27.0.
- Ejecución anterior de las regresiones: iPhone 18 Pro, iOS 27.0, Xcode 27.0.
- SwiftLint estricto y `git diff --check`: aprobados.
- Bundle compilado: mínimo iOS 17.0, región de desarrollo `es`.
- Resultado final local: `/tmp/catalog-beta-final-tests.xcresult`.

## iPhone Duo

Se intentó crear el dispositivo con Xcode 27.2 beta y el perfil oficial `com.apple.CoreSimulator.SimDeviceType.iPhone-Duo`. El runtime iOS 27.2 instalado declara ese modelo como no compatible y CoreSimulator rechaza crearlo. La descarga de iOS 27.1 mediante Xcode tampoco está disponible. Por ello no se declara una prueba ejecutada en Duo.

La app utiliza NavigationSplitView y conserva selección por ID para adaptarse al espacio disponible. Se comprobó visualmente la distribución de dos columnas y el estado recuperable de conexión en iPad. La conexión en vivo de ese simulador está interceptada por Proxyman y su certificado no es de confianza para el runtime recién iniciado; no se modificaron las validaciones TLS de la app. La validación en pantalla amplia es complementaria y no reemplaza la prueba en Duo.

## Entrega

El repositorio tiene historial incremental, README y un pipeline para compilar, probar y validar estilo en cada PR. Estos cambios son locales; la publicación y la ejecución remota del workflow se verifican al subirlos.
