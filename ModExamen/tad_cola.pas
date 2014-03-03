UNIT tad_cola;

INTERFACE

TYPE
	tTematica = longint;

	PNodoCola=^TnodoCola;
	TCola=record
		cab, fin:PnodoCola;
		end;
	TnodoCola=record
		Info:longint;
		Sig:PNodoCola;
		End;

PROCEDURE ColaVacia(var C:tCola);
FUNCTION EsVacia(C:tCola):boolean;
FUNCTION Primero(C:tCola):longint;
PROCEDURE Poner(var C:tCola; tematica:longint);
PROCEDURE Quitar(var C:tCola; var tematica:longint);
PROCEDURE Suprimir(var C:tCola);

IMPLEMENTATION

PROCEDURE ColaVacia(var C:tCola);
Begin
	C.cab:=nil;
	C.fin:=nil;
End;

FUNCTION EsVacia(C:tCola):boolean;
Begin
	EsVacia:= C.cab=nil;
End;

FUNCTION Primero(C:tCola):longint;
Begin
if Not EsVacia(C)
	then Primero:=C.cab^.Info;
end;

PROCEDURE Poner(var C:tCola; tematica:longint);
var aux:PNodoCola;
Begin
	new(aux);
	aux^.Info:=tematica;
	aux^.Sig:=nil;

	If EsVacia(C)
		then
		begin
			C.Cab:=aux;
			C.fin:=aux;
		end
		else
		begin
			C.fin^.sig:=aux;
			C.fin:=aux;
		end;
End;

PROCEDURE Suprimir(var C:tCola);
var aux:PNodoCola;
begin
if not EsVacia(C) then
	begin 
		aux:=C.cab;
		C.cab:=C.Cab^.sig;
		If c.cab=nil then c.fin:=nil;
		dispose(aux);
	end;
end;

PROCEDURE Quitar (var C:tCola; var tematica:longint);

begin
	If not esvacia(c) then
		begin
			tematica := Primero(c);
			Suprimir(c);
			end;
end;

END.
