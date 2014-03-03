UNIT errorsInOut;

INTERFACE

PROCEDURE calcError(error:integer);

IMPLEMENTATION

{ procedure calcError, nos va a devolver errores que sucedan cuando trabaja
con ficheros }

PROCEDURE calcError(error:integer);

Begin

	case error of
			{Errores del Dos}
			2 : writeln('Archivo no encontrado');
			3 : writeln('Path no encontrado');
			4 : writeln('Demasiados archivos abiertos');
			5 : writeln('Acceso denegado');
			6 : writeln('Variable de manipulacion de archivo invalida');
			12 : writeln('Modo de acceso al archivo invalido');
			15 : writeln('Numero de disco invalido');
			16 : writeln('No se puede borrar el actual directorio');
			17 : writeln('No puede renombrar al otro lado de los volumenes');
			{Errores de entrada y salida}
			100 : writeln('Error cuando se intentaba leer desde el disco');
			101 : writeln('Error cuando se intentaba escribir en el disco');
			102 : writeln('Archivo no asignado o adjuntado');
			103 : writeln('Archivo no abierto');
			104 : writeln('Archivo no abierto para entrada');
			105 : writeln('Archivo no abierto para salida de datos');
			106 : writeln('Numero invalido');
			{Errores fatales}
			150 : writeln('Disco esta protegido para escritura');
			151 : writeln('Dispositivo desconocido');
			152 : writeln('Disco no listo');
			153 : writeln('Comando desconocido');
			154 : writeln('Chequeo de CRC fallado');
			155 : writeln('Disco especificado invalido');
			156 : writeln('Fallo al buscar en el disco');
			157 : writeln('Tipo invalido');
			158 : writeln('Sector no encontrado');
			159 : writeln('Impresora sin papel');
			160 : writeln('Error cuando se intentaba escribir en el dispositivo');
			161 : writeln('Error cuando se intentaba leer desde el dispositivo');
			162 : writeln('Fallo del Hardware');
		end;
End;

END.
