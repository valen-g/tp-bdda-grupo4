import tkinter as tk
import pyodbc
import tkintermapview
import requests
from tkinter import ttk
from tkinter import messagebox

# ------------------------
# FUNCIONES
# ------------------------

def obtener_conexion():

    return pyodbc.connect(
        "DRIVER={SQL Server};"
        "SERVER=Agus\\SQLEXPRESS;"              #Aca va el nombre del servidor de sql
        "DATABASE=ParquesNacionalesDB;"
        "Trusted_Connection=yes;"
    )

def buscar_parque():

    nombre_busqueda = txt_busqueda.get()

    conexion = obtener_conexion()

    cursor = conexion.cursor()

    cursor.execute("""
    SELECT TOP 1
        P.IdParque,
        P.Nombre,
        P.Ubicacion,
        P.Superficie,
        TP.Descripcion
    FROM Administracion.Parque P
    LEFT JOIN Administracion.TipoParque TP
        ON P.IdTipoParque = TP.IdTipoParque
    WHERE P.Nombre LIKE ?
    """, f"%{nombre_busqueda}%")

    parque = cursor.fetchone()

    conexion.close()

    txt_id.delete(0, tk.END)
    txt_nombre.delete(0, tk.END)
    txt_ubicacion.delete(0, tk.END)
    txt_superficie.delete(0, tk.END)

    cmb_tipo.set("")

    if parque:

        txt_id.insert(0, str(parque[0]))
        txt_nombre.insert(0, parque[1])
        txt_ubicacion.insert(0, parque[2])
        txt_superficie.insert(0, str(parque[3]))

        if parque[4]:
            cmb_tipo.set(parque[4])

    else:

        messagebox.showwarning(
            "Atención",
            "No se encontró un parque con ese nombre."
        )

def nuevo_parque():

    txt_id.delete(0, tk.END)
    txt_nombre.delete(0, tk.END)
    txt_ubicacion.delete(0, tk.END)
    txt_superficie.delete(0, tk.END)
    cmb_tipo.set("")

def guardar_parque():

    try:

        nombre = txt_nombre.get()
        ubicacion = txt_ubicacion.get()
        superficie = float(txt_superficie.get())
        tipo = cmb_tipo.get()

        conexion = obtener_conexion()

        cursor = conexion.cursor()

        # Buscar IdTipoParque a partir de la descripción
        cursor.execute("""
            SELECT IdTipoParque
            FROM Administracion.TipoParque
            WHERE Descripcion = ?
        """, tipo)

        resultado = cursor.fetchone()

        if resultado:
            id_tipo = resultado[0]
        else:
            id_tipo = None

        cursor.execute("""
            DECLARE @IdParqueNuevo INT;

            EXEC Administracion.Parque_Insertar
                @Nombre = ?,
                @Ubicacion = ?,
                @Superficie = ?,
                @Descripcion = NULL,
                @IdTipoParque = ?,
                @EsActivo = 1,
                @IdParque = @IdParqueNuevo OUTPUT;

            SELECT @IdParqueNuevo;
        """,
        nombre,
        ubicacion,
        superficie,
        id_tipo)

        nuevo_id = cursor.fetchone()[0]

        conexion.commit()
        conexion.close()

        txt_id.delete(0, tk.END)
        txt_id.insert(0, str(nuevo_id))

        messagebox.showinfo(
            "Éxito",
            f"Parque guardado correctamente. ID: {nuevo_id}"
        )

    except Exception as e:

        messagebox.showerror(
            "Error",
            str(e)
        )

def modificar_parque():

    try:

        id_parque = int(txt_id.get())
        nombre = txt_nombre.get()
        ubicacion = txt_ubicacion.get()
        superficie = int(txt_superficie.get())
        tipo = cmb_tipo.get()

        conexion = obtener_conexion()

        cursor = conexion.cursor()

        cursor.execute("""
            SELECT IdTipoParque
            FROM Administracion.TipoParque
            WHERE Descripcion = ?
        """, tipo)

        resultado = cursor.fetchone()

        if resultado:
            id_tipo = resultado[0]
        else:
            id_tipo = None

        cursor.execute("""
            EXEC Administracion.Parque_Actualizar
                @IdParque=?,
                @Nombre=?,
                @Ubicacion=?,
                @Superficie=?,
                @Descripcion=NULL,
                @IdTipoParque=?,
                @EsActivo=1
        """,
        id_parque,
        nombre,
        ubicacion,
        superficie,
        id_tipo)

        conexion.commit()
        conexion.close()

        messagebox.showinfo(
            "Éxito",
            "Parque modificado correctamente"
        )

    except Exception as e:

        messagebox.showerror(
            "Error",
            str(e)
        )

