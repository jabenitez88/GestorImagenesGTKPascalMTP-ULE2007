Unit tratadoXML;
{$H+}
Interface

Uses sysutils,strutils,errorsInOut,GestionImagenes,miMysql,unix,tad_cola;

Const
   ESP1 = '   ';					{ Aquí asigno los espacios que necesitaré para agregar a mi fichero descriptor.xml.	}
   ESP2 = '       ';
   ESP3 = '           ';
   ESP4 = '               ';
   NumEti = 60;						{ Asigno un máximo de etiquetas a introducir por el usuario.				}
   nombreFichero = 'descriptor.xml';			{ El nombre del descriptor lo guardo en una constante.					}
   							{ Y guardo los tags que me harán falta tanto para importar comparando con lo que ya hay }
	tagXML = '<?xml version="1.0" encoding="UTF-8"?>';{ escrito, como para exportar escribiéndolas.						}
	tagImagenes = '<imágenes>';
    	tagImagen = '<imagen ';
	tagImagen2 = '<imagen ';
    		tagFichero = '<fichero ';
    		tagInformacion = '<información ';
    			tagDescripcion = '<descripción>';
         		tagDescripcionC = '</descripción>';
				tagEtiquetas = '<etiquetas>';
				tagEtiquetasNO = '<etiquetas/';
		 				tagEtiqueta = '<etiqueta>';
		 				tagEtiquetaC = '</etiqueta>';
  	 	 		tagEtiquetasC = '</etiquetas>';
				tagEtiquetasCS = '<etiquetas/>';
       			tagInformacionC = '</información>';
     		tagImagenC = '</imagen>';   
   		tagImagenesC = '</imágenes>';
	ERROR = '¡¡ ERROR. El archivo no es un fichero XML valido !!';
Type
	tDatos = array [0..60] of string;

Procedure ImportarImagenes(nombre_tar,directorio:string;var Mensaje:string);
Procedure ExportarImagenes(nombre_tar:string;var mensaje:string;t: tTablaBusqueda;conjunto: tTablaBorrado);
Procedure cogerEtiquetas(cadena:string;var eti:tDatos;var num_eti:longint;var spuntuacion:tDatos);

Implementation
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Procedure errorFichero(var fichero:text;var i:longint); { Esta función sólo se ejecuta cuando el descriptor.xml está mal hecho.		}
Begin
	i := 100;
	Writeln('El fichero importado es erróneo');
End;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Procedure cortarCadena(cadena:string;var cad:tDatos);	{ Esta función es la encargada de cortar las cadenas en el descriptor.xml	}
Var i,j,k:longint;					{ para sacar la info de las imágenes.						}
    cadaux:string;
Begin	//for i:=0 to 60 do cad[i] := '';
	i := 0; j := 1; k := 0;
	while (i <= length(cadena)) do begin
		cadaux := '';
		while((cadena[i] <> '=') and (i<=length(cadena))) do i := i + 1;
		i := i + 2;
		while((cadena[i] <> '"') and (i<=length(cadena))) do begin
					cadaux := cadaux + cadena[i];
					i := i + 1; j := j + 1 ;
					end;
		cad[k] := cadaux;
		j := 1;
		i := i + 2;
		k := k + 1;
		end;
			
End;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Procedure cortaEtiquetas(cadena:string;var eti:string); { Esta función es parecida a la de arriba, pero exclusiva para guardar en un 	}
Var i:longint;						{ string todas las estiquetas que hay en un descriptor.xml			}
Begin	
	i := 0;
	while (i <= length(cadena)) do begin
		while((cadena[i] <> '>') and (i<=length(cadena))) do i := i + 1;
		i := i + 1;
		while((cadena[i] <> '<') and (i<=length(cadena))) do begin
					eti := eti + cadena[i];
					i := i + 1; 
					end;
		if (cadena[i] <> '<') then eti := eti + ', ';
		i := i + 1;
		end;
			
