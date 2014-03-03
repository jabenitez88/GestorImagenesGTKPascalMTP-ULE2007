Program JabaGI;
{$H+}{$mode objfpc}
Uses glib2, gdk2, gtk2, sysutils,baseunix,intGes,miMysql,GestionImagenes,gdk2pixbuf,tratadoXML,tad_cola,unix;

Const
	subtDef : PCHAR = 'Elija una temática';	{ Cadena que veremos en un desplegable donde nos mostrará las subtemáticas disponibles.	}
	borimg 	= ' ID = ';				{ Campo que usaremos para borrar imágenes. 						}
	noElegida : PCHAR = 'NO';			{ Esto lo usaremos para saber si está, o no, seleccionada, una imagen en el cuadro de  	}
	siElegida : PCHAR = 'SI';			{ búsqueda, sólo sirve para eso. 							}
	IDIMG = 12;					{ En nuestra tabla de tipo tTablaBusqueda, la ID es el campo 11, por eso vale 12. 	}
	UNICOELEM = 0;					{ Esto nos sirve para, al modificar una imagen, coger sólo la info de un elemento, el  	
							  primero de todos concretamente, por eso es un 0. 					}
  	ancho = 900;					{ Anchura de la ventana principal del programa.						}
  	alto = 600;					{ Altura de la ventana principal del programa.						}
	thumb_ancho = 50;
	thumb_alto  = 50;
	bTem : PCHAR = 'imagen.subtematica = ';		{ Si su criterio de búsqueda es temática, se utilizará esta cadena.			}
	bEti : PCHAR = 'etiquetas RLIKE "';		{ Si es por etiquetas, se utilizará esta.						}

	Creditos1 : PCHAR = 'Autor : Jose Alberto Benítez Andrades'#10'DNI   : 71454586A'#10'E-Mail: infjab02@estudiantes.unileon.es'#10'Metodología y Tecnología de la Programación'#10'Gestor de Imágenes 3.1';
Var
 	{ Widgets }

  	window			: PGtkWidget;		{ Esto será la ventana principal donde tendremos el cuadro de búsqueda con los menús.	}
  	vbox  			: PGtkWidget;	 	{ Caja vertical, gracias a la cual, podremos hacer una buena separación el interfaz. 	}
  	vbox1  			: PGtkWidget;	 	{ Caja vertical, gracias a la cual, podremos hacer una buena separación el interfaz. 	}
  	hboxBot  		: PGtkWidget;	 	{ Caja vertical, donde almacenaremos los botones de búsqueda.			 	}
	hbox  			: PGtkWidget;		{ Caja horizontal que necesitaremos para hacer bien la interfaz, junto con la vbox.	}
	scroll			: PGtkWidget;		{ Barra de scroll que utilizaremos en la tabla de búsqueda. 				}	
	thelist			: PGtkWidget;		{ Widget que será un clist en el que mostrará el resultado de la búsqueda, las imágenes 
							  con toda su info y las miniaturas .							}
	button_insertar		: PGtkWidget;		{ Botón para INSERTAR imágenes en la db.						}
	button_modificar	: PGtkWidget;		{ Botón para activar el MODIFICAR imagen.						}
	button_borrar   	: PGtkWidget;		{ Botón con el que borraremos la selección de imágenes que hayamos hecho.		}
	button_importar   	: PGtkWidget;		{ Botón para importar el fichero .tar.gz que queramos.					}
	button_exportar   	: PGtkWidget;		{ Botón para exportar el conjunto de imágenes que queramos.				}
	button_buscar		: PGtkWidget;		{ Botón para buscar las imágenes por el criterio que deseemos.				}
	button_conjunto		: PGtkWidget;		{ Botón para crear conjuntos de imágenes, de última hora.				}
	rbutton_tem		: PGtkWidget;		{ Buscar por temáticas.									}
	rbutton_eti		: PGtkWidget;		{ Buscar por etiquetas.									}
	texto_buscador 		: PGtkWidget;		{ Cuadro de texto en el que se ejecuta la búsqueda.					}
	frame_buscador		: PGtkWidget;		{ Frame en el que insertaremos cuadro de búsqueda.					}
	frame_listado		: PGtkWidget;		{ Frame en el que insertaremos la lista CLIST.						}
	menu_bar		: PGtkWidget;		{ Barra superior de menú, ejecuta los mismos comandos que los botones de abajo.		}
	pixmap 			: PGtkWidget;
	tabla			: tTablaBusqueda;	{ Tabla en la que insertaremos toda la información de las imágenes que hemos búscado 	}
	tematicas		: tTablaBusqueda;	{ para más tarde, mostrarlas.								}
	borrado			: tTablaBorrado;	{ Tabla en la que almacenaremos las imágenes que seleccionamos para después borrar o 
							  exportar 										}
	seleccion		: longint;		{ Imagen elegida en el modificar_imagen, sirve para cambiar a siguiente imagen, o 	}
	primera			: longint;		{ anterior., primera almacena la fila de la primera imagen a modificar y 		}
	ultima			: longint;		{ ultima la ultima.									}
        numTematicas		: longint;

	ancho_buscador		: longint;		{ El ancho del buscador.								}
	cadenaAuxmod		: string;		{ En esta variable almacenaremos la última imagen seleccionada.				}
	criterio		: string;		{ Almacenará el criterio de búsqueda elegido por el usuario.				}
	DirImagenes		: string;		{ Almacenará el directorio donde se encuentran las imágenes.				}
        idrepetido,temrepe	: boolean;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Procedure asignar_criterio( data: gpointer ); cdecl;
Begin
	criterio := StrPas(data);
End;
Procedure buscar_imagen( data: pGtkCList ); cdecl;
Var
  indx 		: 0..N;					{ Índice de la tabla de búsqueda.							}
  alfa,num_eti 	: longint;			       
  tema,espadre 	: longint;			        { Tema se usa para saber la id de la temática, y espadre para saber si tiene hijos o no.}
  elemtotals 	: longint;			        { elemtotals se usa para ejecutar busquedadb, es el contador en nuestra tabla de datos.	}
  texto		: string;				{ Alfa guarda el color_alpha del pixmap. Texto contiene la búsqueda que queremos hacer.	}
  aux,busqueda	: string;				{ Alfa guarda el color_alpha del pixmap. Texto contiene la búsqueda que queremos hacer.	}
  tabaux,tabTem	: tTablaBusqueda;			{ Tabaux es la tabla en la que almacenaremos la información de las imágenes buscadas.	}
  maskB 	: PGdkBitMap;				{ Esta nos hace falta para mostrar el pixmap en nuestro clist.				}
  pixmapB	: PGdkPixmap;				{ Lo mismo que la de arriba, me hace falta para mostrar las miniaturas en la CLIST.	}
  pixbufim,thumbnail: PGdkPixbuf;			{ Pixbuf de la imagen, y Thumbnail es la miniatura (imagen ya escalada).		}
  error		: PGError;
  c 		: tCola;
  eti,puntuacion: tDatos;
Begin
  error := nil; alfa := 0; maskB:=nil; pixmapB := nil; busqueda := '';
  elemtotals := 0; num_eti := 0;
  for indx:=0 to N do borrado[indx] := FALSE;
  gtk_clist_clear(data);
  texto := StrPas(gtk_entry_get_text(GTK_ENTRY(texto_buscador)));
  if (criterio=(StrPas(bEti))) then 
			Begin
			if (texto <> '') then 
					Begin
					cogerEtiquetas(texto,eti,num_eti,puntuacion);
					for indx := 0 to num_eti-1 do
							Begin
							 busqueda :=  busqueda + criterio + eti[indx] + ' " or ' + criterio + eti[indx];
							if (puntuacion[indx] = ',') then busqueda := busqueda + '," AND '
							else busqueda := busqueda + '," OR ';
							End;
					busqueda := BusquedaIMG2a + BusquedaIMG2b + busqueda + criterio + eti[num_eti] + '" or ' + criterio + eti[num_eti] + '," ORDER BY imagen.id';
					End
			else busqueda := BusquedaIMG2a + BusquedaIMG2b + criterio + texto +  '  " ORDER BY imagen.id';
			//writeln(busqueda);
			BusquedaDB(@busqueda[1],elemtotals,TRUE,tabaux);
			End
  else begin				{ Para sacar todas las imágenes que contienen una temática, ya sea por ser ella misma, hija de ella, nieta...  }
	elemtotals := 0;		{ Lo que hacemos es, buscar si en la tabla, espadre es TRUE, si lo es, lo encolamos y metemos a todos sus hijos}
	ColaVacia(c);			{ en la cola, y a la vez, mostramos todas las imágenes en las que él, es subtemática, y así con todos sus hijos}
	busqueda := BusquedaIMG2porTEM1 + texto +'"'; { Así funciona este procedimiento. 								}
	espadre := 0; tema := 0;
	BusquedaTematicas(@busqueda[1],C,false,tabTem);

	Val(tabTem[0,1],tema);
	Val(tabTem[0,2],espadre);
	
	if espadre = 1 then Poner(c,tema)
	else busqueda := BusquedaIMG2a + BusquedaIMG2b  + criterio + Num2St(tema);

	While not EsVacia(c) do
		begin	Quitar(c,tema);		 
			aux := BusquedaIMG2porTEM2 +  Num2St(tema);
			busqueda := BusquedaIMG2a + BusquedaIMG2b  + criterio + Num2St(tema) + ' ORDER BY imagen.id';
			BusquedaDB(@busqueda[1],elemtotals,true,tabaux);
   			BusquedaTematicas(@aux[1],C,true,tabTem);
		end;
  	end;
  tabla := tabaux;
  indx := 0;
  alfa := 0;
  gtk_clist_set_row_height(gtk_clist(thelist),thumb_alto);
  // Con esta función insertamos la info de la tabla de búsqueda en la CLIST.
  while (tabla[indx][1] <> '') do begin
        gtk_clist_appEnd(data, @tabla[indx]);
	pixbufim := gdk_pixbuf_new_from_file(@tabla[indx][1][1],@error);
	if (pixbufim=nil) then begin indx := indx + 1;
					continue;
				end;
	thumbnail := gdk_pixbuf_scale_simple(pixbufim,thumb_ancho,thumb_alto,GDK_INTERP_BILINEAR);
	gdk_pixbuf_render_pixmap_and_mask(thumbnail,pixmapB,maskB,alfa);
	gtk_clist_set_pixmap(Gtk_CList(thelist),indx,9,pixmapB,maskB);
	g_object_unref(G_OBJECT(pixbufim));
	g_object_unref(G_OBJECT(thumbnail));
	g_object_unref(G_OBJECT(pixmapB));
        indx:= indx+1;
      end;
	
End;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Procedure VentanaInformacion(w : pGtkWidget ; fs : pGtkFileSelection); cdecl;
Var  mensaje,nombrefichero 	: string; 	     	{ Mensaje es el error a mostrar en la ventana de fallo.					}
     dialogo,window3	   	: PGtkWidget;		{ Widgets para necesarios para crear la ventana.					}		
     hayselec			: boolean;		{ Comprueba si han hecho una selección de imágenes para exportar, o no.			}
     i 				: longint;
