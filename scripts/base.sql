CREATE DATABASE BDABD_BlackCatDB
GO

USE BDABD_BlackCatDB
GO

CREATE TABLE Clientes (
    IdCliente INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    TipoCliente VARCHAR(10) CHECK (TipoCliente IN ('PERSONA', 'EMPRESA')) NOT NULL,
    NombreRazonSocial NVARCHAR(150) NOT NULL,
    DniRuc VARCHAR(11) UNIQUE NOT NULL,
    Telefono VARCHAR(20) NOT NULL,
    Correo VARCHAR(100) NULL,
    Direccion NVARCHAR(200) NULL
)
GO

CREATE TABLE Roles (
    IdRol INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    Nombre VARCHAR(50) UNIQUE NOT NULL
)
GO

CREATE TABLE Usuarios (
    IdUsuario INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    NombresCompletos NVARCHAR(150) NOT NULL,
    NombreUsuario VARCHAR(50) UNIQUE NOT NULL,
    IdRol INT NOT NULL,
    Contrasena VARCHAR(255) NOT NULL,
    Telefono VARCHAR(20) NOT NULL,
    Correo VARCHAR(100) NULL,
    Activo BIT DEFAULT 1 NOT NULL,

    CONSTRAINT FK_Usuarios_Roles FOREIGN KEY (IdRol) REFERENCES Roles (IdRol)
)
GO

CREATE TABLE Categorias (
    IdCategoria INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    Nombre NVARCHAR(100) UNIQUE NOT NULL
)
GO

CREATE TABLE Servicios (
    IdServicio INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    Nombre NVARCHAR(150) UNIQUE NOT NULL,
    IdCategoria INT NOT NULL,
    Precio DECIMAL(10,2) NOT NULL,
    Activo BIT DEFAULT 1 NOT NULL,

    CONSTRAINT FK_Servicios_Categorias FOREIGN KEY (IdCategoria) REFERENCES Categorias (IdCategoria)
)
GO

CREATE TABLE Cotizaciones (
    IdCotizacion INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    IdCliente INT NOT NULL,
    IdUsuario INT NOT NULL,
    FechaEmision DATETIME DEFAULT SYSDATETIME() NOT NULL,
    FechaVigencia DATETIME NOT NULL,
    MontoTotal DECIMAL(10,2) NOT NULL,
    Estado VARCHAR(10) DEFAULT 'BORRADOR' CHECK (Estado IN ('BORRADOR','ENVIADA','APROBADA','RECHAZADA','VENCIDA','ANULADA')) NOT NULL,
    MotivoRechazo NVARCHAR(500) NULL,

    CONSTRAINT FK_Cotizaciones_Clientes FOREIGN KEY (IdCliente) REFERENCES Clientes (IdCliente),
    CONSTRAINT FK_Cotizaciones_Usuarios FOREIGN KEY (IdUsuario) REFERENCES Usuarios (IdUsuario)
)
GO

CREATE TABLE DetalleCotizaciones (
    IdDetalle INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    IdCotizacion INT NOT NULL,
    IdServicio INT NOT NULL,
    Cantidad INT NOT NULL,
    PrecioUnitario DECIMAL(10,2) NOT NULL,
    Subtotal DECIMAL(10, 2) NOT NULL,
    Especificaciones NVARCHAR(MAX) NULL,

    CONSTRAINT FK_DetalleCotizaciones_Cotizaciones FOREIGN KEY (IdCotizacion) REFERENCES Cotizaciones (IdCotizacion),
    CONSTRAINT FK_DetalleCotizaciones_Servicios FOREIGN KEY (IdServicio) REFERENCES Servicios (IdServicio)
)
GO

CREATE TABLE Pedidos (
    IdPedido INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    IdCotizacion INT UNIQUE NOT NULL,
    FechaPedido DATETIME DEFAULT SYSDATETIME() NOT NULL,
    NumeroOrdenCompra VARCHAR(50) NULL,
    MontoTotal DECIMAL(10,2) NOT NULL,
    Estado VARCHAR(20) DEFAULT 'PENDIENTE_ADELANTO' CHECK (Estado IN ('PENDIENTE_ADELANTO','EN_PROCESO','EN_REVISION','COMPLETADO','CERRADO','CANCELADO')) NOT NULL,
    FechaCierre DATETIME NULL,

    CONSTRAINT FK_Pedidos_Cotizaciones FOREIGN KEY (IdCotizacion) REFERENCES Cotizaciones (IdCotizacion)
)
GO

