# FarmaYopin - Aplicacion Movil

Aplicacion movil cliente para la gestion de articulos farmaceuticos, pedidos, recetas medicas y catalogo de productos. Desarrollada en Flutter para el curso Taller de Aplicaciones Moviles, como parte de una solucion arquitectonica distribuida con backend en Spring Boot y persistencia en MySQL.

---

## Indice
- [Arquitectura del Sistema](#arquitectura-del-sistema)
- [Funcionalidades y Pantallas Implementadas](#funcionalidades-y-pantallas-implementadas)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Tecnologias Utilizadas](#tecnologias-utilizadas)
- [Requisitos Previos](#requisitos-previos)
- [Instalacion y Puesta en Marcha](#instalacion-y-puesta-en-marcha)
- [Pruebas Automatizadas](#pruebas-automatizadas)
- [Diseno y Tokens de Figma](#diseno-y-tokens-de-figma)

---

## Arquitectura del Sistema

La solucion general sigue una arquitectura distribuida compuesta por dos nodos principales:

1. Nodo Cliente (Movil):
   - Aplicacion desarrollada en Flutter (Dart) multiplataforma (Android e iOS).
   - Consume la API REST del backend mediante intercambio de datos en formato JSON.
   - Soporta autenticacion basada en JWT (header Authorization: Bearer token).
   - Preparada para incorporar cache local offline (SQLite o Hive) para consulta del historial de compras sin conexion.

2. Nodo Servidor (Backend):
   - Servidor externo con Spring Boot, Spring Data JPA e Hibernate.
   - Base de datos relacional MySQL ejecutandose en un contenedor Docker.
   - Endpoints organizados por casos de uso para clientes y administradores.

---

## Funcionalidades y Pantallas Implementadas

### 1. Iniciar Sesion (UC-02 - LoginScreen)
- Formulario de autenticacion con validacion reactiva de correo y contrasena.
- Alternador de visibilidad de contrasena (mostrar u ocultar).
- Manejo de estados de carga con indicador circular y notificaciones mediante SnackBar.
- Integracion con el endpoint POST /api/auth/login.
- Acceso directo a la creacion de cuenta nueva.

### 2. Crear Cuenta (UC-01 - RegisterScreen)
- Formulario completo para registrarse como cliente (rol: CLIENTE):
  - Nombre y apellido (campos obligatorios).
  - Correo electronico con validacion de sintaxis.
  - Contrasena y confirmacion de contrasena con verificacion de coincidencia.
- Boton de retroceso y enlace rapido a iniciar sesion.
- Integracion con el endpoint POST /api/auth/register.

### 3. Catalogo de Productos (UC-04 - CatalogScreen)
- Cabecera institucional con isotipo de marca y acceso directo al carrito con contador dinamico (badge).
- Buscador en vivo: Filtrado instantaneo por nombre o descripcion mientras el usuario escribe.
- Filtros por categoria: Chips horizontales interactivos (Todos, Medicamentos, Vitaminas, Cuidado Personal).
- Grilla responsiva: Tarjetas de productos con imagen, titulo, precio, indicador de stock (verde para disponible, rojo para agotado) y boton de anadir al carrito.
- Soporte offline y fallback: Si el backend no esta disponible, la aplicacion inicializa con catalogo demostrativo fiel al diseno de Figma.
- Barra de navegacion inferior: Acceso a Inicio, Catalogo, Carrito, Historial y Perfil.

### 4. Crear Producto (UC-06 - CreateProductScreen)
- Formulario de gestion para administradores con validaciones completas:
  - Subida/asignacion de foto del producto con previsualizacion interactiva.
  - Nombre del producto (obligatorio).
  - Descripcion detallada del producto (dosis, contraindicaciones, etc.).
  - Precio en dolares con validacion numerica mayor a 0.
  - Stock inicial con validacion de numero entero no negativo.
- Boton de retorno a la pantalla anterior.
- Integracion con el endpoint POST /api/productos y retorno del producto creado al catalogo.

### 5. Ver Detalle del Producto (UC-05 - ProductDetailScreen)
- Pantalla de visualizacion detallada del articulo seleccionado desde el catalogo:
  - Barra superior con boton de retroceso a la pantalla previa.
  - Fotografia destacada del producto con bordes redondeados (radio 20px) y fallback visual en caso de fallo de red.
  - Nombre y categoria del producto con etiqueta en badge neutro.
  - Precio en tipografia de alto impacto (color Teal primario #0D9488, 28px).
  - Indicador de stock reactivo en banner destacado:
    - Verde (#DCFCE7 / #16A34A) cuando hay unidades disponibles.
    - Rojo (#FEE2E2 / #DC2626) en caso de producto agotado.
  - Descripcion detallada del producto (propiedades farmacologicas, beneficios, posologia).
  - Botones de accion para gestion:
    - 'Editar producto' (boton primario solido en color Teal que navega a EditProductScreen).
    - 'Ver historial de compras' (boton outline con borde Teal de 2px, vinculado a UC-08).

### 6. Editar Producto (UC-07 - EditProductScreen)
- Pantalla de modificacion para administradores basada en Screen5Editarproducto:
  - Precarga automatica de los datos actuales del producto: nombre, descripcion, precio, stock y foto.
  - Carga de imagen dual:
    - Opcion de seleccion directa desde el almacenamiento interno del dispositivo (galeria / explorador de archivos) con conversion base64 y previsualizacion inmediata en memoria.
    - Opcion de ingreso de enlace web (URL).
  - Validaciones completas:
    - Nombre del producto obligatorio.
    - Precio valido mayor a 0.
    - Stock entero no negativo.
  - Boton de accion 'Guardar cambios' con efecto de sombra Teal.
  - Integracion con el endpoint PUT /api/productos/{id} y actualizacion reactiva tanto en la vista de detalle como en el catalogo general.

---

## Estructura del Proyecto

El codigo esta organizado siguiendo un enfoque Feature-First / Clean Architecture simplificada para facilitar el mantenimiento y escalabilidad:

```text
farmayopin/
├── lib/
│   ├── main.dart                          # Punto de entrada de la aplicacion
│   ├── core/                              # Componentes transversales
│   │   ├── constants/
│   │   │   └── api_constants.dart         # URLs base y rutas de endpoints
│   │   ├── theme/
│   │   │   ├── app_colors.dart            # Paleta de colores oficial de Figma
│   │   │   └── app_theme.dart             # Tema global (ThemeData, Inter font)
│   │   └── utils/
│   │       └── validators.dart            # Validaciones de formularios
│   └── features/                          # Modulos por caso de uso
│       ├── auth/                          # Modulo de Autenticacion
│       │   ├── data/
│       │   │   ├── models/                # DTOs (login_request, register_request, auth_response)
│       │   │   └── services/              # AuthService (llamadas HTTP /api/auth/*)
│       │   └── presentation/
│       │       ├── screens/               # login_screen.dart, register_screen.dart
│       │       └── widgets/               # brand_logo.dart, custom_text_field.dart
│       └── catalog/                       # Modulo de Catalogo
│           ├── data/
│           │   ├── models/                # product_model.dart, producto_request.dart
│           │   └── services/              # catalog_service.dart (/api/productos)
│           └── presentation/
│               ├── screens/               # catalog_screen.dart, create_product_screen.dart, product_detail_screen.dart, edit_product_screen.dart
│               └── widgets/               # product_card.dart, category_chip.dart
└── test/                                  # Suite de pruebas unitarias y de widgets
    ├── unit/                              # Tests de validadores y DTOs
    └── features/                          # Tests de widgets de Auth y Catalogo
```

---

## Tecnologias Utilizadas

- Framework: Flutter (v3.47.2 / Dart 3.13.2)
- Tipografia: Google Fonts (Inter)
- Networking: http
- Diseno: Figma to Code adaptado a widgets responsivos nativos
- Linter y Analisis: flutter_lints

---

## Requisitos Previos

1. Tener instalado el Flutter SDK (version stable recomendada).
2. Tener configurado un emulador Android, simulador iOS o navegador Google Chrome.
3. (Opcional) Para interactuar con datos en tiempo real, tener levantado el backend Spring Boot (farma-yopin-api) con su base de datos MySQL en Docker en http://localhost:8080.

---

## Instalacion y Puesta en Marcha

1. Abrir la carpeta del proyecto:
   ```bash
   cd farmayopin
   ```

2. Descargar las dependencias:
   ```bash
   flutter pub get
   ```

3. Ejecutar la aplicacion:
   - En Google Chrome (modo web rapido):
     ```bash
     flutter run -d chrome
     ```
   - En Emulador Android:
     ```bash
     flutter run
     ```
     (Nota: La URL base de la API se ajusta automaticamente a http://10.0.2.2:8080 cuando se ejecuta en Android).

---

## Pruebas Automatizadas

El proyecto incluye tests unitarios de modelos/validadores y pruebas de widgets con interaccion de usuario:

- Analisis estatico de codigo:
  ```bash
  dart analyze
  ```
  (Resultado actual: 0 advertencias o errores).

- Ejecucion de la suite de pruebas:
  ```bash
  flutter test
  ```
  (Resultado actual: 27/27 tests pasando).

---

## Diseno y Tokens de Figma

La interfaz respeta los tokens del diseno original de Figma:

| Token | Hex / Valor | Uso principal |
| :--- | :--- | :--- |
| Primary | #0D9488 (Teal) | Botones de accion, 'Y' en logo, acentos y badge |
| Text Dark | #1F2937 | Titulos principales, encabezados y textos destacados |
| Text Muted | #6B7280 | Subtitulos descriptivos, labels secundarios y placeholders |
| Borders | #E5E7EB | Bordes de inputs, tarjetas y separadores |
| Accent Link | #0284C7 | Enlaces interactivos |
| Radius | 12px / 14px / 16px | Inputs, botones principales y tarjetas |
