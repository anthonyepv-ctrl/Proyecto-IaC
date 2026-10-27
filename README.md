# TuCochera — Infraestructura como Código (IaC) en AWS con Terraform

Este repositorio contiene la infraestructura como código (IaC) para desplegar el MVP de **TuCochera**, una plataforma web de gestión y reserva de espacios de estacionamiento en tiempo real para 12 sedes a nivel nacional en Perú.

---

## 1. Arquitectura del MVP

```text
INTERNET
   │
   ├── CloudFront (HTTPS)
   │      ├── S3 privado  →  Frontend (HTML / CSS / JS)
   │      └── /api/*      →  API Gateway (REST API /dev)
   │                              └── Lambda (Subredes privadas)
   │                                      └── RDS PostgreSQL 16 (Subredes privadas)
   │
   └── (Sin acceso directo a la VPC)

VPC 10.0.0.0/16 (Completamente Privada)
├── app-a  10.0.1.0/24  (us-east-1a)  →  Lambdas
├── app-b  10.0.2.0/24  (us-east-1b)  →  Alta disponibilidad / expansión futura
├── db-a   10.0.3.0/24  (us-east-1a)  →  RDS PostgreSQL 16
└── db-b   10.0.4.0/24  (us-east-1b)  →  RDS Subnet Group (Requisito Multi-AZ de AWS)
```

### Principios de Seguridad y Red
- **Cero exposición a internet para la VPC:** No se despliega Internet Gateway (IGW), NAT Gateway ni VPC Endpoints, eliminando costos innecesarios y vectores de ataque externos.
- **Microsegmentación por Security Groups:**
  - El SG de Lambda solo permite tráfico de salida (egress) por el puerto 5432 dirigido exclusivamente hacia el SG del RDS.
  - El SG de RDS solo permite tráfico de entrada (ingress) por el puerto 5432 proveniente del SG de Lambda.
- **Acceso Web Seguro:** CloudFront centraliza las peticiones HTTPS y enruta el tráfico web estático a S3 (vía Origin Access Control - OAC) y las peticiones `/api/*` al API Gateway.

---

## 2. Estructura del Proyecto

```text
Proyecto-IaC/
├── terraform/
│   ├── providers.tf             # Versión de Terraform y providers (AWS, random, archive)
│   ├── variables.tf             # Definición de variables parametrizables
│   ├── locals.tf                # Variables locales, nombres y tags estandarizados
│   ├── outputs.tf               # Outputs globales / reserva de outputs del proyecto
│   ├── network.tf               # VPC, 4 subredes, 2 tablas de rutas y asociaciones
│   ├── security.tf              # Security Groups (Lambda y RDS) con reglas explícitas
│   ├── database.tf              # RDS PostgreSQL (Propietario: Kevin)
│   ├── iam.tf                   # Roles y políticas IAM (Propietario: Aldair)
│   ├── lambda.tf                # Definición de funciones Lambda (Propietario: Aldair)
│   ├── api.tf                   # API Gateway REST y métodos (Propietario: Alberth)
│   ├── frontend.tf              # S3 + CloudFront + OAC (Propietario: Alberth)
│   └── terraform.tfvars.example # Plantilla de variables locales para el despliegue
├── app/
│   ├── backend/                 # Código fuente de las funciones Lambda (Python 3.12)
│   └── frontend/                # Archivos estáticos de la aplicación web
├── scripts/
│   ├── build.ps1                # Script para empaquetar Lambdas
│   └── deploy_frontend.ps1      # Script para subir frontend a S3 e invalidar CloudFront
├── .gitignore                   # Exclusión de archivos sensibles y de estado
└── README.md                    # Documentación del proyecto y guía de despliegue
```

---

## 3. Guía de Despliegue Oficial (Deployer: Pita)

> [!IMPORTANT]
> El despliegue de infraestructura lo realiza únicamente **Pita (Deployer Oficial)** desde su entorno local con credenciales de AWS activas. El archivo `terraform.tfstate` es crítico y **no debe eliminarse ni subirse a Git**.

### Prerrequisitos
- Terraform `>= 1.6.0` instalado.
- AWS CLI v2 instalado y configurado con credenciales válidas.
- PowerShell 7 o terminal Bash.

