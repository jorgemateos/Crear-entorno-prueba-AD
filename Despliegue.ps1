#requires -RunAsAdministrator
#requires -Modules ActiveDirectory, GroupPolicy


############################################################################
###################### Lineas que se pueden modificar ######################
############################################################################

# Ruta del fichero de importacion de Usuarios
    $importarUsuario = 'doc\Usuarios.csv'

# Ruta del fichero de importacion las Ubicaciones de las sedes
    $importarUbicacionesSedes = 'doc\UbicacionesSedes.txt'

# Ruta del fichero de importacion de departamentos
    $importarDepartamento = 'doc\Departamentos.txt'


############################################################################
################### Fin de Lineas que se pueden modificar ##################
############################################################################

# Solicitar el nombre de la compañía y el dominio
    $nombreCompania = Read-Host -Prompt 'Introduce el nombre de la compañía'
    $dominio = "dc=" + (Get-ADDomain).DNSRoot.Replace(".",",dc=")

# Solicitar el nombre del Share principal
    $nombbreSharePrincipal = Read-Host -Prompt 'Introduce el Share principal'

# Leer el fichero de importacion de los usuarios
    $usuarios = Import-Csv -Path $importarUsuario -Delimiter ';'

# Leer el fichero de importacion las Ubicaciones de las sedes
    $contenidoUbicacionesSedes = Get-Content $importarUbicacionesSedes | ForEach-Object { $_.Trim() }

# Convertir la lista de las Ubicaciones de las sedes en una fila separada por comas
    $nombresUbicacionesSedes = $contenidoUbicacionesSedes -join ','

# Leer el fichero de importacion de departamentos
    $contenidoDepartamento = Get-Content $importarDepartamento | ForEach-Object { $_.Trim() }

# Convertir la lista de Departamentos en una fila separada por comas
    $nombresDepartamentos = $contenidoDepartamento -join ','


###################### Crear Unidades Organizativas - OU ######################

# Crear la OU RAIZ
    $ouRaiz = "OU=$nombreCompania,$dominio"
    New-ADOrganizationalUnit -Name $nombreCompania -Path $dominio

# Crear las OUs de las diferentes Ubicaciones de las sedes dentro de la OU=Raiz
    $nombresUbicacionesSedes.Split(',') | ForEach-Object {
        $nombreUbicacionesSedes = $_.Trim()
        New-ADOrganizationalUnit -Name $nombreUbicacionesSedes -Path $ouRaiz

        $ouSedes = "OU=$nombreUbicacionesSedes,OU=$nombreCompania,$dominio"

        New-ADOrganizationalUnit -Name Equipos -Path $ouSedes
        New-ADOrganizationalUnit -Name Grupos -Path $ouSedes
        New-ADOrganizationalUnit -Name Servidores -Path $ouSedes
        New-ADOrganizationalUnit -Name Usuarios -Path $ouSedes

        $ouEquipos = "OU=Equipos,OU=$nombreUbicacionesSedes,OU=$nombreCompania,$dominio"
        $ouUsuarios = "OU=Usuarios,OU=$nombreUbicacionesSedes,OU=$nombreCompania,$dominio"
        $ouGrupos = "OU=Grupos,OU=$nombreUbicacionesSedes,OU=$nombreCompania,$dominio"

        New-ADOrganizationalUnit -Name Equipos -Path $ouGrupos
        New-ADOrganizationalUnit -Name Usuarios -Path $ouGrupos

# Crear las OUs de los diferentes departamentos dentro de la OU=Departamento y OU=Equipos
        $nombresDepartamentos.Split(',') | ForEach-Object {
            $nombreDepartamento = $_.Trim()
            New-ADOrganizationalUnit -Name $nombreDepartamento -Path $ouUsuarios
            New-ADOrganizationalUnit -Name $nombreDepartamento -Path $ouEquipos
        }
    }


###################### Crear Grupos de usuarios ######################

# Crear el grupo Raiz en la OU Raiz
    $GrupoRaiz = "GRP_$nombreCompania"
    New-ADGroup -Name $GrupoRaiz -GroupScope Global -Path $ouRaiz

