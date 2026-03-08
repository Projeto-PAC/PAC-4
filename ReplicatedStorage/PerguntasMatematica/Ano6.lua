local Util = require(script.Parent.Utilidades)

local Modulo = {}

-- FACIL
function Modulo.Facil()

	local usarDecimal = math.random() < 0.4

	local a
	local b

	if usarDecimal then
		a = Util.decimal(1,20)
		b = Util.decimal(1,20)
	else
		a = math.random(1,40)
		b = math.random(1,40)
	end

	local resposta = Util.arredondar(a + b)

	local pergunta = "Quanto é "..Util.formatarNumero(a).." + "..Util.formatarNumero(b).." ?"

	return pergunta,resposta,Util.gerarOpcoes(resposta)

end


-- MEDIO
function Modulo.Medio()

	local usarDecimal = math.random() < 0.3

	local a
	local b

	if usarDecimal then
		a = Util.decimal(1,30)
		b = Util.decimal(1,30)
	else
		a = math.random(-30,30)
		b = math.random(-30,30)
	end

	local resposta = Util.arredondar(a - b)

	local pergunta = "Quanto é "..Util.formatarNumero(a).." - ("..Util.formatarNumero(b)..") ?"

	return pergunta,resposta,Util.gerarOpcoes(resposta)

end


-- DIFICIL (multiplicação inteira)
function Modulo.Dificil()

	local a = math.random(2,12)
	local b = math.random(2,12)

	local resposta = a*b

	local pergunta = "Quanto é "..a.." × "..b.." ?"

	return pergunta,resposta,Util.gerarOpcoes(resposta)

end


return Modulo