Begin   mensaje :=''; nombrefichero:='';  hayselec := FALSE;
	//writeln(imagen.existefich,imagen.malformato,imagen.idsubtematica);
	if not bandera_importar then begin
	bandera_importar := TRUE;
	nombrefichero := gtk_file_selection_get_filename(GTK_FILE_SELECTION(fs));
	ImportarImagenes(nombrefichero,DirImagenes,mensaje);
	end
        else if not imagen.existefich then begin 
		mensaje := 'El fichero introducido no existe';
		end
	else if imagen.malformato then
		begin
		mensaje := 'La imagen introducida no posee un formato correcto';
		end
	else if (not idrepetido) and (not temrepe) then begin
		nombrefichero := gtk_file_selection_get_filename(GTK_FILE_SELECTION(fs));
		bandera_exportar := TRUE;
		for i:=0 to N do if (borrado[i] = TRUE) then hayselec := TRUE;
		if hayselec then ExportarImagenes(nombrefichero,mensaje,tabla,borrado)
		else mensaje := 'No ha seleccionado ninguna imagen.';
		end
	else if idrepetido then begin
		mensaje := 'La id introducida ya está en la base de datos';
		end
	else 	begin
		mensaje := 'Ya existe la imagen seleccionada con la temática elegida';
		idrepetido:=true;
		end;
	// Creo el dialogo
 	window3 := gtk_window_new(GTK_WINDOW_TOPLEVEL);
   	gtk_window_set_title(GTK_WINDOW(window3), '');
   	gtk_signal_connect(GTK_OBJECT(window3), 'destroy', GTK_SIGNAL_FUNC(@gtk_widget_destroy), NIL);
   	gtk_widget_set_usize(window3,10,10);
	if (not imagen.existefich) or (imagen.malformato) or (idrepetido) then dialogo:=gtk_message_dialog_new(GTK_WINDOW(window3),GTK_DIALOG_MODAL or GTK_DIALOG_DESTROY_WITH_PARENT,GTK_MESSAGE_ERROR,GTK_BUTTONS_OK,pgchar(mensaje))
	else dialogo:=gtk_message_dialog_new(GTK_WINDOW(window3),GTK_DIALOG_MODAL or GTK_DIALOG_DESTROY_WITH_PARENT,GTK_MESSAGE_INFO,GTK_BUTTONS_OK,pgchar(mensaje));
	gtk_dialog_run(GTK_DIALOG(dialogo));
	gtk_widget_destroy(dialogo);
	gtk_widget_destroy(window3);
	
	
End;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Procedure Creditos(w : pGtkWidget); cdecl;
Var  
     dialogo		   	: PGtkWidget;		{ Widgets para necesarios para crear la ventana.					}
     m1				: PGtkWidget;		{ Muestra el mensaje de error.								}
     nombreventana 		: PCHAR;			
Begin  
	nombreventana := 'Créditos';
	// Creo el dialogo
        dialogo := gtk_window_new(GTK_WINDOW_TOPLEVEL);
        gtk_widget_set_usize(dialogo,300,150);  
        gtk_window_set_title(gtk_window(dialogo),nombreventana);
        gtk_window_set_policy (GTK_WINDOW (dialogo), 0,0,0);
        gtk_window_set_position(GTK_WINDOW(dialogo),GTK_WIN_POS_CENTER);  
 	gtk_signal_connect(pGtkObject(dialogo),'destroy', tGtkSignalFunc(@destroy_wid), NIL);

        m1   := gtk_label_new(creditos1);  
        gtk_container_add(pGTKContainer(dialogo),m1);
        gtk_widget_show_all(dialogo);
	
	
End;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Procedure visualizar_imagen(tamimg:boolean;nombreimg:string;wid:pGtkWidget);
Var ventana,fixed,pixmap2	: PGtkWidget;		{ Widgets que necesito.. para mostrar imagen.						}
    ancho_img,alto_img	   	 : longint;		{ Ancho y alto de la imagen.								}
    ancho_ven,alto_ven	   	 : longint;		{ Ancho y alto de la imagen.								}
    error:PGerror;					{ Error, por si no puede crear el pixbuf.						}
    gdk_pixmap			 : PGdkPixmap;
    mask	 		 : PGdkBitMap;
    imagen_pixbuf,imgMod	 : PGdkPixbuf;
Begin	
	error := nil; imagen_pixbuf := nil; gdk_pixmap := nil; mask := nil; imgMod := nil;
	// Renderizo la imagen y calculo el ancho y el alto.
	imagen_pixbuf := gdk_pixbuf_new_from_file(@nombreimg[1],@error);
	if (imagen_pixbuf <> nil) then 
	begin
	if tamimg then begin
		imgMod := gdk_pixbuf_scale_simple(imagen_pixbuf,220,200,GDK_INTERP_BILINEAR);
        	gdk_pixbuf_render_pixmap_and_mask(imgMod,gdk_pixmap,mask,0);
		pixmap := gtk_pixmap_new(gdk_pixmap,mask);
		end
	else gdk_pixbuf_render_pixmap_and_mask(imagen_pixbuf,gdk_pixmap,mask,0);
	pixmap2 := gtk_pixmap_new(gdk_pixmap,mask);
	ancho_img := gdk_pixbuf_get_width(imagen_pixbuf);
	alto_img := gdk_pixbuf_get_height(imagen_pixbuf);
	// Creo la ventana donde mostraré la imagen posteriormente...
	ancho_ven := ancho_img;
	alto_ven := alto_img;
	if not tamimg then
	Begin
       		wid := gtk_window_new(GTK_WINDOW_TOPLEVEL);
		if (((ancho_img < 800) and (alto_img < 600)) and ((ancho_img > 50) and (alto_img > 50))) then gtk_widget_set_usize(wid,ancho_img,alto_img)
		else gtk_widget_set_usize(wid,800,600);
        	gtk_window_set_title(gtk_window(wid),@nombreimg[1]);
        	//gtk_window_set_policy (GTK_WINDOW (wid), 0,0,0);
        	gtk_window_set_position(GTK_WINDOW(wid),GTK_WIN_POS_CENTER);
		// Creo una ventana con un scroll, para poder moverme sobre ella si la imagen es muy grande.
		ventana := gtk_scrolled_window_new(nil,nil);
		gtk_widget_set_usize(ventana,ancho_ven,alto_ven);
		gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(ventana),700,700);
		fixed := gtk_fixed_new();
		gtk_widget_set_usize(fixed,ancho_img,alto_img);
		gtk_fixed_put(GTK_FIXED(fixed),pixmap2,0,0);
		gtk_scrolled_window_add_with_viewport(GTK_SCROLLED_WINDOW(ventana),fixed);
		gtk_container_add(GTK_CONTAINER(wid),ventana);
	End
	else  begin
		ancho_ven := 200;
		alto_ven := 210;
		fixed := gtk_fixed_new();
		gtk_widget_set_usize(fixed,ancho_ven,alto_ven);
		gtk_fixed_put(GTK_FIXED(fixed),pixmap,0,0);
		gtk_container_add(GTK_CONTAINER(wid),fixed);
		g_object_unref(G_OBJECT(imgMod));
	end;
        	gtk_widget_show_all(wid);
		g_object_unref(G_OBJECT(gdk_pixmap));
		g_object_unref(G_OBJECT(imagen_pixbuf));
	end; // END DEL IF IMAGEN PIXBUF <> NIL
