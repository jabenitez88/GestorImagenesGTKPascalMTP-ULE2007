{$H+}
UNIT miMysql;

INTERFACE

uses mysql4,errorsInOut,sysutils,strutils,tad_cola;

Const
  N = 10000;				{ Este número nos dice cuántas imágenes podremos mostrar en nuestra tabla CLIST }
  Configuracion = 'config.ini';		{ Aquí asignamos el nombre del fichero de configuración }
  DataBase : Pchar = 'jabagi';  	{ Nombre de la base de datos }
  CreaBBDD : Pchar = 'CREATE DATABASE IF NOT EXISTS jabagi';	{ Sentencia creadora de la DB }	
  // Cadena que usaremos para insertar imágenes en la DB
  INSIMG = 'INSERT INTO imagen (nombre_imagen,descripcion,tipo,tematica,subtematica,anchura,altura,tamano,etiquetas,identificador,fecha) VALUES (';
INSIMGMOD = 'INSERT INTO imagen (nombre_imagen,descripcion,tipo,tematica,subtematica,anchura,altura,tamano,etiquetas,identificador) VALUES (';
   
  UPDIMG1 = 'UPDATE imagen SET descripcion = "'; { Cadenas que usaremos para MODIFICAR una imagen en la DB }
  UPDIMG2 = '" , etiquetas = "';
  UPDIMG3 = ' " , subtematica = ';
  UPDIMG4 = ' , tematica = ';
  UPDIMG5 = ' , nombre_imagen = "';
  UPDIMG6 = '" WHERE id = ';
  DELIMG = 'DELETE FROM imagen WHERE ';		 { Cadena que usaremos para BORRAR una imagen en la DB }
  // Cádenas de búsqueda que nos serviran para hacer búsquedas en la db de todo tipo
  // Tanto de imágenes, como de temática... lo que haga falta
  BusquedaIMG = 'SELECT * FROM imagen WHERE etiquetas RLIKE "';

  BusquedaIDIMG = 'SELECT identificador FROM imagen WHERE identificador = "';

  BusquedaIDSub = 'SELECT id FROM tematica WHERE nombre = "';

  BusquedaNOMSub = 'SELECT nombre_hijo FROM subtematica ';
  BusquedaNOMTem = 'SELECT nombre FROM tematica '; 
  BusquedaIMG2a = 'SELECT imagen.id, imagen.nombre_imagen, imagen.descripcion, imagen.tipo, imagen.anchura, imagen.altura , imagen.tamano ,imagen.etiquetas ,subtematica.nombre_hijo,tematica.nombre, imagen.identificador, imagen.fecha';
  BusquedaIMG2b = ' FROM imagen join tematica on imagen.tematica = tematica.id join subtematica on imagen.subtematica = subtematica.id_hijo WHERE ';

  BusquedaIMG2porTEM1 = 'SELECT id,espadre FROM tematica WHERE nombre = "';
  BusquedaIMG2porTEM2 = 'SELECT id_hijo FROM subtematica WHERE id_padre = ';

  BusquedaTEM = 'SELECT tematica.id FROM tematica join subtematica on tematica.id = subtematica.id_padre WHERE id_hijo = ';
  // Sentencias con las que creo mi base de datos al completo.
  CreaTabla1 : Pchar = 'CREATE TABLE IF NOT EXISTS tematica (id int not null auto_increment,nombre varchar(50) NOT NULL,espadre BOOLEAN default FALSE,PRIMARY KEY  (id)) ENGINE=InnoDB DEFAULT CHARSET=latin1';

  CreaTablaSub1 = 'CREATE TABLE IF NOT EXISTS subtematica (id_padre int not null auto_increment,id_hijo int NOT NULL,nombre_hijo varchar(50) NOT NULL,index (id_padre),foreign key (id_padre) references tematica';
  CreaTablaSub2 = '(id) on update cascade,index (id_hijo),foreign key (id_hijo) references tematica(id),PRIMARY KEY(id_hijo)) ENGINE=InnoDB DEFAULT CHARSET=latin1';	

  CreaTablaImg1 = 'CREATE TABLE IF NOT EXISTS imagen (id int unsigned NOT NULL auto_increment,nombre_imagen varchar(100) default NULL,descripcion text,tipo varchar(20) default NULL,tematica int not NULL,subtematica int not NULL,anchura int';
  CreaTablaImg2 = ' default NULL,altura int default NULL,tamano bigint default NULL,etiquetas text,identificador varchar(15),fecha date,PRIMARY KEY  (id),index (tematica),foreign key (tematica) references';
  CreaTablaImg3 = ' tematica(id) on update cascade,index (subtematica),foreign key (subtematica) references subtematica(id_hijo) on update cascade)ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1';
  // Sentencias con las que creo mis TEMATICAS y SUBTEMATICAS
  INSTEM1 = 'INSERT INTO tematica (nombre,espadre) VALUES ("Imagen",TRUE),("Animales",TRUE),("Personas",TRUE),("Cosas",TRUE),("Lugares",TRUE),("Informatica",TRUE),("Plantas",TRUE),("Cobayas",FALSE),';
  INSTEM2 = '("Perros",TRUE),("Gatos",FALSE),("Derivados",FALSE),("Escritorios",FALSE),("Exteriores",FALSE),("Aguilas",FALSE),("Tulipan",FALSE),("Mastines",FALSE)';
  INSSTEM1 = 'INSERT INTO subtematica (id_padre,id_hijo,nombre_hijo) VALUES (1,2,"Animales"),(1,3,"Personas"),(1,4,"Cosas"),(1,5,"Lugares"),(1,6,"Informatica"),(1,7,"Plantas"),';
  INSSTEM2 = '(2,8,"Cobayas"),(2,9,"Perros"),(2,10,"Gatos"),(2,14,"Aguilas"),(4,11,"Derivados"),(5,13,"Exteriores"),(6,12,"Escritorios"),(7,15,"Tulipan"),(9,16,"Mastines")'; 
  INSTEMXML = 'INSERT INTO tematica (nombre,espadre) VALUES ("';
  INSSTEMXML = 'INSERT INTO subtematica (id_padre,id_hijo,nombre_hijo) VALUES (';

  DIRIMG = 'directorio_imagenes=';
  SERVSQL = 'servidor=';
  USUSQL = 'usuario=';
  PASSSQL = 'contraseña=';
  
