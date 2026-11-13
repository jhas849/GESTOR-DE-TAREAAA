# Prototipo preliminar de interfaz

Este wireframe de baja fidelidad sirve como base para recrear las pantallas en Figma o Adobe XD. El flujo coincide con las pantallas ya implementadas en Flutter.

## Flujo

```text
Inicio -> Iniciar sesion / Crear cuenta -> Lista de tareas -> Nueva o editar tarea
                                      |                  |-> Marcar completada
                                      |                  |-> Eliminar (confirmacion)
                                      |                  |-> Cambiar tema
                                      |-> Cerrar sesion
```

## Dashboard

```text
+--------------------------------------+
| Mis tareas                      [tema]|
+--------------------------------------+
|                                      |
| [ ]  Preparar entrega                |
|      Informe del proyecto            |
|      Estudio · 15 nov 2026       [⋮] |
|                                      |
| [x]  Revisar requisitos               |
|      Trabajo · 17 nov 2026       [⋮] |
|                                      |
|                              [ + ]   |
+--------------------------------------+
```

## Formulario de tarea

```text
+--------------------------------------+
| Nueva tarea                          |
|                                      |
| Titulo                               |
| [__________________________________] |
| Descripcion                          |
| [__________________________________] |
| Categoria                            |
| [ Estudio                         v ]|
| Fecha de vencimiento                 |
| [ calendario  15 nov 2026 ]          |
|                                      |
|                  [Cancelar] [Guardar]|
+--------------------------------------+
```

## Acceso

```text
+--------------------------------------+
|             [icono tareas]           |
|          Gestor de tareas            |
|                                      |
| Correo electronico                   |
| [__________________________________] |
| Contrasena                           |
| [__________________________________] |
|                                      |
|            [Iniciar sesion]          |
|          Crear una cuenta nueva      |
+--------------------------------------+
```

## Especificacion visual

- Formato de referencia: frame movil de 390 x 844 px; crear tambien variantes compacta (360 px) y tablet.
- Colores: verde petroleo como acento, superficies neutrales y el color de error del tema Material; el modo oscuro invierte superficies manteniendo contraste legible.
- Tipografia: estilos Material `headlineSmall`, `titleMedium` y `bodyMedium`; evitar que la informacion de categoria y vencimiento compita con el titulo.
- Componentes: app bar con acciones iconograficas accesibles, lista desplazable, tarjetas de tarea, checkbox, menu contextual, FAB, formulario validado, selector de fecha y dialogo de confirmacion.
- Estados a prototipar: carga, lista vacia, error de red, tarea pendiente/completada, validacion del formulario y confirmacion de borrado.