End;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Procedure crear_conjunto;						{ Procedure con el que modificaremos las imágenes.			}
Var
        { Widgets utilizados }
        dialogo,hbox1,main_vbox		: PGtkWidget;
	button_aceptar, button_cancelar		: PGtkWidget;		{ Botones que uso.							}
	button_agrandar,button_sigimg		: PGtkWidget;
	button_antimg				: PGtkWidget;
	tSub					: tTablaBusqueda; 	{ Tablas de búsqueda que usaremos para sacar la subtemática y la info	}
	numSub					: longint;		{ de las imágenes. numSub:id de la subtemática.				}
	ultimaS					: boolean;		{ Otra bandera para entrar en modificar 				}
	j					: longint;
	Procedure rellenar_valores(imgelegida:longint);
	Var 
	desc		 : string;
	i 		 : longint;
	error		 : PGerror;
    	img,img2	 : PGdkPixbuf;		{ Pixbuf de la imagen.	}
	gdk_pixmap	 : PGdkPixmap;
	mask	 	 : PGdkBitMap;
	glist 		 : pGList;
	Begin	 error:=nil;
		glist := nil;
		glist := g_list_append(glist,@tabla[imgelegida][2][1]);
		for i:=0 to  numTematicas do glist := g_list_append(glist,@tematicas[i][1][1]);
		gtk_entry_set_editable(PGTKENTRY(GTK_COMBO(subt_img)^.entry),TRUE);
		gtk_combo_set_popdown_strings(GTK_COMBO(subt_img),glist);
		gtk_combo_disable_activate(GTK_COMBO(subt_img));
		{ Inicializamos la lista del desplegable que contiene la subtemática.	}
		gtk_entry_set_text(GTK_ENTRY(id_img),@tabla[imgelegida][11][1]);
		gtk_entry_set_text(GTK_ENTRY(nombre_img),@tabla[imgelegida][1][1]);
		gtk_entry_set_text(GTK_ENTRY(tem_img),@tabla[imgelegida][3][1]);
		gtk_entry_set_text(GTK_ENTRY(tipo_img),@tabla[imgelegida][4][1]);
		gtk_entry_set_text(GTK_ENTRY(tam_img),@tabla[imgelegida][5][1]);
		gtk_entry_set_text(GTK_ENTRY(anc_img),@tabla[imgelegida][6][1]);
		gtk_entry_set_text(GTK_ENTRY(alt_img),@tabla[imgelegida][7][1]);
		gtk_entry_set_text(GTK_ENTRY(eti_img),@tabla[imgelegida][8][2]);
		gtk_editable_delete_text(GTK_EDITABLE(desc_img),0,-1);
		desc := StrPas(@tabla[imgelegida][9][1]);
		gtk_text_insert(GTK_TEXT(desc_img), nil, NIL, NIL,@tabla[imgelegida][9][1], length(desc));
		//gtk_entry_set_text(GTK_ENTRY(desc_img),@t[imgelegida][9][1]);
		cadenaAuxmod := tabla[imgelegida][1];
        	gtk_entry_set_editable(PGTKENTRY(id_img),TRUE );
        	gtk_entry_set_editable(PGTKENTRY(nombre_img),FALSE );
        	gtk_entry_set_editable(PGTKENTRY(tem_img),FALSE );
        	gtk_entry_set_editable(PGTKENTRY(tipo_img),FALSE );
        	gtk_entry_set_editable(PGTKENTRY(tam_img),FALSE );
        	gtk_entry_set_editable(PGTKENTRY(anc_img),FALSE );
        	gtk_entry_set_editable(PGTKENTRY(alt_img),FALSE );
       		gtk_entry_set_editable(PGTKENTRY(eti_img),TRUE );
        	gtk_text_set_editable(PGTKTEXT(desc_img),TRUE );
		img := gdk_pixbuf_new_from_file(@cadenaAuxmod[1],@error);
		if (img<>nil) then begin
		img2 := gdk_pixbuf_scale_simple(img,220,200,GDK_INTERP_BILINEAR);
		gdk_pixbuf_render_pixmap_and_mask(img2,gdk_pixmap,mask,0);
		{imagen_pixbuf := gdk_pixbuf_copy(img);
		imgMod := gdk_pixbuf_scale_simple(imagen_pixbuf,250,200,GDK_INTERP_BILINEAR);
        	gdk_pixbuf_render_pixmap_and_mask(imgMod,gdk_pixmap,mask,0);}
		if (not bandera_img) then gtk_pixmap_set(PGTKPIXMAP(pixmap),gdk_pixmap,mask);
		bandera_img := FALSE; 
		g_object_unref(G_OBJECT(img));
		g_object_unref(G_OBJECT(img2));
		g_object_unref(G_OBJECT(gdk_pixmap));
		end; // if img <> nil
	End;
	Procedure aceptar_imagen;
	Var     wid			: PGtkWidget;
		fs			: pGtkFileSelection;
		subt,buscarepe,insTema	: string;
		t 			: tTablaBusqueda;
		Begin   idrepetido := FALSE; temrepe := FALSE;
			imagen.fichero := StrPas(gtk_entry_get_text(GTK_ENTRY(nombre_img)));
			imagen.subtematica := StrPas(gtk_entry_get_text(GTK_ENTRY(GTK_COMBO(subt_img)^.entry)));
			subt := BusquedaIDSub + imagen.subtematica + '"';
			imagen.idsubtematica := -1;
			BusquedaDB(@subt[1],imagen.idsubtematica,false,t);
			buscarepe := 'SELECT * FROM imagen WHERE imagen.nombre_imagen = "' + imagen.fichero + '" AND imagen.subtematica = ' + Num2St(imagen.idsubtematica);
			//writeln(buscarepe);
			BusquedaIdentificador(Pchar(buscarepe),temrepe);
			bandera_img := true; wid := nil; fs := nil;
			imagen.id_desc := StrPas(gtk_entry_get_text(GTK_ENTRY(id_img)));
			imagen.existefich := FileExists(imagen.fichero);
       			imagen.etiquetas := ' ' + StrPas(gtk_entry_get_text(GTK_ENTRY(eti_img)));
			imagen.descripcion := StrPas(gtk_editable_get_chars(GTK_EDITABLE(desc_img),0,gtk_text_get_length(GTK_TEXT(desc_img))));
			buscarepe := BusquedaIDIMG + imagen.id_desc + '"';
			BusquedaIdentificador(Pchar(buscarepe),idrepetido);
			if (imagen.idsubtematica = -1) then 
					Begin
					insTema := INSTEMXML + imagen.subtematica + '",FALSE)';
					llamadasDB(@insTema[1]);
					BusquedaDB(@subt[1],imagen.idsubtematica,false,t);
					insTema := INSSTEMXML + '1,' + Num2St(imagen.idsubtematica) + ',"' + imagen.subtematica + '")';
					llamadasDB(@insTema[1]);
					End;
			if (not idrepetido) and (not temrepe) then GuardarImagen(imagen);
			
			if (imagen.malformato) or (not imagen.existefich) or (imagen.id_desc = '') or (idrepetido) or (temrepe) then VentanaInformacion(wid,fs);
			bandera_img := FALSE;
		End;
	Function create_bbox_mod( objeto : longint; horizontal : boolean ; title : pchar ; spacing : gint ;
             child_w : gint ; child_h : gint ; layout : gint ) : pGtkWidget;
	{ Create a Button Box with the specified parameters }
	Var
           frame, bbox,tablaDesc  : pGtkWidget;
	   vboxA,hboxA,DescScrollbar  : pGtkWidget;
	   glist : pGList;
	   i	: longint;
	Begin
           frame := gtk_frame_new(pchar(title));
           if (horizontal = true) THEN
                         bbox := gtk_hbutton_box_new()
           else
                         bbox := gtk_vbutton_box_new();

	   if (objeto = 0) then
		Begin
			gtk_container_set_border_width(GTK_CONTAINER(bbox), 5);
          	        gtk_container_add(GTK_CONTAINER(frame), bbox);
           		{ Set the appearance of the Button Box }
           		gtk_button_box_set_layout(GTK_BUTTON_BOX(bbox), layout);
           		gtk_button_box_set_spacing(GTK_BUTTON_BOX(bbox), spacing);
           		gtk_button_box_set_child_size(GTK_BUTTON_BOX(bbox), child_w, child_h);

			labelm0   := gtk_label_new('Id:');
			labelm1   := gtk_label_new('Nombre:');
			labelm2   := gtk_label_new('Temática:');
			labelm3   := gtk_label_new('Tem-Padre:');
			labelm4   := gtk_label_new('Tipo:');
			labelm5   := gtk_label_new('Tamanio:');
			labelm6   := gtk_label_new('Anchura:');
			labelm7   := gtk_label_new('Altura:');
			labelm8   := gtk_label_new('Etiquetas:');
			labelm9   := gtk_label_new('Descripcion:');
			gtk_container_add(GTK_CONTAINER(bbox), labelm0);
			gtk_container_add(GTK_CONTAINER(bbox), labelm1);
			gtk_container_add(GTK_CONTAINER(bbox), labelm2);
			gtk_container_add(GTK_CONTAINER(bbox), labelm3);
			gtk_container_add(GTK_CONTAINER(bbox), labelm4);
			gtk_container_add(GTK_CONTAINER(bbox), labelm5);
			gtk_container_add(GTK_CONTAINER(bbox), labelm6);
			gtk_container_add(GTK_CONTAINER(bbox), labelm7);
			gtk_container_add(GTK_CONTAINER(bbox), labelm8);
			gtk_container_add(GTK_CONTAINER(bbox), labelm9);

           		create_bbox_mod := frame;
		End
	   else if(objeto = 1) then
		Begin	
			gtk_container_set_border_width(GTK_CONTAINER(bbox), 5);
          	     	gtk_container_add(GTK_CONTAINER(frame), bbox);
           		
           		gtk_button_box_set_layout(GTK_BUTTON_BOX(bbox), layout);
           		gtk_button_box_set_spacing(GTK_BUTTON_BOX(bbox), spacing);
           		gtk_button_box_set_child_size(GTK_BUTTON_BOX(bbox), child_w, child_h);
			
        		id_img   := gtk_entry_new_with_max_length(15);
        		nombre_img   := gtk_entry_new_with_max_length(100);		
			subt_img := gtk_combo_new;					
			tem_img  := gtk_entry_new_with_max_length(100);		
			tipo_img := gtk_entry_new_with_max_length(100);
			tam_img  := gtk_entry_new_with_max_length(10);
        		anc_img  := gtk_entry_new_with_max_length(10); 
        		alt_img  := gtk_entry_new_with_max_length(10);
        		eti_img  := gtk_entry_new_with_max_length(500);
        		desc_img := gtk_text_new(nil,nil);

	   		DescScrollbar := gtk_vscrollbar_new(GTK_TEXT(desc_img)^.vadj);
	  	 	tablaDesc := gtk_table_new(8, 1, FALSE);

			numSub := 90;
			BusquedaDB(BusquedaNOMSub,numSub,false,tSub);	
			tematicas := tSub; 		
			glist := nil;
			for i:=0 to numSub do glist := g_list_append(glist,@tSub[i][1][1]);
		 	numTematicas := numSub;
			gtk_entry_set_editable(PGTKENTRY(GTK_COMBO(subt_img)^.entry),FALSE);
			gtk_combo_set_popdown_strings(GTK_COMBO(subt_img),glist);
			gtk_combo_disable_activate(GTK_COMBO(subt_img));

			gtk_table_set_row_spacings(GTK_TABLE(tablaDesc), spacing);
	   		gtk_table_attach_defaults(GTK_TABLE(tablaDesc), id_img, 0, 1, 0, 1);
	   		gtk_table_attach_defaults(GTK_TABLE(tablaDesc), nombre_img, 0, 1, 1, 2);
	   		gtk_table_attach_defaults(GTK_TABLE(tablaDesc), subt_img, 0, 1, 2, 3);
	   		gtk_table_attach_defaults(GTK_TABLE(tablaDesc), tem_img, 0, 1, 3, 4);
	   		gtk_table_attach_defaults(GTK_TABLE(tablaDesc), tipo_img, 0, 1, 4, 5);
	   		gtk_table_attach_defaults(GTK_TABLE(tablaDesc), tam_img, 0, 1, 5, 6);
	   		gtk_table_attach_defaults(GTK_TABLE(tablaDesc), anc_img, 0, 1, 7, 8);
	   		gtk_table_attach_defaults(GTK_TABLE(tablaDesc), alt_img, 0, 1, 8, 9);
	   		gtk_table_attach_defaults(GTK_TABLE(tablaDesc), eti_img, 0, 1, 9, 10);
			gtk_table_attach(GTK_TABLE(tablaDesc), desc_img, 0, 1, 10, 11,GTK_FILL,GTK_FILL, 0, 0);
	   		gtk_table_attach(GTK_TABLE(tablaDesc), DescScrollbar, 1, 2, 10, 11, GTK_SHRINK,GTK_FILL, 0, 0);
			gtk_container_add(GTK_CONTAINER(bbox), tablaDesc);
			rellenar_valores(primera);
           		create_bbox_mod := frame
		End
	   else if (objeto = 2) then 
	 	Begin
           		gtk_container_set_border_width(GTK_CONTAINER(bbox), 5);
          	        gtk_container_add(GTK_CONTAINER(frame), bbox);
           		{ Set the appearance of the Button Box }
           		gtk_button_box_set_layout(GTK_BUTTON_BOX(bbox), layout);
           		gtk_button_box_set_spacing(GTK_BUTTON_BOX(bbox), spacing);
           		gtk_button_box_set_child_size(GTK_BUTTON_BOX(bbox), child_w, child_h);
           		button_aceptar := gtk_button_new_with_label('Crear conjunto');
           		gtk_container_add(GTK_CONTAINER(bbox), button_aceptar);
           		button_cancelar := gtk_button_new_with_label('Salir');
           		gtk_container_add(GTK_CONTAINER(bbox), button_cancelar);
           		create_bbox_mod := frame;
		End
	 else Begin
		        gtk_container_set_border_width(GTK_CONTAINER(bbox), 5);
          	        gtk_container_add(GTK_CONTAINER(frame), bbox);
           		{ Set the appearance of the Button Box }
           		gtk_button_box_set_layout(GTK_BUTTON_BOX(bbox), layout);
           		gtk_button_box_set_spacing(GTK_BUTTON_BOX(bbox), spacing);
           		gtk_button_box_set_child_size(GTK_BUTTON_BOX(bbox), child_w, child_h);
			vboxA := gtk_vbox_new(false,0);
			hboxA := gtk_hbox_new(false,0);
			visualizar_imagen(true,tabla[primera][1],vboxA);
  			button_agrandar := gtk_button_new_with_label('Agrandar Imagen');
			button_sigimg := gtk_button_new_with_label('Siguiente Imagen');
			button_antimg := gtk_button_new_with_label('Anterior Imagen');
           		gtk_container_add(GTK_CONTAINER(vboxA), button_agrandar);
			gtk_container_add(GTK_CONTAINER(hboxA), button_antimg);
			gtk_container_add(GTK_CONTAINER(hboxA), button_sigimg);
			gtk_container_add(GTK_CONTAINER(vboxA), hboxA);
			gtk_container_add(GTK_CONTAINER(bbox),vboxA);
           		create_bbox_mod := frame;
		End;
	End;   
	Procedure agrandar_imagen;
	Var w : PGtkWidget;
	Begin	w:=nil;
		visualizar_imagen(false,cadenaAuxmod,w);
	End;
	Procedure siguiente_imagen; 
	Begin	
		if (seleccion <> ultima) then Begin
			seleccion := seleccion + 1;
			while(seleccion <= N) AND (borrado[seleccion] = FALSE) do begin seleccion := seleccion + 1; writeln(seleccion); end;
			rellenar_valores(seleccion);
		End;
	End;
	Procedure anterior_imagen;
	Begin	
		if (seleccion <> primera) then Begin
				seleccion := seleccion - 1;
				while(seleccion >= 0) AND (borrado[seleccion] = FALSE) do seleccion := seleccion - 1;
				rellenar_valores(seleccion);
		End;
	End;