Type
      tTablaBusqueda = array [0..N,1..13] of string;	{ Tabla que almacenará la info de las imágenes cuando hacemos un busquedaDB }
							{ ID,NOMBRE, TEMATICA, SUBTEMATICA.... etc }
      tTablaBorrado = array [0..N] of boolean;		{ Tabla con la que sabremos qué imágenes seleccionan desde la tabla de búsqueda CLIST }
							{ La usaremos para borrar imágenes a bloque y crear conjuntos... }
Var
  //num 		: longint;	 no sé por qué tengo esto... si no lo uso
  fichConf	: text;			 { Fichero de configuración que leeremos para obtener Usuario, Servidor, Contraseña y Directorio }
  sock 		: PMYSQL;		 { La conexión a MYSQL }
  qmysql 	: TMYSQL;		 { El query a MYSQL }
  qbuf 		: string [160];		 { El buffer de MYSQL }
  rowbuf 	: TMYSQL_ROW;		 { Las FILAS de las tablas }
  recbuf 	: PMYSQL_RES;		

Procedure LlamadasDB(llamada:Pchar);	{ Procedure para hacer llamadas desde la base de datos }
Procedure ConectaDB(var directorio:string);			{ Con él conectaremos a la DB }
Procedure CreaDB();			{ Este se encarga de crear la DB, con las tablas y todo }
Procedure BusquedaDB(busqueda:pchar;var valor:longint;mostrar:boolean;var tabla:tTablaBusqueda);
Function Num2St(entero : longint):string;{ Este pasa un entero a un string }
Procedure BusquedaTematicas(busqueda:pchar;var colaTems:tCola; encolar:boolean;var tabla:tTablaBusqueda);
Procedure BusquedaIdentificador(busqueda:pchar;var serepite:boolean);
Procedure DameFecha(var fecha:string);	
Procedure CerrarDB();



IMPLEMENTATION
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function Num2St(entero : longint):string;
Var
	cadena: string;
Begin
	str(entero, cadena);
	Num2St := cadena;
End;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Procedure RecogeDatosDB(var usuario,contrasena,servidor,directorio:string);
Var errorF : integer;
    cadena	: string;
Begin	
	assign(fichConf, Configuracion);
	{$I-}reset(fichConf);{$I+}
	errorF := ioresult;
	if (errorF<>0) then begin 
				calcError(errorF);
				end
	else begin
	while not eof (fichConf) do
	begin
		while not eoln (fichConf) do
		begin
			readln (fichConf, cadena);
			if (copy(cadena,1, length(DIRIMG)) = DIRIMG) then directorio := copy(cadena,length(DIRIMG)+1,length(cadena));
			if (copy(cadena,1, length(SERVSQL)) = SERVSQL) then servidor := copy(cadena,length(SERVSQL)+1,length(cadena));
			if (copy(cadena,1, length(USUSQL)) = USUSQL) then usuario := copy(cadena,length(USUSQL)+1,length(cadena));
			if (copy(cadena,1, length(PASSSQL)) = PASSSQL) then contrasena := copy(cadena,length(PASSSQL)+1,length(cadena));
		end;

		readln(fichConf);
	end;
	close(fichConf);
	end;
	
