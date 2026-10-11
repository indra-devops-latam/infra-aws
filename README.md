# Infraestructura AWS para microservicios

Este proyecto define con Terraform la infraestructura base en AWS para desplegar microservicios: una red VPC, un clúster de Kubernetes administrado con Amazon EKS y repositorios de imágenes en Amazon ECR.

## Componentes

- **VPC**: subredes públicas y privadas en dos zonas de disponibilidad, resolución DNS habilitada y un NAT Gateway compartido.
- **Amazon EKS**: clúster Kubernetes versión `1.30`, con endpoint de API público y un grupo administrado de nodos `ON_DEMAND` en las subredes privadas.
- **Amazon ECR**: un repositorio por servicio declarado en `var.services`, con escaneo de imágenes al subirlas y una política que conserva las cinco imágenes más recientes.

Actualmente, `services` incluye `client-gateway`. Otros nombres de microservicios aparecen comentados en `variables.tf`, por lo que no crean repositorios mientras no se agreguen a la lista activa.

## Requisitos

- Terraform CLI `1.5.0` o posterior.
- AWS CLI configurado con credenciales y permisos para administrar VPC, EKS, EC2, IAM y ECR.
- Acceso a la región y cuotas de AWS necesarias para crear los recursos.

El proveedor AWS en `provider.tf` utiliza la región definida por variables y el perfil local `adrian-fullstack`. Para usar ese perfil, configúralo con AWS CLI:

```powershell
aws configure --profile adrian-fullstack
```

Si tu perfil tiene otro nombre, actualiza `provider.tf` antes de ejecutar Terraform. No guardes claves de AWS en este repositorio.

## Entornos

Los archivos de variables se encuentran en `env/`:

| Archivo | Región | Clúster | Tipo de instancia | Nodos (mín./deseados/máx.) |
| --- | --- | --- | --- | --- |
| `env/dev.tfvars` | `us-east-1` | `cluster-dev` | `t3.medium` | 1 / 2 / 3 |
| `env/prod.tfvars` | `us-east-1` | `cluster-prod` | `t3.large` | 2 / 3 / 6 |

Cada entorno usa un bloque CIDR y subredes propios. Ajusta estos valores en el archivo correspondiente si tu red AWS tiene rangos que se solapan.

## Inicializar y validar

Ejecuta estos comandos desde la carpeta que contiene `main.tf`:

```powershell
terraform init
terraform fmt -check
terraform validate
terraform test
```

Para revisar los cambios que se aplicarían en desarrollo:

```powershell
terraform plan -var-file="env/dev.tfvars"
```

Para producción:

```powershell
terraform plan -var-file="env/prod.tfvars"
```

Después de revisar el plan, aplica explícitamente el entorno deseado:

```powershell
terraform apply -var-file="env/dev.tfvars"
```

Reemplaza el archivo por `env/prod.tfvars` únicamente cuando quieras modificar producción. Antes de aplicar, revisa cuidadosamente el plan: estos recursos pueden generar costos, especialmente EKS, los nodos EC2 y el NAT Gateway.

Para eliminar los recursos administrados para un entorno, selecciona el mismo archivo de variables y revisa el plan de destrucción antes de confirmar:

```powershell
terraform destroy -var-file="env/dev.tfvars"
```

## Pruebas

`tests/infrastructure.tftest.hcl` ejecuta pruebas de plan que verifican la configuración del repositorio ECR para `client-gateway`, el CIDR de la VPC y la cantidad de subredes privadas.

## Estado de Terraform

`backend.tf` contiene un ejemplo de backend S3 y bloqueo DynamoDB, pero está comentado. Por tanto, Terraform usa su backend local de forma predeterminada. Para trabajo colaborativo o automatización, configura un backend remoto compartido antes de aplicar cambios desde distintos equipos o ejecuciones.

## Automatización con GitHub Actions

Hay workflows para validar y generar un plan en solicitudes de cambio, y para aplicar infraestructura después de cambios en ramas configuradas. Antes de depender de ellos, alinea sus rutas con este proyecto: actualmente usan `infra/` como directorio de trabajo y filtran cambios bajo `infra/**`, pero los archivos Terraform y `env/` están en la raíz de este proyecto. Además, el workflow de apply se activa con eventos `push` y condiciona el job a `github.base_ref == 'main'`; en un evento `push`, normalmente debe comprobarse `github.ref` en su lugar. Revisa y corrige estos puntos en `.github/workflows/` si deseas habilitar la ejecución automática para esta estructura.

## Consideraciones

- El endpoint del API de EKS tiene acceso público habilitado. Restringe su acceso a los rangos IP requeridos si la política del entorno lo exige.
- La configuración utiliza un único NAT Gateway para las subredes privadas. Reduce costos, pero no ofrece la misma disponibilidad que un NAT Gateway por zona.
- La versión de Kubernetes del clúster está fijada en `1.30`; revisa su disponibilidad y soporte en AWS antes de crear un clúster nuevo.
- `outputs.tf` no declara salidas actualmente. Si necesitas consultar identificadores o endpoints con `terraform output`, decláralos explícitamente en ese archivo a partir de los outputs de los módulos.