Begin   
	ultimaS := False;
	for j:=0 to N do if borrado[j] then ultimaS := True;
        if bandera_img and ultimaS then begin		{ Si la bandera está true, podemos crear la ventana, con lo que entramos.}
        //bandera_img := FALSE;						{ ponemos la bandera en falso, para que no se puedan modificar más.	}
	seleccion := 0;	
	while(seleccion <= N) AND (borrado[seleccion] = FALSE) do seleccion := seleccion + 1;
	primera := seleccion;
	seleccion := N;
	while(seleccion >= 0) AND (borrado[seleccion] = FALSE) do seleccion := seleccion - 1;
	ultima := seleccion;
	seleccion := primera;
	//writeln('PRIMERA ',primera);
	//writeln('ULTIMA ',ultima);
        dialogo := gtk_window_new(GTK_WINDOW_TOPLEVEL);
        gtk_widget_set_usize(dialogo,650,650);   
        gtk_window_set_title(gtk_window(dialogo),'Crear Conjunto');
        gtk_window_set_policy (GTK_WINDOW (dialogo), 0,0,0);
        gtk_window_set_position(GTK_WINDOW(dialogo),GTK_WIN_POS_CENTER);  { Centramos la ventana }
 	gtk_signal_connect(pGtkObject(dialogo),'destroy', tGtkSignalFunc(@destroy_wid), NIL);
        main_vbox:=gtk_vbox_new(false,0);
        gtk_container_set_border_width(gtk_container(vbox),8);
	{ Asignamos funcionalidad a los botones }
        { Lo mostramos todo }
        main_vbox := gtk_vbox_new(FALSE, 0);

        gtk_container_add(GTK_CONTAINER(dialogo), main_vbox);
           
        frame_vertm := gtk_frame_new('Datos de la imagen');
     	gtk_box_pack_start(GTK_BOX(main_vbox), frame_vertm, TRUE, TRUE, 10);
        hbox1 := gtk_hbox_new(FALSE, 0);
     	gtk_container_set_border_width(GTK_CONTAINER(hbox1), 1);
        gtk_container_add(GTK_CONTAINER(frame_vertm), hbox1);
        gtk_box_pack_start(GTK_BOX(hbox1),create_bbox_mod(0,FALSE, pchar('Datos'), 17, 1, 1,GTK_BUTTONBOX_START), TRUE, TRUE, 5);
        gtk_box_pack_start(GTK_BOX(hbox1),create_bbox_mod(1,FALSE, pchar('Valores'), 6, 1, 1,GTK_BUTTONBOX_START), TRUE, TRUE, 5);
	gtk_box_pack_start(GTK_BOX(hbox1),create_bbox_mod(3,FALSE, pchar(''), 10, 85, 20,GTK_BUTTONBOX_START), TRUE, TRUE, 5);

	frame_horzm := gtk_frame_new('');
        gtk_box_pack_start(GTK_BOX(main_vbox), frame_horzm, TRUE, TRUE, 10);
        vbox1 := gtk_vbox_new(FALSE, 0);
        gtk_container_set_border_width(GTK_CONTAINER(vbox1), 10);
        gtk_container_add(GTK_CONTAINER(frame_horzm), vbox1);
        gtk_box_pack_start(GTK_BOX(vbox1),create_bbox_mod(2,TRUE, pchar(''), 10, 85, 20,GTK_BUTTONBOX_END), TRUE, TRUE, 5);
	{ Asignamos funcionalidad a los botones }
        gtk_signal_connect_object(pGtkObject(button_aceptar), 'clicked', tGtksignalfunc(@aceptar_imagen), gpointer(dialogo));
        //gtk_signal_connect_object(pGtkObject(button_aceptar), 'clicked', tGtksignalfunc(@buscar_imagen), gpointer(thelist));
        //gtk_signal_connect_object(pGtkObject(button_aceptar), 'clicked', tGtksignalfunc(@destroy_wid), gpointer(dialogo));
	gtk_signal_connect_object(pGtkObject(button_agrandar), 'clicked', tGtksignalfunc(@agrandar_imagen), nil);
	gtk_signal_connect_object(pGtkObject(button_antimg), 'clicked', tGtksignalfunc(@anterior_imagen), nil );
	gtk_signal_connect_object(pGtkObject(button_sigimg), 'clicked', tGtksignalfunc(@siguiente_imagen), nil );
        gtk_signal_connect_object(pGtkObject(button_cancelar), 'clicked', tGtksignalfunc(@destroy_wid), gpointer(dialogo));
	gtk_signal_connect_object(pGtkObject(button_cancelar), 'clicked', tGtksignalfunc(@gtk_clist_unselect_all),pGTKClist(thelist));

        { Lo mostramos todo }
   
        gtk_widget_show_all(dialogo);
        end;

end; { Ventana_Informacion }
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Procedure modificar_imagen;						{ Procedure con el que modificaremos las imágenes.			}
Var
        { Widgets utilizados }
        dialogo,hbox1,main_vbox		: PGtkWidget;
	button_aceptar, button_cancelar		: PGtkWidget;		{ Botones que uso.							}
	button_agrandar,button_sigimg		: PGtkWidget;
	button_antimg				: PGtkWidget;
	//tSub					: tTablaBusqueda; 	{ Tablas de búsqueda que usaremos para sacar la subtemática y la info	}
	//numSub					: longint;		{ de las imágenes. numSub:id de la subtemática.				}
	ultimaS					: boolean;		{ Otra bandera para entrar en modificar 				}
	j					: longint;
	Procedure rellenar_valores(imgelegida:longint);
	Var 
	desc		 : string;
	error		 : PGerror;
    	img,img2	 : PGdkPixbuf;		{ Pixbuf de la imagen.	}
	gdk_pixmap	 : PGdkPixmap;
	mask	 	 : PGdkBitMap;
	Begin	 error:=nil;

		{ Inicializamos la lista del desplegable que contiene la subtemática.	}
		gtk_entry_set_text(GTK_ENTRY(id_img),@tabla[imgelegida][11][1]);
		gtk_entry_set_text(GTK_ENTRY(nombre_img),@tabla[imgelegida][1][1]);
		gtk_entry_set_text(GTK_ENTRY(subt_img),@tabla[imgelegida][2][1]);
		gtk_entry_set_text(GTK_ENTRY(tem_img),@tabla[imgelegida][3][1]);
		gtk_entry_set_text(GTK_ENTRY(tipo_img),@tabla[imgelegida][4][1]);
		gtk_entry_set_text(GTK_ENTRY(tam_img),@tabla[imgelegida][5][1]);
		gtk_entry_set_text(GTK_ENTRY(anc_img),@tabla[imgelegida][6][1]);
		gtk_entry_set_text(GTK_ENTRY(alt_img),@tabla[imgelegida][7][1]);
		gtk_entry_set_text(GTK_ENTRY(eti_img),@tabla[imgelegida][8][2]);
		gtk_editable_delete_text(GTK_EDITABLE(desc_img),0,-1);
		desc := StrPas(@tabla[imgelegida][9][1]);
		gtk_text_insert(GTK_TEXT(desc_img), nil, NIL, NIL,@tabla[imgelegida][9][1], length(desc));
		//gtk_entry_set_text(GTK_ENTRY(desc_img),@t[imgelegida][9][1]);
		cadenaAuxmod := tabla[imgelegida][1];
        	gtk_entry_set_editable(PGTKENTRY(id_img),FALSE );
        	gtk_entry_set_editable(PGTKENTRY(nombre_img),FALSE );
        	gtk_entry_set_editable(PGTKENTRY(subt_img),FALSE );
        	gtk_entry_set_editable(PGTKENTRY(tem_img),FALSE );
        	gtk_entry_set_editable(PGTKENTRY(tipo_img),FALSE );
        	gtk_entry_set_editable(PGTKENTRY(tam_img),FALSE );
        	gtk_entry_set_editable(PGTKENTRY(anc_img),FALSE );
        	gtk_entry_set_editable(PGTKENTRY(alt_img),FALSE );
       		gtk_entry_set_editable(PGTKENTRY(eti_img),TRUE );
        	gtk_text_set_editable(PGTKTEXT(desc_img),TRUE );
		img := gdk_pixbuf_new_from_file(@cadenaAuxmod[1],@error);
		if (img<>nil) then begin
		img2 := gdk_pixbuf_scale_simple(img,220,200,GDK_INTERP_BILINEAR);
		gdk_pixbuf_render_pixmap_and_mask(img2,gdk_pixmap,mask,0);
		{imagen_pixbuf := gdk_pixbuf_copy(img);
		imgMod := gdk_pixbuf_scale_simple(imagen_pixbuf,250,200,GDK_INTERP_BILINEAR);
        	gdk_pixbuf_render_pixmap_and_mask(imgMod,gdk_pixmap,mask,0);}
		if (not bandera_img) then gtk_pixmap_set(PGTKPIXMAP(pixmap),gdk_pixmap,mask);
		bandera_img := FALSE; 
		g_object_unref(G_OBJECT(img));
		g_object_unref(G_OBJECT(img2));
		g_object_unref(G_OBJECT(gdk_pixmap));
		end; // if del img <> nil
	End;
	Procedure actualizar_imagen;
		Var 	subt			: string;
			t			: tTablaBusqueda;
			wid 			: PGtkWidget;
			fs 			: pGtkFileSelection;
		Begin  
			//bandera_img := true;				{ Volvemos a poner la bandera imagen a true para poder abrir más.	}
			wid := nil; fs := nil;
			Val(tabla[seleccion][IDIMG],imagen.id_imagen);
			imagen.fichero := StrPas(gtk_entry_get_text(GTK_ENTRY(nombre_img)));
			imagen.etiquetas := ' ' + StrPas(gtk_entry_get_text(GTK_ENTRY(eti_img)));
			imagen.descripcion := StrPas(gtk_editable_get_chars(GTK_EDITABLE(desc_img),0,gtk_text_get_length(GTK_TEXT(desc_img))));
			imagen.subtematica := StrPas(gtk_entry_get_text(GTK_ENTRY(subt_img)));
			subt := BusquedaIDSub + imagen.subtematica + '"';
			imagen.idsubtematica := -1;
			BusquedaDB(@subt[1],imagen.idsubtematica,false,t);
			//write(imagen.idsubtematica);
			if (imagen.idsubtematica <> -1) then 
					Begin
					ModificarImagen(imagen);
					if (tabla[seleccion][1] <> imagen.fichero) then shell('mv '+tabla[seleccion][1]+' '+imagen.fichero);	
					End
			else VentanaInformacion(wid,fs);
			{ESTO AHORA NO HACE NADA
			tems := BusquedaNOMTem + 'WHERE id = ' + Num2St(imagen.idtematica);
			writeln(tems);
			BusquedaDB(@tems[1],n,false,t);
			writeln(t[0][1]);
			imagen.tematica := t[0][1];}
			tabla[seleccion][8] := imagen.etiquetas;
			tabla[seleccion][9] := imagen.descripcion;
			gtk_clist_set_text(pGtkClist(thelist),seleccion,7,pgchar(imagen.etiquetas));
			gtk_clist_set_text(pGtkClist(thelist),seleccion,8,pgchar(imagen.descripcion));
			rellenar_valores(seleccion);
			bandera_img := FALSE;
		End;
	Function create_bbox_mod( objeto : longint; horizontal : boolean ; title : pchar ; spacing : gint ;
             child_w : gint ; child_h : gint ; layout : gint ) : pGtkWidget;
	{ Create a Button Box with the specified parameters }
	Var
           frame, bbox,tablaDesc  : pGtkWidget;
	   vboxA,hboxA,DescScrollbar  : pGtkWidget;
	Begin
           frame := gtk_frame_new(pchar(title));
           if (horizontal = true) THEN
                         bbox := gtk_hbutton_box_new()
           else
                         bbox := gtk_vbutton_box_new();

	   if (objeto = 0) then
		Begin
			gtk_container_set_border_width(GTK_CONTAINER(bbox), 5);
          	        gtk_container_add(GTK_CONTAINER(frame), bbox);
           		{ Set the appearance of the Button Box }
           		gtk_button_box_set_layout(GTK_BUTTON_BOX(bbox), layout);
           		gtk_button_box_set_spacing(GTK_BUTTON_BOX(bbox), spacing);
           		gtk_button_box_set_child_size(GTK_BUTTON_BOX(bbox), child_w, child_h);
		
			labelm0   := gtk_label_new('Identificador:');
			labelm1   := gtk_label_new('Nombre:');
			labelm2   := gtk_label_new('Temática:');
			labelm3   := gtk_label_new('Tem-Padre:');
			labelm4   := gtk_label_new('Tipo:');
			labelm5   := gtk_label_new('Tamanio:');
			labelm6   := gtk_label_new('Anchura:');
			labelm7   := gtk_label_new('Altura:');
			labelm8   := gtk_label_new('Etiquetas:');
			labelm9   := gtk_label_new('Descripcion:');
			gtk_container_add(GTK_CONTAINER(bbox), labelm0);
			gtk_container_add(GTK_CONTAINER(bbox), labelm1);
			gtk_container_add(GTK_CONTAINER(bbox), labelm2);
			gtk_container_add(GTK_CONTAINER(bbox), labelm3);
			gtk_container_add(GTK_CONTAINER(bbox), labelm4);
			gtk_container_add(GTK_CONTAINER(bbox), labelm5);
			gtk_container_add(GTK_CONTAINER(bbox), labelm6);
			gtk_container_add(GTK_CONTAINER(bbox), labelm7);
			gtk_container_add(GTK_CONTAINER(bbox), labelm8);
			gtk_container_add(GTK_CONTAINER(bbox), labelm9);

           		create_bbox_mod := frame;
		End
	   else if(objeto = 1) then
		Begin	
			gtk_container_set_border_width(GTK_CONTAINER(bbox), 5);
          	     	gtk_container_add(GTK_CONTAINER(frame), bbox);
           		{ Set the appearance of the Button Box }
           		gtk_button_box_set_layout(GTK_BUTTON_BOX(bbox), layout);
           		gtk_button_box_set_spacing(GTK_BUTTON_BOX(bbox), spacing);
           		gtk_button_box_set_child_size(GTK_BUTTON_BOX(bbox), child_w, child_h);
			{ Asignamos a las entradas los valores de la imagen actualmente. }
        		nombre_img   := gtk_entry_new_with_max_length(100);		
			subt_img := gtk_entry_new_with_max_length(100);			
			id_img  := gtk_entry_new_with_max_length(15);				
			tem_img  := gtk_entry_new_with_max_length(100);		
			tipo_img := gtk_entry_new_with_max_length(100);
			tam_img  := gtk_entry_new_with_max_length(10);
        		anc_img  := gtk_entry_new_with_max_length(10); 
        		alt_img  := gtk_entry_new_with_max_length(10);
        		eti_img  := gtk_entry_new_with_max_length(500);
        		desc_img := gtk_text_new(nil,nil);

	   		DescScrollbar := gtk_vscrollbar_new(GTK_TEXT(desc_img)^.vadj);
	  	 	tablaDesc := gtk_table_new(8, 1, FALSE);


			gtk_table_set_row_spacings(GTK_TABLE(tablaDesc), spacing);
	   		gtk_table_attach_defaults(GTK_TABLE(tablaDesc), id_img, 0, 1, 0, 1);
	   		gtk_table_attach_defaults(GTK_TABLE(tablaDesc), nombre_img, 0, 1, 1, 2);
	   		gtk_table_attach_defaults(GTK_TABLE(tablaDesc), subt_img, 0, 1, 2, 3);
	   		gtk_table_attach_defaults(GTK_TABLE(tablaDesc), tem_img, 0, 1, 3, 4);
	   		gtk_table_attach_defaults(GTK_TABLE(tablaDesc), tipo_img, 0, 1, 4, 5);
	   		gtk_table_attach_defaults(GTK_TABLE(tablaDesc), tam_img, 0, 1, 5, 6);
	   		gtk_table_attach_defaults(GTK_TABLE(tablaDesc), anc_img, 0, 1, 7, 8);
	   		gtk_table_attach_defaults(GTK_TABLE(tablaDesc), alt_img, 0, 1, 8, 9);
	   		gtk_table_attach_defaults(GTK_TABLE(tablaDesc), eti_img, 0, 1, 9, 10);
			gtk_table_attach(GTK_TABLE(tablaDesc), desc_img, 0, 1, 10, 11,GTK_FILL,GTK_FILL, 0, 0);
	   		gtk_table_attach(GTK_TABLE(tablaDesc), DescScrollbar, 1, 2, 10, 11, GTK_SHRINK,GTK_FILL, 0, 0);
   			gtk_container_add(GTK_CONTAINER(bbox), tablaDesc);
			rellenar_valores(primera);
           		create_bbox_mod := frame
		End
	   else if (objeto = 2) then 
	 	Begin
           		gtk_container_set_border_width(GTK_CONTAINER(bbox), 5);
          	        gtk_container_add(GTK_CONTAINER(frame), bbox);
           		{ Set the appearance of the Button Box }
           		gtk_button_box_set_layout(GTK_BUTTON_BOX(bbox), layout);
           		gtk_button_box_set_spacing(GTK_BUTTON_BOX(bbox), spacing);
           		gtk_button_box_set_child_size(GTK_BUTTON_BOX(bbox), child_w, child_h);
           		button_aceptar := gtk_button_new_with_label('Modificar');
           		gtk_container_add(GTK_CONTAINER(bbox), button_aceptar);
           		button_cancelar := gtk_button_new_with_label('Salir');
           		gtk_container_add(GTK_CONTAINER(bbox), button_cancelar);
           		create_bbox_mod := frame;
		End
	 else Begin
		        gtk_container_set_border_width(GTK_CONTAINER(bbox), 5);
          	        gtk_container_add(GTK_CONTAINER(frame), bbox);
           		{ Set the appearance of the Button Box }
           		gtk_button_box_set_layout(GTK_BUTTON_BOX(bbox), layout);
           		gtk_button_box_set_spacing(GTK_BUTTON_BOX(bbox), spacing);
           		gtk_button_box_set_child_size(GTK_BUTTON_BOX(bbox), child_w, child_h);
			vboxA := gtk_vbox_new(false,0);
			hboxA := gtk_hbox_new(false,0);
			visualizar_imagen(true,tabla[primera][1],vboxA);
  			button_agrandar := gtk_button_new_with_label('Agrandar Imagen');
			button_sigimg := gtk_button_new_with_label('Siguiente Imagen');
			button_antimg := gtk_button_new_with_label('Anterior Imagen');
           		gtk_container_add(GTK_CONTAINER(vboxA), button_agrandar);
			gtk_container_add(GTK_CONTAINER(hboxA), button_antimg);
			gtk_container_add(GTK_CONTAINER(hboxA), button_sigimg);
			gtk_container_add(GTK_CONTAINER(vboxA), hboxA);
			gtk_container_add(GTK_CONTAINER(bbox),vboxA);
           		create_bbox_mod := frame;
		End;
	End;   
	Procedure agrandar_imagen;
	Var w : PGtkWidget;
	Begin	w:=nil;
		visualizar_imagen(false,cadenaAuxmod,w);
	End;
	Procedure siguiente_imagen; 
	Begin	
		if (seleccion <> ultima) then Begin
			seleccion := seleccion + 1;
			while(seleccion <= N) AND (borrado[seleccion] = FALSE) do begin seleccion := seleccion + 1; writeln(seleccion); end;
			rellenar_valores(seleccion);
		End;
	End;
	Procedure anterior_imagen;
	Begin	
		if (seleccion <> primera) then Begin
				seleccion := seleccion - 1;
				while(seleccion >= 0) AND (borrado[seleccion] = FALSE) do seleccion := seleccion - 1;
				rellenar_valores(seleccion);
		End;
	End;