### Paso 1: Configurar credenciales y variables locales
1. Verificar que la sesión de AWS esté activa:
   ```bash
   aws sts get-caller-identity
   ```
2. Crear el archivo `terraform.tfvars` dentro de `terraform/` a partir de la plantilla:
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   ```
3. Ajustar en `terraform.tfvars` el `aws_profile` correspondiente (por ejemplo `"default"` o `"admin"`).

### Paso 2: Inicializar y validar Terraform
```bash
# 1. Inicializar providers y backend local
terraform init

# 2. Verificar formato del código
terraform fmt -check

# 3. Validar sintaxis y referencias cruzadas
terraform validate
```

### Paso 3: Planificar y desplegar la infraestructura
```bash
# 1. Inspeccionar el plan de ejecución
terraform plan

# 2. Aplicar la creación de recursos
terraform apply
```
*Escribir `yes` para confirmar la ejecución.*

### Paso 4: Inicialización de la Base de Datos (`db-init`)
Una vez creado el RDS y desplegadas las Lambdas, inicializar el esquema y sedes:
```powershell
aws lambda invoke --function-name tucochera-dev-db-init --cli-binary-format raw-in-base64-out --payload '{}' response.json
cat response.json
```

### Paso 5: Despliegue del Frontend
Ejecutar el script de sincronización con S3 e invalidación de CloudFront:
```powershell
..\scripts\deploy_frontend.ps1
```

> Antes de desplegar, cambia `USE_FAKE_DATA = true` a `false` en `app/frontend/index.html` para consumir la API real.

### Paso 6: Compartir información con el equipo
Pita comparte en el grupo de trabajo:
- **CloudFront URL:** Dominio HTTPS para acceder a la aplicación web.
- **API URL:** Endpoint base de API Gateway.
- **RDS Endpoint:** Endpoint de la base de datos PostgreSQL privada.

### Paso 7: Destrucción de Recursos al Finalizar Pruebas
Para evitar costos innecesarios en la cuenta de AWS:
```bash
terraform destroy
```
*Confirmar con `yes` para eliminar todos los recursos creados.*

---

## 4. Contrato de Nombres de Recursos

Para garantizar que el merge de los diferentes módulos del equipo se realice sin fricción ni discrepancias, se respeta estrictamente el siguiente contrato:

| Recurso | Dirección en Terraform | Propietario |
|---|---|---|
| **VPC** | `aws_vpc.this` | Pita |
| **Subredes** | `aws_subnet.app_a`, `aws_subnet.app_b`, `aws_subnet.db_a`, `aws_subnet.db_b` | Pita |
| **Route Tables** | `aws_route_table.app`, `aws_route_table.db` | Pita |
| **Security Groups** | `aws_security_group.lambda`, `aws_security_group.rds` | Pita |
| **Contraseña RDS** | `random_password.db` | Kevin |
| **Subnet Group RDS**| `aws_db_subnet_group.this` | Kevin |
| **Instancia RDS** | `aws_db_instance.this` | Kevin |
| **Lambdas** | `aws_lambda_function.disponibilidad`, `registrar`, `expandir`, `db_init` | Aldair |
| **API Gateway** | `aws_api_gateway_rest_api.this`, `aws_api_gateway_stage.this` | Alberth |
| **Bucket Frontend** | `aws_s3_bucket.frontend` | Alberth |
| **CloudFront** | `aws_cloudfront_distribution.this` | Alberth |

---

## 5. Glosario Técnico y Conceptos Clave

- **Terraform State (`terraform.tfstate`):** Registro interno donde Terraform guarda el mapa entre los archivos `.tf` y los recursos físicos aprovisionados en AWS. Si se borra, Terraform pierde el control del estado real.
- **Stateful Security Groups:** Los grupos de seguridad de AWS son *stateful*: si una solicitud es permitida en salida, la respuesta entrante correspondiente es permitida automáticamente.
- **default_tags:** Bloque en el provider de AWS que inyecta automáticamente etiquetas (`Project`, `Environment`, `ManagedBy`) a todos los recursos que soportan tags.