def eliminar_parque():

    try:

        id_parque = int(txt_id.get())

        respuesta = messagebox.askyesno(
            "Confirmar",
            f"¿Desea eliminar el parque ID {id_parque}?"
        )

        if not respuesta:
            return

        conexion = obtener_conexion()

        cursor = conexion.cursor()

        cursor.execute("""
            EXEC Administracion.Parque_Eliminar
                @IdParque=?
        """, id_parque)

        conexion.commit()
        conexion.close()

        nuevo_parque()

        messagebox.showinfo(
            "Éxito",
            "Parque eliminado correctamente"
        )

    except Exception as e:

        messagebox.showerror(
            "Error",
            str(e)
        )

def guardar_tipo_parque(descripcion, ventana_tipo):

    try:

        conexion = obtener_conexion()

        cursor = conexion.cursor()

        cursor.execute("""
            DECLARE @NuevoId INT;

            EXEC Administracion.TipoParque_Insertar
                @Descripcion=?,
                @IdTipoParque=@NuevoId OUTPUT;

            SELECT @NuevoId;
        """, descripcion)

        cursor.fetchone()

        conexion.commit()
        conexion.close()

        cargar_tipos_parque()

        cmb_tipo.set(descripcion)

        ventana_tipo.destroy()

        messagebox.showinfo(
            "Éxito",
            "Tipo de parque agregado correctamente"
        )

    except Exception as e:

        messagebox.showerror(
            "Error",
            str(e)
        )

def abrir_ventana_tipo():

    ventana_tipo = tk.Toplevel(ventana)

    ventana_tipo.title("Nuevo Tipo de Parque")
    ventana_tipo.geometry("350x150")
    ventana_tipo.resizable(False, False)

    tk.Label(
        ventana_tipo,
        text="Descripción:"
    ).pack(pady=10)

    txt_descripcion_tipo = tk.Entry(
        ventana_tipo,
        width=35
    )

    txt_descripcion_tipo.pack(pady=5)

    tk.Button(
        ventana_tipo,
        text="Guardar",
        command=lambda: guardar_tipo_parque(
            txt_descripcion_tipo.get(),
            ventana_tipo
        )
    ).pack(pady=10)

def cargar_tipos_parque():

    conexion = obtener_conexion()

    cursor = conexion.cursor()

    cursor.execute("""
        SELECT Descripcion
        FROM Administracion.TipoParque
        ORDER BY Descripcion
    """)

    tipos = []

    for fila in cursor.fetchall():
        tipos.append(fila[0])

    conexion.close()

    cmb_tipo["values"] = tipos

def buscar_por_nombre():

    nombre = txt_busqueda.get()

    conexion = obtener_conexion()

    cursor = conexion.cursor()

    cursor.execute("""
        SELECT
            IdParque,
            Nombre
        FROM Administracion.Parque
        WHERE Nombre LIKE ? AND EsActivo = 1
        ORDER BY Nombre
    """, f"%{nombre}%")

    resultados = cursor.fetchall()

    conexion.close()

    lista_resultados.delete(0, tk.END)

    for fila in resultados:

        lista_resultados.insert(
            tk.END,
            f"ID {fila[0]} - {fila[1]}"
        )

def cargar_parque_por_id(id_parque):

    conexion = obtener_conexion()

    cursor = conexion.cursor()

    cursor.execute("""
        SELECT
            P.IdParque,
            P.Nombre,
            P.Ubicacion,
            P.Superficie,
            TP.Descripcion
        FROM Administracion.Parque P
        LEFT JOIN Administracion.TipoParque TP
            ON P.IdTipoParque = TP.IdTipoParque
        WHERE P.IdParque = ?
    """, id_parque)

    parque = cursor.fetchone()

    conexion.close()

    if parque:

        txt_id.delete(0, tk.END)
        txt_nombre.delete(0, tk.END)
        txt_ubicacion.delete(0, tk.END)
        txt_superficie.delete(0, tk.END)

        cmb_tipo.set("")

        txt_id.insert(0, str(parque[0]))
        txt_nombre.insert(0, parque[1])
        mostrar_mapa(parque[2])
        txt_ubicacion.insert(0, parque[2])
        txt_superficie.insert(0, str(parque[3]))

        if parque[4]:
            cmb_tipo.set(parque[4])

