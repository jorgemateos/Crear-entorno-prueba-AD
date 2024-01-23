# PowerShell Script para la Configuración de Estructura de Active Directory

Este script PowerShell automatiza la creación y configuración de la estructura de Active Directory (AD) para una nueva organización. El objetivo principal es establecer unidades organizativas (OUs), grupos de usuarios y equipos, así como configurar carpetas compartidas con permisos específicos.

## Características Principales:

- **Importación de Datos:** Importa datos de usuarios, ubicaciones de sedes y departamentos desde archivos CSV y de texto para personalizar la configuración.
- **Creación de OUs y Grupos:** Establece OUs jerárquicas para ubicaciones, departamentos y grupos de usuarios y equipos, proporcionando una estructura organizativa lógica.
- **Protección contra Eliminación Accidental:** Habilita la protección contra eliminación accidental para todas las unidades organizativas y grupos creados.
- **Creación de Usuarios:** Crea usuarios en base a datos importados, asignándolos a grupos según su ubicación y departamento.
- **Configuración de Recursos Compartidos:** Crea un recurso compartido raíz y comparte carpetas específicas para cada departamento con permisos adecuados.
- **Configuraciones de Active Directory:** Incluye configuraciones adicionales como la habilitación de la Papelera de Reciclaje en AD y la protección contra eliminación accidental en todas las OUs.

## Configuración Personalizable:

El script permite la personalización de rutas de archivos de importación y otros parámetros clave para adaptarse a las necesidades específicas de la organización.

## Requisitos:

- Ejecutar el script con privilegios de administrador.
- Módulos necesarios: ActiveDirectory, GroupPolicy.

## Instrucciones de Uso:

1. Ejecute el script en un entorno de PowerShell con los privilegios adecuados.
2. Siga las instrucciones interactivas para proporcionar detalles como el nombre de la compañía, el dominio y el nombre del recurso compartido principal.

¡Automatice la configuración de Active Directory de manera eficiente con este script personalizable y bien documentado!

 