# Crear los Grupo de las diferentes Ubicaciones de las sedes dentro de la OU=Raiz
    $nombresUbicacionesSedes.Split(',') | ForEach-Object {
        $nombreUbicacionSedes = $_.Trim()

        $ouSedes = "OU=$nombreUbicacionSedes,OU=$nombreCompania,$dominio"
        $ouEquiposGrupos = "OU=Equipos,OU=Grupos,OU=$nombreUbicacionSedes,OU=$nombreCompania,$dominio"
        $ouUsuariosGrupos = "OU=Usuarios,OU=Grupos,OU=$nombreUbicacionSedes,OU=$nombreCompania,$dominio"

        $GrupoUbicacionSedes = "GRP_$nombreUbicacionSedes"
        New-ADGroup -Name $GrupoUbicacionSedes -GroupScope Global -Path $ouSedes
        Add-ADGroupMember -Identity $GrupoRaiz -Members $GrupoUbicacionSedes

# Crear los grupos de los departamento en la OU=Usuarios/grupos/.. y añadirlos al grupo Raiz
        $nombresDepartamentos.Split(',') | ForEach-Object {
            $nombreDepartamento = $_.Trim()

# Extraer las primeras tres primeras letras  de la ubicacion de la sede
            $letrasUbicacionSedes = $nombreUbicacionSedes.Substring(0, 3)

            $GrupoDepartamento = "GRP_" + $letrasUbicacionSedes + "_" + $nombreDepartamento
            New-ADGroup -Name $GrupoDepartamento -GroupScope Global -Path $ouUsuariosGrupos
            Add-ADGroupMember -Identity $GrupoUbicacionSedes -Members $GrupoDepartamento
        }
    }


###################### Crear Grupos de Equipos ######################

# Crear el grupo Raiz en la OU Raiz
    $GrupoEquipoRaiz = "GRP_C_$nombreCompania"
    New-ADGroup -Name $GrupoEquipoRaiz -GroupScope Global -Path $ouRaiz

# Crear los Grupo de las diferentes Ubicaciones de las sedes dentro de la OU=Raiz
    $nombresUbicacionesSedes.Split(',') | ForEach-Object {
        $nombreUbicacionSedes = $_.Trim()

        $ouSedes = "OU=$nombreUbicacionSedes,OU=$nombreCompania,$dominio"
        $ouEquiposGrupos = "OU=Equipos,OU=Grupos,OU=$nombreUbicacionSedes,OU=$nombreCompania,$dominio"
        $ouUsuariosGrupos = "OU=Usuarios,OU=Grupos,OU=$nombreUbicacionSedes,OU=$nombreCompania,$dominio"

        $GrupoUbicacionSedes = "GRP_C_$nombreUbicacionSedes"
        New-ADGroup -Name $GrupoUbicacionSedes -GroupScope Global -Path $ouSedes
        Add-ADGroupMember -Identity $GrupoEquipoRaiz -Members $GrupoUbicacionSedes

# Crear los grupos de los departamento en la OU=Equipos/grupos/.. y añadirlos al grupo Raiz
        $nombresDepartamentos.Split(',') | ForEach-Object {
            $nombreDepartamento = $_.Trim()

# Extraer las primeras tres primeras letras  de la ubicacion de la sede
            $letrasUbicacionSedes = $nombreUbicacionSedes.Substring(0, 3)

            $GrupoDepartamento = "GRP_C_" + $letrasUbicacionSedes + "_" + $nombreDepartamento
            New-ADGroup -Name $GrupoDepartamento -GroupScope Global -Path $ouEquiposGrupos
            Add-ADGroupMember -Identity $GrupoUbicacionSedes -Members $GrupoDepartamento
        }
    }


###################### Crear Unidades Organizativas y Grupos - ESPECIALES ######################

