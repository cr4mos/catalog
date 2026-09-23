# Catálogo de productos

App iOS en Swift y SwiftUI con catálogo de [DummyJSON](https://dummyjson.com/docs/products), búsqueda por nombre, marca o categoría, detalle y favoritos locales. Interfaz en español y precios con formato MXN.

## Cómo ejecutar

1. Abrir `productsCatalogTest.xcodeproj` en Xcode 16 o posterior.
2. Seleccionar el scheme compartido `productsCatalogTest` y un simulador con iOS 17 o posterior.
3. Ejecutar con **⌘R**. No hay dependencias externas ni claves de API.
4. Para un dispositivo físico, configurar tu equipo de desarrollo y bundle identifier en Signing & Capabilities.

El deployment target es iOS 17.0. La validación local usa Xcode 27.0 y 27.2 beta; los dispositivos y resultados comprobados están en [REVIEW.md](REVIEW.md).

## Pruebas y estilo

**⌘U** ejecuta la suite de Swift Testing. Por terminal:

```sh
xcrun simctl list devices available
# Sustituir <UDID> por un simulador disponible.
xcodebuild \
  -project productsCatalogTest.xcodeproj \
  -scheme productsCatalogTest \
  -destination 'platform=iOS Simulator,id=<UDID>' \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults.xcresult \
  CODE_SIGNING_ALLOWED=NO test

brew install swiftlint
swiftlint lint --strict --no-cache
```

Usar un destino nuevo para `-resultBundlePath` en cada ejecución. `.swiftlint.yml` define el estilo y las abreviaturas intencionales del sistema de diseño.

Las pruebas usan repositorios inyectados, respuestas HTTP locales con `URLProtocol`, archivos temporales y suites aisladas de `UserDefaults`. No dependen de la disponibilidad de DummyJSON ni modifican los favoritos del usuario. Cubren búsqueda en español, palabras combinadas entre campos, persistencia y migración de favoritos, disponibilidad, caché, conectividad, cancelación, reintentos y estados de presentación.

El workflow `.github/workflows/ios-ci.yml` se activa en cada Pull Request y manualmente. Valida todos los archivos Swift, compila, ejecuta las pruebas con cobertura y conserva el reporte `.xcresult`.

## Arquitectura y decisiones

- **Domain:** entidades, protocolos de repositorio y casos de uso de carga, búsqueda y favoritos. Las reglas se prueban independientemente de SwiftUI.
- **Data:** `ProductService` con URLSession, DTOs, caché en disco y favoritos en UserDefaults. Encapsula transporte y persistencia.
- **Presentation:** `CatalogViewModel` con Observation, estados de carga y vistas SwiftUI.
- **App:** composición de dependencias, cargador de imágenes y sistema de diseño.

El ViewModel y los favoritos están aislados a `MainActor`; el disco y las imágenes usan actores. Los DTOs pueden codificarse y decodificarse desde el actor de caché sin aislamiento global al actor principal.

La carga publica primero la copia local y luego intenta actualizar. Distingue explícitamente snapshots locales y remotos: solo una respuesta remota completa confirma que un favorito desapareció. Una copia antigua conserva los datos más recientes guardados del favorito. Si falla la red, la copia sigue visible y los favoritos permanecen accesibles incluso sin caché del catálogo.

Los favoritos guardan el producto completo. Si desaparece del catálogo remoto, conserva sus últimos detalles y muestra stock cero; si reaparece, recupera sus datos actuales. Se rechazan respuestas incompletas o con IDs duplicados antes de reconciliar.

La búsqueda comparte las categorías españolas con la presentación, normaliza acentos, mayúsculas, espacios y guiones, y permite combinar palabras entre nombre, marca y categoría. También acepta las categorías originales de la API.

Las imágenes usan caché y reducción de resolución con ImageIO, con reintento independiente. La petición del catálogo tiene timeout de 15 segundos y reintento manual.

`NavigationSplitView` adapta lista y detalle al espacio disponible y conserva la selección por ID. Se usan estilos de texto escalables, etiquetas de accesibilidad y áreas táctiles de 48 puntos. No se deduce el diseño a partir del modelo de dispositivo.

## Supuestos

- Los favoritos se guardan exclusivamente en el dispositivo y persisten entre aperturas, superando el mínimo de persistencia durante la sesión.
- La copia local del catálogo es opcional y automática; no hay un paso de descarga manual para el usuario.
- Se solicita `limit=0` con los campos utilizados. La [API documenta](https://dummyjson.com/docs/products) que esto obtiene todo el catálogo, permitiendo búsqueda local y reconciliación completa.
- Para esta demostración se interpreta el número `price` como MXN. No hay conversión cambiaria: una integración comercial deberá definir moneda de origen y tipo de cambio.
- Se conservan los nombres comerciales y las marcas del proveedor. La ficha presenta información estructurada con etiquetas y categorías en español; el texto editorial no localizado de la API se conserva en el modelo sin mostrarse en la interfaz.
- Las categorías nuevas usan «Otros productos» hasta incorporar su traducción.
- Un catálogo remoto completo con cero productos es válido y deja los favoritos anteriores sin existencias.

## Trade-offs

- Cargar el catálogo completo simplifica la búsqueda y disponibilidad de favoritos, pero aumenta la transferencia inicial. Para un catálogo grande se necesitarían paginación, búsqueda remota por todos los campos y consultas individuales de disponibilidad.
- UserDefaults basta para una colección pequeña de favoritos; una base de datos sería más adecuada para un volumen mayor.
- Se prioriza el reintento explícito y el contenido disponible sobre reintentos automáticos continuos.
- La ficha usa datos estructurados en español para evitar depender de un servicio externo de traducción.
- El CI usa las herramientas del runner y SwiftLint de Homebrew; fijar versiones daría mayor reproducibilidad.

## Qué haría con más tiempo

- Incorporar pruebas UI automatizadas de navegación, favoritos y cambios de tamaño.
- Medir inicio, scroll, consumo de memoria y conexiones lentas con Instruments y un dispositivo físico.
- Ampliar la validación de VoiceOver, Dynamic Type y sistemas operativos.
- Incorporar contenido editorial localizado desde un backend y una política comercial de conversión monetaria.
- Fijar versiones de Xcode/SwiftLint y preparar capturas para la demostración.
