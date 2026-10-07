# PROYECTO: RESERVAS DE ESTACIONAMIENTO EN TIEMPO REAL (TUCOCHERA)

Este repositorio contiene el código de Infraestructura como Código para desplegar en AWS una **aplicación web con API para la gestión de reservas de estacionamiento en tiempo real**, usando Terraform y buenas prácticas.


**Integrantes:** Flores Leonardo Alberth Jair, Pita Verástegui Anthony Eduardo, Rujel Alvarez Kevin David, Romero Asmat Bryans Aldair, Santisteban Novoa Julio Alejandro

## ¿Qué hace nuestro proyecto?

**TuCochera** es una cadena de cocheras con **12 sucursales** en distintos departamentos del Perú, y cada sucursal puede albergar hasta **60 vehículos**. Hoy los conductores no tienen cómo saber si hay espacio ni cómo reservarlo.

Nuestra propuesta es una aplicación web con una API donde el usuario puede **consultar los espacios disponibles, elegir su sede y horario, y reservar**. Al reservar, recibe una notificación. 

## Flujo de Trabajo en Equipo
1. **Ramas y PR:** Nadie escribe directamente en main. Cada entrega se hace mediante una rama propia y se debe abrir un Pull Request, para revisión del equipo.
2. **Validación:** Antes de subir un cambio, ejecuta de forma local:

   "terraform fmt" y "terraform validate"

3. **Despliegue Único:** Solo el Desplegador Oficial ejecuta terraform apply desde su máquina.


## Primer commit: la parte de VPC
 
Decidimos empezar por la red, ya que el resto de servicios (RDS, Lambda, etc.) va a estar dentro de ella y necesita sus datos. Por eso, **en nuestro primer commit vamos a subir solo la parte de la VPC.**
 
En ese commit van los cuatro archivos de Terraform: `providers.tf` (la versión de Terraform y el provider de AWS), `variables.tf` (región, entorno), `vpc.tf` (la VPC, las subredes, el Internet Gateway, las rutas). También subimos el `.terraform.lock.hcl`, que se genera al hacer `terraform init` y guarda las versiones exactas del provider, el `.gitignore`, para no subir por error la carpeta `.terraform/` ni el estado de Terraform, y este mismo `README.md`.


Pasos para hacerlo, dentro de la carpeta `Proyecto-IaC`:
```bash
terraform init
```
```bash
terraform fmt
```
```bash
terraform validate
```
```bash
git add .
```
```bash
git commit -m "feat: agrega VPC, subredes, rutas y endpoint de S3"
```
```bash
git branch -M main
```
```bash
git push -u origin main
```


## Instrucciones de Despliegue de la Infraestructura

> Solo el **Desplegador Oficial** hace el despliegue.

### Clonar el repositorio y acceder a la carpeta
```bash
git clone https://github.com/anthonyepv-ctrl/Proyecto-IaC.git
cd Proyecto-IaC
```

### Verificar que las credenciales de AWS funcionan
```bash
aws sts get-caller-identity
```

### Inicializar
```bash
terraform init
```

### Validar el código
```bash
terraform fmt -check
```
```bash
terraform validate
```

### Revisar el plan (opcional pero recomendable)
```bash
terraform plan -var="environment=dev"
```

### Aplicar los cambios
```bash
terraform apply -var="environment=dev"
```
Escribe `yes` cuando lo pida. Al final muestra los outputs: `vpc_id`, `public_subnet_ids`, `private_subnet_ids`, etc.

Para otro entorno cambia `environment` (`dev`, `qa` o `prod`) y usa un CIDR distinto para que no choquen, por ejemplo:
```bash
terraform apply -var="environment=qa" -var="vpc_cidr=10.1.0.0/16"
```

### Destruir la infraestructura
Si encendemos el NAT Gateway, cobra por hora, así que destruimos todo al terminar las pruebas.
```bash
terraform destroy -var="environment=dev"
```

---
