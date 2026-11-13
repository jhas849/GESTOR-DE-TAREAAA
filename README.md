# Gestor de tareas

Aplicacion multiplataforma Flutter/Dart para iOS y Android. Usa Firebase Authentication con correo y contrasena para conservar el mismo UID entre dispositivos, Cloud Firestore para CRUD y sincronizacion en tiempo real, FCM para recibir avisos y `flutter_local_notifications` para mostrar mensajes cuando la app esta en primer plano.

## Esquema conceptual Firestore

```text
users/{userId}
  tasks/{taskId}
    title: string
    description: string
    category: string
    dueDate: timestamp
    isCompleted: boolean
    userId: string
```

Cada tarea vive bajo el usuario propietario. El documento raiz de usuario no requiere campos adicionales. `dueDate` es Timestamp para permitir ordenamiento y consultas por rango. La pantalla escucha `users/{uid}/tasks` ordenado por fecha; Firestore emite cambios remotos y locales a traves de `snapshots()`.

Las reglas completas para aislar datos por UID estan en `firestore.rules`; se despliegan desde Firebase Console o Firebase CLI.

## Puesta en marcha

1. Instalar Flutter y crear los archivos de plataforma: `flutter create . --platforms=android,ios`.
2. Crear un proyecto Firebase y habilitar Firestore, Firebase Authentication (proveedor correo/contrasena) y Cloud Messaging.
3. Registrar las apps Android/iOS. Añadir `google-services.json` en `android/app/` y `GoogleService-Info.plist` en `ios/Runner/`, y completar la configuracion nativa de Firebase indicada por FlutterFire.
4. Ejecutar `flutter pub get` y `flutter run` desde la raiz.

El starter usa `Firebase.initializeApp()` con los archivos nativos de Firebase. En aplicaciones destinadas a distribucion, se recomienda `flutterfire configure` y pasar `DefaultFirebaseOptions.currentPlatform`. No se incluyen credenciales ni archivos generados por Firebase.

Cada dispositivo que inicia sesion con la misma cuenta utiliza el mismo UID y puede acceder a las mismas tareas. No usar un UID recibido libremente desde la interfaz como control de acceso.

### Demo local sin Firebase

Para revisar la interfaz y probar el CRUD sin configurar Firebase, ejecutar:

```powershell
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 5000 --dart-define=DEMO_MODE=true
```

Abrir `http://localhost:5000`. Este modo utiliza tareas en memoria; los cambios se pierden al reiniciar y no se sincronizan entre dispositivos. Para una ejecucion web conectada a Firebase, generar la configuracion web con `flutterfire configure --platforms=web` y usar las opciones generadas al inicializar Firebase.

## Recordatorios

La app solicita permiso de notificaciones y convierte los mensajes FCM recibidos en primer plano en notificaciones locales. `NotificationService.getDeviceToken()` expone el token para registrarlo de forma autenticada en `users/{uid}/devices/{token}`. Para un recordatorio real a una hora futura, el backend debe programar un mensaje FCM al acercarse `dueDate` (por ejemplo, Cloud Functions con Cloud Tasks o una cola). No se debe enviar desde la app cliente ni guardar credenciales administrativas en Flutter. En Android/iOS hay que completar los permisos y configuraciones nativas de notificaciones push.

## Pruebas y entregables

El informe final con arquitectura, base de datos, respuestas a las preguntas guia y plan de validacion esta en `INFORME_FINAL.md`. El wireframe preliminar y sus especificaciones para trasladarlo a Figma/Adobe XD estan en `docs/prototipo-ui.md`.

La prueba `integration_test/firestore_sync_test.dart` verifica altas, cambios de estado y borrados observados por dos streams autenticados. Para ejecutarla, inicia `firebase emulators:start --only auth,firestore --project demo-gestor-tareas` y luego ejecuta `flutter test integration_test/firestore_sync_test.dart -d <deviceId>` con un emulador o dispositivo conectado. La entrega de FCM/APNs requiere una prueba manual en dispositivos configurados; el emulador de Firestore no simula notificaciones push.

## Respuestas tecnicas

- **Compatibilidad:** Flutter comparte la mayor parte del codigo Dart entre Android e iOS. Firebase requiere configuracion nativa por plataforma, permisos y pruebas en dispositivos; no significa que una compilacion sea identica para ambos sistemas.
- **Widgets clave:** `StreamBuilder` refleja snapshots de Firestore; `ListView.builder` crea elementos bajo demanda; `Form` y `TextFormField` validan el alta/edicion; `FloatingActionButton` inicia el alta. Las tareas individuales usan un `Card` y `Checkbox`.
- **Usabilidad:** alta y edicion comparten formulario, fecha elegible con selector nativo, categorias controladas, confirmacion antes de eliminar y cambio de tema claro/oscuro persistido en preferencias locales.
- **Sincronizacion:** Firestore `snapshots()` mantiene la lista actualizada en tiempo real, con cache offline administrada por el SDK. Las reglas verifican el UID propietario en cada operacion; el cliente no reemplaza la autorizacion del backend.

## Archivos principales

- `lib/models/task.dart`: modelo y conversion a/desde documentos Firestore.
- `lib/services/task_service.dart`: lecturas en stream y operaciones CRUD.
- `lib/services/in_memory_task_service.dart`: datos temporales del modo demo.
- `lib/services/notification_service.dart`: permisos FCM y presentacion local en primer plano.
- `lib/screens/task_dashboard.dart`: dashboard reactivo, formulario, edicion, completado y borrado.
- `lib/screens/sign_in_screen.dart`: registro e inicio de sesion con correo y contrasena.
- `lib/main.dart`: inicializacion de Firebase, enrutamiento por estado de sesion y preferencia de tema.
- `firestore.rules` y `firebase.json`: reglas de acceso y configuracion de emuladores.
- `integration_test/firestore_sync_test.dart`: prueba de CRUD y actualizacion entre streams.