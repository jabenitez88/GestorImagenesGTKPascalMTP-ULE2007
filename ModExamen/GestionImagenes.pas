UNIT GestionImagenes;
{$H+}
INTERFACE
uses miMysql,gtk2,glib2,Gdk2PixBuf,sysutils,DOS;

Const 
      INSIMG2 = 'INSERT INTO imagen (descripcion,image,id_subtematica,anchura,altura,tamano) VALUES (';

Type tImagen = Record				{ Registro en el que almacenaremos la informacion completa de la imagen }
		id_imagen 	: longint;		{ Almacena la ID de la imagen }
		id_desc 	: string;		{ Almacena la ID de la imagen }
		titulo		: string;		{ Campo que almacenará la id de la imagen}		
		descripcion	: string;		{ Almacena la DESCRIPCION de la imagen }
		fichero 	: string;		{ Almacena el NOMBRE DEL FICHERO imagen }
		tipo_fichero 	: pchar;		{ Almacena la MIME TYPE de la imagen }
		tamano_img	: longint;		{ Almacena la TAMAÑO EN BYTES del fichero imagen }
		ancho_img	: longint;		{ Almacena la ANCHURA de la imagen }
		alto_img	: longint;		{ Almacena la ALTURA de la imagen }
		etiquetas	: string;		{ Almacena las ETIQUETAS de la imagen }
		tematica	: string;		{ Almacena la SUBTEMATICA de la imagen }
		subtematica	: string;		{ Almacena la SUBTEMATICA de la imagen }
		idsubtematica	: longint;		{ Almacena la SUBTEMATICA de la imagen }
		idtematica	: longint;		{ Almacena la TEMATICA de la imagen }
		existefich	: boolean;		{ Almacena la EXISTENCIA DEL FICHERO de la imagen }
		malformato	: boolean;		{ Nos dice si la imagen posee un FORMATO valido para gdkpixbuf }
		solouna		: boolean;		{ Para insertar la fecha... }
		End;
      
       PGdkPixbufModulePattern = ^TGdkPixbufModulePattern; 
       TGdkPixbufModulePattern = record			 { Los tipos declarados abajo hasta el final, nos sirven para obtener el mime type en nuestra funcion } 
            	prefix 		: ^byte;		
            	mask 		: ^byte;
            	relevance 	: longint;
         end;
    
    PGdkPixbufFormat  = ^TGdkPixbufFormat;
    TGdkPixbufFormat = record
            	name 		: ^gchar;
            	signature 	: PGdkPixbufModulePattern;
            	domain 		: ^gchar;
            	description 	: ^gchar;
            	mime_types 	: ^Pgchar;
            	extensions 	: ^Pgchar;
            	flags 		: guint32;
            	disabled 	: gboolean;
            	license 	: ^gchar;
         end;

Var   //imagen : tImagen;
      imagen	: tImagen;		{ Variable en la que almacenaremos la info de la imagen.				}
      imagenPix		: PGdkPixbuf;		{ Almacenara el PIXBUF de la imagen }
      valores,valores2	: string;		{ Strings que enviaremos a la DB al hacer búsquedas }
      nom		: Pchar;		{ Nombre del fichero imagen pasado a PCHAR }

Function gdk_pixbuf_get_file_info(filename:Pgchar; width:Pgint; height:Pgint):PGdkPixbufFormat; cdecl; external gdkpixbuflib;
Procedure ObtenerInfoFichero(var imagen:tImagen);
Procedure SubirImagen(var imagen:tImagen); 	
Procedure GuardarImagen(var imagen:tImagen);
Procedure AlmacenarDB(var imagen:tImagen);
Procedure ModificarImagen(var imagen:tImagen);
//Procedure BuscarImagen();

IMPLEMENTATION
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Procedure SubirImagen(var imagen:tImagen); 		{ Procedure con el cual crearemos el pixbuf de la imagen , si es posible }
Var   error:PGError;
Begin	
	imagen.existefich := FileExists(imagen.fichero);
	error := nil; imagenPix := nil;
	if (imagen.existefich) then begin
	nom := PCHAR(@imagen.fichero[1]);
	imagenPix := gdk_pixbuf_new_from_file(nom,@error);
	imagen.malformato := True;
	end;
	if (imagenPix <> nil) then imagen.malformato := False;
End;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function CalculaTamano(var imagen:tImagen):longint;	{ Función que cálcula el tamaño del fichero que se le envíe }
Var
  Dir : SearchRec;