End;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Procedure cogerEtiquetas(cadena:string;var eti:tDatos;var num_eti:longint;var spuntuacion:tDatos);
Var i:longint;						{ Esta función es la equivalente a la contraria, pero para exportar las imágenes.}
Begin   num_eti:=0;
	cadena := trim(cadena); // Con trim quitamos los espacios que hay en los inicios de las cadenas.
	cadena := delspace1(cadena);
	for i:= 0 to NumEti do eti[i] := '';
	i:=1;
	while (i <= length(cadena)) do begin
		while((cadena[i] <> ',') and (cadena[i] <> '.') and (cadena[i] <> ' ') and (i<=length(cadena))) do begin
					eti[num_eti]:= eti[num_eti] + cadena[i];
					i := i + 1; 
					end;
		if (cadena[i] = ',') or (cadena[i] = '.') then spuntuacion[num_eti] := cadena[i];
		i := i + 1;
		if (cadena[i] <> ' ') and (cadena[i] <> #10) and (cadena[i] <> ',') and (cadena[i] <> '.') then num_eti := num_eti + 1;
		end;
	num_eti := num_eti - 1;
End;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Procedure ExportarImagenes(nombre_tar:string;var mensaje:string;t: tTablaBusqueda;conjunto: tTablaBorrado);	{ Función principal con la que exportaremos los elementos de la base de datos.	}
Var numEtiquetas,j: longint;
    i:0..N;
    comando: string;
    cadaux : array [0..9] of string;
    etiquetas,aux : tDatos;
    descriptor:text;
    errorF : longint;
Begin   numEtiquetas := 0; comando := ''; 
	shell('mkdir imagenes');
	Assign(descriptor,nombreFichero);
	{$I-}rewrite(descriptor);{$I+}
	errorF := ioresult;
	if (errorF<>0) then begin 
				calcError(errorF);
				end
	else begin
	writeln(descriptor,tagXML);
	writeln(descriptor,tagImagenes);
	for i:= 0 to N do
	begin	
	if (conjunto[i] = TRUE) then 
		begin
		cadaux[0] := StrPas(@t[i][11][1]);
		cadaux[1] := StrPas(@t[i][1][1]);
		cadaux[2] := StrPas(@t[i][2][1]);
		cadaux[3] := StrPas(@t[i][3][1]);
		cadaux[4] := StrPas(@t[i][4][1]);
		cadaux[5] := StrPas(@t[i][5][1]);
		cadaux[6] := StrPas(@t[i][6][1]);
		cadaux[7] := StrPas(@t[i][7][1]);
		cadaux[8] := StrPas(@t[i][8][1]);
		cadaux[9] := StrPas(@t[i][9][1]);
		cogerEtiquetas(cadaux[8],etiquetas,numEtiquetas,aux);
		writeln(descriptor,ESP1+tagImagen+'identificador="'+cadaux[0]+'">');
		writeln(descriptor,ESP2+tagFichero+'nombre="'+cadaux[1]+'" tipo="'+cadaux[4]+'" tamaño="'+cadaux[5]+'"/>');
		writeln(descriptor,ESP2+tagInformacion+'anchura="'+cadaux[6]+'" altura="'+cadaux[7]+'" temática-padre="'+cadaux[3]+'" temática="'+cadaux[2]+'">');
		writeln(descriptor,ESP3+tagDescripcion);
		writeln(descriptor,ESP4+cadaux[9]);
		writeln(descriptor,ESP3+tagDescripcionC);

		if numEtiquetas > 0 then begin
				writeln(descriptor,ESP3+tagEtiquetas);
				for j:= 0 to numEtiquetas do writeln(descriptor,ESP4+tagEtiqueta+etiquetas[j]+tagEtiquetaC);
				writeln(descriptor,ESP3+tagEtiquetasC);
				end
		else writeln(descriptor,ESP3+tagEtiquetasCS);	
		writeln(descriptor,ESP2+tagInformacionC);
		writeln(descriptor,ESP1+tagImagenC);
		writeln(cadaux[1]);
		shell('cp '+cadaux[1]+' imagenes/');	
		end;
	end;
	writeln(descriptor,tagImagenesC);
	Close(descriptor);
	comando := ' imagenes/ descriptor.xml';
	if copy(nombre_tar,length(nombre_tar)-6,length(nombre_tar)) <> '.tar.gz' then nombre_tar := nombre_tar + '.tar.gz';
	writeln(nombre_tar,comando);
	shell('tar czf '+nombre_tar+comando);
	shell('rm descriptor.xml imagenes/ -rf');
	mensaje := 'La exportación se ha finalizado con exito';
	end;
End;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Procedure ImportarImagenes(nombre_tar,directorio:string;var Mensaje:string);
Var descriptor : text; 					{ Función principal con la que importarenis los elementos en la base de datos.	}
	cadena1,cadena2,id,buscarepe:string;
	t:tTablaBusqueda;
	tem,subtem,tipo,idsub,idtem:string;
	inserTem,inserSubt : string;
     datos : tDatos;
     imagen : tImagen;
	serepiteid:boolean;
     i,numimg,errorF,esp: longint;
	c: tCola;
Begin   Mensaje := '';
	shell('tar -xzf '+nombre_tar);
	serepiteid := FALSE;
	i := 0;
	numimg := 0;
	//Write(FileExists(nombreFichero));
	Assign(descriptor,nombreFichero);
	{$I-}reset(descriptor);{$I+}
	errorF := ioresult;
	if (errorF<>0) then begin 
				calcError(errorF);
				end
	else begin
	While not EoF (descriptor) and (i<>100) do begin
		While not EoLN (descriptor) and (i<>100) do begin
		//writeln(i);
		if (i = 0) then begin
				readln(descriptor,cadena1);
				if (copy(trim(cadena1), 1, length(tagXML))<> tagXML) then errorFichero(descriptor,i)
				else 	i := i + 1;
				end;
		if (i = 1) then begin
				readln(descriptor,cadena1);
				if (copy(trim(cadena1), 1, length(tagImagenes))<> tagImagenes) then errorFichero(descriptor,i)
				else 	i := i + 1;
				end;
		if (i = 2) then begin
				readln(descriptor,cadena1);				
				cadena2 := copy(trim(cadena1), 1, length(tagImagen));
	        		if (cadena2 <> tagImagen) and (cadena2 <> '</imáge')  then errorFichero(descriptor,i)
				else if (cadena2 = '</imáge') then i := 8
				else begin
					cortarCadena(cadena1, datos);
					id := datos[0];
					i := i + 1;
					numimg := numimg + 1;
					end;
				end;
		if (i = 3) then begin
				readln(descriptor,cadena1);
	        		if (copy(trim(cadena1), 1, length(tagFichero)) <> tagFichero) then errorFichero(descriptor,i)
				else 	begin
					cortarCadena(cadena1, datos);
					tipo := datos[1];
					imagen.fichero := datos[0]; imagen.tipo_fichero := PCHAR(@tipo[1]); Val(datos[2],imagen.tamano_img);
					i := i + 1;
					end;
				end;
		if (i = 4) then begin
				readln(descriptor,cadena1);
	        		if (copy(trim(cadena1), 1, length(tagInformacion)) <> tagInformacion) then errorFichero(descriptor,i)
				else 	begin
					cortarCadena(cadena1, datos);
					Val(datos[0],imagen.ancho_img); Val(datos[1],imagen.alto_img); tem := datos[2]; subtem := datos[3];
					imagen.subtematica := subtem; imagen.tematica := tem;					
					idtem := BusquedaIMG2porTEM1 + tem + '"';
					BusquedaTematicas(@idtem[1],c,true,t);
					imagen.idtematica := -1;
					val(t[0][1],imagen.idtematica);
					val(t[0][1],esp);
					inserTem := INSTEMXML + tem + '",TRUE)';
					if (imagen.idtematica < 1) then 
							begin
								llamadasDB(@inserTem[1]);
								BusquedaTematicas(@idtem[1],c,true,t);
								val(t[0][1],imagen.idtematica);
								inserTem := INSSTEMXML + '1,' + Num2St(imagen.idtematica) +',"' + tem + '")';
								llamadasDB(@inserTem[1]);
							end;
					
					inserSubt := 'UPDATE tematica SET espadre = TRUE WHERE id = ' + Num2St(imagen.idtematica);
					if (esp = 0) then llamadasDB(@inserSubt[1]);
					idsub := BusquedaIMG2porTEM1 + subtem + '"';
					imagen.idsubtematica := -1;	
					BusquedaTematicas(@idsub[1],c,true,t);
					val(t[0][1],imagen.idsubtematica);
					//writeln('SUB ANTES DE : ',imagen.idsubtematica);
					val(t[0][1],esp);
					inserSubt := INSTEMXML + subtem + '",FALSE)';
					if (imagen.idsubtematica < 1) then 
						begin
							llamadasDB(@inserSubt[1]);
							BusquedaTematicas(@idsub[1],c,true,t);
							val(t[0][1],imagen.idsubtematica);
							inserSubt := INSSTEMXML + Num2St(imagen.idtematica) + ',' + Num2St(imagen.idsubtematica) +',"' + subtem + '")';
							//writeln(insersubt);
							llamadasDB(@inserSubt[1]);
						end;
					i := i + 1;
					end;
				end;
		if (i = 5) then begin
				readln(descriptor,cadena1);
				imagen.descripcion := '';
	        		if (copy(trim(cadena1), 1, length(tagDescripcion)) <> tagDescripcion) then errorFichero(descriptor,i)
				else 	begin
					cadena1 := trim(cadena1);
					while(cadena1 <> tagDescripcionC) do begin
						readln(descriptor,cadena1);
						cadena1 := trim(cadena1);
						if (cadena1 <> tagDescripcionC) then 
							begin
							if (imagen.descripcion <> '') then imagen.descripcion := imagen.descripcion + #10;
							imagen.descripcion := imagen.descripcion + cadena1;
							end;
						end;
					i := i + 1;
					end;
				end;
		if (i = 6) then begin
				readln(descriptor,cadena1);
				imagen.etiquetas := '';
				cadena2 := copy(trim(cadena1), 1, length(tagEtiquetas));
	        		if (cadena2 <> tagEtiquetas) and (cadena2 <> tagEtiquetasNO) then errorFichero(descriptor,i)
				else 	begin
					cadena1 := trim(cadena1);
					while((cadena1 <> tagEtiquetasC) and (cadena1 <> tagEtiquetasCS)) do 
						begin
						readln(descriptor,cadena1);
						cadena1 := trim(cadena1);
						if ((cadena1 <> tagEtiquetasC) and (cadena1 <> tagEtiquetasCS)) then cortaEtiquetas(cadena1,imagen.etiquetas);
						end;
					imagen.etiquetas := copy(imagen.etiquetas,1,length(imagen.etiquetas)-2);
					readln(descriptor,cadena1);
					buscarepe := BusquedaIDIMG + id + '"';
					BusquedaIdentificador(Pchar(buscarepe),serepiteid);
					imagen.id_desc := id;
					//writeln(imagen.idsubtematica);
					if (not serepiteid) and (FileExists('imagenes/'+imagen.fichero))  then AlmacenarDB(imagen);
					i := 2;
					end;
				end;
		readln(descriptor,cadena1);
		end;
	end;
	if (i = 100) then  begin 
				Mensaje := 'El fichero descriptor.xml contiene errores';
				Close(descriptor);
			end
	else begin 	
		shell('mv imagenes/*.* '+directorio);
		Mensaje := 'La importación de imágenes se ha realizado con éxito :D';
		Close(descriptor);
		end;
	shell('rm descriptor.xml imagenes/ -rf');
	end;// End del else principal
End;

End.