End;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Procedure LlamadasDB(llamada:Pchar);
Begin
    //writeln ('Ejecutando: ',llamada,'...');
    if (mysql_query(sock,llamada) < 0) then
      begin
      Writeln (stderr,'Llamada fallida');
      writeln (stderr,mysql_error(sock));
      Halt(1);
      end;
End;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Procedure CreaDB();
Var Aux,Aux2,Aux3,Aux4:string;
    CreaTabla2,CreaTabla3,insertaTem,insertaStem : Pchar;
Begin
   Aux := CreaTablaImg1 + CreaTablaImg2 + CreaTablaImg3;
   CreaTabla3 := PCHAR(@Aux[1]);
   Aux2 := CreaTablaSub1 + CreaTablaSub2;
   CreaTabla2 := PCHAR(@Aux2[1]);
   Aux3 := INSTEM1 + INSTEM2;
   insertaTem := PCHAR(@Aux3[1]);
   Aux4 := INSSTEM1 + INSSTEM2;
   insertaStem := PCHAR(@Aux4[1]);
   LlamadasDB(CreaBBDD);
   mysql_select_db(sock,DataBase);
   LlamadasDB(CreaTabla1);
   LlamadasDB(CreaTabla2);
   LlamadasDB(CreaTabla3);
   LLamadasDB(insertaTem);
   LlamadasDB(insertaStem);

End;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Procedure ConectaDB(var directorio:string);
Var Usuario,Contrasena,Servidor:string;
Begin
  RecogeDatosDB(Usuario,Contrasena,Servidor,directorio);
  mysql_init(PMySQL(@qmysql));
  sock :=  mysql_real_connect(PMysql(@qmysql),@Servidor[1],@Usuario[1],@Contrasena[1],nil,0,nil,0);

if sock=Nil then
    begin
    Writeln (stderr,'No se ha podido conectar');
    Writeln (stderr,mysql_error(@qmysql));
    halt(1);
    end;
  if mysql_select_db(sock,DataBase) < 0 then
    begin
    Writeln (stderr,'No se puede seleccionar esa base de datos. ',Database);
    Writeln (stderr,mysql_error(sock));
    halt (1);
    end
  else if mysql_select_db(sock,DataBase) = 1 then CreaDB();	{ Si la DB no está creada, la crea }
End;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Procedure BusquedaDB(busqueda:pchar;var valor:longint;mostrar:boolean;var tabla:tTablaBusqueda);
Var i:longint;				{ Con este procedure haremos todo tipo de búsquedas, las que nos hagan falta... }
Begin				 	{ de imágenes... de subtemáticas... temáticas..., es una función muy usada en este }
  i:=0;					{ programa. }
  llamadasDB(busqueda);			{ busqueda:pchar => la sentencia a ejecutar, lo que queremos buscar }
  recbuf := mysql_store_result(sock);	{ valor:longint  => Es un entero que nos sirve para obtener la id de temática o  }
  //if RecBuf=Nil then			{ 		subtemática cuando la necesitamos, solo sirve cuando mostrar es  }
    //begin				{		FALSO, en otro caso no tiene un valor indicativo de nada.	 }
    //mysql_close(sock);			{ mostrar:boolean => Nos indica para qué queremos la búsqueda, si es general, o  }
    //halt (1);				{ 		 si tan sólo queríamos obtener una ID en vez de toda la info de imagen }
    //end;
  if (recbuf<>nil) then 
	begin
  rowbuf := mysql_fetch_row(recbuf);
  if mostrar and (valor <> 90) then 
	begin
  while (rowbuf <> nil) do
       	begin
      
       tabla[valor,13] := rowbuf[0];	{ ID }
       tabla[valor,1] := rowbuf[1];		{ Nombre }
       tabla[valor,9] := rowbuf[2];		{ Descripción }
       tabla[valor,4] := rowbuf[3];		{ Tipo }
       tabla[valor,6] := rowbuf[4];		{ Subtemática }
       tabla[valor,7] := rowbuf[5];		{ Temática }
       tabla[valor,5] := rowbuf[6];		{ Anchura }
       tabla[valor,8] := rowbuf[7];		{ Altura }
       tabla[valor,2] := rowbuf[8];		{ Descripción }
       tabla[valor,3] := rowbuf[9];		{ Etiquetas }
       tabla[valor,11] := rowbuf[10];		{ IDENTIFICADOR }
       tabla[valor,12] := rowbuf[11];		{ FECHA }
       rowbuf := mysql_fetch_row(recbuf);
       i:=i+1;
       valor := valor + 1 ;
       		end
	end
   // Cuando se ejecute este else if de abajo, estará buscando el valor de una id temática o subtemática.
   else if (mysql_num_rows(recbuf)<>0) and (not mostrar) and (busqueda <> BusquedaNomSub)  and (busqueda <> BusquedaNomTem) and (valor <> 90) then Val(rowbuf[0],valor)
   // Cuando se ejecute este else if de abajo, estará obteniendo los nombres de la tabla SUBTEMATICA

   else if (mysql_num_rows(recbuf)<>0) and (not mostrar) and ((busqueda = BusquedaNomSub) or (valor = 90)) then 
		begin
		while (rowbuf <> nil) do 
			begin
			//writeln('hola');
			valor := i;
			tabla[i,1] := rowbuf[0];
			i:=i+1;
			rowbuf := mysql_fetch_row(recbuf);
			end;
		end;
	end;
    mysql_free_result(recbuf);
