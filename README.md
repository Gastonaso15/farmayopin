# 🏥 FarmaYopin — Aplicación Móvil

Aplicación móvil cliente para la gestión de artículos farmacéuticos, pedidos, recetas médicas y catálogo de productos. Desarrollada en **Flutter** para el curso *Taller de Aplicaciones Móviles*, como parte de una solución arquitectónica distribuida con backend en **Spring Boot** y persistencia en **MySQL**.

---

## 📋 Índice
- [Arquitectura del Sistema](#-arquitectura-del-sistema)
- [Funcionalidades y Pantallas Implementadas](#-funcionalidades-y-pantallas-implementadas)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Tecnologías Utilizadas](#-tecnologías-utilizadas)
- [Requisitos Previos](#-requisitos-previos)
- [Instalación y Puesta en Marcha](#-instalación-y-puesta-en-marcha)
- [Pruebas Automatizadas](#-pruebas-automatizadas)
- [Diseño y Tokens de Figma](#-diseño-y-tokens-de-figma)

---

## 🏛️ Arquitectura del Sistema

La solución general sigue una **arquitectura distribuida** compuesta por dos nodos principales:

1. **Nodo Cliente (Móvil)**:
   - Aplicación desarrollada en **Flutter (Dart)** multiplataforma (Android e iOS).
   - Consume la API REST del backend mediante intercambio de datos en formato **JSON**.
   - Soporta autenticación basada en **JWT** (`Authorization: Bearer <token>`).
   - Preparada para incorporar caché local offline (SQLite / Hive) para consulta del historial de compras sin conexión.

2. **Nodo Servidor (Backend)**:
   - Servidor externo con **Spring Boot**, **Spring Data JPA** y **Hibernate**.
   - Base de datos relacional **MySQL** corriendo en un contenedor **Docker**.
   - Endpoints organizados por casos de uso para clientes y administradores.

---

## 📱 Funcionalidades y Pantallas Implementadas

### 1. Iniciar Sesión (`UC-02 · LoginScreen`)
- Formulario de autenticación con validación reactiva de correo y contraseña.
- Alternador de visibilidad de contraseña (mostrar/ocultar).
- Manejo de estados de carga con indicador circular y notificaciones mediante `SnackBar`.
- Integración con el endpoint `POST /api/auth/login`.
- Acceso directo a la creación de cuenta nueva.

### 2. Crear Cuenta (`UC-01 · RegisterScreen`)
- Formulario completo para registrarse como cliente (`rol: CLIENTE`):
  - Nombre y apellido (campos obligatorios).
  - Correo electrónico con validación de sintaxis.
  - Contraseña y confirmación de contraseña con verificación de coincidencia.
- Botón de retroceso y enlace rápido a iniciar sesión.
- Integración con el endpoint `POST /api/auth/register`.

### 3. Catálogo de Productos (`UC-04 · CatalogScreen`)
- Cabecera institucional con isotipo de marca y acceso directo al carrito con **contador dinámico (badge)**.
- **Buscador en vivo**: Filtrado instantáneo por nombre o descripción mientras el usuario escribe.
- **Filtros por categoría**: Chips horizontales interactivos (*Todos*, *Medicamentos*, *Vitaminas*, *Cuidado Personal*).
- **Grilla responsiva**: Tarjetas de productos con imagen, título, precio teal, indicador de stock (verde/rojo) y botón de añadir al carrito.
- **Soporte offline / fallback**: Si el backend no está disponible, la app inicializa con catálogo demostrativo fiel al diseño de Figma.
- **Barra de navegación inferior**: Acceso a *Inicio*, *Catálogo*, *Carrito*, *Historial* y *Perfil*.

---

## 📂 Estructura del Proyecto

El código está organizado siguiendo un enfoque **Feature-First / Clean Architecture simplificada** para facilitar el mantenimiento y escalabilidad:

```text
farmayopin/
├── lib/
│   ├── main.dart                          # Punto de entrada de la aplicación
│   ├── core/                              # Componentes transversales
│   │   ├── constants/
│   │   │   └── api_constants.dart         # URLs base y rutas de endpoints
│   │   ├── theme/
│   │   │   ├── app_colors.dart            # Paleta de colores oficial de Figma
│   │   │   └── app_theme.dart             # Tema global (ThemeData, Inter font)
│   │   └── utils/
│   │       └── validators.dart            # Validaciones de formularios
│   └── features/                          # Módulos por caso de uso
│       ├── auth/                          # Módulo de Autenticación
│       │   ├── data/
│       │   │   ├── models/                # DTOs (login_request, register_request, auth_response)
│       │   │   └── services/              # AuthService (llamadas HTTP /api/auth/*)
│       │   └── presentation/
│       │       ├── screens/               # login_screen.dart, register_screen.dart
│       │       └── widgets/               # brand_logo.dart, custom_text_field.dart
│       └── catalog/                       # Módulo de Catálogo
│           ├── data/
│           │   ├── models/                # product_model.dart
│           │   └── services/              # catalog_service.dart (/api/productos)
│           └── presentation/
│               ├── screens/               # catalog_screen.dart
│               └── widgets/               # product_card.dart, category_chip.dart
└── test/                                  # Suite de pruebas unitarias y de widgets
    ├── unit/                              # Tests de validadores y DTOs
    └── features/                          # Tests de widgets de Auth y Catálogo
```

---

## 🛠️ Tecnologías Utilizadas

- **Framework**: [Flutter](https://flutter.dev/) (v3.47.2 / Dart 3.13.2)
- **Tipografía**: [Google Fonts (Inter)](https://pub.dev/packages/google_fonts)
- **Networking**: [http](https://pub.dev/packages/http)
- **Diseño**: Figma to Code adaptado a widgets responsivos nativos
- **Linter & Análisis**: `flutter_lints`

---

## ⚡ Requisitos Previos

1. Tener instalado el **Flutter SDK** (versión stable recomendada).
2. Tener configurado un emulador Android, simulador iOS o navegador Google Chrome.
3. *(Opcional)* Para interactuar con datos en tiempo real, tener levantado el backend Spring Boot (`farma-yopin-api`) con su base de datos MySQL en Docker en `http://localhost:8080`.

---

## 🚀 Instalación y Puesta en Marcha

1. **Abrir la carpeta del proyecto**:
   ```bash
   cd farmayopin
   ```

2. **Descargar las dependencias**:
   ```bash
   flutter pub get
   ```

3. **Ejecutar la aplicación**:
   - En **Google Chrome** (modo web rápido):
     ```bash
     flutter run -d chrome
     ```
   - En **Emulador Android**:
     ```bash
     flutter run
     ```
     *(Nota: La URL base de la API se ajusta automáticamente a `http://10.0.2.2:8080` cuando se ejecuta en Android).*

---

## 🧪 Pruebas Automatizadas

El proyecto incluye tests unitarios de modelos/validadores y pruebas de widgets con interacción de usuario:

- **Análisis estático de código**:
  ```bash
  dart analyze
  ```
  *(Resultado actual: 0 advertencias o errores).*

- **Ejecución de la suite de pruebas**:
  ```bash
  flutter test
  ```
  *(Resultado actual: 15/15 tests pasando).*

---

## 🎨 Diseño y Tokens de Figma

La interfaz respeta los tokens del diseño original de Figma:

| Token | Hex / Valor | Uso principal |
| :--- | :--- | :--- |
| **Primary** | `#0D9488` (Teal) | Botones de acción, 'Y' en logo, acentos y badge |
| **Text Dark** | `#1F2937` | Títulos principales, encabezados y textos destacados |
| **Text Muted** | `#6B7280` | Subtítulos descriptivos, labels secundarios y placeholders |
| **Borders** | `#E5E7EB` | Bordes de inputs, tarjetas y separadores |
| **Accent Link** | `#0284C7` | Enlaces interactivos |
| **Radius** | `12px` / `14px` / `16px` | Inputs, botones principales y tarjetas |