CREATE TABLE Revisiones (
    IdRevision INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    IdPedido INT NOT NULL,
    NumeroIteracion INT NOT NULL,
    FechaEnvio DATETIME DEFAULT SYSDATETIME() NOT NULL,
    FechaRespuesta DATETIME NULL,
    ObservacionesCliente NVARCHAR(MAX) NULL,
    Aprobada BIT NULL,

    CONSTRAINT FK_Revisiones_Pedidos FOREIGN KEY (IdPedido) REFERENCES Pedidos (IdPedido)
)
GO

CREATE TABLE Tareas (
    IdTarea INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    IdPedido INT NOT NULL,
    IdDetalle INT NULL,
    IdRevision INT NULL,
    IdUsuario INT NULL,
    Tipo VARCHAR(10) CHECK (Tipo IN ('SERVICIO','GENERAL','AJUSTE')) NOT NULL,
    Descripcion NVARCHAR(500) NOT NULL,
    FechaAsignacion DATETIME NULL,
    FechaEntrega DATETIME NULL,
    Estado VARCHAR(10) DEFAULT 'PENDIENTE' CHECK (Estado IN ('PENDIENTE','EN_CURSO','COMPLETADA')) NOT NULL,

    CONSTRAINT FK_Tareas_Pedidos FOREIGN KEY (IdPedido) REFERENCES Pedidos (IdPedido),
    CONSTRAINT FK_Tareas_DetalleCotizaciones FOREIGN KEY (IdDetalle) REFERENCES DetalleCotizaciones (IdDetalle),
    CONSTRAINT FK_Tareas_Revisiones FOREIGN KEY (IdRevision) REFERENCES Revisiones (IdRevision),
    CONSTRAINT FK_Tareas_Usuarios FOREIGN KEY (IdUsuario) REFERENCES Usuarios (IdUsuario)
)
GO

CREATE TABLE Pagos (
    IdPago INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    IdPedido INT NOT NULL,
    Descripcion NVARCHAR(200) NULL,
    TipoPago VARCHAR(10) CHECK (TipoPago IN ('ADELANTO','SALDO')) NOT NULL,
    Monto DECIMAL(12,2) NOT NULL,
    MetodoPago VARCHAR(30) NOT NULL,
    FechaPago DATETIME DEFAULT SYSDATETIME() NOT NULL,
    Estado VARCHAR(10) DEFAULT 'REGISTRADO' CHECK (Estado IN ('REGISTRADO','ANULADO')) NOT NULL,
    MotivoAnulacion NVARCHAR(500) NULL,
    FechaAnulacion DATETIME2(0) NULL,
    
    CONSTRAINT FK_Pagos_Pedidos FOREIGN KEY (IdPedido) REFERENCES Pedidos (IdPedido)
)
GO

CREATE TABLE Recibos (
    IdRecibo INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    IdPago INT UNIQUE NOT NULL,
    NumeroRecibo VARCHAR(20) UNIQUE NOT NULL,
    FechaEmision DATETIME DEFAULT SYSDATETIME() NOT NULL,

    CONSTRAINT FK_Recibos_Pagos FOREIGN KEY (IdPago) REFERENCES Pagos (IdPago)
)
GO

CREATE TABLE Comprobantes (
    IdComprobante INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    IdPedido INT UNIQUE NOT NULL,
    TipoComprobante VARCHAR(10) CHECK (TipoComprobante IN ('BOLETA','FACTURA')) NOT NULL,
    NumeroComprobante VARCHAR(20) UNIQUE NOT NULL,
    FechaEmision DATETIME2(0) NOT NULL CONSTRAINT DF_Comprobante_Fecha DEFAULT SYSDATETIME(),
    ValorVenta DECIMAL(12,2) NOT NULL,
    Igv DECIMAL(12,2) NOT NULL,
    MontoTotal DECIMAL(12,2) NOT NULL,

    CONSTRAINT FK_Comprobantes_Pedidos FOREIGN KEY (IdPedido) REFERENCES Pedidos (IdPedido)
)
GO

CREATE TABLE AuditoriaLogs (
    IdLog BIGINT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    TablaAfectada VARCHAR(50) NOT NULL,
    Operacion VARCHAR(10) CHECK (Operacion IN ('INSERT','UPDATE','DELETE')) NOT NULL,
    IdRegistro BIGINT NOT NULL,
    ValorAnterior NVARCHAR(MAX) NULL,
    ValorNuevo NVARCHAR(MAX) NULL,
    UsuarioBd NVARCHAR(128) DEFAULT SUSER_SNAME() NOT NULL,
    IdUsuario INT NULL,
    FechaEvento DATETIME DEFAULT SYSDATETIME() NOT NULL
)
GO