Begin   
	ultimaS := False;
	for j:=0 to N do if borrado[j] then ultimaS := True;
        if bandera_img and ultimaS then begin		{ Si la bandera está true, podemos crear la ventana, con lo que entramos.}
        //bandera_img := FALSE;						{ ponemos la bandera en falso, para que no se puedan modificar más.	}
	seleccion := 0;	
	while(seleccion <= N) AND (borrado[seleccion] = FALSE) do seleccion := seleccion + 1;
	primera := seleccion;
	seleccion := N;
	while(seleccion >= 0) AND (borrado[seleccion] = FALSE) do seleccion := seleccion - 1;
	ultima := seleccion;
	seleccion := primera;
	//writeln('PRIMERA ',primera);
	//writeln('ULTIMA ',ultima);
        dialogo := gtk_window_new(GTK_WINDOW_TOPLEVEL);
        gtk_widget_set_usize(dialogo,650,650);  
        gtk_window_set_title(gtk_window(dialogo),'Modificar imagen');
        gtk_window_set_policy (GTK_WINDOW (dialogo), 0,0,0);
        gtk_window_set_position(GTK_WINDOW(dialogo),GTK_WIN_POS_CENTER);  { Centramos la ventana }
 	gtk_signal_connect(pGtkObject(dialogo),'destroy', tGtkSignalFunc(@destroy_wid), NIL);
        main_vbox:=gtk_vbox_new(false,0);
        gtk_container_set_border_width(gtk_container(vbox),8);
	{ Asignamos funcionalidad a los botones }
        { Lo mostramos todo }
        main_vbox := gtk_vbox_new(FALSE, 0);

        gtk_container_add(GTK_CONTAINER(dialogo), main_vbox);
           
        frame_vertm := gtk_frame_new('Datos de la imagen');
     	gtk_box_pack_start(GTK_BOX(main_vbox), frame_vertm, TRUE, TRUE, 10);
        hbox1 := gtk_hbox_new(FALSE, 0);
     	gtk_container_set_border_width(GTK_CONTAINER(hbox1), 1);
        gtk_container_add(GTK_CONTAINER(frame_vertm), hbox1);
        gtk_box_pack_start(GTK_BOX(hbox1),create_bbox_mod(0,FALSE, pchar('Datos'), 17, 1, 1,GTK_BUTTONBOX_START), TRUE, TRUE, 5);
        gtk_box_pack_start(GTK_BOX(hbox1),create_bbox_mod(1,FALSE, pchar('Valores'), 6, 1, 1,GTK_BUTTONBOX_START), TRUE, TRUE, 5);
	gtk_box_pack_start(GTK_BOX(hbox1),create_bbox_mod(3,FALSE, pchar(''), 10, 85, 20,GTK_BUTTONBOX_START), TRUE, TRUE, 5);

	frame_horzm := gtk_frame_new('');
        gtk_box_pack_start(GTK_BOX(main_vbox), frame_horzm, TRUE, TRUE, 10);
        vbox1 := gtk_vbox_new(FALSE, 0);
        gtk_container_set_border_width(GTK_CONTAINER(vbox1), 10);
        gtk_container_add(GTK_CONTAINER(frame_horzm), vbox1);
        gtk_box_pack_start(GTK_BOX(vbox1),create_bbox_mod(2,TRUE, pchar(''), 10, 85, 20,GTK_BUTTONBOX_END), TRUE, TRUE, 5);
	{ Asignamos funcionalidad a los botones }
        gtk_signal_connect_object(pGtkObject(button_aceptar), 'clicked', tGtksignalfunc(@actualizar_imagen), gpointer(dialogo));
        //gtk_signal_connect_object(pGtkObject(button_aceptar), 'clicked', tGtksignalfunc(@buscar_imagen), gpointer(thelist));
        //gtk_signal_connect_object(pGtkObject(button_aceptar), 'clicked', tGtksignalfunc(@destroy_wid), gpointer(dialogo));
	gtk_signal_connect_object(pGtkObject(button_agrandar), 'clicked', tGtksignalfunc(@agrandar_imagen), nil);
	gtk_signal_connect_object(pGtkObject(button_antimg), 'clicked', tGtksignalfunc(@anterior_imagen), nil );
	gtk_signal_connect_object(pGtkObject(button_sigimg), 'clicked', tGtksignalfunc(@siguiente_imagen), nil );
        gtk_signal_connect_object(pGtkObject(button_cancelar), 'clicked', tGtksignalfunc(@destroy_wid), gpointer(dialogo));
	gtk_signal_connect_object(pGtkObject(button_cancelar), 'clicked', tGtksignalfunc(@gtk_clist_unselect_all),pGTKClist(thelist));

        { Lo mostramos todo }
   
        gtk_widget_show_all(dialogo);
        end;

end; { Ventana_Informacion }
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Procedure borrar_imagen ( data : pGtkClist); cdecl;			{ Con esto borraremos las imágenes que seleccionemos de la db		}
Var borrar		: string;					{ comprueba en el array borrado las que hay seleccionadas y las borra.	}
	i		: longint;
