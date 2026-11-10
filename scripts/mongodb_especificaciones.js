// =================================================================================================
// PASO 4: PARADIGMA NOSQL - MONGODB
// Base de Datos: BDABD_BlackCatNoSQL (o blackcat_nosql)
// Colección: EspecificacionesDetalleCotizaciones
// =================================================================================================
// Propósito Arquitectónico:
// Implementar persistencia políglota para almacenar las especificaciones técnicas semiestructuradas
// de los servicios de Black Cat, desacoplando el campo relacional NVARCHAR(MAX) de SQL Server
// hacia documentos BSON flexibles y consultables por atributos anidados.
// =================================================================================================

// Seleccionar la base de datos
use blackcat_nosql;

// -------------------------------------------------------------------------------------------------
// 1. CREATE: Inserción de documentos con esquemas polimórficos según el tipo de servicio
// -------------------------------------------------------------------------------------------------

db.EspecificacionesDetalleCotizaciones.insertMany([
  {
    "id_detalle": 1,
    "id_cotizacion": 1,
    "id_pedido": 1,
    "id_servicio": 1,
    "categoria": "Impresión Publicitaria",
    "servicio": "Lona Banner Publicitaria Gigante",
    "cliente": "Inversiones Retail del Norte S.A.C.",
    "especificaciones": {
      "tipo_material": "Lona Frontlight 13oz brillante",
      "dimensiones": {
        "ancho_metros": 8.0,
        "alto_metros": 3.5,
        "area_total_m2": 28.0
      },
      "resolucion_dpi": 1440,
      "tipo_tinta": "Solvente de alta resistencia UV",
      "acabados": [
        "Termosellado perimetral con refuerzo",
        "Ojalillos metálicos cada 50 cm",
        "Bolsillos tubulares superior e inferior"
      ],
      "requiere_instalacion": true,
      "detalles_instalacion": {
        "altura_montaje_metros": 6.0,
        "tipo_superficie": "Estructura metálica existente",
        "requiere_andamio": true
      }
    },
    "fecha_creacion": new Date()
  },
  {
    "id_detalle": 2,
    "id_cotizacion": 1,
    "id_pedido": 1,
    "id_servicio": 4,
    "categoria": "Producción Audiovisual",
    "servicio": "Video Publicitario para Redes (Reels / TikTok)",
    "cliente": "Inversiones Retail del Norte S.A.C.",
    "especificaciones": {
      "duracion_segundos": 30,
      "relacion_aspecto": "9:16 (Vertical)",
      "resolucion": "4K (2160x3840)",
      "fps": 60,
      "locucion": {
        "requerida": true,
        "tipo_voz": "Femenina juvenil",
        "idioma": "Español neutro"
      },
      "musicalizacion": "Pista con derechos comerciales incluidos",
      "entregables": [
        "Master en ProRes 422",
        "Copia web en H.264 (.mp4)",
        "Miniatura de portada (.png)"
      ],
      "incluye_subtitulos_dinamicos": true
    },
    "fecha_creacion": new Date()
  },
  {
    "id_detalle": 3,
    "id_cotizacion": 2,
    "id_pedido": 2,
    "id_servicio": 7,
    "categoria": "Merchandising",
    "servicio": "Polos Corporativos Publicitarios",
    "cliente": "Constructora e Inmobiliaria Horizonte",
    "especificaciones": {
      "material": "Algodón Jersey 30/1 peinado",
      "color_tela": "Azul marino corporativo (Pantone 289 C)",
      "tipo_estampado": "Serigrafía textil plastisol al tacto cero",
      "posiciones_estampado": [
        "Pecho izquierdo (Logo 8x8 cm)",
        "Espalda superior (Eslogan 25x10 cm)"
      ],
      "distribucion_tallas": {
        "S": 20,
        "M": 50,
        "L": 40,
        "XL": 10
      },
      "empaque": "Bolsa individual transparente con adhesivo"
    },
    "fecha_creacion": new Date()
  },
  {
    "id_detalle": 4,
    "id_cotizacion": 3,
    "id_pedido": null,
    "id_servicio": 10,
    "categoria": "Marketing Digital",
    "servicio": "Campaña de Pauta Digital de Conversión",
    "cliente": "Clínica Dental Sonrisas",
    "especificaciones": {
      "plataformas": ["Meta Ads (Facebook e Instagram)", "Google Ads Search"],
      "objetivo_campana": "Generación de clientes potenciales (Leads WhatsApp)",
      "segmentacion": {
        "ubicacion_geografica": "Trujillo, La Libertad",
        "radio_km": 15,
        "rango_edad": [22, 55],
        "intereses": ["Salud dental", "Estética dental", "Ortodoncia"]
      },
      "presupuesto_publicitario_mensual": 1500.00,
      "kpis_comprometidos": {
        "costo_por_lead_objetivo": 12.50,
        "leads_estimados_mes": 120
      }
    },
    "fecha_creacion": new Date()
  }
]);

// -------------------------------------------------------------------------------------------------
// 2. READ: Consultas sobre atributos semiestructurados y anidados
// -------------------------------------------------------------------------------------------------

// 2.1 Consulta relacional: Obtener todas las especificaciones de una cotización específica
db.EspecificacionesDetalleCotizaciones.find(
  { "id_cotizacion": 1 },
  { "servicio": 1, "categoria": 1, "especificaciones": 1 }
);

// 2.2 Consulta sobre atributos anidados: Buscar impresiones que midan más de 5 metros de ancho
db.EspecificacionesDetalleCotizaciones.find(
  { "especificaciones.dimensiones.ancho_metros": { $gte: 5.0 } },
  { "cliente": 1, "servicio": 1, "especificaciones.dimensiones": 1 }
);

// 2.3 Consulta sobre arreglos: Buscar servicios de video que tengan entregable en formato 'Master en ProRes 422'
db.EspecificacionesDetalleCotizaciones.find(
  { "especificaciones.entregables": "Master en ProRes 422" }
);

// 2.4 Consulta con operadores lógicos: Buscar servicios de Merchandising o Impresión que requieran instalación o empaque especial
db.EspecificacionesDetalleCotizaciones.find({
  $or: [
    { "especificaciones.requiere_instalacion": true },
    { "especificaciones.empaque": { $exists: true } }
  ]
});

// -------------------------------------------------------------------------------------------------
// 3. UPDATE: Modificación dinámica de especificaciones
// -------------------------------------------------------------------------------------------------

// 3.1 Actualizar campo anidado: Cambiar la altura de montaje de la lona publicitaria
db.EspecificacionesDetalleCotizaciones.updateOne(
  { "id_detalle": 1 },
  { 
    $set: { 
      "especificaciones.detalles_instalacion.altura_montaje_metros": 7.5,
      "fecha_modificacion": new Date()
    } 
  }
);

// 3.2 Agregar un nuevo elemento a un arreglo: Agregar nuevo acabado a la lona sin reescribir el arreglo
db.EspecificacionesDetalleCotizaciones.updateOne(
  { "id_detalle": 1 },
  { 
    $push: { 
      "especificaciones.acabados": "Barniz de protección UV antigraffiti" 
    } 
  }
);

// -------------------------------------------------------------------------------------------------
// 4. DELETE: Eliminación de especificaciones de un detalle anulado o cancelado
// -------------------------------------------------------------------------------------------------

// Eliminar las especificaciones de un detalle de cotización específico
db.EspecificacionesDetalleCotizaciones.deleteOne({ "id_detalle": 4 });