Begin
  FindFirst(imagen.fichero,archive,Dir);
  FindClose(Dir); 
  CalculaTamano := Dir.Size;
End;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Procedure ObtenerInfoFichero(var imagen:tImagen);	{ Procedure con el que guardamos el tamaño, la altura y anchura en el registro de tipo tImagen }
Var 
  	estFormat:PGdkPixbufFormat;
Begin    
	imagen.tamano_img := CalculaTamano(imagen);
	estFormat:=gdk_pixbuf_get_file_info(Pchar(imagen.fichero), @imagen.ancho_img, @imagen.alto_img);
	imagen.tipo_fichero := estFormat^.mime_types[0];
	//writeln(imagen.tipo_fichero);
End;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Procedure AlmacenarDB(var imagen:tImagen);		{ Procedure con el agregaremos la imagen a la DB, enviamos la sentencia completa de inserción }
Var datos	: PChar; 
    a		: tTablaBusqueda;			{ mediante una llamada a LlamadasDB }
    etiqueta,buscarepe,fecha 	: string;				{ INSERT INTO imagen (nombre_imagen,descripcion,tipo,id_subtematica,id_tematica,anchura,altura,tamano,etiquetas) }
    serepiteid	: boolean;
Begin 			
	serepiteid := FALSE;		{ pasandole los valores mediante VALUES (1,.....) }
	buscarepe := BusquedaIDIMG + imagen.id_desc + '"';
	BusquedaIdentificador(Pchar(buscarepe),serepiteid);
	if (not serepiteid) then 
		begin
			etiqueta := BusquedaTEM + Num2ST(imagen.idsubtematica);
			//writeln('subtematica := ',imagen.idsubtematica);
			BusquedaDB(@etiqueta[1],imagen.idtematica,False,a);
        		imagen.tematica := a[1][1];
			DameFecha(fecha);
			if (not imagen.solouna) then begin
			imagen.solouna := TRUE;
			with(imagen) do valores := INSIMG + '"' + fichero + '","' + descripcion + '","' + tipo_fichero +
'",' + Num2St(idtematica) + ',' + Num2St(idsubtematica) + ',' + Num2St(ancho_img) + ',' + Num2St(alto_img) + ',' + Num2St(tamano_img) + '," ' + etiquetas + ' ","' + id_desc + '","' + fecha + '")';			
			end
			else begin
				with(imagen) do valores := INSIMGMOD + '"' + fichero + '","' + descripcion + '","' + tipo_fichero +
'",' + Num2St(idtematica) + ',' + Num2St(idsubtematica) + ',' + Num2St(ancho_img) + ',' + Num2St(alto_img) + ',' + Num2St(tamano_img) + '," ' + etiquetas + ' ","' + id_desc + '")';				end;
			datos := PCHAR(@valores[1]);
			//writeln(datos);
			LlamadasDB(datos);
			imagen.solouna := TRUE;
		end;
End;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Procedure GuardarImagen(var imagen:tImagen);		{ Es el encargado de Guardar la imagen al completo, pasando por las 3 funciones explicadas }
Begin   						{ anteriormente, si la imagen posee un formato equivocado o el fichero no existe, no llegará }
	SubirImagen(imagen);				{ a ejecutar la funcion AlmacenaDB, dará un error e informará al usuario }
	if (imagenPix<>nil) then begin
		ObtenerInfoFichero(imagen);	
		AlmacenarDB(imagen);
	end;

End;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Procedure ModificarImagen(var imagen:tImagen);		{ Con este procedure modificaremos una imagen en la DB ( etiquetas, subtematica y/o descripcion ) }
Var datos: PChar; 					{ UPDATE imagen SET descripcion = "", id.subtematica = "", etiquetas = "", WHERE id = X }
    llamada_act,etiqueta:string;
    a:tTablaBusqueda;
Begin 	
	etiqueta := BusquedaTEM + Num2ST(imagen.idsubtematica);
	BusquedaDB(@etiqueta[1],imagen.idtematica,False,a);
	imagen.tematica := a[1][1];
	//writeln(a[0][1]);
	//writeln(a[0][2]);
	with(imagen) do llamada_act:= UPDIMG1 + descripcion + UPDIMG2 + etiquetas + UPDIMG3 + Num2St(idsubtematica) + UPDIMG4 + Num2St(idtematica) + UPDIMG5 + imagen.fichero + UPDIMG6 + Num2St(id_imagen);
	datos := PCHAR(@llamada_act[1]);
	//writeln(datos);
	LlamadasDB(datos);
End;


End.