Begin
   borrar := 'inicial';
   for i:=0 to N do
	if borrado[i] then 
		Begin 
		if borrar = 'inicial' then borrar := DELIMG + borimg + tabla[i][IDIMG]
		else borrar := borrar + ' OR ' + borimg + tabla[i][IDIMG];
		//shell('rm '+tabla[i][1]);
		end;
   llamadasDB(@borrar[1]);
				
End;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Procedure selection_made( thelist : pGtkCList ; row, column : gint ; event : pGdkEventButton ; data : pchar ); cdecl;
Begin									{ Selection made se activa cuando seleccionamos las imágenes en la CLIST }
  if (data=noElegida) then borrado[row] := false			{ si no selecciona, pone el valor en el array de booleanos a false, y si }
	else begin							{ se selecciona, se pone a true.					 }
		borrado[row] := true;
		{if (column = 9) then 
				visualizar_imagen(tabla[row][1]);}
		end;
End;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Procedure insertar_imagen;
   
Var	
        dialogo,vbox1,main_vbox,hbox1	: PGtkWidget;			{ Widgets que necesitaremos para crear la ventana de inserción.		}
	button_aceptar, button_cancelar, button_agrandar: PGtkWidget;	{ Botones que necesitaremos...						}
	t,tSub				: tTablaBusqueda;		{ Tablas de búsqueda que utilizaremos para sacar la id de subtemática.	}	
	numSub				: longint;		
	Procedure aceptar_imagen;
	Var     wid			: PGtkWidget;
		fs			: pGtkFileSelection;
		subt,buscarepe,insTema	: string;
		Begin   
			bandera_img := true; wid := nil; fs := nil;
			shell('cp '+nombreImagen+' '+DirImagenes);
			imagen.id_desc := StrPas(gtk_entry_get_text(GTK_ENTRY(id_img)));
			imagen.fichero := imagen.titulo;
			imagen.existefich := FileExists(imagen.fichero);
       			imagen.etiquetas := StrPas(gtk_entry_get_text(GTK_ENTRY(eti_img)));
			imagen.descripcion := StrPas(gtk_editable_get_chars(GTK_EDITABLE(desc_img),0,gtk_text_get_length(GTK_TEXT(desc_img))));
			imagen.subtematica := StrPas(gtk_entry_get_text(GTK_ENTRY(GTK_COMBO(subt_img)^.entry)));
			subt := BusquedaIDSub + imagen.subtematica + '"';
			imagen.idsubtematica := -1;
			buscarepe := BusquedaIDIMG + imagen.id_desc + '"';
			BusquedaDB(@subt[1],imagen.idsubtematica,false,t);
			BusquedaIdentificador(Pchar(buscarepe),idrepetido);
			if (imagen.idsubtematica = -1) then 
					Begin
					insTema := INSTEMXML + imagen.subtematica + '",FALSE)';
					llamadasDB(@insTema[1]);
					BusquedaDB(@subt[1],imagen.idsubtematica,false,t);
					insTema := INSSTEMXML + '1,' + Num2St(imagen.idsubtematica) + ',"' + imagen.subtematica + '")';
					llamadasDB(@insTema[1]);
					End;
			if (not idrepetido) then GuardarImagen(imagen);
			if (imagen.malformato) or (not imagen.existefich) or (imagen.id_desc = '') or (idrepetido) then VentanaInformacion(wid,fs);
		End;
	Procedure rellenar_valores(imgelegida:longint);
	Var 
	i 		 : longint;
	glist 		 : pGList;
	Begin	 
		glist := nil;
		glist := g_list_append(glist,subtDef);
		for i:=0 to  numTematicas do glist := g_list_append(glist,@tematicas[i][1][1]);
		gtk_entry_set_editable(PGTKENTRY(GTK_COMBO(subt_img)^.entry),TRUE);
		gtk_combo_set_popdown_strings(GTK_COMBO(subt_img),glist);
		gtk_combo_disable_activate(GTK_COMBO(subt_img));
		{ Inicializamos la lista del desplegable que contiene la subtemática.	}
		writeln(imagen.titulo);
		gtk_entry_set_text(GTK_ENTRY(nombre_img),Pgchar(imagen.titulo));
		gtk_entry_set_text(GTK_ENTRY(tipo_img),@imagen.tipo_fichero[0]);
		gtk_entry_set_text(GTK_ENTRY(tam_img),Pgchar(Num2St(imagen.tamano_img)));
		gtk_entry_set_text(GTK_ENTRY(anc_img),Pgchar(Num2St(imagen.ancho_img)));
		gtk_entry_set_text(GTK_ENTRY(alt_img),Pgchar(Num2St(imagen.alto_img)));
		//gtk_entry_set_text(GTK_ENTRY(eti_img),@imagen.etiquetas[1]);
		//gtk_editable_delete_text(GTK_EDITABLE(desc_img),0,-1);
        	gtk_entry_set_editable(PGTKENTRY(id_img),TRUE );
        	gtk_entry_set_editable(PGTKENTRY(nombre_img),FALSE );
        	gtk_entry_set_editable(PGTKENTRY(tipo_img),FALSE );
        	gtk_entry_set_editable(PGTKENTRY(tam_img),FALSE );
        	gtk_entry_set_editable(PGTKENTRY(anc_img),FALSE );
        	gtk_entry_set_editable(PGTKENTRY(alt_img),FALSE );
       		gtk_entry_set_editable(PGTKENTRY(eti_img),TRUE );
        	gtk_text_set_editable(PGTKTEXT(desc_img),TRUE );

		//g_object_unref(G_OBJECT(gdk_pixmap));
	End;
	Function create_bbox_mod( objeto : longint; horizontal : boolean ; title : pchar ; spacing : gint ;
             child_w : gint ; child_h : gint ; layout : gint ) : pGtkWidget;
	{ Create a Button Box with the specified parameters }
	Var
           frame, bbox,tablaDesc  : pGtkWidget;
	   vboxA,hboxA,DescScrollbar  : pGtkWidget;
	   glist : pGList;
	   i : longint;
	Begin
           frame := gtk_frame_new(pchar(title));
           if (horizontal = true) THEN
                         bbox := gtk_hbutton_box_new()
           else
                         bbox := gtk_vbutton_box_new();

	   if (objeto = 0) then
		Begin
			gtk_container_set_border_width(GTK_CONTAINER(bbox), 5);
          	        gtk_container_add(GTK_CONTAINER(frame), bbox);
           		{ Set the appearance of the Button Box }
           		gtk_button_box_set_layout(GTK_BUTTON_BOX(bbox), layout);
           		gtk_button_box_set_spacing(GTK_BUTTON_BOX(bbox), spacing);
           		gtk_button_box_set_child_size(GTK_BUTTON_BOX(bbox), child_w, child_h);

			labelm1   := gtk_label_new('Id:');
			labelm2   := gtk_label_new('Nombre:');
			labelm3   := gtk_label_new('Temática:');
			labelm4   := gtk_label_new('Tipo:');
			labelm5   := gtk_label_new('Tamanio:');
			labelm6   := gtk_label_new('Anchura:');
			labelm7   := gtk_label_new('Altura:');
			labelm8   := gtk_label_new('Etiquetas:');
			labelm9   := gtk_label_new('Descripcion:');
			gtk_container_add(GTK_CONTAINER(bbox), labelm1);
			gtk_container_add(GTK_CONTAINER(bbox), labelm2);
			gtk_container_add(GTK_CONTAINER(bbox), labelm3);
			gtk_container_add(GTK_CONTAINER(bbox), labelm4);
			gtk_container_add(GTK_CONTAINER(bbox), labelm5);
			gtk_container_add(GTK_CONTAINER(bbox), labelm6);
			gtk_container_add(GTK_CONTAINER(bbox), labelm7);
			gtk_container_add(GTK_CONTAINER(bbox), labelm8);
			gtk_container_add(GTK_CONTAINER(bbox), labelm9);

           		create_bbox_mod := frame;
		End
	   else if(objeto = 1) then
		Begin	
			gtk_container_set_border_width(GTK_CONTAINER(bbox), 5);
          	     	gtk_container_add(GTK_CONTAINER(frame), bbox);
           		{ Set the appearance of the Button Box }
           		gtk_button_box_set_layout(GTK_BUTTON_BOX(bbox), layout);
           		gtk_button_box_set_spacing(GTK_BUTTON_BOX(bbox), spacing);
           		gtk_button_box_set_child_size(GTK_BUTTON_BOX(bbox), child_w, child_h);
			{ Asignamos a las entradas los valores de la imagen actualmente. }
			id_img := gtk_entry_new_with_max_length(15);
        		nombre_img   := gtk_entry_new_with_max_length(100);		
			subt_img := gtk_combo_new;							
			tipo_img := gtk_entry_new_with_max_length(100);
			tam_img  := gtk_entry_new_with_max_length(10); 
        		anc_img  := gtk_entry_new_with_max_length(10); 
        		alt_img  := gtk_entry_new_with_max_length(10);
        		eti_img  := gtk_entry_new_with_max_length(500);
        		desc_img := gtk_text_new(nil,nil);

	   		DescScrollbar := gtk_vscrollbar_new(GTK_TEXT(desc_img)^.vadj);
	  	 	tablaDesc := gtk_table_new(8, 1, FALSE);

			numSub := 90;
			BusquedaDB(BusquedaNOMSub,numSub,false,tSub);	{Buscamos todas las subtemáticas que existen en la db.	}
			tematicas := tSub; // Esta es la global donde almaceno las tematicas.		
			glist := nil;
			for i:=0 to numSub do glist := g_list_append(glist,@tSub[i][1][1]);
		 	numTematicas := numSub;
			gtk_entry_set_editable(PGTKENTRY(GTK_COMBO(subt_img)^.entry),FALSE);
			gtk_combo_set_popdown_strings(GTK_COMBO(subt_img),glist);
			gtk_combo_disable_activate(GTK_COMBO(subt_img));

			gtk_table_set_row_spacings(GTK_TABLE(tablaDesc), spacing);
	   		gtk_table_attach_defaults(GTK_TABLE(tablaDesc), id_img, 0, 1, 0, 1);
	   		gtk_table_attach_defaults(GTK_TABLE(tablaDesc), nombre_img, 0, 1, 1, 2);
	   		gtk_table_attach_defaults(GTK_TABLE(tablaDesc), subt_img, 0, 1, 2, 3);
	   		gtk_table_attach_defaults(GTK_TABLE(tablaDesc), tipo_img, 0, 1, 3, 4);
	   		gtk_table_attach_defaults(GTK_TABLE(tablaDesc), tam_img, 0, 1, 4, 5);
	   		gtk_table_attach_defaults(GTK_TABLE(tablaDesc), anc_img, 0, 1, 5, 6);
	   		gtk_table_attach_defaults(GTK_TABLE(tablaDesc), alt_img, 0, 1, 6, 7);
	   		gtk_table_attach_defaults(GTK_TABLE(tablaDesc), eti_img, 0, 1, 7, 8);
			gtk_table_attach(GTK_TABLE(tablaDesc), desc_img, 0, 1, 8, 9,GTK_FILL,GTK_FILL, 0, 0);
	   		gtk_table_attach(GTK_TABLE(tablaDesc), DescScrollbar, 1, 2, 8, 9, GTK_SHRINK,GTK_FILL, 0, 0);
   			gtk_container_add(GTK_CONTAINER(bbox), tablaDesc);
			rellenar_valores(1);
           		create_bbox_mod := frame
		End
	   else if (objeto = 2) then 
	 	Begin
           		gtk_container_set_border_width(GTK_CONTAINER(bbox), 5);
          	        gtk_container_add(GTK_CONTAINER(frame), bbox);
           		{ Set the appearance of the Button Box }
           		gtk_button_box_set_layout(GTK_BUTTON_BOX(bbox), layout);
           		gtk_button_box_set_spacing(GTK_BUTTON_BOX(bbox), spacing);
           		gtk_button_box_set_child_size(GTK_BUTTON_BOX(bbox), child_w, child_h);
           		button_aceptar := gtk_button_new_with_label('Aceptar');
           		gtk_container_add(GTK_CONTAINER(bbox), button_aceptar);
           		button_cancelar := gtk_button_new_with_label('Cancelar');
           		gtk_container_add(GTK_CONTAINER(bbox), button_cancelar);
           		create_bbox_mod := frame;
		End
	 else Begin
		        gtk_container_set_border_width(GTK_CONTAINER(bbox), 5);
          	        gtk_container_add(GTK_CONTAINER(frame), bbox);
           		{ Set the appearance of the Button Box }
           		gtk_button_box_set_layout(GTK_BUTTON_BOX(bbox), layout);
           		gtk_button_box_set_spacing(GTK_BUTTON_BOX(bbox), spacing);
           		gtk_button_box_set_child_size(GTK_BUTTON_BOX(bbox), child_w, child_h);
			vboxA := gtk_vbox_new(false,0);
			hboxA := gtk_hbox_new(false,0);
			visualizar_imagen(true,imagen.fichero,vboxA);
  			button_agrandar := gtk_button_new_with_label('Agrandar Imagen');
           		gtk_container_add(GTK_CONTAINER(vboxA), button_agrandar);
			gtk_container_add(GTK_CONTAINER(vboxA), hboxA);
			gtk_container_add(GTK_CONTAINER(bbox),vboxA);
           		create_bbox_mod := frame;
		End;
	End;   
	Procedure agrandar_imagen;
	Var w : PGtkWidget;
	Begin	w:=nil;
		visualizar_imagen(false,imagen.fichero,w);
	End;