def mostrar_mapa(nombre):

    try:

        url = "https://nominatim.openstreetmap.org/search"

        parametros = {
            "q": nombre + ", Argentina",
            "format": "json",
            "limit": 1
        }

        headers = {
            "User-Agent": "ParquesNacionales"
        }

        respuesta = requests.get(
            url,
            params=parametros,
            headers=headers
        )

        datos = respuesta.json()

        if datos:

            lat = float(datos[0]["lat"])
            lon = float(datos[0]["lon"])
            mostrar_clima(lat, lon)

            mapa.delete_all_marker()

            mapa.set_position(lat, lon)
            mapa.set_zoom(12)

            mapa.set_marker(
                lat,
                lon,
                text=nombre
            )

    except Exception as e:
        print(e)

def mostrar_clima(lat, lon):

    url = (
        f"https://api.open-meteo.com/v1/forecast?"
        f"latitude={lat}&longitude={lon}"
        "&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code"
    )

    datos = requests.get(url).json()

    actual = datos["current"]

    temperatura = actual["temperature_2m"]
    humedad = actual["relative_humidity_2m"]
    viento = actual["wind_speed_10m"]
    codigo = actual["weather_code"]

    estados = {
        0: ("☀️","Despejado"),
        1: ("🌤️","Mayormente despejado"),
        2: ("⛅","Parcialmente nublado"),
        3: ("☁️","Nublado"),
        45: ("🌫️","Niebla"),
        51: ("🌦️","Llovizna"),
        61: ("🌧️","Lluvia"),
        71: ("❄️","Nieve"),
        95: ("⛈️","Tormenta")
    }

    icono, estado = estados.get(codigo,("🌤️","Normal"))

    lbl_icono.config(text=icono)
    lbl_temp.config(text=f"{temperatura} °C")
    lbl_estado.config(text=estado)
    lbl_humedad.config(text=f"💧 {humedad}%")
    lbl_viento.config(text=f"🌬️ {viento} km/h")

def seleccionar_resultado(event):

    seleccion = lista_resultados.curselection()

    if not seleccion:
        return

    texto = lista_resultados.get(seleccion[0])

    id_parque = texto.split("-")[0]
    id_parque = id_parque.replace("ID", "").strip()

    cargar_parque_por_id(id_parque)

# ------------------------
# VENTANA PRINCIPAL
# ------------------------

ventana = tk.Tk()

ventana.title("Sistema de Parques Nacionales")
ventana.geometry("800x950")
ventana.resizable(False, False)

style = ttk.Style()
style.theme_use("clam")
# ------------------------
# TITULO
# ------------------------

titulo = tk.Label(
    ventana,
    text="Gestión de Parques",
    font=("Arial", 20, "bold")
)

titulo.pack(pady=15)

# ------------------------
# BUSQUEDA
# ------------------------

frame_busqueda = tk.LabelFrame(
    ventana,
    text="Búsqueda",
    padx=10,
    pady=10
)

frame_busqueda.pack(pady=10)

frame_resultados = tk.Frame(ventana)
frame_resultados.pack(pady=5)

scroll_resultados = tk.Scrollbar(frame_resultados)

lista_resultados = tk.Listbox(
    frame_resultados,
    width=80,
    height=4,
    yscrollcommand=scroll_resultados.set
)

scroll_resultados.config(
    command=lista_resultados.yview
)

lista_resultados.pack(
    side=tk.LEFT,
    fill=tk.BOTH
)

scroll_resultados.pack(
    side=tk.RIGHT,
    fill=tk.Y
)

lista_resultados.bind(
    "<Double-Button-1>",
    seleccionar_resultado
)

lbl_busqueda = tk.Label(
    frame_busqueda,
    text="Nombre del Parque:"
)

lbl_busqueda.grid(row=0, column=0, padx=5)

txt_busqueda = tk.Entry(
    frame_busqueda,
    width=40
)

txt_busqueda.grid(row=0, column=1, padx=5)

btn_buscar = tk.Button(
    frame_busqueda,
    text="Buscar",
    command=buscar_por_nombre
)

btn_buscar.grid(row=0, column=2, padx=5)

# ------------------------
# DATOS DEL PARQUE
# ------------------------

