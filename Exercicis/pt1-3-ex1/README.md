# Ejercicio 1 – Terraform con AWS

Este proyecto utiliza **Terraform** para desplegar dos instancias EC2 del tipo `t3.micro` con **Amazon Linux 2023** en la región `us-east-1`. El objetivo es familiarizarse con la infraestructura como código (IaC) y comprender la topología básica de un entorno en la nube.

## 📦 Recursos creados

- **2 instancias EC2** con Amazon Linux 2023
- **Etiquetas personalizadas** para identificar cada instancia
- **Región AWS**: us-east-1

## 🗺️ Topología
La siguiente imagen muestra la topología creada con LucidChart:

![Topología EC2 con Terraform](assets/Imatges/MarcoverticalAWS(2019).png)

## 📁 Estructura del proyecto
    exercicis/
    └── pt1-3-ex1/
        ├── README.md
        ├── Fitxers Terraform/
        └── assets/
            └── Imatges/

## 📁 Archivos del proyecto

- `pt1-3-ex1.tf`: archivo principal con la configuración de Terraform
- `README.md`: documentación del proyecto y explicación de la topología
- `assets/Imatges/MarcoverticalAWS(2019).png`: diagrama exportado desde LucidChart

## 🚀 Ejecución del proyecto

1. Inicializa Terraform:
   ```bash
   terraform init
2. Aplica la configuracion:
   ```bash
   terraform apply