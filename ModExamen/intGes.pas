Unit intGes;

Interface

Uses glib2,gtk2,gdk2,sysutils,tratadoXML,miMysql,GestionImagenes;

Procedure destroy( widget : pGtkWidget; data : gpointer ); cdecl;
Procedure destroy_wid(widget : pGtkWidget; data : gpointer ); cdecl;
Procedure file_ok_sel( w : pGtkWidget ; fs : pGtkFileSelection ); cdecl;
Procedure enter_callback( widget, entry : pGtkWidget); cdecl;

Var 	bandera_eleccion    : boolean;
   	bandera_img	    : boolean;
	bandera_importar    : boolean;
	bandera_exportar    : boolean;
        nombreImagen 	    : string;
	frame_horz	    : PGtkWidget;		{ Frames para el cuadro de dialogo de insercion de imagen.	  }
	frame_vert	    : PGtkWidget;
	frame_horzm	    : PGtkWidget;		{ Frames para el cuadro de dialogo de modificar imagen.	  	  }
	frame_vertm	    : PGtkWidget;
	{ Estos son los widgets que necesito para modificar_imagen }
	labelm0, labelm1, labelm2, labelm3,labelm4, 
	labelm5, labelm6,labelm7, labelm8, labelm9	: PGtkWidget;	
	nombre_img,subt_img,tem_img,tipo_img,tam_img,anc_img,alt_img,eti_img,desc_img,id_img: PGtkWidget;

Implementation
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Procedure destroy( widget : pGtkWidget; data : gpointer ); cdecl;	{ Procedure que destruye un widget principal.			}
Begin    
           bandera_img := TRUE;
           bandera_eleccion := TRUE;
	   bandera_importar := TRUE;
	   bandera_exportar := TRUE;
	   CerrarDB();
           gtk_main_quit();
End;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Procedure destroy_wid(widget : pGtkWidget; data : gpointer ); cdecl;	{ Como la de arriba, pero destruye un widget no principal.	}
Begin
	  bandera_img := TRUE;
          bandera_eleccion := TRUE;
	  bandera_importar := TRUE;
	  bandera_exportar := TRUE;
          gtk_widget_destroy(widget);
End;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Procedure file_ok_sel( w : pGtkWidget ; fs : pGtkFileSelection ); cdecl; { Con este seleccionamos ficheros, y dependiendo de qué botón la}
Var i:longint; 								{ llame, hace unas funciones u otras.				}
Begin	   nombreImagen := '';
	   if not bandera_eleccion then begin
			nombreImagen := gtk_file_selection_get_filename(GTK_FILE_SELECTION(fs));+
			imagen.fichero := nombreImagen;
			i := length(nombreImagen);
			imagen.titulo := '';
			while(nombreImagen[i]<> '/') do i := i - 1;
			i := i + 1;
			writeln(nombreImagen);	
			while(i<=length(nombreImagen)) do begin
					imagen.titulo := imagen.titulo + nombreImagen[i];
					i := i + 1;
					end;
			//gtk_entry_set_text(pGtkENTRY(nombre_img), @nombreImagen[i]);
			end;
	   bandera_img := TRUE;
           bandera_eleccion := TRUE;
	   bandera_importar := TRUE;
	   bandera_exportar := TRUE;
           writeln(nombreImagen);
End;   
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Procedure enter_callback( widget, entry : pGtkWidget); cdecl;
Var
           entry_text : pgchar;
Begin
           entry_text := gtk_entry_get_text(pGtkEntry(entry));
End;         

End.