Begin   
	SubirImagen(imagen);
	ObtenerInfoFichero(imagen);
	//writeln('ollasdasd');
        if bandera_img and imagen.existefich then begin		{ Si la bandera está true, podemos crear la ventana, con lo que entramos.}
        bandera_img := FALSE;			{ ponemos la bandera en falso, para que no se puedan modificar más.	}
        dialogo := gtk_window_new(GTK_WINDOW_TOPLEVEL);
        gtk_widget_set_usize(dialogo,640,600);  
        gtk_window_set_title(gtk_window(dialogo),'Insertar imagen');
        gtk_window_set_policy (GTK_WINDOW (dialogo), 0,0,0);
        gtk_window_set_position(GTK_WINDOW(dialogo),GTK_WIN_POS_CENTER);  { Centramos la ventana }
 	gtk_signal_connect(pGtkObject(dialogo),'destroy', tGtkSignalFunc(@destroy_wid), NIL);
        main_vbox:=gtk_vbox_new(false,0);
        gtk_container_set_border_width(gtk_container(vbox),8);
	{ Asignamos funcionalidad a los botones }
        { Lo mostramos todo }
        main_vbox := gtk_vbox_new(FALSE, 0);

        gtk_container_add(GTK_CONTAINER(dialogo), main_vbox);
           
        frame_vertm := gtk_frame_new('Datos de la imagen');
     	gtk_box_pack_start(GTK_BOX(main_vbox), frame_vertm, TRUE, TRUE, 10);
        hbox1 := gtk_hbox_new(FALSE, 0);
     	gtk_container_set_border_width(GTK_CONTAINER(hbox1), 1);
        gtk_container_add(GTK_CONTAINER(frame_vertm), hbox1);
        gtk_box_pack_start(GTK_BOX(hbox1),create_bbox_mod(0,FALSE, pchar('Datos'), 17, 1, 1,GTK_BUTTONBOX_START), TRUE, TRUE, 5);
        gtk_box_pack_start(GTK_BOX(hbox1),create_bbox_mod(1,FALSE, pchar('Valores'), 6, 1, 1,GTK_BUTTONBOX_START), TRUE, TRUE, 5);
	gtk_box_pack_start(GTK_BOX(hbox1),create_bbox_mod(3,FALSE, pchar(''), 10, 85, 20,GTK_BUTTONBOX_START), TRUE, TRUE, 5);

	frame_horzm := gtk_frame_new('');
        gtk_box_pack_start(GTK_BOX(main_vbox), frame_horzm, TRUE, TRUE, 10);
        vbox1 := gtk_vbox_new(FALSE, 0);
        gtk_container_set_border_width(GTK_CONTAINER(vbox1), 10);
        gtk_container_add(GTK_CONTAINER(frame_horzm), vbox1);
        gtk_box_pack_start(GTK_BOX(vbox1),create_bbox_mod(2,TRUE, pchar(''), 10, 85, 20,GTK_BUTTONBOX_END), TRUE, TRUE, 5);
	{ Asignamos funcionalidad a los botones }
        gtk_signal_connect_object(pGtkObject(button_aceptar), 'clicked', tGtksignalfunc(@aceptar_imagen), gpointer(dialogo));
        gtk_signal_connect_object(pGtkObject(button_aceptar), 'clicked', tGtksignalfunc(@destroy_wid), gpointer(dialogo));
	gtk_signal_connect_object(pGtkObject(button_agrandar), 'clicked', tGtksignalfunc(@agrandar_imagen), nil);
        gtk_signal_connect_object(pGtkObject(button_cancelar), 'clicked', tGtksignalfunc(@destroy_wid), gpointer(dialogo));

        { Lo mostramos todo }
   
        gtk_widget_show_all(dialogo);
        end;

end; { Ventana_Informacion }

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Procedure AbrirImagen; cdecl;				{ Es el menu de elección que ejecutamos cuando queremos insertar una imagen	}
Var							{ al pulsar en el botón "Examinar".						}
           filew : pGtkWidget ;
Begin
     if bandera_eleccion then begin
     bandera_eleccion := FALSE;
     gtk_init(@argc, @argv);
     filew := gtk_file_selection_new('Fichero imagen');
     gtk_signal_connect(GTK_OBJECT(filew), 'destroy',tGtkSignalFunc(@gtk_main_quit), @filew);
     (* Connect the ok_button to file_ok_sel function *)
     gtk_signal_connect(GTK_OBJECT(GTK_FILE_SELECTION (filew)^.ok_button), 'clicked',GTK_SIGNAL_FUNC(@file_ok_sel), filew );
     gtk_signal_connect(GTK_OBJECT(GTK_FILE_SELECTION (filew)^.ok_button), 'clicked',GTK_SIGNAL_FUNC(@insertar_imagen), filew );
     gtk_signal_connect_object(GTK_OBJECT(GTK_FILE_SELECTION(filew)^.ok_button),'clicked', GTK_SIGNAL_FUNC(@destroy_wid), GTK_OBJECT(filew));

     (* Connect the cancel_button to destroy the widget *)
     gtk_signal_connect_object(GTK_OBJECT(GTK_FILE_SELECTION(filew)^.cancel_button),'clicked', GTK_SIGNAL_FUNC(@destroy_wid), GTK_OBJECT(filew));

     gtk_widget_show(filew);
     gtk_main();
     end;

End;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Procedure Importar_imagenes;				{ Proceso principal con el que importaremos nuestras imágenes.				}
Var							{ El método es, abrir un cuadro de selección, seleccionar el fichero .tar.gz, y una vez }
    filew : PGtkWidget;					{ seleccionado, el programa lo descomprime, y si lo ha hecho correctamente, mostrará	}
Begin							{ un mensaje satisfactorio, y si falla, mostrará que la importación ha fallado.		}
     if bandera_importar then begin
     	bandera_importar := FALSE; bandera_eleccion := FALSE;
     	gtk_init(@argc, @argv);
     	filew := gtk_file_selection_new('Fichero a Importar');
     	gtk_signal_connect(GTK_OBJECT(filew), 'destroy',tGtkSignalFunc(@gtk_main_quit), @filew);
     	gtk_signal_connect(GTK_OBJECT(GTK_FILE_SELECTION (filew)^.ok_button), 'clicked',GTK_SIGNAL_FUNC(@VentanaInformacion), filew );
     	gtk_signal_connect_object(GTK_OBJECT(GTK_FILE_SELECTION(filew)^.ok_button),'clicked', GTK_SIGNAL_FUNC(@destroy_wid), GTK_OBJECT(filew));
     	gtk_signal_connect_object(GTK_OBJECT(GTK_FILE_SELECTION(filew)^.cancel_button),'clicked', GTK_SIGNAL_FUNC(@destroy_wid), GTK_OBJECT(filew));
     	gtk_widget_show(filew);
    	gtk_main();
     end;
End;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Procedure Exportar_imagenes;				{ Proceso principal con el que importaremos nuestras imágenes.				}
Var							{ El método es, abrir un cuadro de selección, seleccionar el fichero .tar.gz, y una vez }
    filew : PGtkWidget;					{ seleccionado, el programa lo descomprime, y si lo ha hecho correctamente, mostrará	}
Begin							{ un mensaje satisfactorio, y si falla, mostrará que la importación ha fallado.		}
     if bandera_exportar then begin
     	bandera_eleccion := FALSE; bandera_exportar := FALSE;
     	gtk_init(@argc, @argv);
     	filew := gtk_file_selection_new('Fichero Exportado');
     	gtk_signal_connect(GTK_OBJECT(filew), 'destroy',tGtkSignalFunc(@gtk_main_quit), @filew);
     	gtk_signal_connect(GTK_OBJECT(GTK_FILE_SELECTION (filew)^.ok_button), 'clicked',GTK_SIGNAL_FUNC(@VentanaInformacion), filew );
     	gtk_signal_connect_object(GTK_OBJECT(GTK_FILE_SELECTION(filew)^.ok_button),'clicked', GTK_SIGNAL_FUNC(@destroy_wid), GTK_OBJECT(filew));
     	gtk_signal_connect_object(GTK_OBJECT(GTK_FILE_SELECTION(filew)^.cancel_button),'clicked', GTK_SIGNAL_FUNC(@destroy_wid), GTK_OBJECT(filew));
     	gtk_widget_show(filew);
    	gtk_main();
     end;
End;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Type
           FactCB = tGtkItemFactoryCallback;		{ Creamos el menú superior, tendrá las mismas funciones que los botones inferiores.	}
Const
  	titles : ARRAY[0..10] OF pgchar = ('Nombre','Temática', 'Tem-Padre', 'Tipo', 'Filesize', 'Ancho', 'Alto', 'Etiquetas','Descripcion', 'Imagen','Identificador');
        num_menu_items = 11;
        menu_items : ARRAY[1..num_menu_items] OF 
	tGtkItemFactoryEntry = (
	(path : '/Inserciones'		; accelerator :    NIL	 ;callback : nil ; callback_action : 0; item_type :'<Branch>';extra_data:nil),
	(path : '/Inserciones/Insertar Imagen'	; accelerator : '<ctrl>O';callback : FactCB(@AbrirImagen); callback_action : 0;item_type : nil;extra_data:nil),
	(path : '/Inserciones/Importar Imágenes'	; accelerator : '<ctrl>S';callback : FactCB(@importar_imagenes); callback_action : 0;item_type : nil;extra_data:nil),
	(path : '/Inserciones/Salir'	; accelerator : '<ctrl>Q';callback : FactCB(@AbrirImagen); callback_action : 0;item_type : NIL;extra_data:nil),
	(path : '/Editar'		; accelerator :    NIL	 ;callback : nil ; callback_action : 0; item_type :'<Branch>';extra_data:nil),
	(path : '/Editar/Modificar Imagen'	; accelerator :    NIL	 ;callback : FactCB(@modificar_imagen); callback_action : 0; item_type : nil;extra_data:nil),
	(path : '/Editar/Exportar Imágenes'	; accelerator :    NIL	 ;callback : FactCB(@Exportar_imagenes); callback_action : 0; item_type : nil;extra_data:nil),
	(path : '/Editar/Borrar Imágenes'; accelerator :    NIL	 ;callback : FactCB(@borrar_imagen); callback_action : 0; item_type : nil;extra_data:nil),
	(path : '/Editar/Crear Conjunto'; accelerator :    NIL	 ;callback : FactCB(@crear_conjunto); callback_action : 0; item_type : nil;extra_data:nil),
	(path : '/Acerca de'		; accelerator :    NIL	 ;callback : nil ; callback_action : 0; item_type :'<Branch>';extra_data:nil),
	(path : '/Acerca de/Creditos'; accelerator : NIL;callback : FactCB(@Creditos); callback_action : 0; item_type : NIL;extra_data:nil));
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Procedure make_menu; cdecl;
Var
           it_factory : pGtkItemFactory;
           it_accel : pGtkAccelGroup;