# Crear Unidades Organizativas ESPECIALES
    $ouProveedores = "OU=Proveedores,$ouRaiz"
    $ouShare = "OU=Share,$ouRaiz"
    $ouSistemas = "OU=Sistemas,$ouRaiz"
    $ouAdmins = "OU=Admins,$ouSistemas"
    $ouRDP = "OU=RDP,$ouSistemas"
    $ouVPN = "OU=VPN,$ouSistemas"

    New-ADOrganizationalUnit -Name Proveedores -Path $ouRaiz
    New-ADOrganizationalUnit -Name Sistemas -Path $ouRaiz
    New-ADOrganizationalUnit -Name Share -Path $ouRaiz

    New-ADOrganizationalUnit -Name Usuarios -Path $ouProveedores

    New-ADOrganizationalUnit -Name Admins -Path $ouSistemas
    New-ADOrganizationalUnit -Name Software -Path $ouSistemas
    New-ADOrganizationalUnit -Name RDP -Path $ouSistemas
    New-ADOrganizationalUnit -Name VPN -Path $ouSistemas

    New-ADGroup -Name Admins_NAS -GroupScope Global -Path $ouAdmins
    New-ADGroup -Name Admins_Firewall -GroupScope Global -Path $ouAdmins
    New-ADGroup -Name Admins_Vmware -GroupScope Global -Path $ouAdmins
    New-ADGroup -Name Admins_Software -GroupScope Global -Path $ouAdmins

    New-ADGroup -Name RDP_Servidor1 -GroupScope Global -Path $ouRDP
    New-ADGroup -Name RDP_Servidor2 -GroupScope Global -Path $ouRDP
    New-ADGroup -Name RDP_Servidor3 -GroupScope Global -Path $ouRDP

    New-ADGroup -Name GRP_VPN -GroupScope Global -Path $ouVPN
    New-ADGroup -Name GRP_VPN-Proveedores -GroupScope Global -Path $ouVPN


###################### habilitar bloqueo contra eliminacion accidental de todos los grupos ######################

# Obtener todos los grupos en Active Directory
$grupos = Get-ADGroup -Filter * -Properties ProtectedFromAccidentalDeletion

# Habilitar la protección contra eliminación accidental para cada grupo
foreach ($grupo in $grupos) {
    $grupo | Set-ADObject -ProtectedFromAccidentalDeletion $true
}


###################### Crear Usuarios Importados ######################

# Extraer los campos del usuario del fichero csv
    foreach ($usuario in $usuarios) {
        $nombre = $usuario.Nombre
        $apellido = $usuario.Apellido
        $departamento = $usuario.Departamento
        $nombreUsuario = $usuario.Usuario
        $contrasena = $usuario.Contrasena
        $Ubicacion = $usuario.Ubicacion

# Extraer las primeras tres primeras letras  de la ubicacion de la sede
        $letrasUbicacionSedes = $Ubicacion.Substring(0, 3)

# Crear el usuario en la OU=departamento/usuarios/Ubicacion correspondiente
        $ouUsuario = "ou=$departamento,ou=Usuarios,ou=$Ubicacion,ou=$nombreCompania,$dominio"
        $contrasenaSegura = ConvertTo-SecureString -String $contrasena -AsPlainText -Force
        $newUser = New-ADUser -SamAccountName $nombreUsuario -UserPrincipalName "$nombreUsuario@laboratorio.local" -Name "$nombre $apellido" -GivenName $nombre -Surname $apellido -Enabled $true -DisplayName "$nombre $apellido" -Path $ouUsuario -AccountPassword $contrasenaSegura

# Obtener el nombre del grupo correspondiente al departamento del usuario
        $GrupoDepartamento = "GRP_" + $letrasUbicacionSedes + "_" + $departamento

# Añadir el usuario al grupo del departamento
        Add-ADGroupMember -Identity $GrupoDepartamento -Members $nombreUsuario
    }


###################### Crear share y archivos ######################

# Ruta del Share Raiz
    $pathShareRaiz = "C:\$nombbreSharePrincipal"

# Crear el Share Personal
    New-Item -Path $pathShareRaiz -ItemType Directory > $null
    Write-Host "# Se ha creado Carpeta $pathShareRaiz; 0 errores"

# Obtener el ACL actual de la carpeta
    $acl = Get-Acl -Path $pathShareRaiz

