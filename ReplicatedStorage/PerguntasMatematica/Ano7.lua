local Util = require(script.Parent.Utilidades)

local Modulo = {}

function Modulo.Facil()

	local a = Util.decimal(1,20)
	local b = Util.decimal(1,20)

	local resposta = Util.arredondar(a + b)

	local pergunta = "Resolva: "..Util.formatarNumero(a).." + "..Util.formatarNumero(b)

	return pergunta,resposta,Util.gerarOpcoes(resposta)

end


function Modulo.Medio()

	local a = math.random(2,12)
	local b = math.random(2,12)

	local resposta = a*b

	local pergunta = "Quanto é "..a.." × "..b.." ?"

	return pergunta,resposta,Util.gerarOpcoes(resposta)

end


function Modulo.Dificil()

	local divisor = math.random(2,12)
	local resposta = math.random(2,12)

	local dividendo = divisor * resposta

	local pergunta = "Quanto é "..dividendo.." ÷ "..divisor.." ?"

	return pergunta,resposta,Util.gerarOpcoes(resposta)

end


return Modulo