Begin
           it_accel := gtk_accel_group_new();
           { This function initializes the item factory.
               Param 1: The type of menu - can be GTK_TYPE_MENU_BAR, GTK_TYPE_MENU, or GTK_TYPE_OPTION_MENU.
               Param 2: The path of the menu.
               Param 3: A pointer to a gtk_accel_group. The item factory sets up the accelerator table while generating menus. }
           it_factory := gtk_item_factory_new(GTK_TYPE_MENU_BAR, '<main>',it_accel);
           { This function generates the menu items. Pass the item factory, the number of items
               in the array, the array itself, and any callback data for the menu items.}
           gtk_item_factory_create_items(it_factory, num_menu_items,@menu_items, NIL);
           { Add the new accelerator group to the window. }
           //gtk_window_add_accel_group(GTK_WINDOW(window), it_accel);
           menu_bar := gtk_item_factory_get_widget(it_factory, '<main>');
End;   

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function crear_botones_buscador(tipoboton:longint; horizontal : boolean ; title : pchar ; spacing : gint ;
             child_w : gint ; child_h : gint ; layout : gint ) : pGtkWidget;
Var
         frame, bbox, vboxA : pGtkWidget;
Begin
         frame := gtk_frame_new(pchar(title));
         if (horizontal = true) THEN
                         bbox := gtk_hbutton_box_new()
         else
                         bbox := gtk_vbutton_box_new();
         gtk_container_set_border_width(GTK_CONTAINER(bbox), 5);
         gtk_container_add(GTK_CONTAINER(frame), bbox);
         gtk_button_box_set_layout(GTK_BUTTON_BOX(bbox), layout);
         gtk_button_box_set_spacing(GTK_BUTTON_BOX(bbox), spacing);
         gtk_button_box_set_child_size(GTK_BUTTON_BOX(bbox), child_w, child_h);
	 if (tipoboton=2) then Begin
         	rbutton_tem := gtk_radio_button_new_with_label(nil,'Temática');
         	gtk_container_add(GTK_CONTAINER(bbox), rbutton_tem);
         	//rbutton_stem := gtk_radio_button_new_with_label(gtk_radio_button_get_group (GTK_RADIO_BUTTON (rbutton_tem)),'Subtematica');
         	//gtk_container_add(GTK_CONTAINER(bbox), rbutton_stem);
         	rbutton_eti := gtk_radio_button_new_with_label(gtk_radio_button_get_group(GTK_RADIO_BUTTON (rbutton_tem)),'Etiquetas');
         	gtk_container_add(GTK_CONTAINER(bbox), rbutton_eti);
         	crear_botones_buscador := frame;
	End
	else if (tipoboton=0) then begin
		vboxA := gtk_vbox_new(false,0);
		//button_buscar := gtk_button_new_with_label('Buscar');
		texto_buscador := gtk_entry_new_with_max_length(100);
		gtk_container_add(GTK_CONTAINER(vboxA),texto_buscador);
		gtk_container_add(GTK_CONTAINER(vboxA), crear_botones_buscador(2,TRUE, pchar('Criterio de búsqueda'), 10, 80, 20,GTK_BUTTONBOX_START));
		gtk_container_add(GTK_CONTAINER(bbox), vboxA);
		crear_botones_buscador := frame;
	end
	else if (tipoboton=1) then begin
		button_buscar := gtk_button_new_with_label('Buscar');
		gtk_container_add(GTK_CONTAINER(bbox), button_buscar);
		crear_botones_buscador := frame
	end;
End;       
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Begin
	ConectaDB(DirImagenes);
	FpChdir(dirImagenes);				{ Para conectar al directorio de imágenes que hemos obtenido del config.ini 	}
  	gtk_init(@argc, @argv);
        bandera_img := TRUE; bandera_eleccion := TRUE; bandera_importar := TRUE;
	bandera_exportar := TRUE;
	imagen.malformato := FALSE; imagen.existefich := TRUE;
	idrepetido := FALSE;
	criterio := StrPas(bTem);
	{ Inicializamos la barra de menús }
	make_menu();
	
	{ Creamos la ventana }
	window := gtk_window_new(GTK_WINDOW_TOPLEVEL);
        gtk_window_set_title(pGtkWindow(window), 'JABAGI 3.1');
	//gtk_widget_set_usize(pGtkWidget(window), 775, 570);
	gtk_widget_set_usize(pGtkWidget(window), ancho, alto);
	//gtk_window_set_policy(PGTKWINDOW(window),0,0,0);
        gtk_window_set_position(GTK_WINDOW(window),GTK_WIN_POS_CENTER);  
        gtk_signal_connect(pGtkObject(window),'destroy', tGtkSignalFunc(@gtk_main_quit), NIL);

	{ Creamos el contenedor principal }
        vbox := gtk_vbox_new(false, 5);
        gtk_container_set_border_width(pGtkContainer(vbox), 5);
	gtk_box_pack_start(GTK_BOX(vbox), menu_bar, FALSE, TRUE, 0);
        gtk_container_add(pGtkContainer(window), vbox);

	frame_buscador:= gtk_frame_new('Buscador');
	gtk_box_pack_start(GTK_BOX(vbox), frame_buscador, false, true, 10);
	gtk_frame_set_shadow_type(GTK_FRAME(frame_buscador), GTK_SHADOW_ETCHED_OUT);
	
	frame_listado:= gtk_frame_new('Resultado');
	gtk_box_pack_start(GTK_BOX(vbox), frame_listado, true, true, 10);
	gtk_frame_set_shadow_type(GTK_FRAME(frame_listado), GTK_SHADOW_ETCHED_OUT);

	{ Creamos el buscador }
	hboxBot := gtk_hbox_new(FALSE, 0);
        gtk_container_set_border_width(GTK_CONTAINER(hboxBot), 10);
        gtk_container_add(GTK_CONTAINER(frame_buscador), hboxBot);
	ancho_buscador := 660;
	if (ancho>=1024) then ancho_buscador := 880;
	gtk_container_add(GTK_CONTAINER(hboxBot), crear_botones_buscador(0,FALSE, pchar(''), 10, ancho_buscador, 20,GTK_BUTTONBOX_START));
	gtk_box_pack_start(GTK_BOX(hboxBot),crear_botones_buscador(1,FALSE, pchar(''), 10, 2, 2,GTK_BUTTONBOX_START), FALSE, FALSE, 1);

        { Creamos una ventana con barras de desplazamiento donde incluir la tabla }
        scroll := gtk_scrolled_window_new(NIL, NIL);
        gtk_scrolled_window_set_policy(pGtkScrolledWindow(scroll),GTK_POLICY_AUTOMATIC, GTK_POLICY_ALWAYS);
	gtk_container_add(pGtkContainer(frame_listado), scroll);

        { Creamos el componente "lista" que será la tabla donde se visualizan los datos }
        thelist := gtk_clist_new_with_titles(11, titles);

        gtk_container_add(pGtkContainer(scroll), thelist);
        { It isn't necessary to shadow the border, but it looks nice :) }
        gtk_clist_set_shadow_type(pGtkCList(thelist), GTK_SHADOW_OUT);


	{ Es necesario indicar el ancho de las columnas para que no se solapen. La primera columna es la 0 }
        gtk_clist_set_column_width(pGtkCList(thelist), 0, 70);
        gtk_clist_set_column_width(pGtkCList(thelist), 1, 70);
        gtk_clist_set_column_width(pGtkCList(thelist), 2, 80);
        gtk_clist_set_column_width(pGtkCList(thelist), 3, 75);
        gtk_clist_set_column_width(pGtkCList(thelist), 4, 70);
        gtk_clist_set_column_width(pGtkCList(thelist), 5, 50);
        gtk_clist_set_column_width(pGtkCList(thelist), 6, 50);
        gtk_clist_set_column_width(pGtkCList(thelist), 7, 85);
        gtk_clist_set_column_width(pGtkCList(thelist), 8, 85);
        gtk_clist_set_column_width(pGtkCList(thelist), 9, 50);
        gtk_clist_set_column_width(pGtkCList(thelist), 10, 15);
	
	gtk_clist_set_selection_mode(pGtkCList(thelist), GTK_SELECTION_MULTIPLE);
	gtk_signal_connect(pGtkObject(thelist), 'select_row', tGtksignalfunc(@selection_made), siElegida);
    	gtk_signal_connect(pGtkObject(thelist), 'unselect_row', tGtksignalfunc(@selection_made), noElegida);

	{ Creamos los botones y los añadimos a la ventana }
        hbox := gtk_hbox_new(false, 0);
        gtk_box_pack_start(pGtkBox(vbox), hbox, false, true, 0);
        button_insertar := gtk_button_new_with_label('Insertar Imagen');
        button_modificar := gtk_button_new_with_label('Modificar Imagen');
        button_conjunto := gtk_button_new_with_label('Crear Conjunto');
        button_borrar := gtk_button_new_with_label('Borrar Imagen');
        button_importar := gtk_button_new_with_label('Importar Imágenes');
	button_exportar := gtk_button_new_with_label('Exportar Imágenes');
        gtk_box_pack_start(pGtkBox(hbox), button_insertar, true, true, 0);
        gtk_box_pack_start(pGtkBox(hbox), button_modificar, true, true, 0);
        gtk_box_pack_start(pGtkBox(hbox), button_conjunto, true, true, 0);
        gtk_box_pack_start(pGtkBox(hbox), button_borrar, true, true, 0);
        gtk_box_pack_start(pGtkBox(hbox), button_importar, true, true, 0);
        gtk_box_pack_start(pGtkBox(hbox), button_exportar, true, true, 0);

	{ Conectamos cada botón con su función correspondiente }	
        gtk_signal_connect_object(pGtkObject(button_insertar), 'clicked', tGtksignalfunc(@AbrirImagen), gpointer(thelist));
        gtk_signal_connect_object(pGtkObject(button_modificar), 'clicked', tGtksignalfunc(@modificar_imagen), gpointer(thelist));
        gtk_signal_connect_object(pGtkObject(button_borrar),'clicked', tGtksignalfunc(@borrar_imagen), gpointer(thelist));
        gtk_signal_connect_object(pGtkObject(button_borrar),'clicked', tGtksignalfunc(@buscar_imagen), gpointer(thelist));
        gtk_signal_connect_object(pGtkObject(button_importar),'clicked', tGtksignalfunc(@importar_imagenes), gpointer(thelist));
        gtk_signal_connect_object(pGtkObject(button_exportar),'clicked', tGtksignalfunc(@Exportar_imagenes), gpointer(thelist));
	gtk_signal_connect_object(pGtkObject(button_conjunto), 'clicked', tGtksignalfunc(@crear_conjunto), gpointer(thelist));
	gtk_signal_connect_object(pGtkObject(button_buscar), 'clicked', tGtksignalfunc(@buscar_imagen), gpointer(thelist));
	gtk_signal_connect_object(pGtkOBJECT(texto_buscador), 'activate', GTK_SIGNAL_FUNC(@buscar_imagen), gpointer(thelist));
	gtk_signal_connect_object(pGtkObject(rbutton_tem), 'clicked', tGtksignalfunc(@asignar_criterio), bTem);
	//gtk_signal_connect_object(pGtkObject(rbutton_stem), 'clicked', tGtksignalfunc(@asignar_criterio), bTem);
	gtk_signal_connect_object(pGtkObject(rbutton_eti), 'clicked', tGtksignalfunc(@asignar_criterio), bEti);
       { Mostramos todos los widgets y añadimos el bucle principal gtk_main }
       gtk_widget_show_all(window);
       gtk_main();
End.     


