local Util = require(script.Parent.Utilidades)

local Modulo = {}

function Modulo.Facil()

	local raiz = math.random(2,12)
	local numero = raiz * raiz

	local pergunta = "Qual é √"..numero.." ?"

	return pergunta,raiz,Util.gerarOpcoes(raiz)

end


function Modulo.Medio()

	local x = math.random(1,20)
	local a = math.random(1,10)

	local resultado = x + a

	local pergunta = "Resolva: x + "..a.." = "..resultado

	return pergunta,x,Util.gerarOpcoes(x)

end


function Modulo.Dificil()

	local a = math.random(2,12)
	local b = math.random(2,12)

	local resposta = a*b

	local pergunta = "Quanto é "..a.." × "..b.." ?"

	return pergunta,resposta,Util.gerarOpcoes(resposta)

end


return Modulo