# Deshabilitar la herencia en la carpeta y conservar los permisos existentes
    icacls $pathShareRaiz /inheritance:d

# Eliminar el grupo Usuarios
    icacls $pathShareRaiz /remove:g Usuarios
    Write-Host "# Permisos asignados correctamente; 0 errores"

# Configurar el recurso compartido
    $shareAcl = Get-Acl -Path $pathShareRaiz
    $shareRule = New-Object System.Security.AccessControl.FileSystemAccessRule($GrupoRaiz, 'Read', 'None', 'None', 'Allow')
    $shareAcl.AddAccessRule($shareRule)
    Set-Acl -Path $pathShareRaiz -AclObject $shareAcl

# Compartir la carpeta
    New-SmbShare -Name $nombbreSharePrincipal -Path $pathShareRaiz -FullAccess $GrupoRaiz > $null

# Crear los Shares de departamento dentro del Share Raiz
    $nombresDepartamentos.Split(',') | ForEach-Object {
        $nombreDepartamento = $_.Trim()

# Crear el Share Personal
        $shareDepartamento = Join-Path $pathShareRaiz $nombreDepartamento

        $pathDepartamento = "${pathShareRaiz}\${nombreDepartamento}"

        New-Item -Path $shareDepartamento -ItemType Directory > $null
        Write-Host "# Se ha creado Carpeta $shareDepartamento; 0 errores"

# Crear Subcarpeta
            1..10 | ForEach-Object {
                $numeroCarpeta  = "Carpeta$_"
		        New-Item -Path "$pathDepartamento\$numeroCarpeta" -ItemType Directory > $null

# Crear Ficheros Txt
                1..10 | ForEach-Object {
                    $numeroTxt  = "Txt$_"
                    New-Item -Path "$pathDepartamento\$numeroCarpeta\${numeroTxt}.txt" -ItemType File > $null
                }

# Crear Ficheros Word
                1..10 | ForEach-Object {
                    $numeroWord  = "Word$_"
                    New-Item -Path "$pathDepartamento\$numeroCarpeta\${numeroWord}.txt" -ItemType File > $null
                }

# Crear Ficheros Excel
                1..10 | ForEach-Object {
                    $numeroExcel  = "Excel$_"
                    New-Item -Path "$pathDepartamento\$numeroCarpeta\${numeroExcel}.txt" -ItemType File > $null
                }

# Crear Ficheros Pdf
                1..10 | ForEach-Object {
                    $numeroPdf  = "Pdf$_"
                    New-Item -Path "$pathDepartamento\$numeroCarpeta\${numeroPdf}.txt" -ItemType File > $null
                }
            }

        $nombresUbicacionesSedes.Split(',') | ForEach-Object {
            $nombreUbicacionSedes = $_.Trim()

# Extraer las primeras tres primeras letras  de la ubicacion de la sede
            $letrasUbicacionSedes = $nombreUbicacionSedes.Substring(0, 3)

# Crear el nombre del grupo correspondiente al departamento
            $nombreGrupo = "grp_" + $letrasUbicacionSedes + "_" + $nombreDepartamento

# Agregar la regla de acceso al grupo del departamento con permisos de modificar
            icacls $pathDepartamento /grant "${nombreGrupo}:(OI)(CI)(M)"
        }
    }


############################################################################
########################### Configuraciones de AD ##########################
############################################################################

###################### Habilitar Papelera de reciclaje en AD ######################

    Enable-ADOptionalFeature –Identity 'CN=Recycle Bin Feature,CN=Optional Features,CN=Directory Service,CN=Windows NT,CN=Services,CN=Configuration,$dominio' –Scope ForestOrConfigurationSet –Target (Get-ADDomain).DNSRoot

###################### Habilitar la protección contra eliminación accidental en todas las Unidades Organizativas (OU) en AD ######################
    Get-ADOrganizationalUnit -filter * -Properties ProtectedFromAccidentalDeletion | where {$_.ProtectedFromAccidentalDeletion -eq $false} | Set-ADOrganizationalUnit -ProtectedFromAccidentalDeletion $true