End;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Procedure BusquedaTematicas(busqueda:pchar;var colaTems:tCola; encolar:boolean;var tabla:tTablaBusqueda);
Var i,tem:longint;				{ Con este procedure vamos a buscar las temáticas hijas y a encolarlas, para luego poder }
Begin				 	{ mostrar todas las imágenes que nacen de esa temática. Por ejemplo... }
  for i:=0 to N do tabla[i,1] := '';
  for i:=0 to N do tabla[i,2] := '';
  i:=0;					{ Animales - > Perros -> Mastines -> Pequeños mastines -> Bebés mastines }
  llamadasDB(busqueda);			{          - > Gatos -> Siamés  }
  recbuf := mysql_store_result(sock);	{          - > Roedores -> Cobayas  } 
  if (recbuf<>nil) then 		{ Si tenemos esta jerarquía y buscamos ANIMALES, deben salir todas las imágenes que subyacen de }
	begin				{ esa temática, es decir, las cobayas, los siameses, los bebés mastines, pequeños mastines, mastines}
  	rowbuf := mysql_fetch_row(recbuf); { roedores, perros y gatos, y no sólo animales - perros, gatos y roedores...			}
  	while (rowbuf <> nil) do
       		begin
		if encolar then tabla[i,1] := rowbuf[0]
		else begin
			tabla[i,1] := rowbuf[0];
			tabla[i,2] := rowbuf[1];
			end;
		val(tabla[i,1],tem);
		if encolar then Poner(colaTems,tem);
       	 	rowbuf := mysql_fetch_row(recbuf);
        	i:=i+1;
       		end;
	end;
	     mysql_free_result(recbuf);


End;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Procedure BusquedaIdentificador(busqueda:pchar;var serepite:boolean);
Var i:longint;				{ Con este procedure vamos a buscar las temáticas hijas y a encolarlas, para luego poder }
Begin				 	{ mostrar todas las imágenes que nacen de esa temática. Por ejemplo... }
  i:=0;					{ Animales - > Perros -> Mastines -> Pequeños mastines -> Bebés mastines }
  llamadasDB(busqueda);			{          - > Gatos -> Siamés  }
  recbuf := mysql_store_result(sock);	{          - > Roedores -> Cobayas  } 
  if (recbuf<>nil) then 		{ Si tenemos esta jerarquía y buscamos ANIMALES, deben salir todas las imágenes que subyacen de }
	begin				{ esa temática, es decir, las cobayas, los siameses, los bebés mastines, pequeños mastines, mastines}
  	rowbuf := mysql_fetch_row(recbuf); { roedores, perros y gatos, y no sólo animales - perros, gatos y roedores...			}
  	while (rowbuf <> nil) do
       		begin
		serepite := TRUE;
       	 	rowbuf := mysql_fetch_row(recbuf);
       		end;
	end;
	     mysql_free_result(recbuf);


End;
Procedure DameFecha(var fecha:string);	
Var f:string;		
Begin		
  f := 'SELECT CURDATE()';		 				
  llamadasDB(pchar(f));			
  recbuf := mysql_store_result(sock);	
  if (recbuf<>nil) then 		
	begin			
  	rowbuf := mysql_fetch_row(recbuf); 
  	while (rowbuf <> nil) do
       		begin
		fecha := rowbuf[0];
       	 	rowbuf := mysql_fetch_row(recbuf);
       		end;
	end;
	     mysql_free_result(recbuf);
End;
Procedure CerrarDB();
Begin
	mysql_close(sock);
End;

end.