frame_datos = tk.LabelFrame(
    ventana,
    text="Datos del Parque",
    padx=15,
    pady=15
)
frame_datos.pack(pady=20)


# ------------------------
# MAPA
# ------------------------

frame_mapa = tk.LabelFrame(
    ventana,
    text="Información en Tiempo Real",
    padx=10,
    pady=10
)

frame_mapa.pack(pady=10)

frame_clima = tk.Frame(frame_mapa)
frame_clima.pack(side=tk.LEFT, padx=10)

lbl_icono = tk.Label(
    frame_clima,
    text="🌤️",
    font=("Arial",40)
)

lbl_icono.pack(pady=(15,5))

lbl_temp = tk.Label(
    frame_clima,
    text="-- °C",
    font=("Arial",18,"bold")
)

lbl_temp.pack()

lbl_estado = tk.Label(
    frame_clima,
    text="Esperando...",
    font=("Arial",10)
)

lbl_estado.pack(pady=5)

lbl_humedad = tk.Label(
    frame_clima,
    text="💧 -- %",
    font=("Arial",11)
)

lbl_humedad.pack(pady=5)

lbl_viento = tk.Label(
    frame_clima,
    text="🌬️ -- km/h",
    font=("Arial",11)
)

lbl_viento.pack(pady=5)

frame_mapa_widget = tk.Frame(frame_mapa)
frame_mapa_widget.pack(side=tk.LEFT)

mapa = tkintermapview.TkinterMapView(
    frame_mapa_widget,
    width=550,
    height=300
)

mapa.pack()

mapa.set_position(-38.4161, -63.6167)
mapa.set_zoom(4)

mapa.pack()

# Argentina por defecto
mapa.set_position(-38.4161, -63.6167)
mapa.set_zoom(4)

# ------------------------
# ID
# ------------------------

tk.Label(
    frame_datos,
    text="ID"
).grid(row=0, column=0, sticky="w")

txt_id = tk.Entry(
    frame_datos,
    width=50
)

txt_id.grid(row=0, column=1, pady=5)

# Nombre

tk.Label(
    frame_datos,
    text="Nombre"
).grid(row=1, column=0, sticky="w")

txt_nombre = tk.Entry(
    frame_datos,
    width=50
)

txt_nombre.grid(row=1, column=1, pady=5)

# Ubicación

tk.Label(
    frame_datos,
    text="Ubicación"
).grid(row=2, column=0, sticky="w")

txt_ubicacion = tk.Entry(
    frame_datos,
    width=50
)

txt_ubicacion.grid(row=2, column=1, pady=5)

# Superficie

tk.Label(
    frame_datos,
    text="Superficie (ha)"
).grid(row=3, column=0, sticky="w")

txt_superficie = tk.Entry(
    frame_datos,
    width=50
)

txt_superficie.grid(row=3, column=1, pady=5)

# Tipo de Parque

tk.Label(
    frame_datos,
    text="Tipo de Parque"
).grid(row=4, column=0, sticky="w")

cmb_tipo = ttk.Combobox(
    frame_datos,
    width=47,
    state="readonly"
)

cmb_tipo.grid(row=4, column=1, pady=5)

btn_nuevo_tipo = tk.Button(
    frame_datos,
    text="+",
    width=3,
    command=abrir_ventana_tipo
)

btn_nuevo_tipo.grid(row=4, column=2, padx=5)

# ------------------------
# BOTONES ABM
# ------------------------

frame_botones = tk.LabelFrame(ventana, text="Acciones", padx=10, pady=10)
frame_botones.pack(pady=20)

btn_nuevo = tk.Button(
    frame_botones,
    text="Nuevo",
    width=15,
    command=nuevo_parque
)

btn_nuevo.grid(row=0, column=0, padx=5)

btn_guardar = tk.Button(
    frame_botones,
    text="Guardar",
    width=15,
    command=guardar_parque
)

btn_guardar.grid(row=0, column=1, padx=5)

btn_modificar = tk.Button(
    frame_botones,
    text="Modificar",
    width=15,
    command=modificar_parque
)

btn_modificar.grid(row=0, column=2, padx=5)

btn_eliminar = tk.Button(
    frame_botones,
    text="Eliminar",
    width=15,
    command=eliminar_parque
)

btn_eliminar.grid(row=0, column=3, padx=5)

# ------------------------
# INICIAR APP
# ------------------------

cargar_tipos_parque()
ventana.mainloop()